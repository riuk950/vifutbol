# Quickstart & Verification Guide: HU 23.1 CI/CD & Android Firebase Distribution

**Feature**: `053-cicd-android-firebase-distribution`  
**Date**: 2026-11-20

---

## 1. Local Automated Verification

```bash
flutter analyze
flutter test test/domain/entities/app_environment_test.dart test/app_entrypoints_test.dart
```

Verify `.gitignore` excludes all sensitive files:

```bash
git check-ignore -v .env.dev .env.prod android/key.properties android/app/upload-keystore.jks
```

Verify Android flavor builds compile locally (debug fallback when `android/key.properties` is absent):

```bash
flutter build apk --debug --flavor dev -t lib/main_dev.dart
```

---

## 2. Release Keystore & GitHub Secrets Setup (Summary — Full Steps in `README.md`)

1. Generate release keystore:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Convert keystore to single-line Base64 (macOS):
   ```bash
   base64 -i upload-keystore.jks | tr -d '\n' | pbcopy
   ```
3. Register two Android apps in Firebase Console:
   - DEV: `com.vifutbol.vifutbol.dev` → copy App ID to `FIREBASE_APP_ID_DEV`
   - PROD: `com.vifutbol.vifutbol` → copy App ID to `FIREBASE_APP_ID_PROD`
4. Create tester groups `testers-dev` and `testers-prod` in Firebase App Distribution.
5. Configure the 9 GitHub Secrets in **Settings → Secrets and variables → Actions** and push to `develop` to validate the live DEV pipeline.
