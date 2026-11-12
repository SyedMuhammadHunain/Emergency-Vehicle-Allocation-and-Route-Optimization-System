"""
Road graph service: loads the road network from MySQL into the pure-Python
Dijkstra Graph, caches it in memory, and converts GPS points to routes.

The cache is invalidated through GraphVersion (a counter row in the DB that is
bumped whenever a road/node changes), so it also works with several server
processes.
"""

import math
import threading
from dataclasses import dataclass

from django.conf import settings

from algorithms.dijkstra import Graph, dijkstra, reconstruct_path
from dispatch.models import GraphVersion, RoadEdge, RoadNode

EARTH_RADIUS_KM = 6371.0088
_lock = threading.Lock()
_cache = {"version": None, "graph": None}


def haversine_km(lat1, lng1, lat2, lng2):
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = p2 - p1
    dl = math.radians(lng2 - lng1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * EARTH_RADIUS_KM * math.asin(math.sqrt(a))


@dataclass
class RouteInfo:
    nodes: list
    edges: list
    coords: list          # [[lat, lng], ...] ready for a map polyline
    eta_minutes: float
    distance_km: float


class RoadGraph:
    def __init__(self, nodes, edges):
        self.graph = Graph()
        self.coords = {}
        self.edge_distance = {}
        for node_id, lat, lng in nodes:
            self.graph.add_node(node_id)
            self.coords[node_id] = (lat, lng)
        for edge_id, u, v, minutes, two_way, dist in edges:
            self.graph.add_edge(u, v, minutes, edge_id=edge_id, two_way=two_way)
            self.edge_distance[edge_id] = dist
        self._ids = list(self.coords)
        self._lats = [self.coords[i][0] for i in self._ids]
        self._lngs = [self.coords[i][1] for i in self._ids]

    @property
    def is_empty(self):
        return not self._ids

    def nearest_node(self, lat, lng):
        """Return (node_id, distance_km) of the closest intersection, or (None, inf)."""
        if not self._ids:
            return None, math.inf
        # Equirectangular approximation is plenty for picking the nearest node.
        k = math.cos(math.radians(lat))
        best_i, best_d = 0, math.inf
        lats, lngs = self._lats, self._lngs
        for i in range(len(lats)):
            dy = lats[i] - lat
            dx = (lngs[i] - lng) * k
            d = dx * dx + dy * dy
            if d < best_d:
                best_i, best_d = i, d
        node = self._ids[best_i]
        return node, haversine_km(lat, lng, *self.coords[node])

    def snap(self, lat, lng):
        """Nearest node + connector minutes, or (None, inf) if off the network."""
        node, dist = self.nearest_node(lat, lng)
        if node is None or dist > settings.RESQ["MAX_SNAP_DISTANCE_KM"]:
            return None, math.inf
        return node, dist / settings.RESQ["CONNECTOR_SPEED_KMH"] * 60.0

    def travel_times(self, sources, targets):
        """
        sources: {source_key: (lat, lng)}, targets: {target_key: (lat, lng)}
        Returns {(source_key, target_key): minutes}; unreachable pairs are omitted.
        One Dijkstra run per source with early exit once all targets are settled.
        """
        snapped_t = {k: self.snap(*p) for k, p in targets.items()}
        target_nodes = {n for n, _ in snapped_t.values() if n is not None}
        out = {}
        for skey, point in sources.items():
            s_node, s_conn = self.snap(*point)
            if s_node is None:
                continue
            dist, _ = dijkstra(self.graph, s_node, targets=target_nodes)
            for tkey, (t_node, t_conn) in snapped_t.items():
                if t_node is not None and t_node in dist:
                    out[(skey, tkey)] = dist[t_node] + s_conn + t_conn
        return out

    def route(self, from_point, to_point):
        """Fastest route between two GPS points, or None if unreachable."""
        s_node, s_conn = self.snap(*from_point)
        t_node, t_conn = self.snap(*to_point)
        if s_node is None or t_node is None:
            return None
        dist, prev = dijkstra(self.graph, s_node, targets=[t_node])
        if t_node not in dist:
            return None
        path = reconstruct_path(prev, s_node, t_node, dist[t_node])
        coords = [[from_point[0], from_point[1]]]
        coords += [[*self.coords[n]] for n in path.nodes]
        coords.append([to_point[0], to_point[1]])
        road_km = sum(self.edge_distance.get(e, 0.0) for e in path.edges)
        conn_km = (s_conn + t_conn) * settings.RESQ["CONNECTOR_SPEED_KMH"] / 60.0
        return RouteInfo(
            nodes=path.nodes,
            edges=path.edges,
            coords=[[round(a, 6), round(b, 6)] for a, b in coords],
            eta_minutes=round(path.total_time + s_conn + t_conn, 2),
            distance_km=round(road_km + conn_km, 2),
        )


def _build():
    nodes = RoadNode.objects.values_list("id", "latitude", "longitude")
    edges = RoadEdge.objects.filter(is_blocked=False).values_list(
        "id", "from_node_id", "to_node_id", "travel_time", "two_way", "distance_km"
    )
    return RoadGraph(list(nodes), list(edges))


def get_graph():
    """Cached RoadGraph that excludes blocked roads."""
    version = GraphVersion.current()
    with _lock:
        if _cache["graph"] is None or _cache["version"] != version:
            _cache["graph"] = _build()
            _cache["version"] = version
        return _cache["graph"]


def invalidate():
    GraphVersion.bump()
