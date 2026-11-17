# Implementation Plan: Phone APK Sync & Cache-Buster

## Overview
Phone screenshots at 10:31 showed old layout because device was running APK downloaded before CI workflow completed (or browser served cached APK). Plan synchronizes CI commit, adds cache-buster to download links, and guides fresh installation.

## Tasks
1. Fast-forward local branch to latest CI release commit `f6d8381`.
2. Add cache-busting timestamp/version parameter to APK download links in `landing-page/index.html`.
3. Push to `upstream` and `origin` so live website serves fresh APK.
