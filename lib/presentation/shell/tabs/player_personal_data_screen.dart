import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../application/providers/auth_providers.dart';
import '../../../application/providers/document_scanner_providers.dart';
import '../../../domain/entities/colombia_location_catalog.dart';
import '../../../domain/entities/colombian_id_scan_result.dart';
import '../../../domain/entities/detailed_football_position.dart';
import '../../../domain/entities/player_personal_enums.dart';
import '../../../domain/entities/role_profile_data.dart';
import '../../../domain/entities/team_enums.dart';
import '../../../domain/entities/user_role.dart';
import '../../../domain/failures/app_failure.dart';
import '../../../domain/services/player_personal_data_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../design_system/kick_pulse_colors.dart';
import '../../design_system/kick_pulse_radii_spacing.dart';
import '../../design_system/kick_pulse_typography.dart';
import '../../design_system/widgets/kick_pulse_button.dart';
import '../widgets/id_document_capture_card.dart';
import '../widgets/searchable_location_picker_sheet.dart';

/// Dedicated full-screen form for capturing and updating player personal data,
/// Colombian location, and multiple tactical football positions.
class PlayerPersonalDataScreen extends ConsumerStatefulWidget {
  const PlayerPersonalDataScreen({super.key});

  @override
  ConsumerState<PlayerPersonalDataScreen> createState() =>
      PlayerPersonalDataScreenState();
}

class PlayerPersonalDataScreenState
    extends ConsumerState<PlayerPersonalDataScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _documentController;
  late final TextEditingController _phoneController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _secondNameController;
  late final TextEditingController _firstSurnameController;
  late final TextEditingController _secondSurnameController;

  PlayerSex? _selectedSex;
  DateTime? _selectedBirthDate;
  int? _calculatedAge;
  String? _selectedBloodType;
  String? _selectedDepartment;
  String? _selectedMunicipality;
  final Set<String> _selectedPositions = {};

  bool _isSaving = false;
  String? _errorMessage;
  bool _showPositionsError = false;
  bool _isDirty = false;

  // HU 21.2 Colombian ID Dual Scan & Capture State
  late PlayerDocumentCapture _documentCapture;
  bool _isCapturing = false;
  bool _isScanning = false;
  bool _cameraPermissionDenied = false;
  String? _documentImagesError;
  String? _scanFeedback;

  // HU 21.3 Player Profile Photo / Avatar State
  String? _photoLocalPath;
  String? _photoRemoteUrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).session?.user;

    _documentController = TextEditingController(text: user?.documentId ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');

    final profile = user?.roleProfile;
    _photoRemoteUrl = profile?.photoUrl;
    if (_photoRemoteUrl != null &&
        !_photoRemoteUrl!.startsWith('http://') &&
        !_photoRemoteUrl!.startsWith('https://')) {
      _photoLocalPath = _photoRemoteUrl;
    }
    _documentCapture = PlayerDocumentCapture(
      frontRemoteUrl: profile?.documentFrontUrl,
      backRemoteUrl: profile?.documentBackUrl,
    );
    _firstNameController = TextEditingController(text: profile?.firstName ?? '');
    _secondNameController =
        TextEditingController(text: profile?.secondName ?? '');
    _firstSurnameController =
        TextEditingController(text: profile?.firstSurname ?? '');
    _secondSurnameController =
        TextEditingController(text: profile?.secondSurname ?? '');

    _selectedSex = PlayerSex.fromRaw(profile?.sex);
    _selectedBirthDate = profile?.birthDate;
    if (_selectedBirthDate != null) {
      _calculatedAge =
          PlayerPersonalDataUtils.calculateAge(_selectedBirthDate!);
    }
    _selectedBloodType = profile?.bloodType;
    _selectedDepartment = profile?.department;
    _selectedMunicipality = profile?.municipality;

    if (profile?.secondaryPositions.isNotEmpty == true) {
      _selectedPositions.addAll(profile!.secondaryPositions);
    }

    _documentController.addListener(_markDirty);
    _phoneController.addListener(_markDirty);
    _firstNameController.addListener(_markDirty);
    _secondNameController.addListener(_markDirty);
    _firstSurnameController.addListener(_markDirty);
    _secondSurnameController.addListener(_markDirty);
  }

  @override
  void dispose() {
    _documentController.dispose();
    _phoneController.dispose();
    _firstNameController.dispose();
    _secondNameController.dispose();
    _firstSurnameController.dispose();
    _secondSurnameController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  /// Hook for future automated document scanner extensions (e.g. HU 21.2 barcode scan).
  void applyDocumentScanData({
    String? documentId,
    String? firstName,
    String? secondName,
    String? firstSurname,
    String? secondSurname,
    PlayerSex? sex,
    DateTime? birthDate,
    BloodType? bloodType,
  }) {
    setState(() {
      if (documentId != null) _documentController.text = documentId;
      if (firstName != null) _firstNameController.text = firstName;
      if (secondName != null) _secondNameController.text = secondName;
      if (firstSurname != null) _firstSurnameController.text = firstSurname;
      if (secondSurname != null) _secondSurnameController.text = secondSurname;
      if (sex != null) _selectedSex = sex;
      if (birthDate != null) {
        _selectedBirthDate = birthDate;
        _calculatedAge = PlayerPersonalDataUtils.calculateAge(birthDate);
      }
      if (bloodType != null) _selectedBloodType = bloodType.value;
      _isDirty = true;
    });
  }

  Future<void> _handleScanAll() async {
    if (_isCapturing || _isScanning) return;
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

  Future<void> _handleCaptureFront() async {
    if (_isCapturing || _isScanning) return;
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

  Future<void> _handleCaptureBack() async {
    if (_isCapturing || _isScanning) return;
    setState(() {
      _isCapturing = true;
      _cameraPermissionDenied = false;
      _scanFeedback = null;
      _documentImagesError = null;
    });

    final scanner = ref.read(colombianIdScannerServiceProvider);
    try {
      final backPath = await scanner.captureDocumentPhoto(isFront: false);
      if (backPath != null && mounted) {
        setState(() {
          _documentCapture =
              _documentCapture.copyWith(backImagePath: backPath);
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
        applyDocumentScanData(
          documentId: scanResult.documentId,
          firstName: scanResult.firstName,
          secondName: scanResult.secondName,
          firstSurname: scanResult.firstSurname,
          secondSurname: scanResult.secondSurname,
          sex: scanResult.sex,
          birthDate: scanResult.birthDate,
          bloodType: scanResult.bloodType,
        );

        final isFullRead = scanResult.documentId != null &&
            scanResult.firstName != null &&
            scanResult.firstSurname != null &&
            scanResult.birthDate != null &&
            scanResult.sex != null &&
            scanResult.bloodType != null;

        setState(() {
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

  Future<void> _pickBirthDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = _selectedBirthDate ?? DateTime(now.year - 18, 1, 1);
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

    if (picked != null) {
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

    if (selected != null && selected != _selectedDepartment) {
      setState(() {
        _selectedDepartment = selected;
        // Cascade rule: clear municipality when department changes
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

    if (selected != null) {
      setState(() {
        _selectedMunicipality = selected;
        _isDirty = true;
      });
    }
  }

  void _showPhotoSourceBottomSheet() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: KickPulseColors.surfaceBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(KickPulseRadiiSpacing.cardRadius),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.playerProfilePhotoSectionTitle,
                  style: KickPulseTypography.sectionHeader,
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                ListTile(
                  key: const Key('player_photo_source_camera'),
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
                    _handlePickProfilePhoto(ImageSource.camera);
                  },
                ),
                ListTile(
                  key: const Key('player_photo_source_gallery'),
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
                    _handlePickProfilePhoto(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handlePickProfilePhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() {
          _photoLocalPath = picked.path;
          _isDirty = true;
        });
      }
    } on PlatformException catch (_) {
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
            content: Text(l10n.playerProfilePhotoUploadError),
            backgroundColor: KickPulseColors.accentLive,
          ),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty || _isSaving) return true;

    final l10n = AppLocalizations.of(context);
    final shouldDiscard = await showDialog<bool>(
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

    return shouldDiscard ?? false;
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context);
    final hasImages = _documentCapture.isComplete;
    setState(() {
      _errorMessage = null;
      _showPositionsError = _selectedPositions.isEmpty;
      _documentImagesError =
          hasImages ? null : l10n.playerDocumentImagesRequiredError;
    });

    final formValid = _formKey.currentState?.validate() ?? false;
    final validCustomFields = _selectedSex != null &&
        _selectedBirthDate != null &&
        _selectedBloodType != null &&
        _selectedDepartment != null &&
        _selectedMunicipality != null &&
        _selectedPositions.isNotEmpty;

    if (!formValid || !validCustomFields || !hasImages) {
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

      String? resolvedPhotoUrl = _photoRemoteUrl;
      if (_photoLocalPath != null && _photoLocalPath!.isNotEmpty) {
        try {
          final uploadedAvatarUrl = await storageRepo.uploadPlayerAvatar(
            userId: userId,
            localPath: _photoLocalPath!,
            existingPhotoUrl: _photoRemoteUrl,
          );
          resolvedPhotoUrl = uploadedAvatarUrl;
        } on OfflineAuthOperationFailure {
          resolvedPhotoUrl = _photoLocalPath;
        } catch (_) {
          resolvedPhotoUrl = _photoLocalPath;
        }
      }

      final positionsList = _selectedPositions
          .map((code) => DetailedFootballPosition.fromCode(code))
          .whereType<DetailedFootballPosition>()
          .toList(growable: false);

      final primaryTacticalLine =
          PlayerPersonalDataUtils.derivePrimaryPosition(positionsList);

      final harmonizedFullName = PlayerPersonalDataUtils.composeFullName(
        firstName: _firstNameController.text,
        secondName: _secondNameController.text,
        firstSurname: _firstSurnameController.text,
        secondSurname: _secondSurnameController.text,
      );

      final roleProfilePayload = RoleProfileData(
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
        primaryPosition: primaryTacticalLine,
        secondaryPositions: _selectedPositions.toList()..sort(),
        documentFrontUrl: uploadResult.frontUrl,
        documentBackUrl: uploadResult.backUrl,
        photoUrl: resolvedPhotoUrl,
      );

      final success = await ref
          .read(authControllerProvider.notifier)
          .updateRoleProfile(
            role: UserRole.player,
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
            l10n.playerPersonalDataTitle,
            style: KickPulseTypography.screenTitle,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              key: const Key('player_personal_data_screen'),
              padding: const EdgeInsets.symmetric(
                horizontal: KickPulseRadiiSpacing.spaceMd,
                vertical: KickPulseRadiiSpacing.spaceSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.playerPersonalDataSubtitle,
                    style: KickPulseTypography.bodyPrimary.copyWith(
                      color: KickPulseColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

                  // Error Banner
                  if (_errorMessage != null) ...[
                    Container(
                      key: const Key('player_personal_data_error_banner'),
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

                  // Profile Photo Avatar Section
                  _buildProfilePhotoSection(l10n),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

                  // Section 1: Identification & Contact
                  _buildSectionCard(
                    title: 'Identificación y Contacto',
                    children: [
                      IdDocumentCaptureCard(
                        capture: _documentCapture,
                        isScanning: _isScanning,
                        isCapturing: _isCapturing,
                        permissionDenied: _cameraPermissionDenied,
                        validationError: _documentImagesError,
                        scanFeedback: _scanFeedback,
                        onScanAll: _handleScanAll,
                        onCaptureFront: _handleCaptureFront,
                        onCaptureBack: _handleCaptureBack,
                        onOpenSettings: _handleOpenSettings,
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                      TextFormField(
                        key: const Key('player_form_document_field'),
                        controller: _documentController,
                        keyboardType: TextInputType.text,
                        style: KickPulseTypography.bodyPrimary,
                        decoration: InputDecoration(
                          labelText: l10n.playerPersonalDataDocumentLabel,
                          hintText: l10n.playerPersonalDataDocumentHint,
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.playerPersonalDataDocumentRequired;
                          }
                          if (value.trim().length < 5) {
                            return l10n.playerPersonalDataDocumentInvalid;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                      TextFormField(
                        key: const Key('player_form_phone_field'),
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: KickPulseTypography.bodyPrimary,
                        decoration: InputDecoration(
                          labelText: l10n.playerPersonalDataPhoneLabel,
                          hintText: l10n.playerPersonalDataPhoneHint,
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.playerPersonalDataPhoneRequired;
                          }
                          final digitsOnly =
                              value.replaceAll(RegExp(r'\D'), '');
                          if (digitsOnly.length < 7) {
                            return l10n.playerPersonalDataPhoneInvalid;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

                  // Section 2: Names and Surnames
                  _buildSectionCard(
                    title: 'Nombres y Apellidos',
                    children: [
                      TextFormField(
                        key: const Key('player_form_first_name_field'),
                        controller: _firstNameController,
                        textCapitalization: TextCapitalization.words,
                        style: KickPulseTypography.bodyPrimary,
                        decoration: InputDecoration(
                          labelText: l10n.playerPersonalDataFirstNameLabel,
                          hintText: l10n.playerPersonalDataFirstNameHint,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.playerPersonalDataFirstNameRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                      TextFormField(
                        key: const Key('player_form_second_name_field'),
                        controller: _secondNameController,
                        textCapitalization: TextCapitalization.words,
                        style: KickPulseTypography.bodyPrimary,
                        decoration: InputDecoration(
                          labelText: l10n.playerPersonalDataSecondNameLabel,
                          hintText: l10n.playerPersonalDataSecondNameHint,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                      TextFormField(
                        key: const Key('player_form_first_surname_field'),
                        controller: _firstSurnameController,
                        textCapitalization: TextCapitalization.words,
                        style: KickPulseTypography.bodyPrimary,
                        decoration: InputDecoration(
                          labelText: l10n.playerPersonalDataFirstSurnameLabel,
                          hintText: l10n.playerPersonalDataFirstSurnameHint,
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.playerPersonalDataFirstSurnameRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                      TextFormField(
                        key: const Key('player_form_second_surname_field'),
                        controller: _secondSurnameController,
                        textCapitalization: TextCapitalization.words,
                        style: KickPulseTypography.bodyPrimary,
                        decoration: InputDecoration(
                          labelText: l10n.playerPersonalDataSecondSurnameLabel,
                          hintText: l10n.playerPersonalDataSecondSurnameHint,
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

                  // Section 3: Demographic and Medical Info
                  _buildSectionCard(
                    title: 'Datos Demográficos y Médicos',
                    children: [
                      // Sex Selector
                      DropdownButtonFormField<PlayerSex>(
                        key: const Key('player_form_sex_selector'),
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

                      // Birth Date Picker & Read-only Age
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: InkWell(
                              key: const Key('player_form_birth_date_field'),
                              onTap: () => _pickBirthDate(context),
                              borderRadius: BorderRadius.circular(
                                KickPulseRadiiSpacing.chipRadius,
                              ),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText:
                                      l10n.playerPersonalDataBirthDateLabel,
                                  prefixIcon:
                                      const Icon(Icons.calendar_today_outlined),
                                  errorText: _selectedBirthDate == null &&
                                          _isDirty
                                      ? l10n.playerPersonalDataBirthDateRequired
                                      : null,
                                ),
                                child: Text(
                                  _selectedBirthDate != null
                                      ? '${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}'
                                      : l10n.playerPersonalDataBirthDateHint,
                                  style: KickPulseTypography.bodyPrimary.copyWith(
                                    color: _selectedBirthDate != null
                                        ? KickPulseColors.textPrimary
                                        : KickPulseColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                          Expanded(
                            flex: 2,
                            child: InputDecorator(
                              key: const Key('player_form_age_field'),
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
                                style: KickPulseTypography.bodyPrimary.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: KickPulseColors.accentWarning,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

                      // Blood Type Selector
                      DropdownButtonFormField<String>(
                        key: const Key('player_form_blood_type_selector'),
                        initialValue: _selectedBloodType,
                        style: KickPulseTypography.bodyPrimary,
                        dropdownColor: KickPulseColors.surfaceElevated,
                        decoration: InputDecoration(
                          labelText: l10n.playerPersonalDataBloodTypeLabel,
                          hintText: l10n.playerPersonalDataBloodTypeHint,
                          prefixIcon: const Icon(Icons.bloodtype_outlined),
                        ),
                        items: BloodType.allValues
                            .map((bt) => DropdownMenuItem(
                                  value: bt,
                                  child: Text(bt),
                                ))
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
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

                  // Section 4: Colombian Geographic Location (Cascading)
                  _buildSectionCard(
                    title: 'Ubicación en Colombia',
                    children: [
                      InkWell(
                        key: const Key('player_form_department_selector'),
                        onTap: () => _pickDepartment(context),
                        borderRadius: BorderRadius.circular(
                          KickPulseRadiiSpacing.chipRadius,
                        ),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.playerPersonalDataDepartmentLabel,
                            prefixIcon: const Icon(Icons.map_outlined),
                            suffixIcon:
                                const Icon(Icons.arrow_drop_down_outlined),
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
                        key: const Key('player_form_municipality_selector'),
                        onTap: () => _pickMunicipality(context),
                        borderRadius: BorderRadius.circular(
                          KickPulseRadiiSpacing.chipRadius,
                        ),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.playerPersonalDataMunicipalityLabel,
                            prefixIcon:
                                const Icon(Icons.location_city_outlined),
                            suffixIcon:
                                const Icon(Icons.arrow_drop_down_outlined),
                            errorText: _selectedMunicipality == null && _isDirty
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
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

                  // Section 5: Multiple Tactical Football Positions
                  _buildSectionCard(
                    title: l10n.playerPersonalDataPositionsLabel,
                    children: [
                      Text(
                        l10n.playerPersonalDataPositionsSubtitle,
                        style: KickPulseTypography.captionMeta,
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

                      // Tactical Lines
                      _buildTacticalLineGroup(
                        lineTitle: l10n.playerTacticalLineGoalkeeper,
                        positions: DetailedFootballPosition.byLine(
                          PlayerPosition.goalkeeper,
                        ),
                      ),
                      _buildTacticalLineGroup(
                        lineTitle: l10n.playerTacticalLineDefender,
                        positions: DetailedFootballPosition.byLine(
                          PlayerPosition.defender,
                        ),
                      ),
                      _buildTacticalLineGroup(
                        lineTitle: l10n.playerTacticalLineMidfielder,
                        positions: DetailedFootballPosition.byLine(
                          PlayerPosition.midfielder,
                        ),
                      ),
                      _buildTacticalLineGroup(
                        lineTitle: l10n.playerTacticalLineForward,
                        positions: DetailedFootballPosition.byLine(
                          PlayerPosition.forward,
                        ),
                      ),

                      if (_showPositionsError) ...[
                        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                        Text(
                          l10n.playerPersonalDataPositionsRequired,
                          key: const Key('player_form_positions_error'),
                          style: KickPulseTypography.captionMeta.copyWith(
                            color: KickPulseColors.accentLive,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

                  // Save Action Button
                  KickPulseButton(
                    key: const Key('player_form_save_button'),
                    label: _isSaving
                        ? l10n.playerPersonalDataSaving
                        : l10n.playerPersonalDataSaveButton,
                    isLoading: _isSaving,
                    isFullWidth: true,
                    onPressed: _isSaving ? null : () async => _handleSave(),
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

  Widget _buildProfilePhotoSection(AppLocalizations l10n) {
    ImageProvider? imageProvider;
    if (_photoLocalPath != null && _photoLocalPath!.isNotEmpty) {
      final file = File(_photoLocalPath!);
      if (file.existsSync()) {
        imageProvider = FileImage(file);
      }
    } else if (_photoRemoteUrl != null && _photoRemoteUrl!.isNotEmpty) {
      if (_photoRemoteUrl!.startsWith('http://') ||
          _photoRemoteUrl!.startsWith('https://')) {
        imageProvider = NetworkImage(_photoRemoteUrl!);
      } else {
        final localFile = File(_photoRemoteUrl!);
        if (localFile.existsSync()) {
          imageProvider = FileImage(localFile);
        }
      }
    }

    final hasPhoto = imageProvider != null;

    return _buildSectionCard(
      title: l10n.playerProfilePhotoSectionTitle,
      children: [
        Text(
          l10n.playerProfilePhotoSectionSubtitle,
          style: KickPulseTypography.bodyPrimary.copyWith(
            color: KickPulseColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
        Center(
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: hasPhoto
                    ? KickPulseColors.accentPrimary
                    : KickPulseColors.borderSubtle,
                width: 3,
              ),
              boxShadow: hasPhoto
                  ? [
                      BoxShadow(
                        color: KickPulseColors.accentPrimary.withAlpha(50),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: CircleAvatar(
              key: const Key('player_form_profile_avatar'),
              radius: 48,
              backgroundColor: KickPulseColors.surfaceBase,
              backgroundImage: imageProvider,
              child: !hasPhoto
                  ? const Icon(
                      Icons.person_outline,
                      size: 48,
                      color: KickPulseColors.textMuted,
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
        Center(
          child: KickPulseButton(
            key: const Key('player_profile_photo_action'),
            label: hasPhoto
                ? l10n.playerProfilePhotoChangeAction
                : l10n.playerProfilePhotoAction,
            variant: hasPhoto
                ? KickPulseButtonVariant.outline
                : KickPulseButtonVariant.primary,
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            onPressed: _isSaving
                ? null
                : () async {
                    _showPhotoSourceBottomSheet();
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      decoration: BoxDecoration(
        color: KickPulseColors.surfaceElevated,
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
        border: Border.all(color: KickPulseColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: KickPulseTypography.cardTitle),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTacticalLineGroup({
    required String lineTitle,
    required List<DetailedFootballPosition> positions,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KickPulseRadiiSpacing.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lineTitle, style: KickPulseTypography.sectionHeader),
          const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
          Wrap(
            spacing: KickPulseRadiiSpacing.spaceXs,
            runSpacing: KickPulseRadiiSpacing.spaceXs,
            children: positions.map((p) {
              final isSelected = _selectedPositions.contains(p.code);
              return FilterChip(
                key: Key('player_form_position_chip_${p.code}'),
                label: Text(
                  _positionLabel(context, p),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.black
                        : KickPulseColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                selectedColor: KickPulseColors.accentWarning,
                backgroundColor: KickPulseColors.surfaceSubtle,
                showCheckmark: false,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedPositions.add(p.code);
                    } else {
                      _selectedPositions.remove(p.code);
                    }
                    _showPositionsError = _selectedPositions.isEmpty;
                    _isDirty = true;
                  });
                },
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }

  String _positionLabel(BuildContext context, DetailedFootballPosition pos) {
    final l10n = AppLocalizations.of(context);
    switch (pos) {
      case DetailedFootballPosition.goalkeeper:
        return l10n.playerPositionPOR;
      case DetailedFootballPosition.centerBack:
        return l10n.playerPositionDFC;
      case DetailedFootballPosition.rightBack:
        return l10n.playerPositionLD;
      case DetailedFootballPosition.leftBack:
        return l10n.playerPositionLI;
      case DetailedFootballPosition.rightWingBack:
        return l10n.playerPositionCAD;
      case DetailedFootballPosition.leftWingBack:
        return l10n.playerPositionCAI;
      case DetailedFootballPosition.defensiveMidfielder:
        return l10n.playerPositionMCD;
      case DetailedFootballPosition.centralMidfielder:
        return l10n.playerPositionMC;
      case DetailedFootballPosition.attackingMidfielder:
        return l10n.playerPositionMCO;
      case DetailedFootballPosition.rightMidfielder:
        return l10n.playerPositionMD;
      case DetailedFootballPosition.leftMidfielder:
        return l10n.playerPositionMI;
      case DetailedFootballPosition.rightWinger:
        return l10n.playerPositionED;
      case DetailedFootballPosition.leftWinger:
        return l10n.playerPositionEI;
      case DetailedFootballPosition.secondStriker:
        return l10n.playerPositionMP;
      case DetailedFootballPosition.centerForward:
        return l10n.playerPositionDC;
    }
  }
}
