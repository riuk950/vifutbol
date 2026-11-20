# Data Model & Build Configuration Matrix: CI/CD DEV / PROD

**Feature**: `053-cicd-android-firebase-distribution` (HU 23.1)  
**Date**: 2026-11-20

---

## 1. Environment Build Profiles Matrix

| Attribute | DEV Profile | PROD Profile |
|---|---|---|
| **Git Branch** | `develop` | `main` |
| **Workflow File** | `.github/workflows/ci-cd-dev.yml` | `.github/workflows/ci-cd-prod.yml` |
| **Flutter Entrypoint** | `lib/main_dev.dart` | `lib/main_prod.dart` |
| **Android Flavor** | `dev` | `prod` |
| **Android `applicationId`** | `com.vifutbol.vifutbol.dev` | `com.vifutbol.vifutbol` |
| **Launcher Label (`appName`)** | `vifutbol DEV` | `vifutbol` |
| **Runtime `EnvironmentConfig`** | `EnvironmentConfig.development()` (`showEnvironmentBanner: true`) | `EnvironmentConfig.production()` (`showEnvironmentBanner: false`) |
| **Env File Materialized** | `.env.dev` (from `ENV_DEV_FILE`) + empty `.env.prod` | `.env.prod` (from `ENV_PROD_FILE`) + empty `.env.dev` |
| **APK Output Path** | `build/app/outputs/flutter-apk/app-dev-release.apk` | `build/app/outputs/flutter-apk/app-prod-release.apk` |
| **Firebase App ID Secret** | `FIREBASE_APP_ID_DEV` | `FIREBASE_APP_ID_PROD` |
| **Firebase Tester Group** | `testers-dev` | `testers-prod` |

---

## 2. GitHub Secrets Schema

| Category | Secret Name | Required In | Format / Validation |
|---|---|---|---|
| **Env DEV** | `ENV_DEV_FILE` | `ci-cd-dev.yml` | Multiline `KEY=VALUE` content for `.env.dev` |
| **Env PROD** | `ENV_PROD_FILE` | `ci-cd-prod.yml` | Multiline `KEY=VALUE` content for `.env.prod` |
| **Android Signing** | `ANDROID_KEYSTORE_BASE64` | Both | Base64-encoded `.jks` keystore binary |
| **Android Signing** | `ANDROID_KEYSTORE_PASSWORD` | Both | Keystore password (`storePassword`) |
| **Android Signing** | `ANDROID_KEY_PASSWORD` | Both | Key password (`keyPassword`) |
| **Android Signing** | `ANDROID_KEY_ALIAS` | Both | Key alias (`keyAlias`) |
| **Firebase** | `FIREBASE_SERVICE_ACCOUNT_JSON` | Both | Raw JSON of Firebase App Distribution Admin service account |
| **Firebase** | `FIREBASE_APP_ID_DEV` | `ci-cd-dev.yml` | Firebase Android App ID registered for `com.vifutbol.vifutbol.dev` |
| **Firebase** | `FIREBASE_APP_ID_PROD` | `ci-cd-prod.yml` | Firebase Android App ID registered for `com.vifutbol.vifutbol` |

---

## 3. Ephemeral Build Files (Strictly `.gitignore`d)

- `.env.dev`
- `.env.prod`
- `android/key.properties`
- `android/app/upload-keystore.jks` (`*.jks`, `*.keystore`)
- `release-notes.txt` (CI runner workspace only, never committed)
