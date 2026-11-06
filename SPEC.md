# Spec: Hunain Branch, Android APK Build, and Hallmark Landing Page Deployment

## Objective
Build a production-ready Android APK for the Emergency Route and Resource Management System Flutter app. Create a Git branch `Hunain` using GitHub CLI. Develop a high-aesthetic static landing page using `hallmark` design standards with an instant download button serving the APK. Install Vercel CLI and deploy the landing page to Vercel.

## Tech Stack
- Mobile App: Flutter (Dart 3.12.2 / Flutter 3.44.9)
- VCS: Git + GitHub CLI (`gh`)
- Landing Page: HTML5, CSS3 / Modern Tailwind, JavaScript (designed with Hallmark principles)
- Hosting: Vercel CLI (`npm install -g vercel`)

## Commands
```bash
# Git branch
git checkout -b Hunain
git push -u origin Hunain

# Flutter APK build
flutter build apk --release

# Install Vercel CLI
npm install -g vercel

# Vercel Deployment (within landing-page directory)
cd landing-page && vercel --prod --yes
```

## Project Structure
```text
.
├── android/                 # Flutter Android project source
├── lib/                     # Flutter Dart application code
├── build/app/outputs/flutter-apk/app-release.apk # Generated APK
├── landing-page/            # Standalone landing page for Vercel
│   ├── index.html           # Landing page with download CTA (Hallmark design)
│   ├── styles.css           # Custom typography, spacing, aesthetic styling
│   ├── app-release.apk      # Direct download target bundled in static site
│   └── vercel.json          # Deployment routing and cache headers
└── SPEC.md                  # This specification document
```

## Code Style & Design System (Hallmark Principles)
- Typography: Clean typography pairing (e.g. Inter / Geist / Newsreader display + crisp sans body).
- Layout: Asymmetric, modern, spacious layout with purposeful whitespace; no cookie-cutter AI aesthetic.
- Color: Curated palette fitting emergency resource management (high contrast slate, safety accents, crisp dark/light harmony).
- Micro-interactions: Subtle hover states, smooth scroll, direct single-click APK trigger (`<a href="/app-release.apk" download>`).

## Testing & Verification Strategy
- Git: Run `git branch --show-current` to ensure branch is `Hunain`.
- APK Build: Verify `build/app/outputs/flutter-apk/app-release.apk` exists and filesize is valid (> 15MB).
- Landing Page: Validate HTML5 structure, responsive layout on mobile/desktop viewports, verify download link triggers file transfer.
- Deployment: Inspect live Vercel deployment URL via HTTP GET and verify 200 OK for `/` and `/app-release.apk`.

## Boundaries
- Always: Preserve existing Flutter codebase integrity; verify APK build before copying to landing page assets.
- Ask first: If Vercel authentication requires interactive login tokens (`vercel login`).
- Never: Commit large binary build artifacts to main Git history unless strictly intended for the deployment folder; do not tamper with sensitive environment configs.

## Success Criteria
1. Git branch `Hunain` created and checked out.
2. `flutter build apk --release` generates working APK.
3. Landing page designed according to Hallmark quality bar with working direct download CTA.
4. Vercel CLI installed and landing page deployed with live accessible URL.

## Open Questions
- None (confirmed standalone landing page with direct static APK bundling).
