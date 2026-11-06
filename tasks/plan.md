# Implementation Plan: Hunain Branch, APK Build, Hallmark Landing Page & Vercel Deployment

## Overview
Deconstruct work into 4 focused vertical tasks: branch setup, Flutter release APK generation, Hallmark-designed landing page creation with APK bundling, and Vercel CLI installation with live deployment.

## Architecture Decisions
- **Branch**: Create `Hunain` from current HEAD using git/gh.
- **APK Target**: Flutter Android release APK (`build/app/outputs/flutter-apk/app-release.apk`).
- **Landing Page**: Dedicated `landing-page/` directory with clean vanilla HTML5/CSS3 styled using Hallmark design principles (typographic discipline, purposeful whitespace, safety/emergency color palette, direct download CTA).
- **Hosting**: Direct deployment from `landing-page/` using Vercel CLI.

## Tasks

### Phase 1: Git Setup & APK Build
- Task 1: Create and checkout `Hunain` branch via `gh`/`git`.
- Task 2: Compile Android release APK via Flutter.

### Checkpoint: Foundation
- Current branch is `Hunain`.
- `app-release.apk` compiled and verified.

### Phase 2: Landing Page & Vercel Deployment
- Task 3: Build Hallmark-styled landing page in `landing-page/` and bundle `app-release.apk`.
- Task 4: Install Vercel CLI and deploy `landing-page` to Vercel production.

### Checkpoint: Final
- Vercel URL live and returning HTTP 200.
- Direct download button triggers APK download.

## Risks and Mitigations
| Risk | Impact | Mitigation |
|---|---|---|
| Gradle / Android SDK cache misses | High | Ensure clean flutter build command and inspect build logs |
| Vercel auth token missing for automated deploy | Med | Check existing Vercel credentials or use `--token` / interactive login if required |
| APK file size over Vercel static limit (100MB) | Med | Flutter release APK is typically 15-35MB, well below 100MB limit |
