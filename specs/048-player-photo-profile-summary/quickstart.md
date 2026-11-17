# Quickstart Validation Guide: Player Photo Capture, Profile Avatar & Personal Data Summary

**Feature**: `048-player-photo-profile-summary`  
**Date**: 2026-11-17

## Prerequisites

- Flutter SDK & Dart toolchain installed (`flutter test`, `flutter analyze`).
- Migration `202611170004_player_profile_avatar.sql` applied on the target `vifutboldev` Supabase database.
- Regenerated localization files (`flutter gen-l10n`) after adding new Spanish/English `l10n` keys.

## Automated Validation Commands

1. **Static Analysis**:
   ```bash
   flutter analyze
   ```
   Expected: `No issues found!`

2. **Unit & Widget Tests for HU 21.3**:
   ```bash
   flutter test test/domain/entities/user_account_test.dart \
     test/presentation/shell/tabs/profile_tab_view_test.dart \
     test/presentation/shell/tabs/player_personal_data_screen_test.dart \
     test/presentation/shell/tabs/player_personal_data_summary_screen_test.dart
   ```
   Expected: 100% passing tests covering:
   - Optional photo save vs completeness badge rule (`isProfileCompleteForActiveRole`).
   - Reactive avatar rendering (local file, remote URL, fallback icon on error).
   - Navigation from Profile tab *"Datos Personales"* to summary screen when complete, and *"Completar Datos Personales"* to form when incomplete.
   - Summary screen rendering all 4 sections (header + calculated age, demographics, tactical chips, dual-side ID thumbnails + enlarged viewer) and *"Editar Datos"* action.

3. **Full Test Suite**:
   ```bash
   flutter test
   ```
   Expected: All tests pass with zero regressions.

## Manual End-to-End Verification (Device / Simulator)

1. Sign in as a `player` account with incomplete profile.
2. Open Profile tab → verify *"Datos incompletos"* badge and *"Completar Datos Personales"* button.
3. Tap *"Completar Datos Personales"*, fill fields, tap *"Tomar Foto de Perfil"*, capture/select a photo, verify circular preview, and tap Save.
4. Return to Profile tab → verify real photo appears in the circular avatar and badge switches to *"Perfil completo"*.
5. Tap *"Datos Personales"* → verify `PlayerPersonalDataSummaryScreen` displays photo, full name, document ID, calculated age, demographic fields, position chips, and front/back ID thumbnails.
6. Tap a thumbnail → verify enlarged viewer opens and closes cleanly.
7. Tap *"Editar Datos"* in AppBar → modify a field or photo, save, and verify summary screen updates reactively.
8. Repeat step 3 in Airplane Mode → verify photo persists locally and displays immediately offline, then reconnect and verify background upload completes.
