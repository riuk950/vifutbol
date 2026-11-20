# Research & Technical Audit: CI/CD Pipeline, Android Release Signing & Firebase App Distribution

**Feature**: `053-cicd-android-firebase-distribution` (HU 23.1)  
**Date**: 2026-11-20  
**Scope**: Separate DEV/PROD Flutter entrypoints, Android `productFlavors` (`dev` / `prod`), release keystore signing in Gradle Kotlin DSL, `.gitignore` hardening, GitHub Actions CI/CD workflows, and setup documentation in `README.md`.

---

## 1. Existing Entrypoints & Environment Loading Audit

### Decision
Create `lib/main_dev.dart` (loading `.env.dev` + `EnvironmentConfig.development()`) and `lib/main_prod.dart` (loading `.env.prod` + `EnvironmentConfig.production()`), and keep `lib/main.dart` delegating to `main_dev.dart` so existing local `flutter run` commands continue working seamlessly.

### Audit Findings
- Only `lib/main.dart` currently exists; it loads `.env.dev` and calls `EnvironmentConfig.development()` (`showEnvironmentBanner: true`).
- `EnvironmentConfig.production()` already exists in `lib/domain/entities/app_environment.dart` with `showEnvironmentBanner: false` and `localStoragePrefix: 'vifutbol_prod'`.
- **`pubspec.yaml` Critical Finding**: Lines 81–83 declare BOTH `.env.dev` and `.env.prod` under `flutter.assets`. During a CI build on `develop` (where only `ENV_DEV_FILE` is injected), Flutter's asset bundler fails if `.env.prod` does not exist on disk (and vice-versa on `main`).
  - **Resolution**: In the DEV workflow, write `ENV_DEV_FILE` to `.env.dev` and create an empty placeholder `: > .env.prod`. In the PROD workflow, write `ENV_PROD_FILE` to `.env.prod` and create an empty placeholder `: > .env.dev`. This keeps zero cross-environment secrets in any APK while satisfying `pubspec.yaml` asset bundling.

---

## 2. Android `productFlavors` & Release Signing Audit

### Decision
Configure `android/app/build.gradle.kts` and `android/app/src/main/AndroidManifest.xml` with:
1. **`flavorDimensions += "environment"`** and two `productFlavors`:
   - `dev`: `applicationIdSuffix = ".dev"` (`com.vifutbol.vifutbol.dev`), `versionNameSuffix = "-dev"`, `manifestPlaceholders["appName"] = "vifutbol DEV"`.
   - `prod`: base `applicationId` (`com.vifutbol.vifutbol`), `manifestPlaceholders["appName"] = "vifutbol"`.
2. **`AndroidManifest.xml`**: Replace hardcoded `android:label="vifutbol"` with `android:label="${appName}"`.
3. **Release Signing (`signingConfigs.create("release")`)**:
   - Load `android/key.properties` via `java.util.Properties` when present (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`).
   - In `buildTypes.release`, use `signingConfigs.getByName("release")` when `key.properties` exists, falling back safely to `signingConfigs.getByName("debug")` for local developer builds without release keys.

### Audit Findings
- `android/app/build.gradle.kts` currently signs `release` with `signingConfigs.getByName("debug")` and has no `productFlavors`.
- Base `applicationId` is `com.vifutbol.vifutbol`, `compileOptions` and `kotlin` target `JavaVersion.VERSION_17`.

---

## 3. Repository Hygiene (`.gitignore`) Audit

### Decision
Append Android signing exclusions (`android/key.properties`, `*.jks`, `*.keystore`) to `.gitignore`.

### Audit Findings
- `.gitignore` already excludes `.env`, `.env.*`, `env.*`, and whitelists `!.env*.example`.
- It does **not** yet exclude `android/key.properties`, `*.jks`, or `*.keystore` (required by FR-005).

---

## 4. GitHub Actions CI/CD Workflows & Firebase App Distribution

### Decision
Create two dedicated workflows under `.github/workflows/`:
1. `.github/workflows/ci-cd-dev.yml`:
   - Triggers: `push` to `develop` + `workflow_dispatch`
   - `concurrency` group per branch (`cancel-in-progress: true`)
   - Quality Gate job / steps: `flutter pub get`, `flutter gen-l10n`, `flutter analyze`, `flutter test`
   - Secret validation step (fails fast naming missing secret keys, never printing values)
   - Materializes `.env.dev` from `secrets.ENV_DEV_FILE` + empty `.env.prod`
   - Decodes `secrets.ANDROID_KEYSTORE_BASE64` → `android/app/upload-keystore.jks` and writes `android/key.properties`
   - Builds `flutter build apk --release --flavor dev -t lib/main_dev.dart` → `build/app/outputs/flutter-apk/app-dev-release.apk`
   - Uploads artifact via `actions/upload-artifact@v4`
   - Distributes via `wzieba/Firebase-Distribution-Github-Action@v1` with `serviceCredentialsFileContent: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_JSON }}`, `appId: ${{ secrets.FIREBASE_APP_ID_DEV }}`, `groups: testers-dev`, and release notes file generated safely from Git metadata (`GITHUB_REF_NAME`, short SHA, author, commit message)
2. `.github/workflows/ci-cd-prod.yml`:
   - Triggers: `push` to `main` + `workflow_dispatch`
   - Same quality gate + secret validation
   - Materializes `.env.prod` from `secrets.ENV_PROD_FILE` + empty `.env.dev`
   - Same Android release keystore reconstruction
   - Builds `flutter build apk --release --flavor prod -t lib/main_prod.dart` → `build/app/outputs/flutter-apk/app-prod-release.apk`
   - Uploads artifact via `actions/upload-artifact@v4`
   - Distributes via `wzieba/Firebase-Distribution-Github-Action@v1` with `appId: ${{ secrets.FIREBASE_APP_ID_PROD }}`, `groups: testers-prod`, and release notes file

### Rationale
- Uses `subosito/flutter-action@v2` with `channel: 'stable'` (matching local Flutter `3.44.0` / Dart `^3.12.0`) and `actions/setup-java@v4` (`java-version: '17'`, `distribution: 'temurin'`).
- Writing release notes to a temporary file (`release-notes.txt`) and passing `releaseNotesFile` prevents shell-escaping bugs with quotes or multi-line commit messages (Edge Case).
- Passing `serviceCredentialsFileContent` directly avoids leaving service-account JSON files lying around on disk.

### Alternatives Considered
- **Single combined workflow with `if:` branch conditionals**: Rejected because separate `ci-cd-dev.yml` and `ci-cd-prod.yml` files provide cleaner GitHub Actions history, independent `workflow_dispatch` buttons, and stricter visual isolation between DEV and PROD.
