import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/providers/auth_providers.dart';
import '../../../application/providers/document_scanner_providers.dart';
import '../../../domain/entities/colombia_location_catalog.dart';
import '../../../domain/entities/colombian_id_scan_result.dart';
import '../../../domain/entities/player_personal_enums.dart';
import '../../../domain/entities/role_profile_data.dart';
import '../../../domain/entities/user_role.dart';
import '../../../domain/failures/app_failure.dart';
import '../../../domain/services/player_personal_data_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../design_system/kick_pulse_colors.dart';
import '../../design_system/kick_pulse_radii_spacing.dart';
import '../../design_system/kick_pulse_typography.dart';
import '../../design_system/widgets/kick_pulse_badge.dart';
import '../../design_system/widgets/kick_pulse_button.dart';
import '../../design_system/widgets/kick_pulse_card.dart';
import '../widgets/id_document_capture_card.dart';
import '../widgets/searchable_location_picker_sheet.dart';

/// Dedicated full-screen form for capturing and updating referee personal data,
/// Colombian ID (dual-side scan & photo capture), location, and referee
/// certification document.
class RefereePersonalDataScreen extends ConsumerStatefulWidget {
  const RefereePersonalDataScreen({
    super.key,
    this.avatarPickerOverride,
  });

  /// Optional test override for picking avatar images from camera or gallery.
  final Future<String?> Function(ImageSource source)? avatarPickerOverride;

  @override
  ConsumerState<RefereePersonalDataScreen> createState() =>
      RefereePersonalDataScreenState();
}

class RefereePersonalDataScreenState
    extends ConsumerState<RefereePersonalDataScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _documentController;
  late final TextEditingController _phoneController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _secondNameController;
  late final TextEditingController _firstSurnameController;
  late final TextEditingController _secondSurnameController;
  late final TextEditingController _certificationLevelController;

  PlayerSex? _selectedSex;
  DateTime? _selectedBirthDate;
  int? _calculatedAge;
  String? _selectedBloodType;
  String? _selectedDepartment;
  String? _selectedMunicipality;

  late PlayerDocumentCapture _documentCapture;
  String? _certDocLocalPath;
  String? _certDocRemoteUrl;
  String? _localAvatarPath;
  String? _remoteAvatarUrl;

  bool _isSaving = false;
  bool _isCapturing = false;
  bool _isScanning = false;
  bool _cameraPermissionDenied = false;
  bool _isDirty = false;
  String? _errorMessage;
  String? _avatarPermissionError;
  String? _documentImagesError;
  String? _certDocError;
  String? _scanFeedback;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).session?.user;
    final profile = user?.roleProfile;

    _documentController = TextEditingController(text: user?.documentId ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _firstNameController = TextEditingController(text: profile?.firstName ?? '');
    _secondNameController =
        TextEditingController(text: profile?.secondName ?? '');
    _firstSurnameController =
        TextEditingController(text: profile?.firstSurname ?? '');
    _secondSurnameController =
        TextEditingController(text: profile?.secondSurname ?? '');
    _certificationLevelController = TextEditingController(
      text: profile?.certificationLevel ?? '',
    );

    _selectedSex = PlayerSex.fromRaw(profile?.sex);
    _selectedBirthDate = profile?.birthDate;
    if (_selectedBirthDate != null) {
      _calculatedAge = PlayerPersonalDataUtils.calculateAge(_selectedBirthDate!);
    }
    _selectedBloodType = profile?.bloodType;
    _selectedDepartment = profile?.department;
    _selectedMunicipality = profile?.municipality;

    _documentCapture = PlayerDocumentCapture(
      frontRemoteUrl: profile?.documentFrontUrl,
      backRemoteUrl: profile?.documentBackUrl,
    );
    _certDocRemoteUrl = profile?.certificationDocumentUrl;
    if (_certDocRemoteUrl != null &&
        !_certDocRemoteUrl!.startsWith('http://') &&
        !_certDocRemoteUrl!.startsWith('https://')) {
      final f = File(_certDocRemoteUrl!);
      if (f.existsSync()) {
        _certDocLocalPath = _certDocRemoteUrl;
      }
    }

    _remoteAvatarUrl = user?.photoUrl;
    if (_remoteAvatarUrl != null &&
        !_remoteAvatarUrl!.startsWith('http://') &&
        !_remoteAvatarUrl!.startsWith('https://')) {
      final avatarFile = File(_remoteAvatarUrl!);
      if (avatarFile.existsSync()) {
        _localAvatarPath = _remoteAvatarUrl;
      }
    }
  }

  @override
  void dispose() {
    _documentController.dispose();
    _phoneController.dispose();
    _firstNameController.dispose();
    _secondNameController.dispose();
    _firstSurnameController.dispose();
    _secondSurnameController.dispose();
    _certificationLevelController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty || _isSaving) return true;
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KickPulseColors.surfaceElevated,
        title: Text(
          l10n.playerPersonalDataUnsavedChangesTitle,
          style: KickPulseTypography.cardTitle,
        ),
        content: Text(
          l10n.playerPersonalDataUnsavedChangesMessage,
          style: KickPulseTypography.bodyPrimary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.playerPersonalDataUnsavedChangesKeepEditing,
              style: const TextStyle(color: KickPulseColors.textSecondary),
            ),
          ),
          KickPulseButton(
            label: l10n.playerPersonalDataUnsavedChangesDiscard,
            variant: KickPulseButtonVariant.secondary,
            onPressed: () async => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _handleScanAll() async {
    if (_isCapturing || _isScanning || _isSaving) return;
    setState(() {
      _isCapturing = true;
      _cameraPermissionDenied = false;
      _scanFeedback = null;
      _documentImagesError = null;
    });

    final scanner = ref.read(colombianIdScannerServiceProvider);
    try {
      final frontPath = await scanner.captureDocumentPhoto(isFront: true);
      if (frontPath != null && mounted) {
        setState(() {
          _documentCapture =
              _documentCapture.copyWith(frontImagePath: frontPath);
          _isDirty = true;
        });
      }

      if (mounted) {
        final backPath = await scanner.captureDocumentPhoto(isFront: false);
        if (backPath != null && mounted) {
          setState(() {
            _documentCapture =
                _documentCapture.copyWith(backImagePath: backPath);
            _isDirty = true;
          });
        }
      }

      if (mounted) {
        await _runScan();
      }
    } on CameraPermissionDeniedFailure {
      if (mounted) {
        setState(() => _cameraPermissionDenied = true);
      }
    } catch (_) {
      // Ignore general capture errors
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _handleCaptureSide({required bool isFront}) async {
    if (_isCapturing || _isScanning || _isSaving) return;
    setState(() {
      _isCapturing = true;
      _cameraPermissionDenied = false;
      _scanFeedback = null;
      _documentImagesError = null;
    });

    final scanner = ref.read(colombianIdScannerServiceProvider);
    try {
      final path = await scanner.captureDocumentPhoto(isFront: isFront);
      if (path != null && mounted) {
        setState(() {
          _documentCapture = isFront
              ? _documentCapture.copyWith(frontImagePath: path)
              : _documentCapture.copyWith(backImagePath: path);
          _isDirty = true;
        });
        await _runScan();
      }
    } on CameraPermissionDeniedFailure {
      if (mounted) {
        setState(() => _cameraPermissionDenied = true);
      }
    } catch (_) {
      // Ignore
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _runScan() async {
    final front = _documentCapture.frontImagePath;
    final back = _documentCapture.backImagePath;
    if ((front == null || front.isEmpty) && (back == null || back.isEmpty)) {
      return;
    }

    setState(() => _isScanning = true);
    final scanner = ref.read(colombianIdScannerServiceProvider);
    final l10n = AppLocalizations.of(context);

    try {
      final scanResult = await scanner.scanDocumentImages(
        frontImagePath: front,
        backImagePath: back,
      );

      if (!mounted) return;

      if (scanResult.hasAnyField) {
        setState(() {
          if (scanResult.documentId != null) {
            _documentController.text = scanResult.documentId!;
          }
          if (scanResult.firstName != null) {
            _firstNameController.text = scanResult.firstName!;
          }
          if (scanResult.secondName != null) {
            _secondNameController.text = scanResult.secondName!;
          }
          if (scanResult.firstSurname != null) {
            _firstSurnameController.text = scanResult.firstSurname!;
          }
          if (scanResult.secondSurname != null) {
            _secondSurnameController.text = scanResult.secondSurname!;
          }
          if (scanResult.sex != null) _selectedSex = scanResult.sex;
          if (scanResult.birthDate != null) {
            _selectedBirthDate = scanResult.birthDate;
            _calculatedAge =
                PlayerPersonalDataUtils.calculateAge(scanResult.birthDate!);
          }
          if (scanResult.bloodType != null) {
            _selectedBloodType = scanResult.bloodType!.value;
          }
          _isDirty = true;

          final isFullRead = scanResult.documentId != null &&
              scanResult.firstName != null &&
              scanResult.firstSurname != null &&
              scanResult.birthDate != null &&
              scanResult.sex != null &&
              scanResult.bloodType != null;
          _scanFeedback = isFullRead
              ? l10n.playerDocumentScanSuccessFeedback
              : l10n.playerDocumentScanPartialFeedback;
        });
      } else {
        setState(() {
          _scanFeedback = l10n.playerDocumentScanEmptyFeedback;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _scanFeedback = l10n.playerDocumentScanEmptyFeedback;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _handleOpenSettings() async {
    final scanner = ref.read(colombianIdScannerServiceProvider);
    await scanner.openCameraSettings();
  }

  void _showCertificationSourceSheet() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: KickPulseColors.surfaceBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(KickPulseRadiiSpacing.cardRadius),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.refereeCertificationDocTitle,
                style: KickPulseTypography.sectionHeader,
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              ListTile(
                key: const Key('referee_cert_source_camera'),
                leading: const Icon(
                  Icons.camera_alt,
                  color: KickPulseColors.accentPrimary,
                ),
                title: Text(
                  l10n.playerProfilePhotoCameraOption,
                  style: KickPulseTypography.bodyPrimary,
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickCertificationImage(ImageSource.camera);
                },
              ),
              ListTile(
                key: const Key('referee_cert_source_gallery'),
                leading: const Icon(
                  Icons.photo_library,
                  color: KickPulseColors.accentElectric,
                ),
                title: Text(
                  l10n.playerProfilePhotoGalleryOption,
                  style: KickPulseTypography.bodyPrimary,
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickCertificationImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCertificationImage(ImageSource source) async {
    if (_isCapturing || _isSaving) return;
    setState(() => _isCapturing = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() {
          _certDocLocalPath = picked.path;
          _certDocError = null;
          _isDirty = true;
        });
      }
    } on PlatformException {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.playerProfilePhotoPermissionDenied),
            backgroundColor: KickPulseColors.accentWarning,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.playerDocumentUploadError),
            backgroundColor: KickPulseColors.accentLive,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _pickBirthDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = _selectedBirthDate ?? DateTime(now.year - 25, 1, 1);
    final firstDate = DateTime(1920, 1, 1);
    final lastDate = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate)
          ? lastDate
          : (initialDate.isBefore(firstDate) ? firstDate : initialDate),
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('es'),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedBirthDate = picked;
        _calculatedAge = PlayerPersonalDataUtils.calculateAge(picked);
        _isDirty = true;
      });
    }
  }

  Future<void> _pickDepartment(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final selected = await SearchableLocationPickerSheet.show(
      context,
      title: l10n.locationPickerSelectDepartmentTitle,
      items: ColombiaLocationCatalog.departments,
      selectedItem: _selectedDepartment,
      searchPlaceholder: l10n.locationPickerSearchPlaceholder,
      emptyMessage: l10n.locationPickerEmptyState,
    );

    if (selected != null && selected != _selectedDepartment && mounted) {
      setState(() {
        _selectedDepartment = selected;
        _selectedMunicipality = null;
        _isDirty = true;
      });
    }
  }

  Future<void> _pickMunicipality(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    if (_selectedDepartment == null || _selectedDepartment!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.playerPersonalDataSelectDepartmentFirst),
          backgroundColor: KickPulseColors.accentLive,
        ),
      );
      return;
    }

    final municipalities =
        ColombiaLocationCatalog.municipalitiesFor(_selectedDepartment!);
    final selected = await SearchableLocationPickerSheet.show(
      context,
      title: l10n.locationPickerSelectMunicipalityTitle,
      items: municipalities,
      selectedItem: _selectedMunicipality,
      searchPlaceholder: l10n.locationPickerSearchPlaceholder,
      emptyMessage: l10n.locationPickerEmptyState,
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedMunicipality = selected;
        _isDirty = true;
      });
    }
  }

  bool get _hasCertificationDocument =>
      (_certDocLocalPath != null && _certDocLocalPath!.trim().isNotEmpty) ||
      (_certDocRemoteUrl != null && _certDocRemoteUrl!.trim().isNotEmpty);

  Future<void> _handleSave() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context);
    final hasIdImages = _documentCapture.isComplete;
    final hasCertDoc = _hasCertificationDocument;

    setState(() {
      _errorMessage = null;
      _documentImagesError =
          hasIdImages ? null : l10n.playerDocumentImagesRequiredError;
      _certDocError =
          hasCertDoc ? null : l10n.refereeCertificationDocRequiredError;
    });

    final formValid = _formKey.currentState?.validate() ?? false;
    final validCustomFields = _selectedSex != null &&
        _selectedBirthDate != null &&
        _selectedBloodType != null &&
        _selectedDepartment != null &&
        _selectedMunicipality != null;

    if (!formValid || !validCustomFields || !hasIdImages || !hasCertDoc) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(authControllerProvider).session?.user;
      final userId = user?.id ?? '';

      final storageRepo = ref.read(documentStorageRepositoryProvider);
      final uploadResult = await storageRepo.uploadPlayerIdDocuments(
        userId: userId,
        frontLocalPath: _documentCapture.frontImagePath,
        backLocalPath: _documentCapture.backImagePath,
        existingFrontUrl: _documentCapture.frontRemoteUrl,
        existingBackUrl: _documentCapture.backRemoteUrl,
      );

      final certDocUrl = _certDocLocalPath != null &&
              _certDocLocalPath!.trim().isNotEmpty
          ? await storageRepo.uploadRefereeCertificationDocument(
              userId: userId,
              localPath: _certDocLocalPath!,
              existingDocumentUrl: _certDocRemoteUrl,
            )
          : (_certDocRemoteUrl ?? '');

      final resolvedPhotoUrl = _localAvatarPath != null &&
              _localAvatarPath!.trim().isNotEmpty
          ? await storageRepo.uploadPlayerAvatar(
              userId: userId,
              localPath: _localAvatarPath!,
              existingPhotoUrl: _remoteAvatarUrl,
            )
          : _remoteAvatarUrl;

      final harmonizedFullName = PlayerPersonalDataUtils.composeFullName(
        firstName: _firstNameController.text,
        secondName: _secondNameController.text,
        firstSurname: _firstSurnameController.text,
        secondSurname: _secondSurnameController.text,
      );

      final existingProfile = user?.roleProfile ?? const RoleProfileData();
      final roleProfilePayload = existingProfile.copyWith(
        firstName: _firstNameController.text.trim(),
        secondName: _secondNameController.text.trim().isEmpty
            ? null
            : _secondNameController.text.trim(),
        firstSurname: _firstSurnameController.text.trim(),
        secondSurname: _secondSurnameController.text.trim().isEmpty
            ? null
            : _secondSurnameController.text.trim(),
        sex: _selectedSex?.value,
        birthDate: _selectedBirthDate,
        bloodType: _selectedBloodType,
        department: _selectedDepartment,
        municipality: _selectedMunicipality,
        certificationLevel: _certificationLevelController.text.trim(),
        documentFrontUrl: uploadResult.frontUrl,
        documentBackUrl: uploadResult.backUrl,
        certificationDocumentUrl: certDocUrl,
        photoUrl: resolvedPhotoUrl,
      );

      final success = await ref
          .read(authControllerProvider.notifier)
          .updateRoleProfile(
            role: UserRole.referee,
            fullName: harmonizedFullName,
            phone: _phoneController.text.trim(),
            documentId: _documentController.text.trim(),
            roleProfile: roleProfilePayload,
          );

      if (!mounted) return;
      if (success) {
        _isDirty = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.playerPersonalDataSaveSuccess),
            backgroundColor: KickPulseColors.accentPrimary,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        final failure = ref.read(authControllerProvider).lastFailure;
        String message = l10n.playerPersonalDataErrorBanner;
        if (failure is DocumentAlreadyLinkedFailure) {
          message = l10n.playerPersonalDataDocumentAlreadyLinked;
        } else if (failure is OfflineAuthOperationFailure) {
          message = l10n.playerPersonalDataOfflineError;
        }
        setState(() {
          _isSaving = false;
          _errorMessage = message;
        });
      }
    } catch (error) {
      if (!mounted) return;
      String message = l10n.playerPersonalDataErrorBanner;
      if (error is OfflineAuthOperationFailure) {
        message = l10n.playerPersonalDataOfflineError;
      } else if (error is DocumentUploadFailure) {
        message = l10n.playerDocumentUploadError;
      }
      setState(() {
        _isSaving = false;
        _errorMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: !_isDirty || _isSaving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: KickPulseColors.canvasBackground,
        appBar: AppBar(
          title: Text(
            l10n.refereePersonalDataTitle,
            style: KickPulseTypography.screenTitle,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              key: const Key('referee_personal_data_screen'),
              padding: const EdgeInsets.symmetric(
                horizontal: KickPulseRadiiSpacing.spaceMd,
                vertical: KickPulseRadiiSpacing.spaceSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      key: const Key('referee_personal_data_error_banner'),
                      padding: const EdgeInsets.all(
                        KickPulseRadiiSpacing.spaceMd,
                      ),
                      decoration: BoxDecoration(
                        color: KickPulseColors.accentLive.withAlpha(25),
                        border: Border.all(
                          color: KickPulseColors.accentLive.withAlpha(120),
                        ),
                        borderRadius: BorderRadius.circular(
                          KickPulseRadiiSpacing.cardRadius,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: KickPulseColors.accentLive,
                          ),
                          const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: KickPulseTypography.bodyPrimary.copyWith(
                                color: KickPulseColors.accentLive,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                  ],

                  // 0. Referee Profile Avatar Section
                  _buildAvatarCard(context, l10n),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

                  // 1. Colombian ID Dual Scan & Both Sides Capture
                  IdDocumentCaptureCard(
                    capture: _documentCapture,
                    isScanning: _isScanning,
                    isCapturing: _isCapturing,
                    permissionDenied: _cameraPermissionDenied,
                    validationError: _documentImagesError,
                    scanFeedback: _scanFeedback,
                    onScanAll: _handleScanAll,
                    onCaptureFront: () => _handleCaptureSide(isFront: true),
                    onCaptureBack: () => _handleCaptureSide(isFront: false),
                    onOpenSettings: _handleOpenSettings,
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

                  // 2. Identification & Contact
                  KickPulseCard(
                    child: Column(
                      children: [
                        TextFormField(
                          key: const Key('referee_document_field'),
                          controller: _documentController,
                          onChanged: (_) => _markDirty(),
                          style: KickPulseTypography.bodyPrimary,
                          decoration: InputDecoration(
                            labelText: l10n.playerPersonalDataDocumentLabel,
                            hintText: l10n.playerPersonalDataDocumentHint,
                            prefixIcon: const Icon(Icons.badge_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return l10n.playerPersonalDataDocumentRequired;
                            }
                            if (v.trim().length < 5) {
                              return l10n.playerPersonalDataDocumentInvalid;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                        TextFormField(
                          key: const Key('referee_phone_field'),
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          onChanged: (_) => _markDirty(),
                          style: KickPulseTypography.bodyPrimary,
                          decoration: InputDecoration(
                            labelText: l10n.playerPersonalDataPhoneLabel,
                            hintText: l10n.playerPersonalDataPhoneHint,
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return l10n.playerPersonalDataPhoneRequired;
                            }
                            final digitsOnly =
                                v.replaceAll(RegExp(r'\D'), '');
                            if (digitsOnly.length < 7) {
                              return l10n.playerPersonalDataPhoneInvalid;
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

                  // 3. Names & Surnames
                  KickPulseCard(
                    child: Column(
                      children: [
                        TextFormField(
                          key: const Key('referee_first_name_field'),
                          controller: _firstNameController,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) => _markDirty(),
                          style: KickPulseTypography.bodyPrimary,
                          decoration: InputDecoration(
                            labelText: l10n.playerPersonalDataFirstNameLabel,
                            hintText: l10n.playerPersonalDataFirstNameHint,
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.playerPersonalDataFirstNameRequired
                              : null,
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                        TextFormField(
                          key: const Key('referee_second_name_field'),
                          controller: _secondNameController,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) => _markDirty(),
                          style: KickPulseTypography.bodyPrimary,
                          decoration: InputDecoration(
                            labelText: l10n.playerPersonalDataSecondNameLabel,
                            hintText: l10n.playerPersonalDataSecondNameHint,
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                        TextFormField(
                          key: const Key('referee_first_surname_field'),
                          controller: _firstSurnameController,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) => _markDirty(),
                          style: KickPulseTypography.bodyPrimary,
                          decoration: InputDecoration(
                            labelText: l10n.playerPersonalDataFirstSurnameLabel,
                            hintText: l10n.playerPersonalDataFirstSurnameHint,
                            prefixIcon: const Icon(Icons.badge_outlined),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.playerPersonalDataFirstSurnameRequired
                              : null,
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                        TextFormField(
                          key: const Key('referee_second_surname_field'),
                          controller: _secondSurnameController,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) => _markDirty(),
                          style: KickPulseTypography.bodyPrimary,
                          decoration: InputDecoration(
                            labelText:
                                l10n.playerPersonalDataSecondSurnameLabel,
                            hintText: l10n.playerPersonalDataSecondSurnameHint,
                            prefixIcon: const Icon(Icons.badge_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

                  // 4. Demographic & Medical Info
                  KickPulseCard(
                    child: Column(
                      children: [
                        DropdownButtonFormField<PlayerSex>(
                          key: const Key('referee_sex_field'),
                          initialValue: _selectedSex,
                          style: KickPulseTypography.bodyPrimary,
                          dropdownColor: KickPulseColors.surfaceElevated,
                          decoration: InputDecoration(
                            labelText: l10n.playerPersonalDataSexLabel,
                            prefixIcon: const Icon(Icons.wc_outlined),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: PlayerSex.male,
                              child: Text(l10n.playerPersonalDataSexMale),
                            ),
                            DropdownMenuItem(
                              value: PlayerSex.female,
                              child: Text(l10n.playerPersonalDataSexFemale),
                            ),
                            DropdownMenuItem(
                              value: PlayerSex.other,
                              child: Text(l10n.playerPersonalDataSexOther),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedSex = val;
                              _isDirty = true;
                            });
                          },
                          validator: (val) => val == null
                              ? l10n.playerPersonalDataSexRequired
                              : null,
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: InkWell(
                                key: const Key('referee_birth_date_field'),
                                onTap: () => _pickBirthDate(context),
                                borderRadius: BorderRadius.circular(
                                  KickPulseRadiiSpacing.chipRadius,
                                ),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText:
                                        l10n.playerPersonalDataBirthDateLabel,
                                    prefixIcon: const Icon(
                                      Icons.calendar_today_outlined,
                                    ),
                                    errorText: _selectedBirthDate == null &&
                                            _isDirty
                                        ? l10n
                                            .playerPersonalDataBirthDateRequired
                                        : null,
                                  ),
                                  child: Text(
                                    _selectedBirthDate != null
                                        ? '${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}'
                                        : l10n.playerPersonalDataBirthDateHint,
                                    style: KickPulseTypography.bodyPrimary
                                        .copyWith(
                                      color: _selectedBirthDate != null
                                          ? KickPulseColors.textPrimary
                                          : KickPulseColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: KickPulseRadiiSpacing.spaceSm,
                            ),
                            Expanded(
                              flex: 2,
                              child: InputDecorator(
                                key: const Key('referee_age_field'),
                                decoration: InputDecoration(
                                  labelText: l10n.playerPersonalDataAgeLabel,
                                  filled: true,
                                ),
                                child: Text(
                                  _calculatedAge != null
                                      ? l10n.playerPersonalDataAgeYears(
                                          _calculatedAge!,
                                        )
                                      : '--',
                                  style: KickPulseTypography.bodyPrimary
                                      .copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: KickPulseColors.accentWarning,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                        DropdownButtonFormField<String>(
                          key: const Key('referee_blood_type_field'),
                          initialValue: _selectedBloodType,
                          style: KickPulseTypography.bodyPrimary,
                          dropdownColor: KickPulseColors.surfaceElevated,
                          decoration: InputDecoration(
                            labelText: l10n.playerPersonalDataBloodTypeLabel,
                            hintText: l10n.playerPersonalDataBloodTypeHint,
                            prefixIcon: const Icon(Icons.bloodtype_outlined),
                          ),
                          items: BloodType.allValues
                              .map(
                                (bt) => DropdownMenuItem(
                                  value: bt,
                                  child: Text(bt),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (val) {
                            setState(() {
                              _selectedBloodType = val;
                              _isDirty = true;
                            });
                          },
                          validator: (val) => val == null || val.isEmpty
                              ? l10n.playerPersonalDataBloodTypeRequired
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

                  // 5. Colombia Location
                  KickPulseCard(
                    child: Column(
                      children: [
                        InkWell(
                          key: const Key('referee_department_field'),
                          onTap: () => _pickDepartment(context),
                          borderRadius: BorderRadius.circular(
                            KickPulseRadiiSpacing.chipRadius,
                          ),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.playerPersonalDataDepartmentLabel,
                              prefixIcon: const Icon(Icons.map_outlined),
                              suffixIcon: const Icon(
                                Icons.arrow_drop_down_outlined,
                              ),
                              errorText: _selectedDepartment == null && _isDirty
                                  ? l10n.playerPersonalDataDepartmentRequired
                                  : null,
                            ),
                            child: Text(
                              _selectedDepartment ??
                                  l10n.playerPersonalDataDepartmentHint,
                              style: KickPulseTypography.bodyPrimary.copyWith(
                                color: _selectedDepartment != null
                                    ? KickPulseColors.textPrimary
                                    : KickPulseColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                        InkWell(
                          key: const Key('referee_municipality_field'),
                          onTap: () => _pickMunicipality(context),
                          borderRadius: BorderRadius.circular(
                            KickPulseRadiiSpacing.chipRadius,
                          ),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText:
                                  l10n.playerPersonalDataMunicipalityLabel,
                              prefixIcon: const Icon(
                                Icons.location_city_outlined,
                              ),
                              suffixIcon: const Icon(
                                Icons.arrow_drop_down_outlined,
                              ),
                              errorText: _selectedMunicipality == null &&
                                      _isDirty
                                  ? l10n.playerPersonalDataMunicipalityRequired
                                  : null,
                            ),
                            child: Text(
                              _selectedMunicipality ??
                                  l10n.playerPersonalDataMunicipalityHint,
                              style: KickPulseTypography.bodyPrimary.copyWith(
                                color: _selectedMunicipality != null
                                    ? KickPulseColors.textPrimary
                                    : KickPulseColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

                  // 6. Referee Certification Section
                  Text(
                    l10n.refereeCertificationSectionTitle,
                    style: KickPulseTypography.sectionHeader,
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                  KickPulseCard(
                    key: const Key('referee_certification_capture_card'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          key: const Key('referee_certification_level_field'),
                          controller: _certificationLevelController,
                          onChanged: (_) => _markDirty(),
                          style: KickPulseTypography.bodyPrimary,
                          decoration: InputDecoration(
                            labelText: l10n.refereeCertificationLevelLabel,
                            hintText: l10n.refereeCertificationLevelHint,
                            prefixIcon: const Icon(
                              Icons.workspace_premium_outlined,
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.refereeCertificationLevelRequiredError
                              : null,
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.refereeCertificationDocTitle,
                                style: KickPulseTypography.cardTitle,
                              ),
                            ),
                            if (_hasCertificationDocument)
                              KickPulseBadge(
                                label: l10n.refereeCertificationCapturedBadge,
                                variant: KickPulseBadgeVariant.success,
                              ),
                          ],
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                        Text(
                          l10n.refereeCertificationDocSubtitle,
                          style: const TextStyle(
                            color: KickPulseColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                        _buildCertificationPreview(),
                        if (_certDocError != null) ...[
                          const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                          Text(
                            _certDocError!,
                            style: const TextStyle(
                              color: KickPulseColors.accentLive,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                        KickPulseButton(
                          key: const Key('referee_certification_capture_button'),
                          label: _hasCertificationDocument
                              ? l10n.refereeCertificationReplaceButton
                              : l10n.refereeCertificationCaptureButton,
                          variant: KickPulseButtonVariant.outline,
                          isFullWidth: true,
                          icon: const Icon(
                            Icons.verified_outlined,
                            color: KickPulseColors.accentPrimary,
                            size: 20,
                          ),
                          onPressed: _isCapturing || _isSaving
                              ? null
                              : () async => _showCertificationSourceSheet(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceXl),

                  // 7. Save CTA
                  KickPulseButton(
                    key: const Key('referee_save_profile_button'),
                    label: l10n.playerPersonalDataSaveButton,
                    variant: KickPulseButtonVariant.primary,
                    isFullWidth: true,
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _handleSave,
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceLg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCertificationPreview() {
    if (_certDocLocalPath != null && _certDocLocalPath!.isNotEmpty) {
      final file = File(_certDocLocalPath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
          child: Image.file(
            file,
            key: const ValueKey('referee_certification_local_preview'),
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    if (_certDocRemoteUrl != null && _certDocRemoteUrl!.isNotEmpty) {
      return FutureBuilder<String?>(
        future: ref.read(documentStorageRepositoryProvider).getSignedDocumentUrl(
              storagePath: _certDocRemoteUrl!,
            ),
        builder: (context, snapshot) {
          final signedUrl = snapshot.data;
          if (signedUrl == null || signedUrl.isEmpty) {
            return Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: KickPulseColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(
                  KickPulseRadiiSpacing.cardRadius,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.verified_user_outlined,
                  color: KickPulseColors.accentPrimary,
                  size: 36,
                ),
              ),
            );
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(
              KickPulseRadiiSpacing.cardRadius,
            ),
            child: Image.network(
              signedUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(
                height: 120,
                child: Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _handlePickAvatar(ImageSource source) async {
    if (_isCapturing || _isSaving) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _avatarPermissionError = null;
      _errorMessage = null;
    });

    try {
      String? pickedPath;
      if (widget.avatarPickerOverride != null) {
        pickedPath = await widget.avatarPickerOverride!(source);
      } else {
        final picker = ImagePicker();
        final file = await picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        pickedPath = file?.path;
      }

      if (!mounted || pickedPath == null || pickedPath.trim().isEmpty) {
        return;
      }

      setState(() {
        _localAvatarPath = pickedPath;
        _isDirty = true;
      });
    } on CameraPermissionDeniedFailure {
      if (!mounted) return;
      setState(() {
        _avatarPermissionError = l10n.refereeAvatarPermissionDeniedError;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'photo_access_denied') {
          _avatarPermissionError =
              l10n.refereeAvatarGalleryPermissionDeniedError;
        } else if (e.code == 'camera_access_denied') {
          _avatarPermissionError = l10n.refereeAvatarPermissionDeniedError;
        } else {
          _errorMessage = l10n.refereeAvatarLoadError;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = l10n.refereeAvatarLoadError;
      });
    }
  }

  Widget _buildAvatarCard(BuildContext context, AppLocalizations l10n) {
    ImageProvider? avatarProvider;
    if (_localAvatarPath != null && _localAvatarPath!.trim().isNotEmpty) {
      final localFile = File(_localAvatarPath!);
      if (localFile.existsSync()) {
        avatarProvider = FileImage(localFile);
      }
    } else if (_remoteAvatarUrl != null &&
        (_remoteAvatarUrl!.startsWith('http://') ||
            _remoteAvatarUrl!.startsWith('https://'))) {
      avatarProvider = NetworkImage(_remoteAvatarUrl!);
    }

    return KickPulseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Semantics(
                label: l10n.refereeAvatarSectionTitle,
                image: true,
                child: CircleAvatar(
                  key: const ValueKey('referee_form_profile_avatar'),
                  radius: 36,
                  backgroundColor: KickPulseColors.surfaceSubtle,
                  backgroundImage: avatarProvider,
                  onBackgroundImageError:
                      avatarProvider != null ? (_, _) {} : null,
                  child: avatarProvider == null
                      ? const Icon(
                          Icons.person_outline,
                          color: KickPulseColors.accentPrimary,
                          size: 36,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.refereeAvatarSectionTitle,
                      style: KickPulseTypography.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.refereeAvatarSectionSubtitle,
                      style: const TextStyle(
                        color: KickPulseColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_avatarPermissionError != null) ...[
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
            Container(
              key: const ValueKey('referee_avatar_permission_banner'),
              padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
              decoration: BoxDecoration(
                color: KickPulseColors.accentWarning.withAlpha(25),
                borderRadius:
                    BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
                border: Border.all(
                  color: KickPulseColors.accentWarning.withAlpha(120),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: KickPulseColors.accentWarning,
                    size: 20,
                  ),
                  const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                  Expanded(
                    child: Text(
                      _avatarPermissionError!,
                      style: const TextStyle(
                        color: KickPulseColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _handleOpenSettings,
                    child: Text(l10n.playerDocumentCameraPermissionOpenSettings),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          Wrap(
            spacing: KickPulseRadiiSpacing.spaceSm,
            runSpacing: KickPulseRadiiSpacing.spaceSm,
            children: [
              Semantics(
                button: true,
                label: l10n.refereeAvatarCameraButton,
                child: OutlinedButton.icon(
                  key: const ValueKey('referee_avatar_camera_button'),
                  onPressed: _isSaving
                      ? null
                      : () => _handlePickAvatar(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: Text(l10n.refereeAvatarCameraButton),
                ),
              ),
              Semantics(
                button: true,
                label: l10n.refereeAvatarGalleryButton,
                child: OutlinedButton.icon(
                  key: const ValueKey('referee_avatar_gallery_button'),
                  onPressed: _isSaving
                      ? null
                      : () => _handlePickAvatar(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: Text(l10n.refereeAvatarGalleryButton),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
