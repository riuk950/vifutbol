# UI & Navigation Contract: Profile Legal, Support & Remove Ads Section (HU 24.2)

**Components**:
- `ProfileTabView` (`lib/presentation/shell/tabs/profile_tab_view.dart`)
- `ProfileLegalSupportSection` (`lib/presentation/shell/tabs/widgets/profile_legal_support_section.dart`)
- `ProfileLegalDocumentScreen` (`lib/presentation/shell/tabs/profile_legal_document_screen.dart`)
- `ProfileFaqScreen` (`lib/presentation/shell/tabs/profile_faq_screen.dart`)
- `RemoveAdsDialog` (`lib/presentation/shell/tabs/widgets/remove_ads_dialog.dart`)

## Placement & Order Contract

In `ProfileTabView`, immediately below the RBAC capabilities card (`l10n.profileCapabilitiesTitle`) and above the logout/login button (`KickPulseButton`):

| Position | Key | Localized Label (es) | Destination |
|---|---|---|---|
| 1 | `Key('profile_remove_ads_tile')` | `Quitar anuncios` | `RemoveAdsDialog` (modal dialog, "Próximamente") |
| 2 | `Key('profile_terms_tile')` | `Términos y condiciones` | `ProfileLegalDocumentScreen(type: ProfileLegalDocumentType.terms)` |
| 3 | `Key('profile_privacy_policy_tile')` | `Políticas de tratamiento de datos` | `ProfileLegalDocumentScreen(type: ProfileLegalDocumentType.privacyPolicy)` |
| 4 | `Key('profile_faq_tile')` | `Preguntas frecuentes` | `ProfileFaqScreen` |

## Routes Registered in `AppRouter`

- `/profile/terms` → `ProfileLegalDocumentScreen(type: ProfileLegalDocumentType.terms)`
- `/profile/privacy-policy` → `ProfileLegalDocumentScreen(type: ProfileLegalDocumentType.privacyPolicy)`
- `/profile/faq` → `ProfileFaqScreen()`

## Interaction & Accessibility Contract

- **Visibility**: Rendered identically for all 5 roles (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`) and guest fan, in both `dev` and `prod`.
- **Touch target**: Each tile enforces `minHeight >= 48.0` (exceeding the 44 px minimum).
- **Double-tap guard**: Rapid consecutive taps on any of the 4 tiles open at most 1 dialog or screen instance; subsequent taps are ignored until the opened destination completes/closes.
- **Offline behavior**: Zero network calls; all copy and documents are served locally via `AppLocalizations`.
- **Back navigation**: System back button, `AppBar` back arrow, or dialog close button returns cleanly to `ProfileTabView`.
