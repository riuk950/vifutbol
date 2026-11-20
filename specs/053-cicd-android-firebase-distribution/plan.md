# Implementation Plan: Automated CI/CD Pipeline, Android Release Signing, and DEV/PROD App Distribution

**Branch**: `053-cicd-android-firebase-distribution` | **Date**: 2026-11-20 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/053-cicd-android-firebase-distribution/spec.md)  
**Input**: Feature specification from `/specs/053-cicd-android-firebase-distribution/spec.md` (Notion HU 23.1)

---

## Summary

Deliver a complete, secure, and repeatable CI/CD pipeline in GitHub Actions for `develop` (**DEV**) and `main` (**PROD**) with separate Flutter entrypoints (`lib/main_dev.dart`, `lib/main_prod.dart`), Android `productFlavors` (`dev` with `.dev` suffix for side-by-side install; `prod` with base ID), Gradle release keystore signing with safe local debug fallback, `.gitignore` hardening, automated `flutter analyze` + `flutter test` quality gates, dynamic `.env` materialization from `ENV_DEV_FILE` / `ENV_PROD_FILE`, artifact archival, Firebase App Distribution publishing, and step-by-step maintainer documentation in `README.md`.

---

## Technical Context

**Language/Version**: Dart 3.12.0 / Flutter 3.44.0 (stable) + Gradle Kotlin DSL (Java 17) + GitHub Actions YAML  
**Primary Dependencies**: `flutter_dotenv`, `subosito/flutter-action@v2`, `actions/setup-java@v4`, `actions/upload-artifact@v4`, `wzieba/Firebase-Distribution-Github-Action@v1`  
**Storage**: Ephemeral CI runner files (`.env.dev`, `.env.prod`, `android/key.properties`, `android/app/upload-keystore.jks`) — strictly excluded from Git  
**Testing**: `flutter analyze`, `flutter test` (unit tests validating DEV/PROD `EnvironmentConfig` isolation + banner visibility), `git check-ignore` hygiene verification, YAML syntax check  
**Target Platform**: Android APK (`app-dev-release.apk` / `app-prod-release.apk`) distributed via Firebase App Distribution  
**Project Type**: Mobile app + CI/CD release automation  
**Performance Goals**: Complete CI/CD run (quality gate + signed APK build + Firebase upload) within typical GitHub Actions runner times with `flutter-action` caching enabled  
**Constraints**: Zero secrets committed or echoed to CI logs; mandatory quality gate before build; strict branch-to-environment isolation (`develop` → DEV, `main` → PROD); side-by-side installability via `.dev` flavor suffix  
**Scale/Scope**: 3 Dart entrypoints + 2 Android config files + `.gitignore` + 2 GitHub Actions workflows + `README.md` + 1 unit test file

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Pre-Design | Post-Design | Verification Notes |
|---|---|---|---|
| **I. Spec-Driven & Incremental Delivery** | PASS | PASS | Driven by `spec.md` + 2 resolved clarifications (`ENV_DEV_FILE`/`ENV_PROD_FILE` multiline secrets; Android `productFlavors` `dev`/`prod`). |
| **II. Data Integrity & Persistence Reliability** | PASS | PASS | Strict environment isolation (`vifutbol_dev` vs `vifutbol_prod`, empty placeholder for opposite `.env` asset) guarantees DEV and PROD data never mix. |
| **III. Automated Tests & Quality Gate** | PASS | PASS | Mandatory `flutter analyze` + `flutter test` gate enforced in both workflows before packaging; unit test verifies DEV/PROD config isolation & banner flag. |
| **IV. Clean Architecture & Modularity** | PASS | PASS | Entrypoints (`main_dev.dart`, `main_prod.dart`) remain thin bootstrappers delegating to `bootstrapApp(config)`. |
| **V. Role-Based Security & KickPulse Design System** | PASS | PASS | Zero credentials in repository or CI logs; PROD hides DEV banner cleanly. |
| **VI. English Codebase & Spanish UI Localization** | PASS | PASS | Technical code, workflows, comments, and tests in English; maintainer docs in `README.md` clear and actionable. |
| **VII. Mobile Engineering & Usability Resilience** | PASS | PASS | Side-by-side installability (`com.vifutbol.vifutbol.dev` vs `com.vifutbol.vifutbol`), release-signed APK, safe local fallback when keystore is absent. |

---

## Project Structure

### Documentation (this feature)

```text
specs/053-cicd-android-firebase-distribution/
├── spec.md                                      # Feature specification + clarifications
├── checklists/requirements.md                   # Spec quality checklist (16/16 PASS)
├── plan.md                                      # This file (/speckit-plan output)
├── research.md                                  # Phase 0 codebase & Gradle audit
├── data-model.md                                # Environment build profiles & GitHub Secrets matrix
├── quickstart.md                                # Local verification & keystore setup summary
├── contracts/
│   └── cicd_pipeline_contract.md                # Entrypoints, Gradle signing/flavors & workflow contracts
└── tasks.md                                     # Phase 2 output (/speckit-tasks — not created yet)
```

### Source Code & CI/CD Files (repository root)

```text
.github/
└── workflows/
    ├── ci-cd-dev.yml                            # DEV workflow (push develop + workflow_dispatch → analyze, test, .env.dev, release sign, APK dev, artifact, Firebase testers-dev)
    └── ci-cd-prod.yml                           # PROD workflow (push main + workflow_dispatch → analyze, test, .env.prod, release sign, APK prod, artifact, Firebase testers-prod)

android/
└── app/
    ├── build.gradle.kts                         # flavorDimensions + productFlavors (dev/prod) + signingConfigs.create("release") with local debug fallback
    └── src/main/
        └── AndroidManifest.xml                  # Dynamic android:label="${appName}"

lib/
├── main.dart                                    # Delegates to main_dev.dart for local default runs
├── main_dev.dart                                # DEV entrypoint (.env.dev + EnvironmentConfig.development())
└── main_prod.dart                               # PROD entrypoint (.env.prod + EnvironmentConfig.production())

test/
└── unit/
    └── domain/
        └── environment_entrypoints_config_test.dart  # Unit tests verifying DEV/PROD EnvironmentConfig isolation (banner, prefix, env)

.gitignore                                       # Add android/key.properties, *.jks, *.keystore
README.md                                        # Add CI/CD, Keystore generation, Base64 encoding, GitHub Secrets & Firebase App Distribution guide
```

**Structure Decision**: Standard Flutter multi-entrypoint + Android Gradle productFlavors + GitHub Actions workflow layout. Zero new runtime dependencies added.

---

## Complexity Tracking

> No Constitution violations. Table intentionally empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| *(none)* | — | — |
