# Feature Specification: Player Photo Capture, Profile Avatar, and Personal Data Summary Page

**Feature Branch**: `048-player-photo-profile-summary`  
**Created**: 2026-11-17  
**Status**: Draft  
**Input**: User description: "/speckit-specify de Notion HU 21.3 en curso" — `[Épica 21] HU 21.3: Captura de Foto del Jugador, Avatar en Perfil y Página Resumen de Datos Personales`

## Clarifications

### Session 2026-11-17

- Q: ¿La fotografía de perfil del jugador debe ser obligatoria para guardar el formulario de datos personales, o debe ser opcional al guardar pero necesaria para marcar el perfil como completo? → A: Opcional para guardar el formulario; obligatoria junto con los datos personales para pasar a "Perfil completo" (Option A).
- Q: ¿Cómo debe almacenarse y servirse la fotografía de perfil del jugador en la nube respecto a la privacidad y visibilidad dentro de la app? → A: Bucket dedicado (`player-avatars`) con escritura exclusiva del dueño y lectura directa para renderizar el avatar, separado de los documentos privados de identidad (Option A).
- Q: En la página resumen de Datos Personales, ¿cómo deben comportarse las vistas previas de ambos lados de la cédula al tocarlas? → A: Mostrar miniaturas en la tarjeta y permitir tocar cada una para abrirla en un visor ampliado con cierre (Option A).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Capture Player Profile Photograph in Personal Data Form (Priority: P1)

As a registered player (`player`), I want to capture or select my profile photograph directly within the personal data form and preview it in a circular ID-card style frame before saving, so that my digital player card displays my real portrait.

**Why this priority**: Capturing and persisting the player's portrait is the foundational data source required for the profile avatar and the personal data summary screen.

**Independent Test**: Can be fully tested by opening the player personal data form, selecting "Tomar Foto de Perfil" (from camera or gallery), verifying the circular preview renders immediately, saving the form, and confirming the photograph reference persists both locally and remotely.

**Acceptance Scenarios**:

1. **Given** the player is filling out or editing the personal data form, **When** the player taps the action to capture or select a profile photo ("Tomar Foto de Perfil"), **Then** the user can choose between taking a photo with the camera or selecting an image from the device gallery.
2. **Given** the player captures or selects a valid image, **When** returning to the form, **Then** a circular ID-card style preview immediately displays the selected photograph and allows replacing it if desired.
3. **Given** the player saves the form with a captured photograph while online or offline, **When** persistence completes, **Then** the photograph is saved locally immediately and linked to the player's account for synchronization with remote storage.
4. **Given** the player denies camera or gallery permission, **When** attempting to capture a photo, **Then** the system displays a clear, non-blocking message explaining the missing permission and keeps the rest of the form usable.

---

### User Story 2 - Reactive Avatar and Profile Completeness Action in Profile Tab (Priority: P1)

As a registered player, I want my real profile photograph to appear automatically in the identity card header of the Profile tab, and I want the profile action button to reflect whether I need to complete my data or view my "Datos Personales" summary, so that I always have quick access to my player record.

**Why this priority**: The Profile tab is the main entry point for the user's digital identity; showing the real avatar and distinguishing between incomplete registration vs. completed summary access delivers immediate daily value.

**Independent Test**: Can be tested independently by loading the Profile tab for a player with a saved photo and complete profile, verifying the avatar displays the image instead of the generic icon, the badge shows "Perfil completo", and tapping "Datos Personales" navigates to the summary page.

**Acceptance Scenarios**:

1. **Given** a player has saved their personal photograph and completed their required profile fields, **When** navigating to the Profile tab, **Then** the identity card avatar renders the player's real photograph instead of the generic placeholder icon, and the status badge shows "Perfil completo".
2. **Given** a player with an incomplete profile is on the Profile tab, **When** viewing the identity card, **Then** the status badge displays "Datos incompletos" and the primary action invites the user to "Completar Datos Personales" (opening the data entry form).
3. **Given** a player with a complete profile is on the Profile tab, **When** tapping the "Datos Personales" button, **Then** the user navigates directly to the dedicated Personal Data Summary screen.
4. **Given** the player's photo was saved offline or the remote image fails to load, **When** viewing the Profile tab, **Then** the avatar displays the local cached image if available or gracefully falls back to the default icon without crashing or blocking navigation.

---

### User Story 3 - Dedicated Personal Data Summary Page & Edit Flow (Priority: P2)

As a registered player, I want to consult a dedicated summary page ("Datos Personales") showing my portrait, full identity details, calculated age, demographic and geographic information, playing positions, and both sides of my ID card, with an option to edit my data, so that I can verify and maintain my registration record.

**Why this priority**: Once the data and photos are captured, players need a clean read-only summary view to inspect their digital dossier and jump into editing when updates are needed.

**Independent Test**: Can be tested independently by navigating to the Personal Data Summary screen with a complete player profile and verifying all four sections (header with calculated age, demographics, tactical positions as chips, and front/back ID card previews) plus the "Editar Datos" action.

**Acceptance Scenarios**:

1. **Given** a player navigates to the Personal Data Summary screen, **When** the screen renders, **Then** it displays:
   - Header with profile photo, full name, document number, and current age calculated from birth date.
   - Demographic section with Sex, Birth Date, Blood Type (RH), Department, and Municipality.
   - Tactical profile section displaying chips for the primary and all secondary football positions.
   - Documentation section showing visual previews for both the front and back sides of the national ID card (or clear empty indicators if a side has not been captured).
2. **Given** the player is viewing the Personal Data Summary screen, **When** the player taps "Editar Datos" in the top bar, **Then** the system opens the personal data edit form pre-populated with all current values and images.
3. **Given** the player updates any field or photo in the edit form and saves, **When** returning to the summary page, **Then** the summary view updates reactively to reflect the new information.

---

### Edge Cases

- **Offline photo capture & sync**: When the player captures and saves a profile photo (or ID card images) without internet connectivity, the images are stored locally on the device, immediately displayed in both the Profile tab avatar and the Personal Data Summary page, and queued for automatic upload to cloud storage once connectivity returns.
- **Corrupted or missing image file**: If a referenced local image path no longer exists on disk or a remote image URL fails to download, the UI gracefully displays a neutral fallback icon or placeholder without throwing unhandled exceptions.
- **Incomplete or missing optional fields on summary**: If optional fields (such as second name, second surname, secondary positions, or one side of the ID card) are absent, the summary screen omits empty values cleanly or shows a clear "No registrado" indicator rather than raw `null` text.
- **Background interruption during camera/gallery pick**: If the app goes to background while the system camera or gallery picker is open, returning to the app restores the captured image into the form state without losing previously entered form fields.
- **Rapid double-tap on actions**: Tapping "Tomar Foto de Perfil", "Datos Personales", or "Editar Datos" repeatedly in quick succession does not open duplicate pickers or push duplicate routes.
- **Large image selection**: High-resolution camera photos are resized/compressed appropriately before storage and display so memory usage remains stable and uploads stay within allowed storage limits.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The player personal data form MUST provide an action to capture or pick a profile photograph ("Tomar Foto de Perfil") supporting both device camera and gallery sources.
- **FR-002**: Upon selecting or capturing a profile photograph, the form MUST render a circular ID-card style preview and allow the user to replace the photo before saving.
- **FR-003**: Saving the player personal data form MUST allow saving even if no profile photograph has been captured yet, while persisting any captured photograph reference (`photo_url` / local synced path) locally immediately and enqueueing remote upload to a dedicated avatar storage space (isolated from private ID card documents, with owner-only write access and direct read access for avatar display) when offline, following offline-first synchronization rules.
- **FR-004**: The Profile tab identity card MUST reactively display the player's saved profile photograph inside the circular avatar (prioritizing the local file when pending sync, or loading the remote image URL when synced) instead of the generic icon.
- **FR-005**: In the Profile tab for the `player` role, the status badge MUST display "Perfil completo" only when both the required personal data and a valid profile photograph (remote URL or local synced path) are present, and "Datos incompletos" otherwise.
- **FR-006**: In the Profile tab for the `player` role, when the profile is incomplete the button MUST invite the user to "Completar Datos Personales" (opening the edit form); once complete, the "Datos Personales" button MUST navigate directly to the Personal Data Summary screen (`PlayerPersonalDataScreen`).
- **FR-007**: The Personal Data Summary screen MUST display a header containing the player's circular profile photo, full name, document ID, and current age calculated accurately in years from the recorded birth date.
- **FR-008**: The Personal Data Summary screen MUST display a demographic details section showing Sex, Birth Date, Blood Type (RH), Department, and Municipality.
- **FR-009**: The Personal Data Summary screen MUST display a tactical profile section listing all football positions (primary and secondary) as visual chips.
- **FR-010**: The Personal Data Summary screen MUST display a documentation section showing thumbnail previews of both sides (front and back) of the player's ID card, supporting both local and remote images with appropriate loading/empty fallbacks, and MUST allow tapping any captured side preview to open an enlarged interactive viewer with a close action.
- **FR-011**: The Personal Data Summary screen MUST provide an "Editar Datos" action in the top app bar that navigates to the personal data form in edit mode and refreshes the summary upon return.
- **FR-012**: All user-facing labels, buttons, empty states, and permission messages MUST be in Spanish and centralized via the localization system (`l10n`), while all technical identifiers remain in English.
- **FR-013**: All image containers, avatars, buttons, and document previews MUST respect system safe areas, dynamic text scaling, screen-reader accessibility labels, and prevent layout overflow across small and large mobile screens.

### Key Entities *(include if feature involves data)*

- **Player Profile**: Represents the registered player's personal record, extended with `photoUrl` (persisted remote path/URL and/or local pending image path) alongside existing personal fields (`firstName`, `secondName`, `firstSurname`, `secondSurname`, `documentId`, `sex`, `birthDate`, `bloodType`, `department`, `municipality`, `primaryPosition`, `secondaryPositions`, `documentFrontUrl`, `documentBackUrl`).
- **User Account / Active Session**: Holds the authenticated user's identity, active role, and profile completeness status, reflecting the player's `photoUrl` and personal record reactively across the Profile tab and summary views.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Players can capture or select a profile photograph and see the circular preview in the form in under 5 seconds after completing the camera/gallery selection.
- **SC-002**: 100% of saved player profile photographs appear immediately in the Profile tab avatar and the Personal Data Summary page regardless of whether the device is online or offline at the moment of saving.
- **SC-003**: The Personal Data Summary screen renders all four required sections (identity header with calculated age, demographics, tactical position chips, and dual-side ID card previews) with zero text truncation or layout overflow across standard mobile screen widths (320dp to 430dp).
- **SC-004**: Tapping "Datos Personales" from a completed player profile navigates to the summary screen in a single tap, and tapping "Editar Datos" opens the pre-filled form ready for modification.
- **SC-005**: Automated widget and unit tests cover the reactive avatar rendering, completeness badge/button transitions, age calculation, and all sections of the Personal Data Summary screen with 100% pass rate.

## Assumptions

- The personal data form and dual-side ID card capture built in HU 21.1 and HU 21.2 already exist and serve as the form where the profile photograph picker is integrated and to which "Editar Datos" navigates.
- Profile completeness for `player` requires the mandatory personal fields from HU 21.1 plus a valid profile photograph (`photoUrl` or local photo path), transitioning the Profile tab badge from "Datos incompletos" to "Perfil completo" and changing the action button from "Completar Datos Personales" to "Datos Personales".
- Offline-first image synchronization reuses the existing local pending upload/sync mechanism established in HU 17.4 / HU 21.2 so local photos are never lost if saved without network connectivity.
- All UI strings follow the project's Spanish `l10n` convention and visual tokens from `DESIGN.md`.
