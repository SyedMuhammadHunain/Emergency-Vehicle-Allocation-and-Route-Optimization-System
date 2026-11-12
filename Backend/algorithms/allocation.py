"""
Dynamic Programming allocation of emergencies to vehicles
(FR: Allocate Emergencies using Dynamic Programming).

Problem
-------
We have N pending emergencies and a limited fleet split into vehicle types
(Ambulance, Fire Brigade, Rescue Vehicle, ...). Each emergency:
  * has a priority score (0..100),
  * needs k vehicles (vehicles_required),
  * can be served by one or more compatible vehicle types,
  * may be unreachable from some vehicles (blocked / disconnected roads).

Choose WHICH emergencies to serve, and with WHICH vehicle type, so that the
total benefit is maximal and we never use more vehicles of a type than exist.

DP formulation (multi-dimensional 0/1 knapsack with choices)
-------------------------------------------------------------
  capacity vector C = (c_1, ..., c_T)   number of usable vehicles per type
  state            s = (u_1, ..., u_T)   vehicles of each type already used

  dp_i(s) = best total benefit using only emergencies 1..i with usage s

  dp_i(s) = max( dp_{i-1}(s),                                   # leave pending
                 max over options (t, k) of emergency i:
                     dp_{i-1}(s - k*e_t) + benefit(i, t) )      # serve with k of type t

  Answer: max over all states s <= C of dp_N(s); back-pointers rebuild choices.

  Number of states = prod(c_t + 1). For 20 vehicles over 3 types that is at
  most 8*8*7 = 448 states, so 50 emergencies need only ~50 * 448 * |options|
  steps (well under the 2 s requirement).

Benefit
-------
  benefit(i, t) = priority_i^2 * timeliness(i, t)
  timeliness    = 1 / (1 + avg_travel_time_of_best_k_vehicles_of_type_t / 30)

  Squaring the priority makes the objective favour serious emergencies:
  one emergency with priority 90 (8100) beats two with priority 45 (2*2025),
  so "helping more people" never ignores a serious emergency.

Concrete vehicles
-----------------
After the DP decides "emergency i gets k vehicles of type t", emergencies are
processed in descending priority and each takes its k nearest still-free
vehicles of that type (by Dijkstra travel time). If conflicts leave too few
reachable vehicles, another compatible type with free vehicles is tried;
otherwise the emergency stays pending.
"""

import math
from dataclasses import dataclass, field

TIMELINESS_HALF_LIFE_MIN = 30.0

REASON_SELECTED = "SELECTED"
REASON_LOWER_PRIORITY = "LOWER_PRIORITY"
REASON_INSUFFICIENT = "INSUFFICIENT_RESOURCES"
REASON_UNREACHABLE = "UNREACHABLE"
REASON_CONFLICT = "VEHICLE_CONFLICT"


@dataclass
class EmergencyInput:
    id: object
    priority: float
    vehicles_required: int = 1
    compatible_types: tuple = ()
    # Optional: subset of vehicle ids that carry the required equipment.
    # None means "every vehicle of a compatible type is eligible".
    eligible_vehicle_ids: frozenset = None


@dataclass
class VehicleInput:
    id: object
    type: str


@dataclass
class Assignment:
    emergency_id: object
    vehicle_ids: list
    vehicle_type: str
    travel_times: list          # minutes, parallel to vehicle_ids
    benefit: float


@dataclass
class AllocationResult:
    assignments: list = field(default_factory=list)
    pending: list = field(default_factory=list)          # emergency ids
    unreachable: list = field(default_factory=list)      # emergency ids
    reasons: dict = field(default_factory=dict)          # emergency id -> (code, text)
    total_benefit: float = 0.0
    dp_states: int = 0


def timeliness(travel_time):
    return 1.0 / (1.0 + travel_time / TIMELINESS_HALF_LIFE_MIN)


def benefit(priority, avg_travel_time):
    return (priority ** 2) * timeliness(avg_travel_time)


def _eligible(em, vehicle):
    return em.eligible_vehicle_ids is None or vehicle.id in em.eligible_vehicle_ids


def allocate(emergencies, vehicles, travel_times):
    """
    emergencies : list[EmergencyInput]
    vehicles    : list[VehicleInput]  (only vehicles that are free and feasible)
    travel_times: dict[(vehicle_id, emergency_id)] -> minutes; a missing key or
                  math.inf means that vehicle cannot reach that emergency.
    """
    result = AllocationResult()
    if not emergencies:
        return result

    types = sorted({v.type for v in vehicles})
    type_index = {t: i for i, t in enumerate(types)}
    capacity = [0] * len(types)
    by_type = {t: [] for t in types}
    for v in vehicles:
        capacity[type_index[v.type]] += 1
        by_type[v.type].append(v)

    def time_of(vid, eid):
        return travel_times.get((vid, eid), math.inf)

    # Process highest priority first: deterministic and gives the greedy
    # vehicle-picking step the right order.
    ordered = sorted(emergencies, key=lambda e: (-e.priority, str(e.id)))

    # ---- 1. Build feasible options per emergency -------------------------
    options = {}  # eid -> list of (type_idx, k, benefit, type)
    for em in ordered:
        k = max(1, int(em.vehicles_required))
        opts = []
        any_compatible_vehicle = False
        enough_compatible_vehicles = False
        for t in em.compatible_types:
            if t not in by_type:
                continue
            eligible = [v for v in by_type[t] if _eligible(em, v)]
            if eligible:
                any_compatible_vehicle = True
            if len(eligible) >= k:
                enough_compatible_vehicles = True
            reachable = sorted(
                time_of(v.id, em.id) for v in eligible if math.isfinite(time_of(v.id, em.id))
            )
            if len(reachable) >= k:
                avg = sum(reachable[:k]) / k
                opts.append((type_index[t], k, benefit(em.priority, avg), t))
        options[em.id] = opts
        if not opts:
            if enough_compatible_vehicles:
                result.unreachable.append(em.id)
                result.reasons[em.id] = (
                    REASON_UNREACHABLE,
                    "No valid route exists from any suitable vehicle to this location "
                    "in the current road network.",
                )
            else:
                result.pending.append(em.id)
                need = ", ".join(em.compatible_types) or "a suitable vehicle"
                if any_compatible_vehicle:
                    text = f"Insufficient resources: needs {k} x ({need}) but fewer are available."
                else:
                    text = f"Insufficient resources: no available {need} with the required crew/equipment."
                result.reasons[em.id] = (REASON_INSUFFICIENT, text)

    candidates = [em for em in ordered if options[em.id]]

    # ---- 2. Dynamic Programming over capacity states ---------------------
    start = tuple([0] * len(types))
    dp = {start: 0.0}
    back = []  # back[i][state] = (previous_state, option or None)
    for em in candidates:
        new_dp = dict(dp)                      # option "leave pending"
        choice = {s: (s, None) for s in dp}
        for state, value in dp.items():
            for opt in options[em.id]:
                ti, k, gain, _ = opt
                if state[ti] + k > capacity[ti]:
                    continue
                ns = list(state)
                ns[ti] += k
                ns = tuple(ns)
                nv = value + gain
                if nv > new_dp.get(ns, -1.0) + 1e-9:
                    new_dp[ns] = nv
                    choice[ns] = (state, opt)
        dp = new_dp
        back.append(choice)
        result.dp_states = max(result.dp_states, len(dp))

    best_state = max(dp, key=lambda s: (dp[s], [-x for x in s]))
    result.total_benefit = round(dp[best_state], 3)

    # Back-track to find the chosen option of each emergency.
    chosen = {}
    state = best_state
    for i in range(len(candidates) - 1, -1, -1):
        prev_state, opt = back[i][state]
        if opt is not None:
            chosen[candidates[i].id] = opt
        state = prev_state

    # ---- 3. Pick concrete vehicles (nearest first, priority order) -------
    used = set()
    for em in candidates:
        opt = chosen.get(em.id)
        if opt is None:
            result.pending.append(em.id)
            result.reasons[em.id] = (
                REASON_LOWER_PRIORITY,
                "Not selected: available vehicles were allocated to higher-benefit emergencies.",
            )
            continue
        # Try the DP's type first, then other options as fallback.
        tried = [opt] + [o for o in options[em.id] if o is not opt]
        done = False
        for _, k, _, vtype in tried:
            free = [
                (time_of(v.id, em.id), str(v.id), v)
                for v in by_type[vtype]
                if v.id not in used and _eligible(em, v) and math.isfinite(time_of(v.id, em.id))
            ]
            if len(free) < k:
                continue
            free.sort(key=lambda x: (x[0], x[1]))
            picked = free[:k]
            for _, _, v in picked:
                used.add(v.id)
            times = [round(t, 2) for t, _, _ in picked]
            gain = benefit(em.priority, sum(times) / k)
            result.assignments.append(
                Assignment(
                    emergency_id=em.id,
                    vehicle_ids=[v.id for _, _, v in picked],
                    vehicle_type=vtype,
                    travel_times=times,
                    benefit=round(gain, 3),
                )
            )
            result.reasons[em.id] = (
                REASON_SELECTED,
                f"Selected by DP (priority {em.priority}). {k} x {vtype}, "
                f"fastest ETA {min(times):.1f} min via Dijkstra.",
            )
            done = True
            break
        if not done:
            result.pending.append(em.id)
            result.reasons[em.id] = (
                REASON_CONFLICT,
                "Selected, but the suitable vehicles were taken by higher-priority emergencies.",
            )

    return result
