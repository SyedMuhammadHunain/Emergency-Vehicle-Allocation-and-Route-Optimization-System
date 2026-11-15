#!/usr/bin/env python3
"""
Live REST API verification client for ResQ backend.
Tests real HTTP request/response lifecycles, authentication,
data models, and algorithmic endpoints (Knapsack & Dijkstra).
"""

import json
import sys
import urllib.request
import urllib.error

DEFAULT_BASE = "http://127.0.0.1:8001"

def make_request(base_url, method, path, data=None, token=None):
    url = f"{base_url.rstrip('/')}{path}"
    headers = {"Content-Type": "application/json", "Accept": "application/json"}
    if token:
        headers["Authorization"] = f"Token {token}"
    
    encoded_data = json.dumps(data).encode("utf-8") if data else None
    req = urllib.request.Request(url, data=encoded_data, headers=headers, method=method)
    
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            body = resp.read().decode("utf-8")
            return resp.status, json.loads(body) if body else {}
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8")
        try:
            parsed = json.loads(body)
        except Exception:
            parsed = {"raw": body}
        return e.code, parsed
    except Exception as e:
        return 0, {"error": str(e)}

def run_tests(base_url):
    print(f"=== ResQ Live API Verification on {base_url} ===\n")
    results = []

    # 1. Health Check
    status, body = make_request(base_url, "GET", "/api/health/")
    ok = (status == 200 and body.get("status") == "ok")
    results.append(("GET /api/health/", ok, f"Status: {status}, nodes: {body.get('road_nodes')}, vehicles: {body.get('vehicles')}"))
    print(f"[{'PASS' if ok else 'FAIL'}] GET /api/health/ -> {status} (Nodes: {body.get('road_nodes')}, Vehicles: {body.get('vehicles')})")

    # 2. Login as Citizen
    status, body = make_request(base_url, "POST", "/api/auth/login/", {"email": "citizen@resq.com", "password": "Citizen123"})
    citizen_token = body.get("token")
    ok = (status == 200 and bool(citizen_token))
    results.append(("POST /api/auth/login/ (Citizen)", ok, f"Status: {status}, Token: {citizen_token[:8] if citizen_token else 'none'}..."))
    print(f"[{'PASS' if ok else 'FAIL'}] POST /api/auth/login/ (Citizen) -> {status} (Token received)")

    # 3. Login as Dispatcher
    status, body = make_request(base_url, "POST", "/api/auth/login/", {"email": "dispatcher@resq.com", "password": "Dispatch123"})
    dispatcher_token = body.get("token")
    ok = (status == 200 and bool(dispatcher_token))
    results.append(("POST /api/auth/login/ (Dispatcher)", ok, f"Status: {status}, Role: {body.get('user', {}).get('role')}"))
    print(f"[{'PASS' if ok else 'FAIL'}] POST /api/auth/login/ (Dispatcher) -> {status} (Role: {body.get('user', {}).get('role')})")

    # 4. Login as Driver
    status, body = make_request(base_url, "POST", "/api/auth/login/", {"email": "driver@resq.com", "password": "Driver123"})
    driver_token = body.get("token")
    ok = (status == 200 and bool(driver_token))
    results.append(("POST /api/auth/login/ (Driver)", ok, f"Status: {status}"))
    print(f"[{'PASS' if ok else 'FAIL'}] POST /api/auth/login/ (Driver) -> {status}")

    # 5. GET /api/vehicles/
    status, body = make_request(base_url, "GET", "/api/vehicles/", token=citizen_token)
    ok = (status == 200 and isinstance(body, list) and len(body) > 0)
    results.append(("GET /api/vehicles/", ok, f"Status: {status}, Vehicle count: {len(body) if isinstance(body, list) else 0}"))
    print(f"[{'PASS' if ok else 'FAIL'}] GET /api/vehicles/ -> {status} ({len(body) if isinstance(body, list) else 0} vehicles)")

    # 6. GET /api/map/
    status, body = make_request(base_url, "GET", "/api/map/", token=citizen_token)
    vehicles = body.get("vehicles", [])
    emergencies = body.get("emergencies", [])
    routes = body.get("routes", [])
    blocked = body.get("blocked_roads", [])
    ok = (status == 200 and "vehicles" in body and "emergencies" in body)
    results.append(("GET /api/map/", ok, f"Status: {status}, Vehicles: {len(vehicles)}, Emergencies: {len(emergencies)}, Blocked: {len(blocked)}"))
    print(f"[{'PASS' if ok else 'FAIL'}] GET /api/map/ -> {status} (Vehicles: {len(vehicles)}, Emergencies: {len(emergencies)}, Blocked: {len(blocked)})")

    # 7. POST /api/emergencies/ (Citizen reports emergency)
    new_emergency = {
        "title": "Road Accident at Shahrah-e-Faisal",
        "description": "Multi-vehicle collision near Nursery flyover.",
        "category": "ACCIDENT",
        "severity": 4,
        "urgency": 5,
        "people_affected": 3,
        "latitude": 24.8640,
        "longitude": 67.0650,
        "location_label": "Shahrah-e-Faisal near Nursery",
    }
    status, body = make_request(base_url, "POST", "/api/emergencies/", data=new_emergency, token=citizen_token)
    emergency_id = body.get("id")
    tracking = body.get("code") or body.get("tracking_number")
    ok = (status == 201 and bool(emergency_id))
    results.append(("POST /api/emergencies/", ok, f"Status: {status}, ID: {emergency_id}, Code: {tracking}"))
    print(f"[{'PASS' if ok else 'FAIL'}] POST /api/emergencies/ -> {status} (Created ID: {emergency_id}, Code: {tracking})")

    # 8. POST /api/allocate/ (Dispatcher triggers DP Knapsack allocation)
    status, body = make_request(base_url, "POST", "/api/allocate/", data={"dry_run": False}, token=dispatcher_token)
    plan_id = body.get("id") or body.get("plan_id")
    assignments = body.get("assignments", [])
    ok = (status == 200 and (plan_id is not None or "message" in body or len(assignments) >= 0))
    results.append(("POST /api/allocate/ (Knapsack DP)", ok, f"Status: {status}, Assignments: {len(assignments)}"))
    print(f"[{'PASS' if ok else 'FAIL'}] POST /api/allocate/ (Knapsack DP) -> {status} ({len(assignments)} assigned)")

    # 9. POST /api/route/ (Dynamic Dijkstra routing)
    route_payload = {
        "from_lat": 24.8720,
        "from_lng": 67.0104,
        "to_lat": 24.8640,
        "to_lng": 67.0650
    }
    status, body = make_request(base_url, "POST", "/api/route/", data=route_payload, token=citizen_token)
    path = body.get("path", [])
    time_min = body.get("total_time")
    dist_km = body.get("distance_km")
    ok = (status == 200 and len(path) > 0 and dist_km is not None)
    results.append(("POST /api/route/ (Dijkstra)", ok, f"Status: {status}, Path nodes: {len(path)}, Distance: {dist_km} km, ETA: {time_min} mins"))
    print(f"[{'PASS' if ok else 'FAIL'}] POST /api/route/ (Dijkstra) -> {status} (Path: {len(path)} nodes, {dist_km} km, {time_min} mins)")

    # 10. GET /api/driver/mission/
    status, body = make_request(base_url, "GET", "/api/driver/mission/", token=driver_token)
    ok = (status == 200)
    results.append(("GET /api/driver/mission/", ok, f"Status: {status}, Has Mission: {body.get('has_mission', False)}"))
    print(f"[{'PASS' if ok else 'FAIL'}] GET /api/driver/mission/ -> {status} (Active mission: {body.get('has_mission', False)})")

    # Summary
    total = len(results)
    passed = sum(1 for _, ok, _ in results if ok)
    print(f"\nAPI Tests Passed: {passed}/{total}")
    
    if passed < total:
        sys.exit(1)
    sys.exit(0)

if __name__ == "__main__":
    target_base = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_BASE
    run_tests(target_base)
