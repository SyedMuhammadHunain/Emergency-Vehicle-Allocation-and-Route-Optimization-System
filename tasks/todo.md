# Task List: Phone APK Sync & Cache-Buster

## Task 1: Fast-Forward Local Main to CI Release Commit
**Description:** Fetch and fast-forward local `main` to commit `f6d8381` so local workspace matches the latest CI release build.
**Acceptance criteria:**
- [x] Local `main` points to `f6d8381`
- [x] Working tree clean
**Verification:**
- [x] `git status` clean and up-to-date with `upstream/main`

## Task 2: Add Download Cache-Busting Version to Landing Page
**Description:** Update `landing-page/index.html` download links with `?v=2.0.1-fixed` so browsers do not serve cached old APK.
**Acceptance criteria:**
- [ ] APK href in `landing-page/index.html` updated with version query parameter
**Verification:**
- [ ] Inspect `landing-page/index.html` href attributes

## Task 3: Push Live
**Description:** Push update to `upstream` and `origin` so GitHub Pages/hosting serves the latest APK.
**Acceptance criteria:**
- [ ] Pushed to both remotes
**Verification:**
- [ ] `git status` clean
