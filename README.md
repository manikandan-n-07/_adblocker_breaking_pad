# 🛡️ BREAKING PAD Browser

**BREAKING PAD Browser** is a privacy-first mobile web browser built with Flutter, powered by a local, standalone **AdGuard-style multi-layer ad-blocking engine**. Designed with a high-contrast monochrome (Black & White) aesthetic, it delivers speed, zero tracking, and local security without relying on any external backend or cloud proxy.

---

## ⚡ Core Features

- **Standalone AdGuard Filtering Engine (No Backend):**
  - **Layer 1: Network Filtering:** Real-time domain and URL pattern blocking (200+ ad networks, 80+ analytics/telemetry trackers, 28 regex path patterns).
  - **Layer 2: JS Scriptlet Injection (`AT_DOCUMENT_START`):** Neutralizes Google Tag (`googletag`/GPT), Prebid.js (`pbjs`), Amazon TAM (`apstag`), Taboola, Outbrain, Criteo, and blocks malicious script/iframe injections.
  - **Layer 3: Extended Cosmetic Filtering:** 120+ CSS rules actively collapsing ad slots, floating sticky promos, loan popups, and banner wrappers.
  - **Layer 4: MutationObserver:** Watches dynamic SPAs and removes lazy-loaded advertisements every 1.5 seconds.
  - **YouTube Ad Mitigation:** Auto-skips video ads, mutes pre-rolls, strips ad placements from API responses, and provides one-tap floating player controls (`⚡ Skip`, `⏩ +10s`, `⏯ Play/Pause`, `⏪ -10s`, `🔇 Mute`).
- **Monochrome Minimalist UI:** Ultra-clean pure black (`#000000`) and white design with instant startup (0s lag, no loading spinner).
- **Tab Management:** Multi-tab browsing, incognito/private browsing with instant tab-switching and isolation.
- **Privacy Dashboard:** Real-time statistics of blocked ads, trackers, YouTube mitigations, and popups.
- **Local Data Management:** Bookmarks, browsing history, and background download management.
- **In-App Version Control & GitHub Releases Updates:**
  - One-tap update check directly connecting to GitHub Releases.
  - Automatically compares semantic versions (`v1.0.0` vs latest).
  - Displays changelog and one-tap direct APK download and install.

---

## 🚀 In-App Version Control & Updates

The browser includes a built-in `AppUpdateService` integrated into **Settings ➔ Check for Updates** and the main menu.

- **GitHub Repository:** [`manikandan-n-07/_adblocker_breaking_pad`](https://github.com/manikandan-n-07/_adblocker_breaking_pad)
- **Releases API:** `https://api.github.com/repos/manikandan-n-07/_adblocker_breaking_pad/releases/latest`
- When a new tag (e.g. `v1.0.1`) is published on GitHub, users can tap **Update Now** in the app to directly download the APK and update.

---

## 📦 Automated GitHub Actions CI/CD

Workflows are configured in `.github/workflows/`:

1. **`release_apk.yml` — Android APK Release:**
   - Triggers on tags matching `v*` (e.g. `git tag v1.0.1 && git push origin v1.0.1`).
   - Runs unit tests and builds `app-release.apk`.
   - Automatically publishes a GitHub Release with the APK attached.

2. **`deploy_pages.yml` — Static Web Site Deployment:**
   - Triggers on push to `main`.
   - Runs `flutter build web --release` and deploys the static build to **GitHub Pages**.

---

## 🛠️ Building & Running Locally

### Prerequisites
- Flutter SDK (3.x+)
- Android SDK (minSdk 21+)
- Java 17

### Commands
```bash
# Install dependencies
flutter pub get

# Run tests (24/24 unit tests)
flutter test

# Run app on connected device / emulator
flutter run --debug

# Build Android Release APK
flutter build apk --release

# Build Web for Static Pages
flutter build web --release
```

---

## 📄 License
MIT License. Built for speed, privacy, and full user control.
