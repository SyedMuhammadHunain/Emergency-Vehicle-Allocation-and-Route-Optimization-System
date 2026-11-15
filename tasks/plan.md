# Implementation Plan: MySQL Backend Migration & Res-Q Showcase Landing Page Deployment

## Overview
Execute two core objectives for project evaluation and UI enhancement:
1. Transition the Django backend from SQLite to a local MySQL database (`resq_db`), execute schema migrations, seed demonstration data (Karachi road network, users, vehicles), and verify all 57 algorithm and dispatch test cases.
2. Reverse-engineer the design aesthetic and interactive layout of `https://guillaumezhu.com/` into a new folder, adapt and populate it with Res-Q emergency system content (removing personal portfolio navigation and unneeded pages), embed a direct "Download APK" button for `app-release.apk`, preserve the legacy landing page accessible under `/legacy/`, and deploy the complete site to `http://res-q.tech/`.

## Architecture Decisions
- **Database Engine**: Local MySQL server (port 3306), database `resq_db`, user `resq` with password `NewPass123` via `PyMySQL` driver in pure Python, matching `Backend/config/settings.py` and `Backend/.env.example`.
- **Landing Page Architecture**: New folder `landing-page-showcase/` containing the reconstructed modern aesthetic (dark theme, Mona Sans & Geist typography, fluid interactive canvas/cards, emergency metrics showcase, download CTA).
- **Legacy Preservation**: Keep the existing landing page files in `landing-page/legacy/` and configure routing in `vercel.json` so `res-q.tech/legacy/` continues to serve the original site, while `res-q.tech/` serves the new showcase.
- **APK Distribution**: Host `app-release.apk` with Vercel headers (`application/vnd.android.package-archive`, `attachment`) so the "Download APK" button immediately downloads the package without navigation hiccups.
- **Strict Read-Only Plan Phase**: No code modifications or destructive changes during planning; document tasks, dependencies, acceptance criteria, and verification commands.

## Task List

### Phase 1: MySQL Database Installation & Backend Connection
- [ ] Task 1: Provision and configure local MySQL server and `resq_db` database
- [ ] Task 2: Configure Django environment and apply migrations & seed demo data
- [ ] Task 3: Verify backend tests and API endpoints against MySQL

### Checkpoint: Backend Operational on MySQL
- [ ] Local MySQL daemon running and accepting connections for `resq` user
- [ ] All Django migrations applied to `resq_db` and Karachi network seeded
- [ ] 57 algorithm and dispatch tests pass with exit code 0 on MySQL

### Phase 2: Reverse-Engineer & Build Res-Q Showcase Landing Page
- [ ] Task 4: Reverse-engineer structural layout and styling of `https://guillaumezhu.com/` in a new showcase directory
- [ ] Task 5: Populate showcase site with Res-Q content and remove personal portfolio links/pages
- [ ] Task 6: Implement Download APK section and wire `app-release.apk` asset and download trigger

### Checkpoint: Showcase Site Functional Locally
- [ ] Showcase site renders with high-aesthetic styling, animations, and Res-Q content
- [ ] "Download APK" button triggers valid download of `app-release.apk`
- [ ] Irrelevant portfolio sections/links removed; responsive across mobile and desktop

### Phase 3: Legacy Preservation, Routing & Production Deployment
- [ ] Task 7: Relocate and configure existing landing page under `/legacy/`
- [ ] Task 8: Configure Vercel build/routes and deploy to `http://res-q.tech/`
- [ ] Task 9: End-to-end verification of live `http://res-q.tech/` (new showcase, legacy route, APK download)

### Checkpoint: Production Deployment Live & Verified
- [ ] `http://res-q.tech/` loads the new showcase landing page
- [ ] `http://res-q.tech/legacy/` serves the preserved original landing page
- [ ] Live APK download link tested and verified functional

## Risks and Mitigations
| Risk | Impact | Mitigation |
|---|---|---|
| Sudo password required for installing MySQL server | High | Provide prompt and script for local installation, or accept root credentials to run `apt install mysql-server` |
| Asset path collisions between showcase and legacy landing pages | Medium | Isolate legacy assets under `/legacy/assets/` and showcase assets under `/assets/` |
| Large APK file payload in Vercel deployments | Low | Existing `app-release.apk` (~57MB) is already tracked and deployed on Vercel Hobby tier without issue |
| Vercel domain alias mismatch | Medium | Verify domain alias `res-q.tech` on project `landing-page` before final production push |

## Open Questions
- None. Confirmation received on user requirements and scope.
