# UI & Interaction Contract: Profile Active Role Display (HU 24.1)

**Component**: `ProfileTabView` (`lib/presentation/shell/tabs/profile_tab_view.dart`)  
**Spec**: [spec.md](../spec.md)

## Visual & Structural Contract

1. **Identity Card (Retained — Read-Only)**:
   - Displays user avatar, display name, email (or visitor subtitle), completeness badge (when authenticated non-guest), and **active role badge** (`KickPulseBadge` with key `ValueKey('profile_active_role_badge')`).
   - The active role badge is strictly non-interactive (no `onTap`, no `InkWell`, no `GestureDetector` triggering role changes).
   - Wrapped with read-only accessibility semantics (`Semantics(readOnly: true, ...)`).
   - Displays localized Spanish role name for all 5 roles (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`).

2. **Role Switcher Section (Removed)**:
   - Must NOT render the section title `Cambiar rol activo` (`l10n.profileSwitchRole`).
   - Must NOT render any `ChoiceChip` widgets for role selection.
   - Must NOT render environment-specific helper strings (`Entorno DEV activo: ...` or `Roles autorizados en tu cuenta:`).
   - Applies identically in `AppEnvironment.development` and `AppEnvironment.production`.

3. **Preserved Profile Sections (No Regression)**:
   - Incomplete profile banner & CTA button (for authenticated non-guest users with incomplete profile).
   - Guest banner (for guest fan sessions).
   - Player personal data navigation tile (when applicable).
   - Role permissions & capabilities card (reflecting `activeRole`).
   - Logout confirmation flow (including pending sync guard when applicable).

## Behavioral & Zero-Mutation Contract

- `AuthController.switchActiveRole` MUST NEVER be invoked from `ProfileTabView`.
- `AuthRepository.switchActiveRole` MUST record 0 calls during any interaction with `ProfileTabView`, including repeated taps on `profile_active_role_badge`.
- No local persistence writes or cloud sync operations may be triggered by tapping role elements in `ProfileTabView`.
