# Task List: MySQL Backend Migration & Res-Q Showcase Deployment

## Task 1: Provision and configure local MySQL server and resq_db database

**Description:** Install `mysql-server` on the Linux host (or start existing service), create database `resq_db`, create user `resq` with password `NewPass123` granting all privileges on `resq_db.*`.

**Acceptance criteria:**
- [x] MySQL server is running locally on port 3306
- [x] Database `resq_db` exists
- [x] User `resq` can authenticate with `NewPass123` against `resq_db`

**Verification:**
- [x] Command check: `mysql -u resq -pNewPass123 -h 127.0.0.1 -e "SHOW DATABASES;" | grep resq_db`
- [x] PyMySQL check: `Backend/.venv/bin/python -c "import pymysql; conn = pymysql.connect(host='127.0.0.1', user='resq', password='NewPass123', database='resq_db'); print(conn.get_server_info())"`

**Dependencies:** None

**Files likely touched:** None (system configuration)

**Estimated scope:** Small: 1-2 files

---

## Task 2: Configure Django environment and apply migrations & seed demo data

**Description:** Update `Backend/.env` to set `DB_ENGINE=mysql`, execute `python manage.py migrate` to create all Django auth, accounts, and dispatch tables in MySQL, and execute `seed_demo` to populate Karachi road network and demo users.

**Acceptance criteria:**
- [x] `Backend/.env` has `DB_ENGINE=mysql`
- [x] `python manage.py migrate` executes successfully against MySQL
- [x] `python manage.py seed_demo` populates Karachi nodes, edges, vehicles, and roles

**Verification:**
- [x] Migrations check: `cd Backend && .venv/bin/python manage.py showmigrations` shows all unapplied migrations applied
- [x] Shell row count check: `cd Backend && .venv/bin/python manage.py shell -c "from accounts.models import User; from dispatch.models import RoadNode; print(f'Users: {User.objects.count()}, Nodes: {RoadNode.objects.count()}')"`

**Dependencies:** Task 1

**Files likely touched:**
- `Backend/.env`

**Estimated scope:** Small: 1-2 files

---

## Task 3: Verify backend tests and API endpoints against MySQL

**Description:** Run all 57 Django unit tests in `algorithms` and `dispatch` against MySQL, boot dev server, and run live API check to ensure knapsack allocation and Dijkstra route calculation succeed.

**Acceptance criteria:**
- [x] 57 tests pass with exit code 0 (`algorithms` and `dispatch`)
- [x] Live API health check and route calculation endpoint respond with HTTP 200

**Verification:**
- [x] Unit tests pass: `cd Backend && .venv/bin/python manage.py test algorithms dispatch`
- [x] Live test pass: `cd Backend && .venv/bin/python test_live_api.py`

**Dependencies:** Task 2

**Files likely touched:** None

**Estimated scope:** Small: 1-2 files

---

## Checkpoint: Backend Operational on MySQL
- [x] Local MySQL daemon running and accepting connections for `resq` user
- [x] All Django migrations applied to `resq_db` and Karachi network seeded
- [x] 57 algorithm and dispatch tests pass with exit code 0 on MySQL
- [x] Review backend verification before moving to showcase landing page

---

## Task 4: Reverse-engineer structural layout and styling of guillaumezhu.com in a new showcase directory

**Description:** Inspect and adapt the aesthetic structure of `https://guillaumezhu.com/` (dark sleek theme, smooth typography, card layout, interactive presentation elements) into a new directory `landing-page/new-showcase/` (or dedicated workspace), preparing a modern web layout.

**Acceptance criteria:**
- [ ] Clean modern HTML/CSS/JS structure created with dark aesthetic and modern typography
- [ ] Header, Hero section, Feature showcase, Algorithm highlight, and Call-to-action sections structured
- [ ] All external personal references, external portfolio scripts, and unnecessary tracking removed

**Verification:**
- [ ] Browser or local HTTP check: `python3 -m http.server` loads new layout with zero 404 console errors

**Dependencies:** None

**Files likely touched:**
- `landing-page/new-showcase/index.html`
- `landing-page/new-showcase/styles.css`
- `landing-page/new-showcase/main.js`

**Estimated scope:** Medium: 3-5 files

---

## Task 5: Populate showcase site with Res-Q content and remove personal portfolio links/pages

**Description:** Populate the structured sections with Res-Q's core value propositions: emergency response mission, real-time vehicle dispatch, 0/1 Knapsack priority optimization, dynamic Dijkstra route calculation on Karachi road network, role interfaces (Citizen, Dispatcher, Driver), and architecture.

**Acceptance criteria:**
- [ ] Hero headline and subtext clearly state Res-Q emergency dispatch system
- [ ] Interactive feature cards detail Knapsack resource allocation & Dijkstra shortest path routing
- [ ] Project screenshots/mockups integrated into case-study card displays
- [ ] Personal portfolio navigation links (Parcours, Toolkit, Resume, Personal bio) replaced or removed

**Verification:**
- [ ] Content inspection: verify zero mentions of "Guillaume Zhu" or portfolio resume links
- [ ] Text and card review in local preview

**Dependencies:** Task 4

**Files likely touched:**
- `landing-page/new-showcase/index.html`
- `landing-page/new-showcase/styles.css`

**Estimated scope:** Small: 1-2 files

---

## Task 6: Implement Download APK section and wire app-release.apk asset and download trigger

**Description:** Add a prominent, high-visibility "Download APK" call-to-action button in both header and hero/footer, linking directly to `/app-release.apk` with package release metadata (version, Android requirement, size ~54MB).

**Acceptance criteria:**
- [ ] Header contains a fixed "Download APK" action button
- [ ] Hero and Download sections feature direct download CTA with Android icon
- [ ] `app-release.apk` is accessible at root download URL with correct MIME type and attachment headers

**Verification:**
- [ ] File download check: `curl -sI http://localhost:.../app-release.apk` returns Content-Type `application/vnd.android.package-archive`

**Dependencies:** Task 5

**Files likely touched:**
- `landing-page/new-showcase/index.html`
- `landing-page/vercel.json`

**Estimated scope:** Small: 1-2 files

---

## Checkpoint: Showcase Site Functional Locally
- [ ] Showcase site renders with high-aesthetic styling, animations, and Res-Q content
- [ ] "Download APK" button triggers valid download of `app-release.apk`
- [ ] Irrelevant portfolio sections/links removed; responsive across mobile and desktop
- [ ] Review showcase before integrating into production deployment structure

---

## Task 7: Relocate and configure existing landing page under /legacy/

**Description:** Move or mirror existing landing page files (`landing-page/index.html`, `styles.css`, `tokens.css`, `base.css`, `privacy.html`, `terms.html`, and `assets/`) into `landing-page/legacy/`, ensuring internal relative paths work so the original site remains fully functional at `/legacy/`.

**Acceptance criteria:**
- [ ] Existing landing page accessible at `/legacy/index.html` (and `/legacy/`)
- [ ] All css and asset links within the legacy page resolve properly without 404s
- [ ] Legal pages (`privacy.html`, `terms.html`) remain intact

**Verification:**
- [ ] Local check: `curl -s http://localhost:.../legacy/ | grep -i "ResQ Operations"`

**Dependencies:** Task 6

**Files likely touched:**
- `landing-page/legacy/*`
- `landing-page/vercel.json`

**Estimated scope:** Medium: 3-5 files

---

## Task 8: Configure Vercel build/routes and deploy to http://res-q.tech/

**Description:** Promote the new showcase site to the root of `landing-page/`, update `vercel.json` rewrite/header rules for APK downloads and `/legacy/` routes, and execute `vercel --prod` to deploy live to `res-q.tech`.

**Acceptance criteria:**
- [ ] `vercel.json` configures `/legacy` routing and `/app-release.apk` attachment headers
- [ ] `vercel --prod` succeeds and deploys to production alias `res-q.tech`
- [ ] Deployment status is READY with no build errors

**Verification:**
- [ ] Deployment command: `cd landing-page && /home/prx/.local/bin/vercel --prod`
- [ ] DNS/HTTP status: `curl -sI https://res-q.tech/` returns HTTP 200/308

**Dependencies:** Task 7

**Files likely touched:**
- `landing-page/vercel.json`
- `landing-page/index.html`

**Estimated scope:** Small: 1-2 files

---

## Task 9: End-to-end verification of live http://res-q.tech/

**Description:** Verify live deployment across all URLs: root `http://res-q.tech/` loads new showcase UI, `http://res-q.tech/legacy/` loads original landing page, and `http://res-q.tech/app-release.apk` downloads the Android package.

**Acceptance criteria:**
- [ ] Root `res-q.tech` serves new showcase landing page with Res-Q content
- [ ] `res-q.tech/legacy/` serves previous landing page
- [ ] "Download APK" link downloads `app-release.apk` (~57MB)
- [ ] Responsive UI verified on mobile and desktop viewports

**Verification:**
- [ ] `curl -sL https://res-q.tech/ | grep -i "Emergency"`
- [ ] `curl -sL https://res-q.tech/legacy/ | grep -i "ResQ Operations"`
- [ ] `curl -sI https://res-q.tech/app-release.apk | grep -i "Content-Length"`

**Dependencies:** Task 8

**Files likely touched:** None (verification)

**Estimated scope:** Small: 1-2 files

---

## Checkpoint: Production Deployment Live & Verified
- [ ] `http://res-q.tech/` loads the new showcase landing page
- [ ] `http://res-q.tech/legacy/` serves the preserved original landing page
- [ ] Live APK download link tested and verified functional
- [ ] End-to-end evaluation sign-off
