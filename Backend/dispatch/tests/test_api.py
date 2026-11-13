"""
End-to-end API tests on a tiny road network.

Road network used by most tests (travel times in minutes):

    N1 --2-- N2 --2-- N3
    |                 |
    10                2
    |                 |
    N4 ------20------ N5          N6 (isolated, unreachable)
"""

from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from accounts.models import Role, User
from dispatch.models import (
    Assignment,
    AuditLog,
    Emergency,
    Notification,
    Resource,
    RoadEdge,
    RoadNode,
    Vehicle,
)

P = {  # node positions (~1 km apart)
    "N1": (24.860, 67.000), "N2": (24.860, 67.010), "N3": (24.860, 67.020),
    "N4": (24.850, 67.000), "N5": (24.850, 67.020), "N6": (24.700, 66.700),
}


def make_network():
    n = {k: RoadNode.objects.create(name=k, latitude=a, longitude=b) for k, (a, b) in P.items()}
    edges = {
        "e12": RoadEdge.objects.create(name="Road 1-2", from_node=n["N1"], to_node=n["N2"], travel_time=2, distance_km=1),
        "e23": RoadEdge.objects.create(name="Road 2-3", from_node=n["N2"], to_node=n["N3"], travel_time=2, distance_km=1),
        "e35": RoadEdge.objects.create(name="Road 3-5", from_node=n["N3"], to_node=n["N5"], travel_time=2, distance_km=1),
        "e14": RoadEdge.objects.create(name="Road 1-4", from_node=n["N1"], to_node=n["N4"], travel_time=10, distance_km=1),
        "e45": RoadEdge.objects.create(name="Road 4-5", from_node=n["N4"], to_node=n["N5"], travel_time=20, distance_km=2),
    }
    return n, edges


def make_vehicle(plate, vtype, at, driver=None, crew=2, equipment=True):
    lat, lng = P[at]
    v = Vehicle.objects.create(license_plate=plate, type=vtype, latitude=lat, longitude=lng,
                               driver=driver, crew_required=2)
    Resource.objects.create(name=f"{plate} crew", category="Crew", quantity=crew, unit="personnel", vehicle=v)
    if equipment:
        cat = "Equipment" if vtype == "Fire Brigade" else "Medical"
        Resource.objects.create(name=f"{plate} kit", category=cat, quantity=1, vehicle=v)
    return v


@override_settings(RESQ={"AUTO_ALLOCATE": False, "MIN_FUEL_LEVEL": 15, "MAX_SNAP_DISTANCE_KM": 3,
                         "CONNECTOR_SPEED_KMH": 20, "LOCATION_LOG_RETENTION_DAYS": 30})
class BaseAPITest(TestCase):
    def setUp(self):
        self.nodes, self.edges = make_network()
        self.admin = User.objects.create_user("admin@t.com", "Admin123", name="Admin", role=Role.ADMIN)
        self.disp = User.objects.create_user("disp@t.com", "Dispatch123", name="Disp", role=Role.DISPATCHER)
        self.drv = User.objects.create_user("drv@t.com", "Driver123", name="Driver", role=Role.DRIVER)
        self.cit = User.objects.create_user("cit@t.com", "Citizen123", name="Cit", role=Role.CITIZEN)

    def client_for(self, user):
        c = APIClient()
        r = c.post("/api/auth/login/", {"email": user.email, "password": {
            Role.ADMIN: "Admin123", Role.DISPATCHER: "Dispatch123",
            Role.DRIVER: "Driver123", Role.CITIZEN: "Citizen123"}[user.role]}, format="json")
        assert r.status_code == 200, r.content
        c.credentials(HTTP_AUTHORIZATION="Token " + r.data["token"])
        return c

    def report(self, client, at="N3", category="MEDICAL", severity=4, urgency=4, people=2):
        lat, lng = P[at]
        r = client.post("/api/emergencies/", {"latitude": lat, "longitude": lng, "category": category,
                                              "severity": severity, "urgency": urgency,
                                              "people_affected": people}, format="json")
        assert r.status_code == 201, r.content
        return r.data


class AuthTests(BaseAPITest):
    def test_login_returns_token_and_role(self):
        r = APIClient().post("/api/auth/login/", {"email": "DISP@t.com", "password": "Dispatch123"}, format="json")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data["role"], "dispatcher")
        self.assertTrue(r.data["token"])

    def test_bad_login(self):
        r = APIClient().post("/api/auth/login/", {"email": "disp@t.com", "password": "nope"}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertEqual(r.data["error"], "VALIDATION_ERROR")

    def test_register_citizen_only(self):
        r = APIClient().post("/api/auth/register/", {"name": "New", "email": "new@t.com", "phone": "1",
                                                     "password": "secret1", "role": "admin"}, format="json")
        self.assertEqual(r.status_code, 201)
        self.assertEqual(r.data["role"], "citizen")

    def test_requires_token(self):
        self.assertEqual(APIClient().get("/api/emergencies/").status_code, 401)

    def test_admin_creates_staff_and_deactivates(self):
        c = self.client_for(self.admin)
        r = c.post("/api/users/", {"name": "D2", "email": "d2@t.com", "phone": "1", "password": "secret1",
                                   "role": "driver"}, format="json")
        self.assertEqual(r.status_code, 201)
        uid = r.data["id"]
        self.assertEqual(c.post(f"/api/users/{uid}/toggle-active/").data["is_active"], False)
        r = APIClient().post("/api/auth/login/", {"email": "d2@t.com", "password": "secret1"}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertIn("deactivated", r.data["message"])

    def test_role_based_access(self):
        self.assertEqual(self.client_for(self.cit).get("/api/users/").status_code, 403)
        self.assertEqual(self.client_for(self.disp).get("/api/users/").status_code, 403)
        self.assertEqual(self.client_for(self.cit).post("/api/allocate/").status_code, 403)
        self.assertEqual(self.client_for(self.drv).post("/api/vehicles/", {}).status_code, 403)


class EmergencyTests(BaseAPITest):
    def test_register_emergency_validation(self):
        c = self.client_for(self.cit)
        bad = [
            {"latitude": 24.86, "longitude": 67.0, "category": "FIRE", "severity": 9, "urgency": 3, "people_affected": 1},
            {"latitude": 24.86, "longitude": 67.0, "category": "FIRE", "severity": 3, "urgency": 3, "people_affected": -2},
            {"category": "FIRE", "severity": 3, "urgency": 3, "people_affected": 1},
            {"latitude": 24.86, "longitude": 67.0, "category": "ALIEN", "severity": 3, "urgency": 3, "people_affected": 1},
        ]
        for body in bad:
            r = c.post("/api/emergencies/", body, format="json")
            self.assertEqual(r.status_code, 400, body)
            self.assertEqual(r.data["error"], "VALIDATION_ERROR")
            self.assertTrue(r.data["message"])

    def test_register_with_design_doc_field_names(self):
        c = self.client_for(self.cit)
        r = c.post("/api/emergencies/", {"lat": 24.8607, "lng": 67.0011, "type": "fire", "severity": 4,
                                         "urgency": 5, "people_affected": 12}, format="json")
        self.assertEqual(r.status_code, 201)
        self.assertEqual(r.data["status"], "REPORTED")
        self.assertEqual(r.data["category"], "FIRE")
        self.assertGreater(r.data["priority_score"], 0)
        self.assertEqual(r.data["vehicles_required"], 2)
        self.assertTrue(r.data["code"].startswith("EM-"))
        self.assertTrue(Notification.objects.filter(target_role="dispatcher").exists())

    def test_citizen_sees_only_own(self):
        other = User.objects.create_user("o@t.com", "x123456", name="O", role=Role.CITIZEN)
        Emergency.objects.create(category="FIRE", severity=1, urgency=1, people_affected=1,
                                 latitude=24.86, longitude=67.0, reported_by=other)
        mine = self.report(self.client_for(self.cit))
        ids = [e["id"] for e in self.client_for(self.cit).get("/api/emergencies/").data]
        self.assertEqual(ids, [mine["id"]])
        self.assertEqual(len(self.client_for(self.disp).get("/api/emergencies/?status=PENDING").data), 2)


class AllocationFlowTests(BaseAPITest):
    def test_full_mission_lifecycle(self):
        amb = make_vehicle("AMB-1", "Ambulance", "N1", driver=self.drv)
        em = self.report(self.client_for(self.cit), at="N3")

        disp = self.client_for(self.disp)
        r = disp.post("/api/allocate/", {}, format="json")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(len(r.data["assignments"]), 1)
        a = r.data["assignments"][0]
        self.assertEqual(a["vehicle_id"], amb.id)
        self.assertEqual(a["emergency_id"], em["id"])
        self.assertEqual(a["route"], [self.nodes["N1"].id, self.nodes["N2"].id, self.nodes["N3"].id])
        self.assertAlmostEqual(a["travel_time_min"], 4.0, places=1)
        self.assertGreater(len(a["route_coords"]), 2)
        amb.refresh_from_db()
        self.assertEqual(amb.status, "Busy")
        self.assertEqual(Resource.objects.filter(vehicle=amb, status="In Use").count(), 2)

        drv = self.client_for(self.drv)
        mission = drv.get("/api/driver/mission/").data["mission"]
        self.assertEqual(mission["emergency"]["id"], em["id"])
        self.assertEqual(drv.patch(f"/api/emergencies/{em['id']}/status/", {"status": "EN_ROUTE"},
                                   format="json").status_code, 200)
        amb.refresh_from_db()
        self.assertEqual(amb.status, "En Route")

        # GPS update recalculates ETA from the new position (now at N2)
        r = drv.patch(f"/api/vehicles/{amb.id}/location/", {"lat": P["N2"][0], "lng": P["N2"][1]}, format="json")
        self.assertEqual(r.status_code, 200)
        self.assertAlmostEqual(r.data["eta_minutes"], 2.0, places=1)

        drv.patch(f"/api/emergencies/{em['id']}/status/", {"status": "ON_SCENE"}, format="json")
        r = drv.post(f"/api/assignments/{a['id']}/complete/")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data["vehicle_status"], "Available")
        self.assertEqual(Emergency.objects.get(pk=em["id"]).status, "RESOLVED")
        self.assertEqual(Resource.objects.filter(vehicle=amb, status="Available").count(), 2)

        events = set(AuditLog.objects.values_list("event", flat=True))
        self.assertTrue({"EMERGENCY_REGISTERED", "PLAN_GENERATED", "ASSIGNMENT_CREATED",
                         "ASSIGNMENT_COMPLETED"} <= events)
        # Citizen got notified
        cit = self.client_for(self.cit).get("/api/notifications/").data
        self.assertGreater(cit["unread_count"], 0)

    def test_edge_case_more_emergencies_than_vehicles(self):
        for i in range(3):
            make_vehicle(f"AMB-{i}", "Ambulance", "N1")
        c = self.client_for(self.cit)
        sev = [5, 2, 4, 1, 3]
        ids = [self.report(c, at="N3", severity=s, urgency=s)["id"] for s in sev]
        r = self.client_for(self.disp).post("/api/allocate/", {}, format="json")
        served = {a["emergency_id"] for a in r.data["assignments"]}
        self.assertEqual(served, {ids[0], ids[2], ids[4]})
        self.assertEqual(set(r.data["pending"]), {ids[1], ids[3]})
        plan = self.client_for(self.disp).get("/api/plan/current/").data
        self.assertEqual(len(plan["pending_details"]), 2)
        self.assertEqual(plan["pending_details"][0]["reason_code"], "LOWER_PRIORITY")

    def test_edge_case_insufficient_resources(self):
        make_vehicle("AMB-NOCREW", "Ambulance", "N1", crew=1)      # crew 1 < required 2
        make_vehicle("AMB-NOKIT", "Ambulance", "N1", equipment=False)
        v = make_vehicle("AMB-LOWFUEL", "Ambulance", "N1")
        v.fuel_level = 5
        v.save()
        em = self.report(self.client_for(self.cit))
        r = self.client_for(self.disp).post("/api/allocate/", {}, format="json")
        self.assertEqual(r.data["assignments"], [])
        self.assertEqual(r.data["pending"], [em["id"]])
        self.assertEqual(Emergency.objects.get(pk=em["id"]).allocation_code, "INSUFFICIENT_RESOURCES")

    def test_edge_case_blocked_and_unreachable(self):
        amb = make_vehicle("AMB-1", "Ambulance", "N1", driver=self.drv)
        em = self.report(self.client_for(self.cit), at="N5")
        disp = self.client_for(self.disp)
        a = disp.post("/api/allocate/", {}, format="json").data["assignments"][0]
        self.assertAlmostEqual(a["travel_time_min"], 6.0, places=1)  # N1-N2-N3-N5

        # Block N2-N3: must re-route via N4 (30 min), never using the blocked road
        r = disp.patch(f"/api/roads/{self.edges['e23'].id}/block/", {"is_blocked": True, "reason": "Flood"},
                       format="json")
        self.assertEqual(r.status_code, 200)
        self.assertTrue(r.data["replan_triggered"])
        asg = Assignment.objects.get(pk=a["id"])
        self.assertNotIn(self.edges["e23"].id, asg.route_edges)
        self.assertAlmostEqual(asg.eta_minutes, 30.0, places=1)

        # Block N4-N5 too: no route left -> 404 UNREACHABLE
        disp.patch(f"/api/roads/{self.edges['e45'].id}/block/", {"is_blocked": True}, format="json")
        r = disp.post("/api/route/", {"vehicle_id": amb.id, "emergency_id": em["id"]}, format="json")
        self.assertEqual(r.status_code, 404)
        self.assertEqual(r.data["error"], "UNREACHABLE")
        self.assertTrue(Assignment.objects.get(pk=a["id"]).route_unreachable)

        blocked = disp.get("/api/roads/blocked/").data
        self.assertEqual({b["id"] for b in blocked}, {self.edges["e23"].id, self.edges["e45"].id})

        # Unblock restores the fast route
        disp.patch(f"/api/roads/{self.edges['e23'].id}/block/", {"is_blocked": False}, format="json")
        r = disp.post("/api/route/", {"vehicle_id": amb.id, "emergency_id": em["id"]}, format="json")
        self.assertEqual(r.status_code, 200)
        self.assertAlmostEqual(r.data["total_time"], 6.0, places=1)

    def test_isolated_location_reported_unreachable(self):
        make_vehicle("AMB-1", "Ambulance", "N1")
        em = self.report(self.client_for(self.cit), at="N6")
        r = self.client_for(self.disp).post("/api/allocate/", {}, format="json")
        self.assertEqual(r.data["unreachable"], [em["id"]])

    def test_edge_case_new_high_priority_preempts_unstarted_assignment(self):
        amb = make_vehicle("AMB-1", "Ambulance", "N1", driver=self.drv)
        c = self.client_for(self.cit)
        low = self.report(c, at="N3", severity=1, urgency=1)
        disp = self.client_for(self.disp)
        disp.post("/api/allocate/", {}, format="json")
        self.assertEqual(Emergency.objects.get(pk=low["id"]).status, "ASSIGNED")

        high = self.report(c, at="N2", severity=5, urgency=5, people=8)
        r = disp.post("/api/plan/recalculate/", {"reason": "NEW_EMERGENCY"}, format="json")
        self.assertEqual(r.status_code, 200)
        self.assertEqual([a["emergency_id"] for a in r.data["assignments"]], [high["id"]])
        self.assertEqual(Emergency.objects.get(pk=low["id"]).status, "REPORTED")
        self.assertEqual(Vehicle.objects.filter(status="Busy").count(), 1)
        self.assertEqual(Assignment.objects.filter(status="ACTIVE", vehicle=amb).count(), 1)

    def test_en_route_mission_is_not_preempted(self):
        make_vehicle("AMB-1", "Ambulance", "N1", driver=self.drv)
        c = self.client_for(self.cit)
        low = self.report(c, severity=1, urgency=1)
        disp = self.client_for(self.disp)
        disp.post("/api/allocate/", {}, format="json")
        self.client_for(self.drv).patch(f"/api/emergencies/{low['id']}/status/", {"status": "EN_ROUTE"}, format="json")
        high = self.report(c, severity=5, urgency=5)
        disp.post("/api/allocate/", {}, format="json")
        self.assertEqual(Emergency.objects.get(pk=low["id"]).status, "EN_ROUTE")
        self.assertEqual(Emergency.objects.get(pk=high["id"]).status, "REPORTED")

    def test_vehicle_never_double_booked_and_type_respected(self):
        make_vehicle("FIRE-1", "Fire Brigade", "N1")
        c = self.client_for(self.cit)
        med = self.report(c, category="MEDICAL")
        r = self.client_for(self.disp).post("/api/allocate/", {}, format="json")
        self.assertEqual(r.data["assignments"], [])
        self.assertIn(med["id"], r.data["pending"])

    def test_manual_assignment_and_candidates(self):
        amb = make_vehicle("AMB-1", "Ambulance", "N1")
        fire = make_vehicle("FIRE-1", "Fire Brigade", "N2")
        em = self.report(self.client_for(self.cit), category="MEDICAL")
        disp = self.client_for(self.disp)
        cands = disp.get(f"/api/emergencies/{em['id']}/candidates/").data["candidates"]
        self.assertEqual(cands[0]["vehicle_id"], amb.id)
        self.assertTrue(cands[0]["recommended"])
        self.assertFalse(next(c for c in cands if c["vehicle_id"] == fire.id)["can_assign"])

        r = disp.post(f"/api/emergencies/{em['id']}/assign/", {"vehicle_id": fire.id}, format="json")
        self.assertEqual(r.status_code, 400)
        r = disp.post(f"/api/emergencies/{em['id']}/assign/", {"vehicle_id": amb.id}, format="json")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data["status"], "ASSIGNED")
        self.assertEqual(r.data["assigned_vehicle"]["id"], amb.id)
        # Busy vehicle cannot be assigned again
        em2 = self.report(self.client_for(self.cit))
        r = disp.post(f"/api/emergencies/{em2['id']}/assign/", {"vehicle_id": amb.id}, format="json")
        self.assertEqual(r.status_code, 409)

    def test_dry_run_does_not_change_anything(self):
        make_vehicle("AMB-1", "Ambulance", "N1")
        em = self.report(self.client_for(self.cit))
        r = self.client_for(self.disp).post("/api/allocate/", {"dry_run": True}, format="json")
        self.assertTrue(r.data["dry_run"])
        self.assertEqual(len(r.data["assignments"]), 1)
        self.assertEqual(Emergency.objects.get(pk=em["id"]).status, "REPORTED")
        self.assertFalse(Assignment.objects.exists())

    def test_citizen_cancel_frees_vehicle(self):
        amb = make_vehicle("AMB-1", "Ambulance", "N1")
        c = self.client_for(self.cit)
        em = self.report(c)
        self.client_for(self.disp).post("/api/allocate/", {}, format="json")
        r = c.patch(f"/api/emergencies/{em['id']}/status/", {"status": "CANCELLED"}, format="json")
        self.assertEqual(r.status_code, 200)
        amb.refresh_from_db()
        self.assertEqual(amb.status, "Available")

    def test_invalid_status_transition(self):
        make_vehicle("AMB-1", "Ambulance", "N1", driver=self.drv)
        em = self.report(self.client_for(self.cit))
        disp = self.client_for(self.disp)
        r = disp.patch(f"/api/emergencies/{em['id']}/status/", {"status": "ON_SCENE"}, format="json")
        self.assertEqual(r.status_code, 400)  # no vehicle yet
        r = self.client_for(self.drv).patch(f"/api/emergencies/{em['id']}/status/", {"status": "RESOLVED"}, format="json")
        self.assertEqual(r.status_code, 404)  # driver cannot see unassigned emergencies


@override_settings(RESQ={"AUTO_ALLOCATE": True, "MIN_FUEL_LEVEL": 15, "MAX_SNAP_DISTANCE_KM": 3,
                         "CONNECTOR_SPEED_KMH": 20, "LOCATION_LOG_RETENTION_DAYS": 30})
class AutoAllocateTests(BaseAPITest):
    def test_new_emergency_is_allocated_automatically_and_vehicle_free_triggers_replan(self):
        make_vehicle("AMB-1", "Ambulance", "N1", driver=self.drv)
        c = self.client_for(self.cit)
        first = self.report(c)
        self.assertEqual(first["status"], "ASSIGNED")
        self.assertIsNotNone(first["plan_id"])
        second = self.report(c, severity=1, urgency=1)
        self.assertEqual(second["status"], "REPORTED")

        aid = Assignment.objects.get(emergency_id=first["id"]).id
        self.client_for(self.drv).post(f"/api/assignments/{aid}/complete/")
        self.assertEqual(Emergency.objects.get(pk=second["id"]).status, "ASSIGNED")


class MiscEndpointTests(BaseAPITest):
    def test_map_reports_resources_notifications(self):
        make_vehicle("AMB-1", "Ambulance", "N1")
        self.report(self.client_for(self.cit))
        disp = self.client_for(self.disp)
        m = disp.get("/api/map/").data
        self.assertEqual(set(m), {"emergencies", "vehicles", "routes", "blocked_roads"})
        self.assertEqual(len(m["vehicles"]), 1)
        s = disp.get("/api/reports/summary/").data
        self.assertEqual(s["emergencies"]["total"], 1)
        rs = disp.get("/api/resources/summary/").data
        self.assertEqual(rs["Crew"]["available"], 2)

        n = disp.get("/api/notifications/").data
        self.assertGreaterEqual(n["unread_count"], 1)
        disp.post(f"/api/notifications/{n['results'][0]['id']}/read/")
        self.assertEqual(disp.get("/api/notifications/").data["unread_count"], n["unread_count"] - 1)
        disp.post("/api/notifications/read-all/")
        self.assertEqual(disp.get("/api/notifications/").data["unread_count"], 0)

    def test_resource_quantity_zero_marks_depleted(self):
        r = Resource.objects.create(name="O2", category="Medical", quantity=1)
        c = self.client_for(self.disp)
        res = c.patch(f"/api/resources/{r.id}/", {"quantity": 0}, format="json")
        self.assertEqual(res.data["status"], "Depleted")
        res = c.patch(f"/api/resources/{r.id}/", {"quantity": -1}, format="json")
        self.assertEqual(res.status_code, 400)

    def test_add_road_and_route_by_points(self):
        c = self.client_for(self.disp)
        r = c.post("/api/roads/", {"from_node": self.nodes["N4"].id, "to_node": self.nodes["N2"].id,
                                   "travel_time": 1, "name": "Shortcut"}, format="json")
        self.assertEqual(r.status_code, 201)
        r = c.post("/api/route/", {"from_lat": P["N4"][0], "from_lng": P["N4"][1],
                                   "to_lat": P["N3"][0], "to_lng": P["N3"][1]}, format="json")
        self.assertEqual(r.status_code, 200)
        self.assertAlmostEqual(r.data["total_time"], 3.0, places=1)

    def test_health_is_public(self):
        self.assertEqual(APIClient().get("/api/health/").status_code, 200)
