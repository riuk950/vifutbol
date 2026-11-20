# Contracts: CI/CD Pipeline, Android Signing & Entrypoints

**Feature**: `053-cicd-android-firebase-distribution` (HU 23.1)  
**Date**: 2026-11-20

---

## 1. Flutter Entrypoints Contract

- **`lib/main_dev.dart`**:
  - Calls `WidgetsFlutterBinding.ensureInitialized()`.
  - Loads `.env.dev` via `dotenv.load(fileName: '.env.dev', isOptional: true)`.
  - Instantiates `EnvironmentConfig.development()` (`showEnvironmentBanner == true`, `environment == AppEnvironment.development`).
  - Calls `bootstrapApp(config)`.
- **`lib/main_prod.dart`**:
  - Calls `WidgetsFlutterBinding.ensureInitialized()`.
  - Loads `.env.prod` via `dotenv.load(fileName: '.env.prod', isOptional: true)`.
  - Instantiates `EnvironmentConfig.production()` (`showEnvironmentBanner == false`, `environment == AppEnvironment.production`).
  - Calls `bootstrapApp(config)`.
- **`lib/main.dart`**:
  - Delegates to `main_dev.main()` so default local `flutter run` continues targeting DEV.

---

## 2. Android Gradle Contract (`android/app/build.gradle.kts`)

1. **Keystore Properties Loading**:
   - Reads `rootProject.file("key.properties")` if it exists.
   - `hasReleaseKeystore` is `true` only when `storeFile`, `storePassword`, `keyAlias`, and `keyPassword` are non-empty.
   - Creates `signingConfigs.create("release")` when `hasReleaseKeystore` is `true`.
   - In `buildTypes.release`, selects `signingConfigs.getByName("release")` when `hasReleaseKeystore` is `true`, otherwise falls back to `signingConfigs.getByName("debug")`.
2. **Product Flavors**:
   - `flavorDimensions += "environment"`
   - `dev`: `dimension = "environment"`, `applicationIdSuffix = ".dev"`, `versionNameSuffix = "-dev"`, `manifestPlaceholders["appName"] = "vifutbol DEV"`
   - `prod`: `dimension = "environment"`, `manifestPlaceholders["appName"] = "vifutbol"`
3. **Manifest Label**:
   - `android/app/src/main/AndroidManifest.xml` uses `android:label="${appName}"`.

---

## 3. GitHub Actions Workflow Contract (`.github/workflows/ci-cd-dev.yml` & `ci-cd-prod.yml`)

### Stage Order (Strict Fail-Fast)
1. **Checkout & Toolchain**: `actions/checkout@v4`, `actions/setup-java@v4` (Java 17 Temurin), `subosito/flutter-action@v2` (`channel: 'stable'`, `cache: true`).
2. **Quality Gate (Mandatory — `FR-002`)**:
   - `flutter pub get`
   - `flutter gen-l10n`
   - `flutter analyze`
   - `flutter test`
   - *Any non-zero exit code halts the job immediately before secret materialization, APK compilation, or Firebase upload.*
3. **Secret Validation (`FR-009`)**:
   - Verifies all required secrets are non-empty via env vars without echoing any secret values; prints only the missing secret name and exits `1` if absent.
4. **Environment & Keystore Materialization (`FR-003`, `FR-004`)**:
   - Writes active `.env.<env>` from `ENV_<ENV>_FILE` and creates empty placeholder for the other `.env` asset.
   - Decodes `ANDROID_KEYSTORE_BASE64` into `android/app/upload-keystore.jks` and writes `android/key.properties` (`storeFile=upload-keystore.jks`).
5. **Signed Release Build**:
   - DEV: `flutter build apk --release --flavor dev -t lib/main_dev.dart`
   - PROD: `flutter build apk --release --flavor prod -t lib/main_prod.dart`
6. **Release Notes & Distribution (`FR-006`, `FR-007`, `FR-008`)**:
   - Writes `release-notes.txt` containing Environment, Branch, Short SHA, Author, and Commit Message.
   - Uploads APK as GitHub Actions artifact (`actions/upload-artifact@v4`, retention 14 days).
   - Uploads APK to Firebase App Distribution (`wzieba/Firebase-Distribution-Github-Action@v1`) with `serviceCredentialsFileContent`, `appId`, `groups` (`testers-dev` / `testers-prod`), and `releaseNotesFile: release-notes.txt`.
