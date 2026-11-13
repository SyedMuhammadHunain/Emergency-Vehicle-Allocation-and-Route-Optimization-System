"""
Planner: connects the database to the pure algorithms.

    priority.py   -> priority score per emergency
    graph.py      -> Dijkstra travel times / routes on the MySQL road network
    allocation.py -> Dynamic Programming selection of emergencies + vehicles

All changes to assignments happen inside database transactions with row locks
(NFR Reliability / Correctness: a vehicle can never be double-booked).
"""

import logging
import math
import time

from django.conf import settings
from django.db import transaction
from django.db.models import Q
from django.utils import timezone

from algorithms.allocation import EmergencyInput, VehicleInput, allocate
from algorithms.priority import priority_score, vehicles_required
from dispatch.exceptions import BadRequest, Conflict, Unreachable
from dispatch.models import (
    COMPATIBLE_VEHICLE_TYPES,
    REQUIRED_RESOURCE_CATEGORY,
    Assignment,
    Emergency,
    EmergencyStatus,
    Plan,
    Resource,
    ResourceCategory,
    ResourceStatus,
    Vehicle,
    VehicleStatus,
)
from dispatch.services.audit import audit
from dispatch.services.graph import get_graph
from dispatch.services.notify import notify

logger = logging.getLogger("resq.planner")

ACTIVE = Assignment.Status.ACTIVE
STATUS_ORDER = [
    EmergencyStatus.REPORTED, EmergencyStatus.ASSIGNED, EmergencyStatus.EN_ROUTE,
    EmergencyStatus.ON_SCENE, EmergencyStatus.RESOLVED,
]


# ---------------------------------------------------------------------------
# Priority
# ---------------------------------------------------------------------------


def score_emergency(em, now=None):
    now = now or timezone.now()
    waiting = max(0.0, (now - em.created_at).total_seconds() / 60.0)
    em.priority_score = priority_score(em.severity, em.urgency, em.people_affected, waiting)
    em.vehicles_required = vehicles_required(em.severity, em.people_affected)
    return em


# ---------------------------------------------------------------------------
# Feasibility (crew, fuel, equipment)
# ---------------------------------------------------------------------------


def _resource_index(vehicle_ids):
    """{vehicle_id: {category: usable quantity}} (Depleted resources excluded)."""
    idx = {}
    rows = Resource.objects.filter(vehicle_id__in=vehicle_ids).exclude(status=ResourceStatus.DEPLETED)
    for r in rows.values("vehicle_id", "category", "quantity"):
        cats = idx.setdefault(r["vehicle_id"], {})
        cats[r["category"]] = cats.get(r["category"], 0) + max(0, r["quantity"])
    return idx


def vehicle_feasibility(vehicle, res_index):
    """(ok, reason) - can this vehicle be dispatched at all?"""
    if vehicle.fuel_level < settings.RESQ["MIN_FUEL_LEVEL"]:
        return False, f"Fuel too low ({vehicle.fuel_level}%)."
    crew = res_index.get(vehicle.id, {}).get(ResourceCategory.CREW, 0)
    if crew < vehicle.crew_required:
        return False, f"Not enough crew ({crew}/{vehicle.crew_required})."
    return True, ""


def vehicle_suits(vehicle, emergency, res_index):
    """(ok, reason) - is this vehicle suitable for this emergency type?"""
    if vehicle.type not in COMPATIBLE_VEHICLE_TYPES[emergency.category]:
        allowed = ", ".join(COMPATIBLE_VEHICLE_TYPES[emergency.category])
        return False, f"{vehicle.type} cannot handle {emergency.category} (needs {allowed})."
    needed = REQUIRED_RESOURCE_CATEGORY.get(emergency.category)
    if needed and res_index.get(vehicle.id, {}).get(needed, 0) <= 0:
        return False, f"Vehicle carries no {needed} equipment."
    return True, ""


# ---------------------------------------------------------------------------
# State changes for vehicles / resources
# ---------------------------------------------------------------------------


def _occupy_vehicle(vehicle):
    vehicle.status = VehicleStatus.BUSY
    vehicle.save(update_fields=["status", "updated_at"])
    Resource.objects.filter(vehicle=vehicle, status=ResourceStatus.AVAILABLE).update(status=ResourceStatus.IN_USE)


def _free_vehicle(vehicle):
    vehicle.status = VehicleStatus.AVAILABLE
    vehicle.save(update_fields=["status", "updated_at"])
    Resource.objects.filter(vehicle=vehicle, status=ResourceStatus.IN_USE).update(status=ResourceStatus.AVAILABLE)


def _apply_route(assignment, route):
    if route is None:
        assignment.route_unreachable = True
        return
    assignment.route_nodes = route.nodes
    assignment.route_edges = route.edges
    assignment.route_coords = route.coords
    assignment.eta_minutes = route.eta_minutes
    assignment.distance_km = route.distance_km
    assignment.route_unreachable = False


def _notify_assigned(em, vehicle, assignment):
    eta = f"{assignment.eta_minutes:.0f} min" if assignment.eta_minutes is not None else "unknown"
    if vehicle.driver_id:
        notify("Mission Dispatched",
               f"Emergency {em.code} assigned to your unit {vehicle.license_plate}. ETA ~{eta}.",
               target_user=vehicle.driver, emergency=em)
    if em.reported_by_id:
        notify("Emergency Assigned",
               f"Report {em.code} assigned to {vehicle.type} {vehicle.license_plate}. ETA: ~{eta}.",
               target_user=em.reported_by, emergency=em)
    notify("Unit Dispatched", f"{vehicle.type} {vehicle.license_plate} dispatched for {em.code}.",
           target_role="dispatcher", emergency=em)


# ---------------------------------------------------------------------------
# Dynamic Programming allocation run (FR-04/05/06, FR-10)
# ---------------------------------------------------------------------------


def run_allocation(reason=Plan.Reason.MANUAL, actor=None, dry_run=False):
    """
    Re-plan: pending emergencies + not-yet-started automatic assignments are
    (re)allocated over free vehicles using DP, routes via Dijkstra.

    Vehicles already EN_ROUTE / ON_SCENE and dispatcher manual assignments are
    never touched.
    """
    t0 = time.perf_counter()
    now = timezone.now()
    with transaction.atomic():
        replannable = list(
            Assignment.objects.select_for_update()
            .filter(status=ACTIVE, emergency__status=EmergencyStatus.ASSIGNED)
            .exclude(plan__reason=Plan.Reason.MANUAL_ASSIGN)
            .select_related("vehicle", "emergency")
        )
        replan_vehicle_ids = {a.vehicle_id for a in replannable}
        replan_em_ids = {a.emergency_id for a in replannable}

        vehicles = list(
            Vehicle.objects.select_for_update()
            .filter(Q(status=VehicleStatus.AVAILABLE) | Q(id__in=replan_vehicle_ids))
            .select_related("driver")
        )
        emergencies = list(
            Emergency.objects.select_for_update()
            .filter(Q(status=EmergencyStatus.REPORTED) | Q(id__in=replan_em_ids))
            .select_related("reported_by")
        )
        for em in emergencies:
            score_emergency(em, now)

        res_index = _resource_index([v.id for v in vehicles])
        usable = [v for v in vehicles if vehicle_feasibility(v, res_index)[0]]
        vehicle_by_id = {v.id: v for v in usable}
        em_by_id = {e.id: e for e in emergencies}

        graph = get_graph()
        times = graph.travel_times(
            {v.id: (v.latitude, v.longitude) for v in usable},
            {e.id: (e.latitude, e.longitude) for e in emergencies},
        )
        em_inputs = [
            EmergencyInput(
                id=e.id,
                priority=e.priority_score,
                vehicles_required=e.vehicles_required,
                compatible_types=COMPATIBLE_VEHICLE_TYPES[e.category],
                eligible_vehicle_ids=frozenset(v.id for v in usable if vehicle_suits(v, e, res_index)[0]),
            )
            for e in emergencies
        ]
        result = allocate(em_inputs, [VehicleInput(v.id, v.type) for v in usable], times)
        runtime_ms = round((time.perf_counter() - t0) * 1000, 1)

        stats = {
            "runtime_ms": runtime_ms,
            "dp_states": result.dp_states,
            "total_benefit": result.total_benefit,
            "emergencies_considered": len(emergencies),
            "vehicles_considered": len(usable),
        }

        if dry_run:
            proposal = []
            for a in result.assignments:
                em = em_by_id[a.emergency_id]
                for vid, t in zip(a.vehicle_ids, a.travel_times):
                    v = vehicle_by_id[vid]
                    proposal.append({
                        "emergency_id": em.id, "emergency_code": em.code,
                        "vehicle_id": v.id, "vehicle_code": v.code, "vehicle_type": v.type,
                        "license_plate": v.license_plate, "travel_time_min": t,
                    })
            transaction.set_rollback(True)
            return {
                "dry_run": True,
                "assignments": proposal,
                "pending": result.pending,
                "unreachable": result.unreachable,
                "reasons": {str(k): {"code": c, "message": m} for k, (c, m) in result.reasons.items()},
                "stats": stats,
            }

        plan = Plan.objects.create(reason=reason, created_by=actor if getattr(actor, "is_authenticated", False) else None)

        new_pairs = {(a.emergency_id, vid) for a in result.assignments for vid in a.vehicle_ids}
        kept_pairs = set()
        for old in replannable:
            pair = (old.emergency_id, old.vehicle_id)
            if pair in new_pairs:
                kept_pairs.add(pair)
                continue
            old.status = Assignment.Status.SUPERSEDED
            old.completed_at = now
            old.save(update_fields=["status", "completed_at"])
            _free_vehicle(old.vehicle)
            if old.vehicle.driver_id:
                notify("Mission Reassigned",
                       f"Your unit {old.vehicle.license_plate} was re-assigned from {old.emergency.code} "
                       f"by the planner (higher-priority emergency).",
                       target_user=old.vehicle.driver, emergency=old.emergency)
            audit("ASSIGNMENT_SUPERSEDED", actor, {"assignment_id": old.id, "plan_id": plan.id})

        created = []
        for a in result.assignments:
            em = em_by_id[a.emergency_id]
            code, text = result.reasons[a.emergency_id]
            em.status = EmergencyStatus.ASSIGNED
            em.allocation_code = code
            em.allocation_reason = text
            for vid in a.vehicle_ids:
                if (em.id, vid) in kept_pairs:
                    continue
                v = vehicle_by_id[vid]
                asg = Assignment(plan=plan, emergency=em, vehicle=v, assigned_at=now,
                                 notes=f"DP plan {plan.id} ({reason})")
                _apply_route(asg, graph.route((v.latitude, v.longitude), (em.latitude, em.longitude)))
                asg.save()
                _occupy_vehicle(v)
                _notify_assigned(em, v, asg)
                created.append(asg)
                audit("ASSIGNMENT_CREATED", actor, {
                    "assignment_id": asg.id, "plan_id": plan.id, "emergency": em.code,
                    "vehicle": v.code, "eta_minutes": asg.eta_minutes,
                })

        for eid in result.pending + result.unreachable:
            em = em_by_id[eid]
            code, text = result.reasons[eid]
            was_assigned = em.status == EmergencyStatus.ASSIGNED
            em.status = EmergencyStatus.REPORTED
            em.allocation_code = code
            em.allocation_reason = text
            if was_assigned and em.reported_by_id:
                notify("Assignment Changed",
                       f"Your report {em.code} is waiting for the next available unit.",
                       target_user=em.reported_by, emergency=em)
            if eid in result.unreachable:
                notify("Location Unreachable",
                       f"{em.code}: no valid route exists in the current road network.",
                       target_role="dispatcher", emergency=em)

        for em in emergencies:
            em.save(update_fields=["status", "priority_score", "vehicles_required",
                                   "allocation_code", "allocation_reason", "updated_at"])

        stats["runtime_ms"] = round((time.perf_counter() - t0) * 1000, 1)
        plan.summary = {
            **stats,
            "assigned": [a.emergency_id for a in result.assignments],
            "pending": result.pending,
            "unreachable": result.unreachable,
            "new_assignment_ids": [a.id for a in created],
        }
        plan.save(update_fields=["summary"])
        audit("PLAN_GENERATED", actor, {"plan_id": plan.id, "reason": reason, **plan.summary})

    return plan_payload(plan)


def maybe_auto_allocate(reason, actor=None):
    """Called after events (new emergency, vehicle free, road change)."""
    if not settings.RESQ["AUTO_ALLOCATE"]:
        return None
    if not Emergency.objects.filter(
        Q(status=EmergencyStatus.REPORTED) | Q(status=EmergencyStatus.ASSIGNED)
    ).exists():
        return None
    try:
        return run_allocation(reason=reason, actor=actor)
    except Exception:  # never fail the triggering request because of the planner
        logger.exception("Automatic allocation failed (reason=%s)", reason)
        return None


# ---------------------------------------------------------------------------
# Plan payloads
# ---------------------------------------------------------------------------


def assignment_payload(a):
    return {
        "id": a.id,
        "plan_id": a.plan_id,
        "emergency_id": a.emergency_id,
        "emergency_code": a.emergency.code,
        "vehicle_id": a.vehicle_id,
        "vehicle_code": a.vehicle.code,
        "vehicle_type": a.vehicle.type,
        "license_plate": a.vehicle.license_plate,
        "route": a.route_nodes,
        "route_coords": a.route_coords,
        "travel_time_min": a.eta_minutes,
        "distance_km": a.distance_km,
        "route_unreachable": a.route_unreachable,
        "status": a.status,
        "assigned_at": a.assigned_at.isoformat(),
    }


def _pending_payload(em):
    return {
        "id": em.id, "code": em.code, "category": em.category,
        "priority_score": em.priority_score, "severity": em.severity, "urgency": em.urgency,
        "people_affected": em.people_affected, "reason_code": em.allocation_code,
        "reason": em.allocation_reason,
    }


def plan_payload(plan=None):
    """Current response plan: all active assignments + pending + unreachable."""
    plan = plan or Plan.objects.order_by("-id").first()
    active = Assignment.objects.filter(status=ACTIVE).select_related("vehicle", "emergency").order_by(
        "-emergency__priority_score", "id")
    reported = Emergency.objects.filter(status=EmergencyStatus.REPORTED).order_by("-priority_score", "created_at")
    pending = [e for e in reported if e.allocation_code != "UNREACHABLE"]
    unreachable = [e for e in reported if e.allocation_code == "UNREACHABLE"]
    return {
        "plan_id": plan.id if plan else None,
        "reason": plan.reason if plan else None,
        "created_at": plan.created_at.isoformat() if plan else None,
        "stats": plan.summary if plan else {},
        "assignments": [assignment_payload(a) for a in active],
        "pending": [e.id for e in pending],
        "unreachable": [e.id for e in unreachable],
        "pending_details": [_pending_payload(e) for e in pending],
        "unreachable_details": [_pending_payload(e) for e in unreachable],
    }


# ---------------------------------------------------------------------------
# Manual dispatcher assignment + candidate list
# ---------------------------------------------------------------------------


def vehicle_candidates(em):
    """All non-maintenance vehicles with suitability, feasibility and Dijkstra ETA."""
    vehicles = list(Vehicle.objects.exclude(status=VehicleStatus.MAINTENANCE).select_related("driver"))
    res_index = _resource_index([v.id for v in vehicles])
    graph = get_graph()
    out = []
    for v in vehicles:
        suits, why_not_suit = vehicle_suits(v, em, res_index)
        feasible, why_not_feasible = vehicle_feasibility(v, res_index)
        available = v.status == VehicleStatus.AVAILABLE
        route = graph.route((v.latitude, v.longitude), (em.latitude, em.longitude))
        reasons = [r for r in (
            "" if available else f"Vehicle is {v.status}.", why_not_suit, why_not_feasible,
            "" if route else "Unreachable: no valid route.") if r]
        out.append({
            "vehicle_id": v.id, "vehicle_code": v.code, "vehicle_type": v.type,
            "license_plate": v.license_plate, "status": v.status,
            "driver_name": v.driver.name if v.driver else None,
            "eta_minutes": route.eta_minutes if route else None,
            "distance_km": route.distance_km if route else None,
            "can_assign": available and suits and feasible and route is not None,
            "reasons": reasons,
        })
    out.sort(key=lambda c: (not c["can_assign"], c["eta_minutes"] if c["eta_minutes"] is not None else math.inf))
    for i, c in enumerate(out):
        c["recommended"] = i == 0 and c["can_assign"]
    return out


def assign_manually(emergency_id, vehicle_id, actor, notes=""):
    with transaction.atomic():
        em = Emergency.objects.select_for_update().select_related("reported_by").get(pk=emergency_id)
        v = Vehicle.objects.select_for_update().select_related("driver").get(pk=vehicle_id)
        if em.status not in (EmergencyStatus.REPORTED, EmergencyStatus.ASSIGNED):
            raise Conflict(f"Emergency is {em.status}; only REPORTED or ASSIGNED emergencies can be assigned.")
        if v.status != VehicleStatus.AVAILABLE:
            raise Conflict(f"Vehicle {v.code} is {v.status}, not Available.")
        if em.assignments.filter(status=ACTIVE, vehicle=v).exists():
            raise Conflict("This vehicle is already assigned to this emergency.")
        res_index = _resource_index([v.id])
        for ok, why in (vehicle_suits(v, em, res_index), vehicle_feasibility(v, res_index)):
            if not ok:
                raise BadRequest(why)
        route = get_graph().route((v.latitude, v.longitude), (em.latitude, em.longitude))
        if route is None:
            raise Unreachable()

        plan = Plan.objects.create(reason=Plan.Reason.MANUAL_ASSIGN, created_by=actor,
                                   summary={"emergency_id": em.id, "vehicle_id": v.id})
        asg = Assignment(plan=plan, emergency=em, vehicle=v, notes=notes or "Manual dispatcher assignment")
        _apply_route(asg, route)
        asg.save()
        _occupy_vehicle(v)
        score_emergency(em)
        em.status = EmergencyStatus.ASSIGNED
        em.allocation_code = "MANUAL"
        em.allocation_reason = notes or f"Manually assigned by dispatcher to {v.type} {v.code} (ETA {route.eta_minutes:.1f} min)."
        em.save()
        _notify_assigned(em, v, asg)
        audit("ASSIGNMENT_CREATED", actor, {
            "assignment_id": asg.id, "plan_id": plan.id, "emergency": em.code,
            "vehicle": v.code, "manual": True, "eta_minutes": asg.eta_minutes,
        })
    return asg


# ---------------------------------------------------------------------------
# Status changes (driver mission progression, resolve, cancel)
# ---------------------------------------------------------------------------


def _close_assignments(em, new_status, actor):
    freed = []
    now = timezone.now()
    for a in em.assignments.select_for_update().filter(status=ACTIVE).select_related("vehicle"):
        a.status = new_status
        a.completed_at = now
        a.save(update_fields=["status", "completed_at"])
        _free_vehicle(a.vehicle)
        freed.append(a.vehicle)
        audit("ASSIGNMENT_" + new_status, actor, {"assignment_id": a.id, "emergency": em.code,
                                                  "vehicle": a.vehicle.code})
    return freed


def change_emergency_status(em_id, new_status, actor):
    from accounts.models import Role

    with transaction.atomic():
        em = Emergency.objects.select_for_update().select_related("reported_by").get(pk=em_id)
        old = em.status
        if new_status == old:
            return em, []
        if old in (EmergencyStatus.RESOLVED, EmergencyStatus.CANCELLED):
            raise Conflict(f"Emergency is already {old}.")

        role = actor.role
        has_active = em.assignments.filter(status=ACTIVE).exists()

        if new_status == EmergencyStatus.CANCELLED:
            if role == Role.CITIZEN:
                if em.reported_by_id != actor.id or old not in (EmergencyStatus.REPORTED, EmergencyStatus.ASSIGNED):
                    raise Conflict("You can only cancel your own report before the unit is en route.")
            elif role not in (Role.DISPATCHER, Role.ADMIN):
                raise Conflict("Drivers cannot cancel emergencies.")
        else:
            if role == Role.CITIZEN:
                raise Conflict("Citizens can only cancel their own reports.")
            if new_status not in STATUS_ORDER or STATUS_ORDER.index(new_status) <= STATUS_ORDER.index(old):
                raise BadRequest(f"Invalid status change {old} -> {new_status}.")
            if new_status in (EmergencyStatus.ASSIGNED, EmergencyStatus.EN_ROUTE, EmergencyStatus.ON_SCENE) and not has_active:
                raise BadRequest("Emergency has no assigned vehicle. Assign a vehicle first.")
            if role == Role.DRIVER and not em.assignments.filter(status=ACTIVE, vehicle__driver=actor).exists():
                raise Conflict("You are not assigned to this emergency.")

        freed = []
        if new_status == EmergencyStatus.EN_ROUTE:
            for a in em.assignments.filter(status=ACTIVE).select_related("vehicle"):
                a.vehicle.status = VehicleStatus.EN_ROUTE
                a.vehicle.save(update_fields=["status", "updated_at"])
        elif new_status == EmergencyStatus.ON_SCENE:
            for a in em.assignments.filter(status=ACTIVE).select_related("vehicle"):
                a.vehicle.status = VehicleStatus.BUSY
                a.vehicle.save(update_fields=["status", "updated_at"])
        elif new_status == EmergencyStatus.RESOLVED:
            freed = _close_assignments(em, Assignment.Status.COMPLETED, actor)
            em.resolved_at = timezone.now()
        elif new_status == EmergencyStatus.CANCELLED:
            freed = _close_assignments(em, Assignment.Status.CANCELLED, actor)

        em.status = new_status
        em.save()
        audit("EMERGENCY_STATUS_CHANGED", actor, {"emergency": em.code, "from": old, "to": new_status})
        msg = f"Report {em.code} is now {new_status.replace('_', ' ').title()}."
        if em.reported_by_id and em.reported_by_id != actor.id:
            notify(f"Status Update: {em.code}", msg, target_user=em.reported_by, emergency=em)
        notify(f"Mission Update: {new_status}", msg, target_role="dispatcher", emergency=em)
    return em, freed


def complete_assignment(assignment_id, actor):
    """Driver/dispatcher marks one assignment done; frees the vehicle."""
    from accounts.models import Role

    with transaction.atomic():
        a = Assignment.objects.select_for_update().select_related("vehicle", "emergency").get(pk=assignment_id)
        if a.status != ACTIVE:
            raise Conflict(f"Assignment is already {a.status}.")
        if actor.role == Role.DRIVER and a.vehicle.driver_id != actor.id:
            raise Conflict("You are not the driver of this vehicle.")
        a.status = Assignment.Status.COMPLETED
        a.completed_at = timezone.now()
        a.save(update_fields=["status", "completed_at"])
        _free_vehicle(a.vehicle)
        audit("ASSIGNMENT_COMPLETED", actor, {"assignment_id": a.id, "vehicle": a.vehicle.code})
        em = a.emergency
        if not em.assignments.filter(status=ACTIVE).exists() and em.status not in (
            EmergencyStatus.RESOLVED, EmergencyStatus.CANCELLED
        ):
            em.status = EmergencyStatus.RESOLVED
            em.resolved_at = timezone.now()
            em.save(update_fields=["status", "resolved_at", "updated_at"])
            audit("EMERGENCY_STATUS_CHANGED", actor, {"emergency": em.code, "to": "RESOLVED"})
            if em.reported_by_id:
                notify(f"Status Update: {em.code}", f"Report {em.code} has been resolved.",
                       target_user=em.reported_by, emergency=em)
    return a


# ---------------------------------------------------------------------------
# Road changes: re-route every active assignment (FR-07, FR-10)
# ---------------------------------------------------------------------------


def reroute_active_assignments(actor=None):
    graph = get_graph()
    rerouted, unreachable = [], []
    with transaction.atomic():
        for a in Assignment.objects.select_for_update().filter(status=ACTIVE).select_related(
                "vehicle", "vehicle__driver", "emergency"):
            route = graph.route((a.vehicle.latitude, a.vehicle.longitude), (a.emergency.latitude, a.emergency.longitude))
            old_edges = list(a.route_edges)
            _apply_route(a, route)
            a.save()
            if route is None:
                unreachable.append(a.id)
                notify("Route Blocked",
                       f"{a.emergency.code}: no alternative route for {a.vehicle.license_plate}.",
                       target_role="dispatcher", emergency=a.emergency)
                if a.vehicle.driver_id:
                    notify("Route Blocked", f"No valid route to {a.emergency.code}. Contact dispatch.",
                           target_user=a.vehicle.driver, emergency=a.emergency)
            elif route.edges != old_edges:
                rerouted.append(a.id)
                if a.vehicle.driver_id:
                    notify("Route Updated",
                           f"New route to {a.emergency.code}: ETA {route.eta_minutes:.0f} min.",
                           target_user=a.vehicle.driver, emergency=a.emergency)
        if rerouted or unreachable:
            audit("ROUTES_RECALCULATED", actor, {"rerouted": rerouted, "unreachable": unreachable})
    return rerouted, unreachable
