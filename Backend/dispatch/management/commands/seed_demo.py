"""
python manage.py seed_demo [--reset] [--grid 30] [--allocate]

Creates:
  * a synthetic Karachi road network (grid of intersections with jitter,
    arterial roads named after real Karachi roads, some missing streets)
  * the demo accounts used by the Flutter app (same emails/passwords)
  * vehicles, resources, blocked roads, emergencies and notifications that
    mirror lib/core/mock/demo_data.dart
"""

import math
import random

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from accounts.models import Role, User
from dispatch.models import (
    Assignment,
    AuditLog,
    Emergency,
    EmergencyStatus,
    GraphVersion,
    Notification,
    NotificationRead,
    Plan,
    Resource,
    RoadEdge,
    RoadNode,
    Vehicle,
    VehicleLocationLog,
    VehicleStatus,
)
from dispatch.services import planner
from dispatch.services.graph import get_graph, haversine_km

# Karachi bounding box (Saddar / Gulshan / SITE / PECHS / Clifton area)
LAT_MIN, LAT_MAX = 24.80, 24.96
LNG_MIN, LNG_MAX = 66.96, 67.14

ARTERIAL_ROWS = {
    5: "Khayaban-e-Iqbal",
    10: "M.A. Jinnah Road",
    14: "Shahrah-e-Faisal",
    19: "Shahrah-e-Pakistan",
    24: "University Road",
}
ARTERIAL_COLS = {
    4: "Mauripur Road",
    9: "Shaheed-e-Millat Road",
    14: "Stadium Road",
    19: "Rashid Minhas Road",
    24: "Korangi Road",
}

DEMO_USERS = [
    ("citizen@resq.com", "Citizen123", "Demo Citizen", Role.CITIZEN, "+92 300 1234567"),
    ("dispatcher@resq.com", "Dispatch123", "Karachi Central Dispatcher", Role.DISPATCHER, "+92 321 9876543"),
    ("driver@resq.com", "Driver123", "Captain Tariq (Ambulance Unit 1)", Role.DRIVER, "+92 333 5551122"),
    ("admin@resq.com", "Admin123", "System Administrator", Role.ADMIN, "+92 300 0000000"),
    ("farooq@resq.com", "Driver123", "Sgt. Farooq", Role.DRIVER, "+92 333 5551123"),
    ("salman@resq.com", "Driver123", "Officer Salman", Role.DRIVER, "+92 333 5551124"),
    ("zubair@resq.com", "Driver123", "Zubair Ahmed", Role.DRIVER, "+92 333 5551125"),
]

# (license_plate, type, status, lat, lng, driver_email, station)
DEMO_VEHICLES = [
    ("KHI-1122-AMB", "Ambulance", "Available", 24.8720, 67.0104, "driver@resq.com", "Saddar EMS Station"),
    ("KHI-FIRE-077", "Fire Brigade", "Available", 24.8550, 66.9987, "farooq@resq.com", "Fire Station 7"),
    ("KHI-RSQ-042", "Rescue Vehicle", "Available", 24.8680, 67.0320, "salman@resq.com", "Rescue 1122 Hub"),
    ("KHI-AMB-015", "Ambulance", "Available", 24.8800, 67.0150, "zubair@resq.com", "Gulshan EMS Station"),
    ("KHI-FIRE-102", "Fire Brigade", "Maintenance", 24.8420, 67.0250, None, "Fire Station 2"),
]

# (name, category, quantity, unit, vehicle_index or None)
DEMO_RESOURCES = [
    ("Paramedic Crew Alpha (3 Staff)", "Crew", 3, "personnel", 0),
    ("Advanced Cardiac Defibrillator", "Medical", 2, "units", 0),
    ("Fire Crew Bravo (4 Staff)", "Crew", 4, "personnel", 1),
    ("High-Expansion Fire Foam Tank", "Equipment", 500, "liters", 1),
    ("Rescue Crew Charlie (3 Staff)", "Crew", 3, "personnel", 2),
    ("Hydraulic Rescue Cutter & Spreader", "Equipment", 1, "kit", 2),
    ("First Aid Trauma Kit", "Medical", 2, "kits", 2),
    ("Paramedic Crew Delta (2 Staff)", "Crew", 2, "personnel", 3),
    ("Emergency Oxygen Cylinders", "Medical", 8, "cylinders", 3),
    ("Fire Crew Echo (4 Staff)", "Crew", 4, "personnel", 4),
    ("Water Tender Hose Set", "Equipment", 2, "sets", 4),
    ("Heavy Duty Diesel Reserve", "Fuel", 1200, "liters", None),
    ("VHF Radio Handsets", "Communication", 12, "units", None),
]

# (road name, reason, lat, lng, is_blocked)
DEMO_BLOCKED_ROADS = [
    ("M.A. Jinnah Road (Near Tibet Centre)", "Water Pipeline Burst & Road Cavity", 24.8625, 67.0180, True),
    ("Shahrah-e-Faisal (Nursery Flyover under repair)", "Scheduled Bridge Expansion Joint Works", 24.8640, 67.0650, True),
    ("University Road (NIPA Intersection)", "Heavy Construction / BRT Line", 24.9180, 67.0980, False),
]

# (category, status, severity, urgency, people, description, lat, lng, label, minutes_ago, vehicle_index)
DEMO_EMERGENCIES = [
    ("MEDICAL", "ON_SCENE", 4, 5, 2, "Cardiac arrest reported at residential flat. Patient unresponsive.",
     24.8607, 67.0105, "Gulshan-e-Iqbal, Block 4, Karachi", 120, 0),
    ("FIRE", "EN_ROUTE", 5, 5, 10, "Multi-story commercial warehouse fire. Thick smoke billowing.",
     24.8700, 66.9950, "SITE Industrial Area, Karachi", 45, 1),
    ("ACCIDENT", "REPORTED", 3, 4, 4, "Two-vehicle collision on highway. Minor to moderate injuries.",
     24.8550, 67.0350, "Shahrah-e-Faisal near Baloch Colony, Karachi", 12, None),
]


class Command(BaseCommand):
    help = "Seed the database with a synthetic Karachi road network and the Flutter demo data."

    def add_arguments(self, parser):
        parser.add_argument("--reset", action="store_true", help="Delete existing data first.")
        parser.add_argument("--grid", type=int, default=30, help="Grid size N (N x N intersections).")
        parser.add_argument("--seed", type=int, default=2026)
        parser.add_argument("--allocate", action="store_true", help="Run the DP planner after seeding.")

    def handle(self, *args, **opts):
        if opts["reset"]:
            self._reset()
        elif RoadNode.objects.exists() or Vehicle.objects.exists():
            self.stdout.write(self.style.WARNING("Data already exists. Use --reset to recreate it."))
            return
        rnd = random.Random(opts["seed"])
        with transaction.atomic():
            self._roads(opts["grid"], rnd)
            users = self._users()
            vehicles = self._vehicles(users)
            self._resources(vehicles)
            self._blocked_roads()
            GraphVersion.bump()
            self._emergencies(users, vehicles)
        if opts["allocate"]:
            payload = planner.run_allocation(Plan.Reason.MANUAL)
            self.stdout.write(f"Planner: {len(payload['assignments'])} active assignments, "
                              f"pending={payload['pending']}")
        self.stdout.write(self.style.SUCCESS(
            f"Seeded {RoadNode.objects.count()} road nodes, {RoadEdge.objects.count()} road edges, "
            f"{User.objects.count()} users, {Vehicle.objects.count()} vehicles, "
            f"{Emergency.objects.count()} emergencies."))
        self.stdout.write("Logins: citizen@resq.com/Citizen123, dispatcher@resq.com/Dispatch123, "
                          "driver@resq.com/Driver123, admin@resq.com/Admin123")

    # ------------------------------------------------------------------
    def _reset(self):
        for model in (NotificationRead, Notification, AuditLog, Assignment, Plan, VehicleLocationLog,
                      Emergency, Resource, Vehicle, RoadEdge, RoadNode):
            model.objects.all().delete()
        User.objects.filter(email__in=[u[0] for u in DEMO_USERS]).delete()
        GraphVersion.bump()
        self.stdout.write("Existing demo data deleted.")

    def _roads(self, n, rnd):
        dlat = (LAT_MAX - LAT_MIN) / (n - 1)
        dlng = (LNG_MAX - LNG_MIN) / (n - 1)
        nodes = []
        for r in range(n):
            for c in range(n):
                jitter = 0.0 if (r in ARTERIAL_ROWS or c in ARTERIAL_COLS) else 0.25
                nodes.append(RoadNode(
                    name=f"Intersection R{r}-C{c}",
                    latitude=round(LAT_MIN + r * dlat + rnd.uniform(-jitter, jitter) * dlat, 6),
                    longitude=round(LNG_MIN + c * dlng + rnd.uniform(-jitter, jitter) * dlng, 6),
                ))
        RoadNode.objects.bulk_create(nodes, batch_size=2000)
        ids = list(RoadNode.objects.order_by("id").values_list("id", "latitude", "longitude"))
        grid = {(i // n, i % n): ids[i] for i in range(len(ids))}

        def edge(a, b, name, speed_kmh):
            (ia, lat1, lng1), (ib, lat2, lng2) = grid[a], grid[b]
            km = haversine_km(lat1, lng1, lat2, lng2)
            congestion = rnd.uniform(1.0, 1.35)
            return RoadEdge(name=name, from_node_id=ia, to_node_id=ib, distance_km=round(km, 3),
                            travel_time=round(km / speed_kmh * 60 * congestion, 3), two_way=True)

        edges = []
        for r in range(n):
            for c in range(n):
                if c + 1 < n:  # east-west
                    if r in ARTERIAL_ROWS:
                        edges.append(edge((r, c), (r, c + 1), ARTERIAL_ROWS[r], 45))
                    elif rnd.random() > 0.06:
                        edges.append(edge((r, c), (r, c + 1), f"Street {r}-{c}", 25))
                if r + 1 < n:  # north-south
                    if c in ARTERIAL_COLS:
                        edges.append(edge((r, c), (r + 1, c), ARTERIAL_COLS[c], 45))
                    elif rnd.random() > 0.06:
                        edges.append(edge((r, c), (r + 1, c), f"Lane {r}-{c}", 25))
                if r + 1 < n and c + 1 < n and rnd.random() < 0.08:  # occasional diagonal
                    edges.append(edge((r, c), (r + 1, c + 1), f"Link {r}-{c}", 30))
        RoadEdge.objects.bulk_create(edges, batch_size=2000)

    def _users(self):
        users = {}
        for email, pwd, name, role, phone in DEMO_USERS:
            u = User.objects.filter(email=email).first()
            if not u:
                u = User.objects.create_user(email, pwd, name=name, role=role, phone=phone,
                                             is_staff=role == Role.ADMIN, is_superuser=role == Role.ADMIN)
            users[email] = u
        return users

    def _vehicles(self, users):
        out = []
        for plate, vtype, status, lat, lng, driver, station in DEMO_VEHICLES:
            out.append(Vehicle.objects.create(
                license_plate=plate, type=vtype, status=status, latitude=lat, longitude=lng,
                driver=users.get(driver), station_name=station,
                crew_required=4 if vtype == "Fire Brigade" else 2,
                fuel_level=random.Random(plate).randint(55, 100),
                capabilities={"Ambulance": ["MEDICAL", "ACCIDENT"], "Fire Brigade": ["FIRE", "RESCUE"],
                              "Rescue Vehicle": ["RESCUE", "ACCIDENT", "MEDICAL"]}[vtype],
            ))
        return out

    def _resources(self, vehicles):
        for name, cat, qty, unit, vi in DEMO_RESOURCES:
            Resource.objects.create(name=name, category=cat, quantity=qty, unit=unit,
                                    vehicle=vehicles[vi] if vi is not None else None)

    def _blocked_roads(self):
        graph_nodes = list(RoadNode.objects.values_list("id", "latitude", "longitude"))
        node_pos = {i: (a, b) for i, a, b in graph_nodes}
        for name, reason, lat, lng, blocked in DEMO_BLOCKED_ROADS:
            best, best_d = None, math.inf
            for e in RoadEdge.objects.values("id", "from_node_id", "to_node_id"):
                a, b = node_pos[e["from_node_id"]], node_pos[e["to_node_id"]]
                d = haversine_km(lat, lng, (a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
                if d < best_d:
                    best, best_d = e["id"], d
            RoadEdge.objects.filter(pk=best).update(name=name, block_reason=reason, is_blocked=blocked)

    def _emergencies(self, users, vehicles):
        now = timezone.now()
        citizen = users["citizen@resq.com"]
        graph = get_graph()
        plan = Plan.objects.create(reason=Plan.Reason.MANUAL, summary={"seed": True})
        for cat, status, sev, urg, people, desc, lat, lng, label, ago, vi in DEMO_EMERGENCIES:
            em = Emergency(category=cat, status=status, severity=sev, urgency=urg, people_affected=people,
                           description=desc, latitude=lat, longitude=lng, location_label=label,
                           reported_by=citizen, created_at=now - timezone.timedelta(minutes=ago))
            planner.score_emergency(em, now)
            em.allocation_reason = ("Seeded demo assignment." if vi is not None
                                    else f"Awaiting allocation: priority {em.priority_score}.")
            em.allocation_code = "SELECTED" if vi is not None else ""
            em.save()
            if vi is not None:
                v = vehicles[vi]
                a = Assignment(plan=plan, emergency=em, vehicle=v, assigned_at=em.created_at,
                               notes="Seeded demo assignment")
                planner._apply_route(a, graph.route((v.latitude, v.longitude), (lat, lng)))
                a.save()
                planner._occupy_vehicle(v)
                v.status = VehicleStatus.EN_ROUTE if status == EmergencyStatus.EN_ROUTE else VehicleStatus.BUSY
                v.save(update_fields=["status"])
                Notification.objects.create(
                    title="Emergency Assigned", target_role="user", target_user=citizen, emergency=em,
                    message=f"Report {em.code} assigned to {v.type} {v.license_plate}. "
                            f"ETA: ~{a.eta_minutes or 0:.0f} min.")
        Notification.objects.create(
            title="Road Block Alert", target_role="driver",
            message="M.A. Jinnah Road blocked near Tibet Centre. Dijkstra route will re-route.")
