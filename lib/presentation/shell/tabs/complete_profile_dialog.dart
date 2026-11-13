import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/auth_providers.dart';
import '../../../domain/entities/role_profile_data.dart';
import '../../../domain/entities/user_account.dart';
import '../../../domain/entities/user_role.dart';
import '../../../domain/failures/app_failure.dart';
import '../../../l10n/app_localizations.dart';
import '../../design_system/kick_pulse_colors.dart';
import '../../design_system/kick_pulse_radii_spacing.dart';
import '../../design_system/kick_pulse_typography.dart';
import '../../design_system/widgets/kick_pulse_button.dart';

/// Adaptive modal form for completing missing personal and role-specific
/// profile data for the authenticated user's active role.
class CompleteProfileDialog extends ConsumerStatefulWidget {
  final UserAccount user;

  const CompleteProfileDialog({super.key, required this.user});

  static Future<bool?> show(
    BuildContext context, {
    required UserAccount user,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompleteProfileDialog(user: user),
    );
  }

  @override
  ConsumerState<CompleteProfileDialog> createState() =>
      _CompleteProfileDialogState();
}

class _CompleteProfileDialogState extends ConsumerState<CompleteProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;
  late final TextEditingController _documentController;
  late final TextEditingController _clubController;
  late final TextEditingController _licenseController;
  late final TextEditingController _organizationController;
  late final TextEditingController _baseCityController;
  late final TextEditingController _cityController;
  late final TextEditingController _preferencesController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final profile = widget.user.roleProfile;
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _documentController =
        TextEditingController(text: widget.user.documentId ?? '');
    _clubController = TextEditingController(text: profile?.clubName ?? '');
    _licenseController =
        TextEditingController(text: profile?.licenseLevel ?? '');
    _organizationController =
        TextEditingController(text: profile?.organizationName ?? '');
    _baseCityController = TextEditingController(text: profile?.baseCity ?? '');
    _cityController = TextEditingController(text: profile?.city ?? '');
    _preferencesController =
        TextEditingController(text: profile?.preferences ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _documentController.dispose();
    _clubController.dispose();
    _licenseController.dispose();
    _organizationController.dispose();
    _baseCityController.dispose();
    _cityController.dispose();
    _preferencesController.dispose();
    super.dispose();
  }

  bool get _requiresDocument => widget.user.activeRole != UserRole.fan;

  Future<void> _submit() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final role = widget.user.activeRole;
    final roleProfile = RoleProfileData(
      clubName: role == UserRole.coach ? _clubController.text.trim() : null,
      licenseLevel:
          role == UserRole.coach ? _licenseController.text.trim() : null,
      organizationName: role == UserRole.organizer
          ? _organizationController.text.trim()
          : null,
      baseCity:
          role == UserRole.organizer ? _baseCityController.text.trim() : null,
      city: role == UserRole.fan ? _cityController.text.trim() : null,
      preferences: role == UserRole.fan &&
              _preferencesController.text.trim().isNotEmpty
          ? _preferencesController.text.trim()
          : null,
    );

    final ok = await ref.read(authControllerProvider.notifier).updateRoleProfile(
          role: role,
          phone: _phoneController.text.trim(),
          documentId:
              _requiresDocument ? _documentController.text.trim() : null,
          roleProfile: roleProfile,
        );

    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    if (ok) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.completeProfileSuccessMessage),
          backgroundColor: KickPulseColors.accentPrimary,
        ),
      );
      return;
    }

    final failure = ref.read(authControllerProvider).lastFailure;
    final resolvedError = switch (failure) {
      DocumentAlreadyLinkedFailure() => l10n.completeProfileDocumentConflictError,
      OfflineAuthOperationFailure() => failure.message,
      _ => failure?.message ?? l10n.completeProfileOfflineError,
    };

    setState(() {
      _isSaving = false;
      _errorMessage = resolvedError;
    });
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: KickPulseColors.textSecondary),
      filled: true,
      fillColor: KickPulseColors.surfaceSubtle,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.chipRadius),
        borderSide: const BorderSide(color: KickPulseColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.chipRadius),
        borderSide: const BorderSide(color: KickPulseColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.chipRadius),
        borderSide: const BorderSide(color: KickPulseColors.accentPrimary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final role = widget.user.activeRole;

    return AlertDialog(
      backgroundColor: KickPulseColors.surfaceBase,
      title: Text(
        l10n.completeProfileDialogTitle,
        style: KickPulseTypography.cardTitle,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
                  decoration: BoxDecoration(
                    color: KickPulseColors.accentLive.withAlpha(30),
                    borderRadius:
                        BorderRadius.circular(KickPulseRadiiSpacing.chipRadius),
                    border: Border.all(color: KickPulseColors.accentLive),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: KickPulseColors.accentLive,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              ],
              TextFormField(
                key: const ValueKey('complete_profile_phone_field'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: KickPulseColors.textPrimary),
                decoration: _inputDecoration(l10n.completeProfilePhoneLabel),
                validator: (value) {
                  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 7) {
                    return l10n.completeProfileInvalidPhoneError;
                  }
                  return null;
                },
              ),
              if (_requiresDocument) ...[
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                TextFormField(
                  key: const ValueKey('complete_profile_document_field'),
                  controller: _documentController,
                  style: const TextStyle(color: KickPulseColors.textPrimary),
                  decoration:
                      _inputDecoration(l10n.completeProfileDocumentLabel),
                  validator: (value) {
                    final trimmed = (value ?? '').trim();
                    if (trimmed.length < 5) {
                      return l10n.completeProfileInvalidDocumentError;
                    }
                    return null;
                  },
                ),
              ],
              if (role == UserRole.coach) ...[
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                TextFormField(
                  key: const ValueKey('complete_profile_club_field'),
                  controller: _clubController,
                  style: const TextStyle(color: KickPulseColors.textPrimary),
                  decoration: _inputDecoration(l10n.completeProfileClubLabel),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.completeProfileRequiredFieldError
                      : null,
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                TextFormField(
                  key: const ValueKey('complete_profile_license_field'),
                  controller: _licenseController,
                  style: const TextStyle(color: KickPulseColors.textPrimary),
                  decoration:
                      _inputDecoration(l10n.completeProfileLicenseLabel),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.completeProfileRequiredFieldError
                      : null,
                ),
              ],
              if (role == UserRole.organizer) ...[
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                TextFormField(
                  key: const ValueKey('complete_profile_organization_field'),
                  controller: _organizationController,
                  style: const TextStyle(color: KickPulseColors.textPrimary),
                  decoration:
                      _inputDecoration(l10n.completeProfileOrganizationLabel),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.completeProfileRequiredFieldError
                      : null,
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                TextFormField(
                  key: const ValueKey('complete_profile_base_city_field'),
                  controller: _baseCityController,
                  style: const TextStyle(color: KickPulseColors.textPrimary),
                  decoration:
                      _inputDecoration(l10n.completeProfileBaseCityLabel),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.completeProfileRequiredFieldError
                      : null,
                ),
              ],
              if (role == UserRole.fan) ...[
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                TextFormField(
                  key: const ValueKey('complete_profile_city_field'),
                  controller: _cityController,
                  style: const TextStyle(color: KickPulseColors.textPrimary),
                  decoration: _inputDecoration(l10n.completeProfileCityLabel),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.completeProfileRequiredFieldError
                      : null,
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                TextFormField(
                  key: const ValueKey('complete_profile_preferences_field'),
                  controller: _preferencesController,
                  style: const TextStyle(color: KickPulseColors.textPrimary),
                  decoration:
                      _inputDecoration(l10n.completeProfilePreferencesLabel),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: Text(
            l10n.actionCancel,
            style: const TextStyle(color: KickPulseColors.textSecondary),
          ),
        ),
        KickPulseButton(
          key: const ValueKey('complete_profile_save_button'),
          label: l10n.completeProfileSaveAction,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _submit,
        ),
      ],
    );
  }
}
