# Task List

## Task 1: Create Hunain Branch
**Description:** Create and checkout branch `Hunain` using GitHub CLI / git, push upstream if remote accessible.
**Acceptance criteria:**
- [x] Active branch is `Hunain` (`git branch --show-current` == `Hunain`)
**Verification:**
- [x] `git status` shows on branch `Hunain`
**Dependencies:** None
**Files touched:** `.git`

## Task 2: Build Android Release APK
**Description:** Compile Flutter Android release binary.
**Acceptance criteria:**
- [ ] `build/app/outputs/flutter-apk/app-release.apk` created
- [ ] File size > 10MB
**Verification:**
- [ ] `ls -lh build/app/outputs/flutter-apk/app-release.apk`
**Dependencies:** Task 1
**Files touched:** `build/app/outputs/flutter-apk/*`

## Checkpoint: Foundation
- [ ] Branch active
- [ ] APK verified

## Task 3: Build Hallmark Landing Page & Bundle APK
**Description:** Create `landing-page/` directory with Hallmark aesthetic, modern emergency management UI, responsive download CTA, and copy `app-release.apk` into static directory.
**Acceptance criteria:**
- [ ] `landing-page/index.html` and `landing-page/styles.css` created
- [ ] Download CTA links directly to `/app-release.apk`
- [ ] `landing-page/app-release.apk` present
**Verification:**
- [ ] Open and test static assets locally; verify link target and responsiveness
**Dependencies:** Task 2
**Files touched:** `landing-page/index.html`, `landing-page/styles.css`, `landing-page/app-release.apk`, `landing-page/vercel.json`

## Task 4: Install Vercel CLI & Deploy
**Description:** Install `vercel` CLI globally or locally via npm, deploy `landing-page` directory to Vercel production.
**Acceptance criteria:**
- [ ] `vercel` binary available in PATH
- [ ] Vercel deployment deployed and URL live
**Verification:**
- [ ] Curl test against deployment URL returning 200 OK
- [ ] Direct download endpoint accessible
**Dependencies:** Task 3
**Files touched:** `landing-page/`

## Checkpoint: Final
- [ ] All tasks completed
- [ ] Live URL verified
