import itertools
import math
import random
import time
import unittest

from algorithms.allocation import (
    REASON_INSUFFICIENT,
    REASON_LOWER_PRIORITY,
    REASON_UNREACHABLE,
    EmergencyInput,
    VehicleInput,
    allocate,
    benefit,
)
from algorithms.priority import priority_score, vehicles_required

AMB, FIRE, RESC = "Ambulance", "Fire Brigade", "Rescue Vehicle"


def em(eid, prio, types=(AMB,), k=1, eligible=None):
    return EmergencyInput(id=eid, priority=prio, vehicles_required=k,
                          compatible_types=tuple(types), eligible_vehicle_ids=eligible)


def all_times(vehicles, emergencies, t=5.0):
    return {(v.id, e.id): t for v in vehicles for e in emergencies}


def used_vehicle_ids(result):
    return [vid for a in result.assignments for vid in a.vehicle_ids]


class PriorityTests(unittest.TestCase):
    def test_range_and_monotonic(self):
        low = priority_score(1, 1, 1)
        high = priority_score(5, 5, 50, waiting_minutes=30)
        self.assertGreater(high, low)
        self.assertEqual(high, 100.0)
        self.assertGreater(priority_score(4, 3, 2), priority_score(3, 3, 2))
        self.assertGreater(priority_score(3, 3, 2, 20), priority_score(3, 3, 2, 0))

    def test_invalid_input_rejected(self):
        for args in [(0, 3, 1), (6, 3, 1), (3, 0, 1), (3, 3, -1)]:
            with self.assertRaises(ValueError):
                priority_score(*args)

    def test_vehicles_required(self):
        self.assertEqual(vehicles_required(5, 10), 2)
        self.assertEqual(vehicles_required(5, 3), 1)
        self.assertEqual(vehicles_required(2, 40), 1)


class AllocationTests(unittest.TestCase):
    def test_edge_case_more_emergencies_than_vehicles(self):
        """Proposal edge case 1: five calls, three vehicles."""
        ems = [em(i, p) for i, p in enumerate([90, 40, 75, 20, 60], start=1)]
        vs = [VehicleInput(f"V{i}", AMB) for i in range(3)]
        r = allocate(ems, vs, all_times(vs, ems))
        served = sorted(a.emergency_id for a in r.assignments)
        self.assertEqual(served, [1, 3, 5])           # three highest priorities
        self.assertEqual(sorted(r.pending), [2, 4])
        self.assertEqual(r.reasons[2][0], REASON_LOWER_PRIORITY)
        self.assertEqual(len(set(used_vehicle_ids(r))), 3)

    def test_edge_case_insufficient_resources(self):
        """Proposal edge case 2: required vehicle type / count not available."""
        ems = [em("fire", 95, types=(FIRE,), k=2), em("med", 50)]
        vs = [VehicleInput("F1", FIRE), VehicleInput("A1", AMB)]
        r = allocate(ems, vs, all_times(vs, ems))
        self.assertEqual([a.emergency_id for a in r.assignments], ["med"])
        self.assertIn("fire", r.pending)
        self.assertEqual(r.reasons["fire"][0], REASON_INSUFFICIENT)

    def test_edge_case_unreachable(self):
        """Proposal edge case 3: no valid route to the location."""
        ems = [em("cut-off", 99), em("ok", 30)]
        vs = [VehicleInput("A1", AMB)]
        times = {("A1", "ok"): 4.0}  # no entry for cut-off => unreachable
        r = allocate(ems, vs, times)
        self.assertEqual(r.unreachable, ["cut-off"])
        self.assertEqual(r.reasons["cut-off"][0], REASON_UNREACHABLE)
        self.assertEqual(r.assignments[0].emergency_id, "ok")

    def test_edge_case_new_high_priority_emergency(self):
        """Proposal edge case 4: new urgent call arrives; re-plan prefers it."""
        vs = [VehicleInput("A1", AMB)]
        old = em("old", 40)
        r1 = allocate([old], vs, all_times(vs, [old]))
        self.assertEqual(r1.assignments[0].emergency_id, "old")
        new = em("new", 95)
        r2 = allocate([old, new], vs, all_times(vs, [old, new]))
        self.assertEqual(r2.assignments[0].emergency_id, "new")
        self.assertEqual(r2.pending, ["old"])

    def test_serious_emergency_not_sacrificed_for_two_minor(self):
        ems = [em("critical", 90, k=2), em("m1", 45), em("m2", 45)]
        vs = [VehicleInput("A1", AMB), VehicleInput("A2", AMB)]
        r = allocate(ems, vs, all_times(vs, ems))
        self.assertEqual([a.emergency_id for a in r.assignments], ["critical"])

    def test_vehicle_type_compatibility(self):
        ems = [em("fire", 80, types=(FIRE,)), em("med", 70, types=(AMB,))]
        vs = [VehicleInput("A1", AMB), VehicleInput("F1", FIRE)]
        r = allocate(ems, vs, all_times(vs, ems))
        got = {a.emergency_id: a.vehicle_ids[0] for a in r.assignments}
        self.assertEqual(got, {"fire": "F1", "med": "A1"})

    def test_nearest_vehicle_chosen(self):
        e = em("e", 50)
        vs = [VehicleInput("far", AMB), VehicleInput("near", AMB)]
        r = allocate([e], vs, {("far", "e"): 20.0, ("near", "e"): 3.0})
        self.assertEqual(r.assignments[0].vehicle_ids, ["near"])
        self.assertEqual(r.assignments[0].travel_times, [3.0])

    def test_equipment_eligibility(self):
        e = em("cardiac", 80, eligible=frozenset({"A2"}))
        vs = [VehicleInput("A1", AMB), VehicleInput("A2", AMB)]
        r = allocate([e], vs, {("A1", "cardiac"): 1.0, ("A2", "cardiac"): 9.0})
        self.assertEqual(r.assignments[0].vehicle_ids, ["A2"])

    def test_no_vehicles_or_no_emergencies(self):
        self.assertEqual(allocate([], [], {}).assignments, [])
        r = allocate([em("x", 50)], [], {})
        self.assertEqual(r.pending, ["x"])

    def test_never_exceeds_capacity_and_is_optimal_vs_brute_force(self):
        """DP total benefit equals exhaustive search on small random instances."""
        rnd = random.Random(42)
        types = [AMB, FIRE, RESC]
        for _ in range(60):
            vs = [VehicleInput(f"V{i}", rnd.choice(types)) for i in range(rnd.randint(1, 5))]
            ems = [
                em(f"E{j}", rnd.randint(10, 100),
                   types=tuple(rnd.sample(types, rnd.randint(1, 2))), k=rnd.randint(1, 2))
                for j in range(rnd.randint(1, 6))
            ]
            # Same travel time for every vehicle => DP benefit is exact.
            times = all_times(vs, ems, t=6.0)
            r = allocate(ems, vs, times)

            ids = used_vehicle_ids(r)
            self.assertEqual(len(ids), len(set(ids)), "vehicle used twice")

            cap = {t: sum(v.type == t for v in vs) for t in types}
            best = 0.0
            for combo in itertools.product(*[[None] + list(e.compatible_types) for e in ems]):
                use = {t: 0 for t in types}
                val = 0.0
                for e, t in zip(ems, combo):
                    if t is not None:
                        use[t] += e.vehicles_required
                        val += benefit(e.priority, 6.0)
                if all(use[t] <= cap[t] for t in types):
                    best = max(best, val)
            got = sum(a.benefit for a in r.assignments)
            self.assertAlmostEqual(got, best, places=2)


class AllocationPerformanceTests(unittest.TestCase):
    def test_50_emergencies_20_vehicles_under_2_seconds(self):
        """NFR Performance: DP for 50 pending emergencies and 20 vehicles < 2 s."""
        rnd = random.Random(3)
        types = [AMB, FIRE, RESC]
        vs = [VehicleInput(f"V{i}", types[i % 3]) for i in range(20)]
        ems = [
            em(f"E{j}", rnd.randint(5, 100),
               types=tuple(rnd.sample(types, rnd.randint(1, 3))), k=rnd.choice([1, 1, 1, 2]))
            for j in range(50)
        ]
        times = {(v.id, e.id): rnd.uniform(1, 40) for v in vs for e in ems}
        t0 = time.perf_counter()
        r = allocate(ems, vs, times)
        elapsed = time.perf_counter() - t0
        self.assertLess(elapsed, 2.0, f"DP took {elapsed:.3f}s")
        self.assertLessEqual(len(used_vehicle_ids(r)), 20)
        self.assertEqual(len(r.assignments) + len(r.pending) + len(r.unreachable), 50)
        self.assertTrue(all(math.isfinite(t) for a in r.assignments for t in a.travel_times))


if __name__ == "__main__":
    unittest.main()
