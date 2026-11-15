# Task List: System Connectivity & Functionality Verification

## Task 1: Verify SQLite database schema, seed data, and Django test suite

**Description:** Inspect the local SQLite database (`Backend/db.sqlite3`) to confirm table existence, row counts for key entities (users, vehicles, road nodes/edges, active plan), and run the 57 Django unit tests covering allocation and Dijkstra routing algorithms.

**Acceptance criteria:**
- [x] Database contains registered demo accounts (`accounts_user` table populated with admin, dispatcher, driver, citizen)
- [x] Karachi road graph nodes and edges are populated in `dispatch_roadnode` and `dispatch_roadedge`
- [x] 57 backend tests in `algorithms` and `dispatch` pass with exit code 0

**Verification:**
- [x] Tests pass: `cd Backend && .venv/bin/python manage.py test algorithms dispatch`
- [x] Shell check: `cd Backend && .venv/bin/python manage.py shell -c "from accounts.models import User; from dispatch.models import Vehicle, RoadNode; print(f'Users: {User.objects.count()}, Vehicles: {Vehicle.objects.count()}, Nodes: {RoadNode.objects.count()}')"`

**Dependencies:** None

**Files likely touched:** None (read-only verification)

**Estimated scope:** Small: 1-2 files

---

## Task 2: Verify live Django REST API endpoints and algorithms via HTTP checks

**Description:** Spin up a background Django dev server instance and exercise all major REST API endpoints (`/api/health/`, `/api/auth/login/`, `/api/emergencies/`, `/api/vehicles/`, `/api/allocate/`, `/api/route/`, `/api/map/`) with real HTTP requests to verify status codes, payload structures, and algorithm execution.

**Acceptance criteria:**
- [ ] `GET /api/health/` returns `{"status": "healthy"}` with HTTP 200
- [ ] `POST /api/auth/login/` returns auth token and user profile for demo credentials
- [ ] `GET /api/vehicles/` and `GET /api/map/` return valid JSON arrays of Karachi resources
- [ ] `POST /api/allocate/` executes 0/1 knapsack multi-criteria optimization and returns allocation plan
- [ ] `GET /api/route/?origin_node=...&destination_node=...` computes dynamic Dijkstra route with distance and travel time

**Verification:**
- [ ] Script execution: `cd Backend && .venv/bin/python -c "import urllib.request; print(urllib.request.urlopen('http://127.0.0.1:8000/api/health/').read().decode())"`
- [ ] Focused API verification script executing login, allocation, and route calculation

**Dependencies:** Task 1

**Files likely touched:**
- `Backend/test_live_api.py` (temporary or test harness)

**Estimated scope:** Small: 1-2 files

---

## Checkpoint: Backend & Database Operational
- [ ] Database contains valid users, vehicles, Karachi road network, and active allocation
- [ ] All 57 Django algorithm and dispatch unit tests pass cleanly
- [ ] HTTP health, auth, allocation, and routing endpoints respond with HTTP 200/201
- [ ] Review backend results before proceeding to frontend verification

---

## Task 3: Implement dedicated Flutter ApiService online and fallback unit tests

**Description:** Create a comprehensive Flutter unit test suite in `test/api_service_test.dart` to verify `ApiService` against a mock HTTP client, testing both successful HTTP responses and offline network error / timeout scenarios ensuring fallback to `MockRepository`.

**Acceptance criteria:**
- [ ] `test/api_service_test.dart` created with test cases for `checkHealth`, `login`, `getVehicles`, `reportEmergency`, and `triggerAllocation`
- [ ] Test validates online mode: parses Django REST JSON response into model objects and sets auth token
- [ ] Test validates offline fallback: network failure triggers `isFromFallback: true` with data from `MockRepository` without raising uncaught exceptions

**Verification:**
- [ ] Tests pass: `flutter test test/api_service_test.dart`

**Dependencies:** Task 2

**Files likely touched:**
- `test/api_service_test.dart`

**Estimated scope:** Small: 1-2 files

---

## Task 4: Run full Flutter widget test suite and static analysis

**Description:** Execute the complete suite of existing Flutter widget tests, auth flow tests, citizen module tests, and static code analyzer to guarantee zero regressions or broken dependencies across the entire UI codebase.

**Acceptance criteria:**
- [ ] All tests in `test/citizen_module_test.dart`, `test/widget_test.dart`, and `test/phase3_role_test.dart` pass
- [ ] `flutter analyze` completes with "No issues found!"
- [ ] Role shell navigation, SOS countdown, and status badge rendering confirmed functional

**Verification:**
- [ ] Tests pass: `flutter test`
- [ ] Analysis passes: `flutter analyze`

**Dependencies:** Task 3

**Files likely touched:** None

**Estimated scope:** Small: 1-2 files

---

## Checkpoint: Frontend Integration Validated
- [ ] `ApiService` correctly handles live responses and falls back to `MockRepository` on error/timeout
- [ ] `flutter test` passes 100% of widget and role-based test cases
- [ ] `flutter analyze` reports zero warnings or errors
- [ ] Review frontend test report before proceeding to unified system harness

---

## Task 5: Build unified system verification script

**Description:** Create an executable shell verification runner script `scripts/verify_system.sh` that sequentially runs backend migrations check, Django unit tests, boots the backend server, runs the live HTTP API diagnostic, runs the Flutter test suite, runs Flutter static analysis, and safely terminates background processes.

**Acceptance criteria:**
- [ ] `scripts/verify_system.sh` created and set executable (`chmod +x`)
- [ ] Script handles starting and stopping the Django server cleanly using traps
- [ ] Script checks return codes and outputs structured PASS/FAIL indicators for each tier (Database, Backend APIs, Frontend Tests, Static Analysis)

**Verification:**
- [ ] Script execution: `bash scripts/verify_system.sh` exits code 0

**Dependencies:** Tasks 1-4

**Files likely touched:**
- `scripts/verify_system.sh`

**Estimated scope:** Small: 1-2 files

---

## Task 6: Execute full verification run and produce system connectivity status report

**Description:** Run the unified verification script and compile the comprehensive results into `docs/system_verification.md` detailing the verified database status, API endpoints, response latencies, Flutter test results, and fallback behavior.

**Acceptance criteria:**
- [ ] `docs/system_verification.md` created with documented verification matrix
- [ ] Report confirms database status (engine, tables, row counts)
- [ ] Report confirms backend API endpoint status codes and sample responses
- [ ] Report confirms Flutter test results and offline fallback verification

**Verification:**
- [ ] File exists: `test -f docs/system_verification.md`
- [ ] Checkpoint sign-off: all acceptance criteria verified

**Dependencies:** Task 5

**Files likely touched:**
- `docs/system_verification.md`

**Estimated scope:** Small: 1-2 files

---

## Checkpoint: Final Verification Complete
- [ ] End-to-end verification script exits code 0 with diagnostic breakdown
- [ ] System connectivity report generated at `docs/system_verification.md`
- [ ] Ready for human review and presentation
