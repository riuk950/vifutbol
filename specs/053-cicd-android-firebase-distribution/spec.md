# Feature Specification: Automated CI/CD Pipeline, Android Release Signing, and DEV/PROD App Distribution

**Feature Branch**: `053-cicd-android-firebase-distribution`

**Created**: 2026-11-20

**Status**: Draft

**Input**: User description: "de Notion HU 23.1 en curso — [Épica 23] HU 23.1: Pipeline CI/CD con GitHub Actions, Firmado Android y Distribución de APK en Firebase App Distribution (DEV / PROD)"

## Clarifications

### Session 2026-11-20

- Q: ¿Cómo prefieres estructurar los GitHub Secrets para generar dinámicamente `.env.dev` y `.env.prod` durante el build? → A: Option A — Un secreto multilínea por entorno (`ENV_DEV_FILE` para `develop` y `ENV_PROD_FILE` para `main`) escrito directamente al archivo `.env.dev` o `.env.prod` en tiempo de build.
- Q: ¿Los APK de DEV y PROD deben conservar el mismo `applicationId` de Android o configurar `productFlavors` con sufijo `.dev`? → A: Option B — Configurar Android `productFlavors` (`dev` con `applicationIdSuffix = ".dev"` y nombre visible diferenciado, `prod` sin sufijo) junto con entrypoints separados (`lib/main_dev.dart` y `lib/main_prod.dart`) para permitir instalación en paralelo en el mismo dispositivo.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Automated DEV Build, Quality Gate, and Tester Distribution on `develop` (Priority: P1)

As a developer or tech lead, I want every push or merge to the `develop` branch to automatically run static analysis and the automated test suite, assemble the development environment configuration from secure secrets, build a signed release Android package pointing to the DEV environment, and distribute it to the DEV tester group with commit traceability, so that QA and testers receive verified development builds automatically without manual packaging.

**Why this priority**: The `develop` branch is the primary integration trunk where daily features are verified; automating its quality gate and tester delivery immediately eliminates manual build errors and accelerates QA feedback.

**Independent Test**: Can be fully tested by pushing a commit to `develop` (or triggering the DEV workflow manually), verifying static analysis and automated tests run first, confirming the DEV environment configuration is injected securely without leaking secrets to logs, confirming a signed release APK is produced and archived as a downloadable build artifact, and confirming the DEV tester group receives the release with commit notes.

**Acceptance Scenarios**:

1. **Given** an automated DEV delivery pipeline is configured for the `develop` branch, **When** a developer pushes or merges a commit to `develop`, **Then** the pipeline first executes static code analysis and the automated test suite as a mandatory quality gate.
2. **Given** the quality gate passes on `develop`, **When** the build stage runs, **Then** the pipeline dynamically generates the development environment configuration from protected secrets, builds a release Android package targeting the DEV environment (showing the DEV environment indicator), signs it with the release certificate, uploads it as a build artifact, and publishes it to the DEV app distribution channel notifying the `testers-dev` group.
3. **Given** static analysis or any automated test fails on `develop`, **When** the quality gate completes, **Then** the pipeline halts immediately and neither compiles a release package nor distributes any build to testers.

---

### User Story 2 - Automated PROD Build, Quality Gate, and Release Distribution on `main` (Priority: P1)

As a tech lead releasing a production version, I want every push or merge to the `main` branch to enforce the same mandatory quality gate, inject strictly isolated production environment secrets, build a release-signed Android package pointing to the PROD environment (with the DEV banner hidden), and distribute it to the PROD distribution channel with release notes, so that production builds are repeatable, traceable, and completely isolated from development data.

**Why this priority**: Production releases must never accidentally ship development credentials, debug signing keys, or visual DEV indicators; strict branch-to-environment isolation prevents high-severity production incidents.

**Independent Test**: Can be fully tested by verifying the PROD entrypoint hides the DEV banner and loads production environment settings, and by running the PROD pipeline on `main` (or dry-run validation) to confirm it uses exclusively PROD secrets, signs with the release certificate, archives the artifact, and targets the PROD distribution channel (`testers-prod`).

**Acceptance Scenarios**:

1. **Given** an automated PROD delivery pipeline is configured for the `main` branch, **When** a release commit or merge is pushed to `main`, **Then** the pipeline runs static analysis and automated tests before proceeding to packaging.
2. **Given** the quality gate passes on `main`, **When** the build stage runs, **Then** the pipeline generates the production environment configuration exclusively from PROD secrets, builds a release-signed Android package using the production entrypoint (which hides the DEV banner), uploads the package as a downloadable artifact, and publishes it to the PROD app distribution channel with branch, short commit SHA, author, and commit message release notes notifying `testers-prod`.
3. **Given** a production package is installed on an Android device, **When** a user opens the application, **Then** no DEV environment banner is displayed and all backend connections target the production environment.

---

### User Story 3 - Secure Release Signing, Zero-Secret Repository Hygiene, and Team Documentation (Priority: P1)

As a security-conscious engineering team, I want Android release builds to be signed with an official release keystore reconstructed only at build time from protected secrets—while keeping all environment files, signing properties, and keystore binaries strictly excluded from version control—and documented step-by-step for onboarding, so that no credential or signing key is ever committed to Git or leaked in CI logs while local development remains smooth.

**Why this priority**: Exposing a release keystore or backend API keys in version control or CI logs compromises application integrity and user data; clear local fallback and onboarding documentation prevent developer friction.

**Independent Test**: Can be fully tested by inspecting repository ignore rules for `.env.dev`, `.env.prod`, signing properties, and keystore files, verifying a local debug/release build degrades safely when local signing properties are absent, verifying release signing activates automatically when signing properties are present, and following the setup guide to verify all required secret names and commands are documented.

**Acceptance Scenarios**:

1. **Given** signing properties and a release keystore are provided at build time (either in CI from encoded secrets or locally by a maintainer), **When** a release Android build runs, **Then** the resulting package is signed with the release signing configuration rather than debug keys.
2. **Given** a contributor builds the app locally without release keystore credentials, **When** running local development builds, **Then** the build configuration falls back safely without breaking local developer workflows.
3. **Given** environment files (`.env.dev`, `.env.prod`), signing properties (`key.properties`), and keystore files (`*.jks`, `*.keystore`) exist on a developer machine or CI runner, **When** checking repository status or CI build logs, **Then** none of these files are tracked by version control and no secret values are printed in pipeline logs.

---

### Edge Cases

- **Missing or Misconfigured CI Secrets**: If a required environment secret, signing secret, or distribution credential is missing in CI, the pipeline MUST fail fast with a clear, non-secret diagnostic message (naming the missing secret key, never printing secret values) before attempting to compile or publish.
- **Concurrent Pushes to the Same Branch**: Rapid consecutive pushes to `develop` or `main` should avoid wasting runner minutes or publishing out-of-order stale builds when superseded (or run cleanly with clear per-commit traceability).
- **Local Developer Without `.env.prod` or Release Keystore**: Running automated tests or local debug builds on a fresh clone without `.env.prod` or `android/key.properties` MUST succeed cleanly without failing the build script.
- **Empty or Multi-Line Commit Messages in Release Notes**: Release notes attached to distributed builds MUST safely handle quotes, special characters, or multi-line commit messages without breaking the distribution command.
- **Manual Workflow Dispatch**: Maintainers should be able to manually trigger the DEV or PROD pipeline on demand (e.g., to re-distribute a build after updating a tester group) without creating empty dummy commits.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide distinct application entrypoints (`lib/main_dev.dart` and `lib/main_prod.dart`) and Android `productFlavors` (`dev` with `.dev` application ID suffix and DEV label; `prod` with base application ID and production label) so DEV and PROD packages can be installed side-by-side on the same device, with DEV displaying the DEV visual indicator and PROD hiding it.
- **FR-002**: System MUST enforce a mandatory pre-build quality gate executing static code analysis and the automated test suite on every pipeline run; any failure MUST abort the pipeline before building or distributing any package.
- **FR-003**: System MUST dynamically materialize environment configuration files (`.env.dev` from secret `ENV_DEV_FILE` on `develop`, `.env.prod` from secret `ENV_PROD_FILE` on `main`) exclusively at build time from protected CI secrets, ensuring zero secret values are logged or committed.
- **FR-004**: System MUST configure Android release signing to read release keystore credentials from a non-versioned properties file reconstructed at CI build time from protected secrets, while retaining a safe fallback for local development when release credentials are not present.
- **FR-005**: System MUST strictly exclude `.env.dev`, `.env.prod`, `android/key.properties`, `*.jks`, and `*.keystore` from version control.
- **FR-006**: System MUST automatically trigger the DEV delivery pipeline on pushes/merges to `develop` (and allow manual dispatch) to build a release-signed DEV Android package, archive it as a downloadable CI artifact, and distribute it to the DEV app distribution channel (`testers-dev`).
- **FR-007**: System MUST automatically trigger the PROD delivery pipeline on pushes/merges to `main` (and allow manual dispatch) to build a release-signed PROD Android package, archive it as a downloadable CI artifact, and distribute it to the PROD app distribution channel (`testers-prod`).
- **FR-008**: System MUST attach structured release notes to every distributed build containing at minimum the target environment, branch name, short commit SHA, commit author, and commit message, safely escaped for shell/command execution.
- **FR-009**: System MUST validate that all required CI secrets are present before compiling or publishing, failing fast with an actionable message without exposing secret contents.
- **FR-010**: System MUST document the complete release signing and CI/CD setup in project documentation (`README.md`), including keystore generation, Base64 encoding, required CI secrets table (`ENV_DEV_FILE`, `ENV_PROD_FILE`, signing & Firebase secrets), registering both `<applicationId>.dev` and `<applicationId>` apps in Firebase App Distribution, and tester group setup.

### Key Entities

- **Environment Build Profile (DEV / PROD)**: The isolated configuration bundle pairing a Git branch (`develop` / `main`), application entrypoint, runtime environment variables, and target distribution app/tester group.
- **Release Signing Material**: The release certificate keystore and credentials file reconstructed ephemerally during CI packaging to produce officially signed Android packages.
- **Distributed Release Artifact**: The signed release Android package archived in CI and delivered to the corresponding tester group with traceable commit release notes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of pushes/merges to `develop` and `main` automatically execute static analysis and automated tests before any build artifact is compiled; 0 failed-test commits produce a distributed APK.
- **SC-002**: 100% of distributed DEV and PROD packages are signed with the release certificate (0 debug-signed packages published to distribution channels) and cleanly install on Android devices.
- **SC-003**: 0 secrets, `.env` files, `key.properties`, or `.jks`/`.keystore` files are tracked in Git or printed in CI execution logs.
- **SC-004**: 100% of PROD packages hide the DEV environment banner and connect exclusively to production settings, while 100% of DEV packages display the DEV banner and connect exclusively to development settings.
- **SC-005**: A maintainer following the documented setup steps can generate a release keystore, configure all required CI secrets, and complete an end-to-end automated DEV distribution in under 15 minutes.

## Assumptions

- **Existing App Infrastructure**: `EnvironmentConfig.development()` and `EnvironmentConfig.production()` already exist in the codebase, and `lib/main.dart` currently serves as the default local development entrypoint.
- **Firebase Project & Service Account**: The Firebase projects/apps for DEV and PROD and the service account JSON for Firebase App Distribution are provisioned outside the repository and stored exclusively as GitHub Secrets by the repository owner.
- **Android APK Focus**: This story delivers signed Android APK distribution via Firebase App Distribution; iOS IPA / App Store Connect and Google Play Store AAB publishing are out of scope for HU 23.1.
- **Tester Groups**: Tester groups `testers-dev` and `testers-prod` exist (or will be created) in Firebase App Distribution prior to the first live pipeline run.
