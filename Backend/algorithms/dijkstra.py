"""
Dijkstra's algorithm for minimum-travel-time routing (FR: Optimize Vehicle Routes,
Handle Blocked Roads, Handle Unreachable Locations).

Graph model
    nodes  : intersections / locations (any hashable id)
    edges  : roads, weight = travel time in minutes (must be >= 0)
    blocked roads are simply never added to the adjacency list, or can be
    excluded per-query with `blocked_edges`.

Complexity: O((V + E) log V) using a binary heap (heapq) with lazy deletion.
"""

import heapq
import math
from dataclasses import dataclass, field

INF = math.inf


@dataclass
class PathResult:
    nodes: list            # node ids from source to target (inclusive)
    edges: list            # edge ids used, in order
    total_time: float      # minutes


@dataclass
class Graph:
    # node -> list of (neighbour, weight, edge_id)
    adj: dict = field(default_factory=dict)

    def add_node(self, node):
        self.adj.setdefault(node, [])

    def add_edge(self, u, v, weight, edge_id=None, two_way=True):
        if weight is None or weight < 0 or math.isnan(weight):
            raise ValueError("Edge weight (travel time) must be a non-negative number.")
        self.add_node(u)
        self.add_node(v)
        self.adj[u].append((v, weight, edge_id))
        if two_way:
            self.adj[v].append((u, weight, edge_id))

    def __contains__(self, node):
        return node in self.adj

    @property
    def node_count(self):
        return len(self.adj)


def dijkstra(graph, source, targets=None, blocked_edges=frozenset()):
    """
    Single-source shortest travel times.

    targets: optional iterable of nodes. When given, the search stops as soon
             as every reachable target is settled (early exit), which makes
             one-vehicle-to-many-emergencies queries much faster.
    Returns (dist, prev) where prev[node] = (previous_node, edge_id).
    """
    if source not in graph:
        return {}, {}

    dist = {source: 0.0}
    prev = {}
    settled = set()
    remaining = set(targets) if targets is not None else None
    if remaining is not None:
        remaining.discard(source)
    heap = [(0.0, 0, source)]
    counter = 1  # tie-breaker so nodes never need to be comparable

    while heap:
        d, _, u = heapq.heappop(heap)
        if u in settled:
            continue  # stale heap entry (lazy deletion)
        settled.add(u)
        if remaining is not None:
            remaining.discard(u)
            if not remaining:
                break
        for v, w, edge_id in graph.adj[u]:
            if edge_id is not None and edge_id in blocked_edges:
                continue
            nd = d + w
            if nd < dist.get(v, INF):
                dist[v] = nd
                prev[v] = (u, edge_id)
                heapq.heappush(heap, (nd, counter, v))
                counter += 1

    if remaining is not None:
        # Only report distances that are final.
        dist = {n: dist[n] for n in settled}
    return dist, prev


def reconstruct_path(prev, source, target, total_time):
    nodes, edges = [target], []
    node = target
    while node != source:
        node, edge_id = prev[node]
        edges.append(edge_id)
        nodes.append(node)
    nodes.reverse()
    edges.reverse()
    return PathResult(nodes=nodes, edges=edges, total_time=total_time)


def shortest_path(graph, source, target, blocked_edges=frozenset()):
    """
    Fastest route from source to target.
    Returns PathResult, or None when the target is unreachable
    (disconnected network or every route uses a blocked road).
    """
    if source not in graph or target not in graph:
        return None
    if source == target:
        return PathResult(nodes=[source], edges=[], total_time=0.0)
    dist, prev = dijkstra(graph, source, targets=[target], blocked_edges=blocked_edges)
    if target not in dist:
        return None
    return reconstruct_path(prev, source, target, dist[target])
