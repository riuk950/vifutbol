---

description: "Actionable, dependency-ordered task list for HU 23.1: Automated CI/CD Pipeline, Android Release Signing, and DEV/PROD App Distribution"
---

# Tasks: Automated CI/CD Pipeline, Android Release Signing, and DEV/PROD App Distribution

**Input**: Design documents from `/specs/053-cicd-android-firebase-distribution/`  
**Prerequisites**: [plan.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/053-cicd-android-firebase-distribution/plan.md), [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/053-cicd-android-firebase-distribution/spec.md), [research.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/053-cicd-android-firebase-distribution/research.md), [data-model.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/053-cicd-android-firebase-distribution/data-model.md), [cicd_pipeline_contract.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/053-cicd-android-firebase-distribution/contracts/cicd_pipeline_contract.md)

**Tests**: Included per Project Constitution Principle III (Automated Tests & Quality Gate).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story mapping (`[US1]`, `[US2]`, `[US3]`)
- Exact file paths included in every task description

---

## Phase 1: Foundational (Entrypoints, Android Flavors, Release Signing & Git Hygiene)

**Purpose**: Establish DEV/PROD entrypoints, Android `productFlavors` (`dev`/`prod`), release keystore signing with local debug fallback, and `.gitignore` secret protection required by both DEV and PROD CI/CD pipelines (FR-001, FR-004, FR-005).

**⚠️ CRITICAL**: Complete this phase before creating the GitHub Actions workflows.

- [X] T001 [P] Create DEV entrypoint loading `.env.dev` and `EnvironmentConfig.development()` in `lib/main_dev.dart`, create PROD entrypoint loading `.env.prod` and `EnvironmentConfig.production()` in `lib/main_prod.dart`, and delegate `lib/main.dart` to `main_dev.dart`
- [X] T002 [P] Configure `flavorDimensions += "environment"` with `dev` (`applicationIdSuffix = ".dev"`, `versionNameSuffix = "-dev"`, `manifestPlaceholders["appName"] = "vifutbol DEV"`) and `prod` (`manifestPlaceholders["appName"] = "vifutbol"`), plus `signingConfigs.create("release")` reading `android/key.properties` with safe fallback to `debug` when absent, in `android/app/build.gradle.kts`
- [X] T003 [P] Replace hardcoded `android:label="vifutbol"` with `android:label="${appName}"` in `android/app/src/main/AndroidManifest.xml`
- [X] T004 [P] Add `android/key.properties`, `*.jks`, and `*.keystore` exclusions to `.gitignore`

**Checkpoint**: DEV and PROD entrypoints, Android flavors, release signing, and secret hygiene are in place.

---

## Phase 2: User Story 1 - Automated DEV Build, Quality Gate, and Tester Distribution on `develop` (Priority: P1) 🎯 MVP

**Goal**: Automate static analysis, automated tests, `.env.dev` materialization from `ENV_DEV_FILE` (plus empty `.env.prod` placeholder), release keystore decoding, signed `dev` flavor APK build, artifact archival, and Firebase App Distribution to `testers-dev` on every push to `develop` or manual dispatch (FR-002, FR-003, FR-006, FR-008, FR-009).

**Independent Test**: Validate YAML syntax, confirm strict stage order (quality gate → secret validation → env/keystore materialization → build → release notes → artifact → Firebase distribution), and verify `flutter analyze` and unit tests pass.

### Implementation for User Story 1

- [X] T005 [US1] Create DEV CI/CD GitHub Actions workflow (`on: push [develop]` + `workflow_dispatch`, `concurrency` cancel-in-progress, Java 17 + Flutter stable, mandatory `flutter analyze` & `flutter test` quality gate, fail-fast secret validation without printing values, `.env.dev` from `ENV_DEV_FILE` + empty `.env.prod`, keystore Base64 decoding & `android/key.properties`, `flutter build apk --release --flavor dev -t lib/main_dev.dart`, safe `release-notes.txt`, `actions/upload-artifact@v4`, and `wzieba/Firebase-Distribution-Github-Action@v1` targeting `FIREBASE_APP_ID_DEV` & `testers-dev`) in `.github/workflows/ci-cd-dev.yml`

**Checkpoint**: DEV CI/CD workflow is ready for `develop`.

---

## Phase 3: User Story 2 - Automated PROD Build, Quality Gate, and Release Distribution on `main` (Priority: P1)

**Goal**: Automate the isolated PROD delivery pipeline on `main` (and manual dispatch) loading `.env.prod` from `ENV_PROD_FILE` (plus empty `.env.dev` placeholder), compiling the release-signed `prod` flavor APK (`lib/main_prod.dart`, DEV banner hidden), archiving the artifact, and distributing to `testers-prod` with commit release notes (FR-001, FR-002, FR-003, FR-007, FR-008, FR-009).

**Independent Test**: Validate YAML syntax, confirm strict PROD isolation (`ENV_PROD_FILE`, `--flavor prod`, `lib/main_prod.dart`, `FIREBASE_APP_ID_PROD`, `testers-prod`), and verify unit tests assert `EnvironmentConfig.production().showEnvironmentBanner == false`.

### Implementation for User Story 2

- [X] T006 [P] [US2] Create PROD CI/CD GitHub Actions workflow (`on: push [main]` + `workflow_dispatch`, `concurrency` cancel-in-progress, Java 17 + Flutter stable, mandatory `flutter analyze` & `flutter test` quality gate, fail-fast secret validation without printing values, `.env.prod` from `ENV_PROD_FILE` + empty `.env.dev`, keystore Base64 decoding & `android/key.properties`, `flutter build apk --release --flavor prod -t lib/main_prod.dart`, safe `release-notes.txt`, `actions/upload-artifact@v4`, and `wzieba/Firebase-Distribution-Github-Action@v1` targeting `FIREBASE_APP_ID_PROD` & `testers-prod`) in `.github/workflows/ci-cd-prod.yml`

### Tests for User Stories 1 & 2

- [X] T007 [P] [US2] Create unit tests verifying strict DEV vs PROD `EnvironmentConfig` isolation (`showEnvironmentBanner` true in DEV / false in PROD, distinct `localStoragePrefix` and `appName`) in `test/unit/domain/environment_entrypoints_config_test.dart`

**Checkpoint**: Both DEV and PROD pipelines and environment isolation contracts are implemented and tested.

---

## Phase 4: User Story 3 - Secure Release Signing, Zero-Secret Repository Hygiene, and Team Documentation (Priority: P1)

**Goal**: Document complete release keystore creation, Base64 encoding, Firebase App registration for both `com.vifutbol.vifutbol.dev` and `com.vifutbol.vifutbol`, tester groups, and all 9 GitHub Secrets in `README.md`, and verify zero-secret Git ignore rules (FR-005, FR-010, SC-003, SC-005).

**Independent Test**: Follow the `README.md` CI/CD section and run `git check-ignore -v .env.dev .env.prod android/key.properties android/app/upload-keystore.jks` to confirm every sensitive file is ignored.

### Implementation for User Story 3

- [X] T008 [US3] Document Android release keystore generation (`keytool`), Base64 conversion, local `android/key.properties` usage, Firebase App registration (`com.vifutbol.vifutbol.dev` & `com.vifutbol.vifutbol`), tester groups (`testers-dev`, `testers-prod`), and the full GitHub Secrets reference table (`ENV_DEV_FILE`, `ENV_PROD_FILE`, `ANDROID_KEYSTORE_*`, `FIREBASE_*`) in `README.md`

---

## Phase 5: Polish & Cross-Cutting Quality Gate

**Purpose**: Run static analysis, unit tests, YAML validation, and `.gitignore` verification before handoff.

- [X] T009 Verify `.gitignore` excludes `.env.dev`, `.env.prod`, `android/key.properties`, and `android/app/upload-keystore.jks` via `git check-ignore`, and validate `.github/workflows/ci-cd-dev.yml` and `.github/workflows/ci-cd-prod.yml` YAML syntax
- [X] T010 Run `flutter analyze` and `flutter test test/unit/domain/environment_entrypoints_config_test.dart` across the repository and verify 0 analyze issues and 100% test pass rate

---

## Dependencies & Execution Order

- **Phase 1 (`T001`–`T004`)**: All 4 tasks touch distinct files and run in parallel.
- **Phase 2 (`T005`)**, **Phase 3 (`T006`–`T007`)**, **Phase 4 (`T008`)**: All touch distinct files and can run in parallel after Phase 1.
- **Phase 5 (`T009`–`T010`)**: Final Quality Gate after all implementation tasks complete.
