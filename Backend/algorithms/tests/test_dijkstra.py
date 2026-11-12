import math
import random
import time
import unittest

from algorithms.dijkstra import Graph, dijkstra, shortest_path


def sample_graph():
    #   A --1-- B --1-- C
    #   |               |
    #   5               1
    #   |               |
    #   D ------10----- E
    g = Graph()
    g.add_edge("A", "B", 1, edge_id=1)
    g.add_edge("B", "C", 1, edge_id=2)
    g.add_edge("C", "E", 1, edge_id=3)
    g.add_edge("A", "D", 5, edge_id=4)
    g.add_edge("D", "E", 10, edge_id=5)
    return g


class DijkstraTests(unittest.TestCase):
    def test_shortest_path_minimum_time(self):
        r = shortest_path(sample_graph(), "A", "E")
        self.assertEqual(r.nodes, ["A", "B", "C", "E"])
        self.assertEqual(r.edges, [1, 2, 3])
        self.assertAlmostEqual(r.total_time, 3)

    def test_blocked_road_finds_alternative(self):
        r = shortest_path(sample_graph(), "A", "E", blocked_edges={2})
        self.assertEqual(r.nodes, ["A", "D", "E"])
        self.assertAlmostEqual(r.total_time, 15)
        self.assertNotIn(2, r.edges)

    def test_unreachable_when_all_routes_blocked(self):
        self.assertIsNone(shortest_path(sample_graph(), "A", "E", blocked_edges={2, 5}))

    def test_disconnected_node_unreachable(self):
        g = sample_graph()
        g.add_node("Z")
        self.assertIsNone(shortest_path(g, "A", "Z"))

    def test_unknown_node(self):
        self.assertIsNone(shortest_path(sample_graph(), "A", "NOPE"))

    def test_same_source_and_target(self):
        r = shortest_path(sample_graph(), "C", "C")
        self.assertEqual(r.nodes, ["C"])
        self.assertEqual(r.total_time, 0)

    def test_one_way_edge(self):
        g = Graph()
        g.add_edge(1, 2, 4, edge_id="x", two_way=False)
        self.assertIsNotNone(shortest_path(g, 1, 2))
        self.assertIsNone(shortest_path(g, 2, 1))

    def test_negative_weight_rejected(self):
        with self.assertRaises(ValueError):
            Graph().add_edge(1, 2, -1)

    def test_multi_target_early_exit_distances_are_exact(self):
        g = sample_graph()
        full, _ = dijkstra(g, "A")
        partial, _ = dijkstra(g, "A", targets=["C", "D"])
        self.assertEqual(partial["C"], full["C"])
        self.assertEqual(partial["D"], full["D"])

    def test_matches_brute_force_on_random_graphs(self):
        rnd = random.Random(7)
        for _ in range(20):
            n = 12
            g = Graph()
            for i in range(n):
                g.add_node(i)
            for _ in range(30):
                u, v = rnd.randrange(n), rnd.randrange(n)
                if u != v:
                    g.add_edge(u, v, rnd.randint(1, 20))
            # Floyd-Warshall as ground truth
            d = [[math.inf] * n for _ in range(n)]
            for i in range(n):
                d[i][i] = 0
                for v, w, _ in g.adj[i]:
                    d[i][v] = min(d[i][v], w)
            for k in range(n):
                for i in range(n):
                    for j in range(n):
                        d[i][j] = min(d[i][j], d[i][k] + d[k][j])
            dist, _ = dijkstra(g, 0)
            for j in range(n):
                self.assertEqual(dist.get(j, math.inf), d[0][j])


class DijkstraPerformanceTests(unittest.TestCase):
    def test_20000_nodes_under_1_second(self):
        """NFR Performance: one route on a 20,000-node / ~60,000-edge graph < 1 s."""
        rnd = random.Random(1)
        side = 142  # 142 * 142 ~= 20,164 nodes
        g = Graph()
        edge_id = 0
        for r in range(side):
            for c in range(side):
                n = r * side + c
                if c + 1 < side:
                    edge_id += 1
                    g.add_edge(n, n + 1, rnd.uniform(0.2, 2.0), edge_id)
                if r + 1 < side:
                    edge_id += 1
                    g.add_edge(n, n + side, rnd.uniform(0.2, 2.0), edge_id)
        # add diagonals until ~60k edges
        while edge_id < 60000:
            n = rnd.randrange(side * side - side - 1)
            edge_id += 1
            g.add_edge(n, n + side + 1, rnd.uniform(0.3, 2.5), edge_id)
        self.assertGreaterEqual(g.node_count, 20000)

        t0 = time.perf_counter()
        r = shortest_path(g, 0, side * side - 1)
        elapsed = time.perf_counter() - t0
        self.assertIsNotNone(r)
        self.assertLess(elapsed, 1.0, f"Dijkstra took {elapsed:.3f}s")


if __name__ == "__main__":
    unittest.main()
