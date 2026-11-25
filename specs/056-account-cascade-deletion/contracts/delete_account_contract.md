# Contract: Account Cascade Deletion (HU 24.3)

## 1. Supabase RPC Contract

- **Function**: `vifutboldev.delete_my_account() RETURNS void`
- **Security**: `SECURITY DEFINER`, `SET search_path = vifutboldev, public, auth, storage`
- **Grants**: `REVOKE ALL FROM PUBLIC, anon`; `GRANT EXECUTE TO authenticated, service_role`
- **Preconditions**:
  - `auth.uid()` MUST NOT be null (raises `42501` / `'Authentication required'` if null).
- **Postconditions**:
  - Executes all `UPDATE` (unlink PII on shared records) and `DELETE` (free-agent players, `user_accounts` with cascades, `storage.objects`, `auth.users`) atomically inside a single transaction.

## 2. Domain & Application Contracts

### `AuthRepository` (`lib/domain/repositories/auth_repository.dart`)
```dart
Future<void> deleteAccount({required String userId});
```
- **Offline (Cloud mode)**: Throws `OfflineConnectivityFailure` before any remote call or local deletion.
- **Remote error**: Throws translated Spanish `AppFailure` and MUST NOT clear local storage or session.
- **Success**: Deletes remote account first (when cloud-backed), then deletes local files and invokes `storage.clearNamespace()`.

### `DeleteAccountUseCase` (`lib/application/use_cases/delete_account_use_case.dart`)
```dart
Future<void> call({required UserAccount user});
```
- Rejects `user.isGuestFan == true` with `InvalidCredentialsFailure`.
- Delegates to `authRepository.deleteAccount(userId: user.id)`.

### `AuthController.deleteAccount()` (`lib/application/controllers/auth_controller.dart`)
```dart
Future<bool> deleteAccount();
```
- Returns `false` immediately if `state.session == null`, `state.session!.user.isGuestFan`, or `state.isSubmitting` (`single-flight`).
- Sets `isSubmitting: true, lastFailure: null`.
- On success: sets `status: AuthStatus.unauthenticated, session: null, isSubmitting: false, lastFailure: null` and returns `true`.
- On failure: sets `isSubmitting: false, lastFailure: failure` (keeping `status` and `session` intact) and returns `false`.

## 3. Presentation & UI Contract

- **Profile button**: `Key('profile_delete_account_button')` in `ProfileTabView`, rendered ONLY when `!isGuest && user != null`, placed below `Key('profile_logout_action_button')`, destructive icon (`Icons.delete_forever_outlined`) + Spanish label `Eliminar cuenta`, minimum height `>= 44 px`.
- **Confirmation dialog**: `DeleteAccountDialog` (`ValueKey('delete_account_dialog')`) with:
  - Spanish title, irreversible warning copy, `Cancelar` button (`ValueKey('delete_account_cancel_button')`), and destructive `Eliminar cuenta` button (`ValueKey('delete_account_confirm_button')`).
  - While deleting: buttons disabled, loading indicator shown, `PopScope(canPop: false)`, and repeated taps ignored (`single-flight`).
  - On failure: dialog closes and `ProfileTabView` displays a Spanish `SnackBar` with `lastFailure.message` while preserving the authenticated session.
