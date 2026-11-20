import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:vifutbol/application/providers/venues_providers.dart';
import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/auth/widgets/kick_pulse_role_guard.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/venues/widgets/kick_pulse_urban_map_canvas.dart';

class _PitchFormItem {
  _PitchFormItem({
    required this.id,
    required this.nameController,
    required this.capacityController,
    this.surfaceType = PitchSurfaceType.syntheticGrass,
    this.format = PitchFormat.football7,
    this.hasLighting = true,
    this.status = VenueOperationalStatus.active,
  });

  final String id;
  final TextEditingController nameController;
  final TextEditingController capacityController;
  PitchSurfaceType surfaceType;
  PitchFormat format;
  bool hasLighting;
  VenueOperationalStatus status;

  void dispose() {
    nameController.dispose();
    capacityController.dispose();
  }
}

/// Screen allowing the Organizer to register or edit sports venues and pitches.
/// Protected by [KickPulseRoleGuard] with [RoleCapability.manageVenues].
class VenueFormScreen extends ConsumerStatefulWidget {
  const VenueFormScreen({super.key, this.existingVenue});

  final SportsVenue? existingVenue;

  @override
  ConsumerState<VenueFormScreen> createState() => _VenueFormScreenState();
}

class _VenueFormScreenState extends ConsumerState<VenueFormScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _urbanRefController;
  late TextEditingController _latController;
  late TextEditingController _lngController;

  late GeoCoordinate _selectedCoordinate;
  final List<_PitchFormItem> _pitches = [];
  bool _hasUnsavedChanges = false;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final venue = widget.existingVenue;
    final draftState = ref.read(venuesControllerProvider);

    final initialName =
        venue?.name ??
        (draftState.draftVenueName.isNotEmpty ? draftState.draftVenueName : '');
    final initialAddress =
        venue?.address ??
        (draftState.draftAddress.isNotEmpty ? draftState.draftAddress : '');
    final initialUrbanRef =
        venue?.urbanReference ??
        (draftState.draftUrbanReference.isNotEmpty
            ? draftState.draftUrbanReference
            : '');

    _selectedCoordinate = venue?.coordinate ?? GeoCoordinate.defaultCityCenter;

    _nameController = TextEditingController(text: initialName)
      ..addListener(_onFieldChanged);
    _addressController = TextEditingController(text: initialAddress)
      ..addListener(_onFieldChanged);
    _urbanRefController = TextEditingController(text: initialUrbanRef)
      ..addListener(_onFieldChanged);
    _latController = TextEditingController(
      text: _selectedCoordinate.latitude.toString(),
    )..addListener(_onCoordinateInputChanged);
    _lngController = TextEditingController(
      text: _selectedCoordinate.longitude.toString(),
    )..addListener(_onCoordinateInputChanged);

    if (venue != null && venue.pitches.isNotEmpty) {
      for (final pitch in venue.pitches) {
        _pitches.add(
          _PitchFormItem(
            id: pitch.id,
            nameController: TextEditingController(text: pitch.name)
              ..addListener(_onFieldChanged),
            capacityController: TextEditingController(
              text: pitch.capacity.toString(),
            )..addListener(_onFieldChanged),
            surfaceType: pitch.surfaceType,
            format: pitch.format,
            hasLighting: pitch.hasLighting,
            status: pitch.status,
          ),
        );
      }
    } else {
      _addDefaultPitch();
    }
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
    _saveDraft();
  }

  void _onCoordinateInputChanged() {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat != null &&
        lng != null &&
        GeoCoordinate.isValidCoordinate(lat, lng)) {
      setState(() {
        _selectedCoordinate = GeoCoordinate(latitude: lat, longitude: lng);
      });
    }
    _onFieldChanged();
  }

  void _addDefaultPitch() {
    final pitchNumber = _pitches.length + 1;
    final item = _PitchFormItem(
      id: _uuid.v4(),
      nameController: TextEditingController(text: 'Cancha $pitchNumber')
        ..addListener(_onFieldChanged),
      capacityController: TextEditingController(text: '100')
        ..addListener(_onFieldChanged),
      surfaceType: PitchSurfaceType.syntheticGrass,
      format: PitchFormat.football7,
      hasLighting: true,
      status: VenueOperationalStatus.active,
    );
    _pitches.add(item);
  }

  void _removePitch(int index) {
    if (_pitches.length <= 1) return;
    setState(() {
      final removed = _pitches.removeAt(index);
      removed.dispose();
      _hasUnsavedChanges = true;
    });
  }

  void _saveDraft() {
    ref
        .read(venuesControllerProvider.notifier)
        .updateDraft(
          name: _nameController.text,
          address: _addressController.text,
          urbanReference: _urbanRefController.text,
        );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveDraft();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _addressController.dispose();
    _urbanRefController.dispose();
    _latController.dispose();
    _lngController.dispose();
    for (final pitch in _pitches) {
      pitch.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _inlineError = null;
    });

    final name = _nameController.text.trim();
    if (name.length < 3) {
      setState(() {
        _inlineError = l10n.venueErrorNameTooShort;
      });
      return;
    }

    final address = _addressController.text.trim();
    if (address.length < 5) {
      setState(() {
        _inlineError = l10n.venueErrorAddressTooShort;
      });
      return;
    }

    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lat < -90.0 || lat > 90.0) {
      setState(() {
        _inlineError = l10n.venueErrorInvalidLatitude;
      });
      return;
    }
    if (lng == null || lng < -180.0 || lng > 180.0) {
      setState(() {
        _inlineError = l10n.venueErrorInvalidLongitude;
      });
      return;
    }

    final List<VenuePitch> parsedPitches = [];
    for (final p in _pitches) {
      final pName = p.nameController.text.trim();
      if (pName.length < 2) {
        setState(() {
          _inlineError = l10n.venueErrorPitchNameTooShort;
        });
        return;
      }
      final capacity = int.tryParse(p.capacityController.text.trim()) ?? 0;
      if (capacity < 0) {
        setState(() {
          _inlineError = l10n.venueErrorPitchCapacityNegative;
        });
        return;
      }
      parsedPitches.add(
        VenuePitch(
          id: p.id,
          name: pName,
          surfaceType: p.surfaceType,
          format: p.format,
          capacity: capacity,
          hasLighting: p.hasLighting,
          status: p.status,
        ),
      );
    }

    final activePitches = parsedPitches.where(
      (p) => p.status == VenueOperationalStatus.active,
    );
    if (activePitches.isEmpty) {
      setState(() {
        _inlineError = l10n.venueErrorPitchRequired;
      });
      return;
    }

    final venueToSave = SportsVenue(
      id: widget.existingVenue?.id ?? _uuid.v4(),
      name: name,
      address: address,
      urbanReference: _urbanRefController.text.trim(),
      coordinate: GeoCoordinate(latitude: lat, longitude: lng),
      pitches: parsedPitches,
      status: widget.existingVenue?.status ?? VenueOperationalStatus.active,
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(venuesControllerProvider.notifier)
        .saveVenue(venueToSave);

    if (success && mounted) {
      _hasUnsavedChanges = false;
      Navigator.of(context).pop();
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    final l10n = AppLocalizations.of(context);
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KickPulseColors.surfaceElevated,
        title: Text(
          l10n.venueFormDiscardTitle,
          style: const TextStyle(color: KickPulseColors.textPrimary),
        ),
        content: Text(
          l10n.venueFormDiscardMessage,
          style: const TextStyle(color: KickPulseColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KickPulseColors.accentLive,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.actionDiscard),
          ),
        ],
      ),
    );
    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final venuesState = ref.watch(venuesControllerProvider);
    final isEditing = widget.existingVenue != null;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          _hasUnsavedChanges = false;
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: KickPulseColors.canvasBackground,
        appBar: AppBar(
          backgroundColor: KickPulseColors.surfaceBase,
          title: Text(
            isEditing ? l10n.venueFormEditTitle : l10n.venueFormCreateTitle,
            style: const TextStyle(color: KickPulseColors.textPrimary),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              if (await _onWillPop() && context.mounted) {
                _hasUnsavedChanges = false;
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: KickPulseRoleGuard(
          requiredCapability: RoleCapability.manageVenues,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_inlineError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(
                        KickPulseRadiiSpacing.spaceSm,
                      ),
                      decoration: BoxDecoration(
                        color: KickPulseColors.accentLive.withAlpha(30),
                        borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
                        border: Border.all(color: KickPulseColors.accentLive),
                      ),
                      child: Text(
                        _inlineError!,
                        style: const TextStyle(
                          color: KickPulseColors.accentLive,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                  ],

                  // Venue name
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: KickPulseColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: l10n.venueFormNameLabel,
                      hintText: l10n.venueFormNameHint,
                      filled: true,
                      fillColor: KickPulseColors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
                      ),
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

                  // Venue physical address
                  TextFormField(
                    controller: _addressController,
                    style: const TextStyle(color: KickPulseColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: l10n.venueFormAddressLabel,
                      hintText: l10n.venueFormAddressHint,
                      filled: true,
                      fillColor: KickPulseColors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
                      ),
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

                  // Urban reference
                  TextFormField(
                    controller: _urbanRefController,
                    style: const TextStyle(color: KickPulseColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: l10n.venueFormReferenceLabel,
                      hintText: l10n.venueFormReferenceHint,
                      filled: true,
                      fillColor: KickPulseColors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
                      ),
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

                  // Map Picker Header
                  Text(
                    l10n.venueFormPickOnMap,
                    style: const TextStyle(
                      color: KickPulseColors.accentElectric,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

                  // Interactive Map Canvas
                  KickPulseUrbanMapCanvas(
                    centerCoordinate: _selectedCoordinate,
                    pickedCoordinate: _selectedCoordinate,
                    isPickerMode: true,
                    height: 200,
                    onCoordinatePicked: (picked) {
                      setState(() {
                        _selectedCoordinate = picked;
                        _latController.text = picked.latitude.toString();
                        _lngController.text = picked.longitude.toString();
                        _hasUnsavedChanges = true;
                      });
                    },
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

                  // Lat / Lng inputs
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          style: const TextStyle(
                            color: KickPulseColors.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.venueFormLatitudeLabel,
                            filled: true,
                            fillColor: KickPulseColors.surfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius:
                                  KickPulseRadiiSpacing.chipBorderRadius,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                      Expanded(
                        child: TextFormField(
                          controller: _lngController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          style: const TextStyle(
                            color: KickPulseColors.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.venueFormLongitudeLabel,
                            filled: true,
                            fillColor: KickPulseColors.surfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius:
                                  KickPulseRadiiSpacing.chipBorderRadius,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

                  // Pitches Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.venuesPitchesSectionTitle,
                        style: const TextStyle(
                          color: KickPulseColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: KickPulseColors.accentPrimary,
                        ),
                        label: Text(
                          l10n.venuesAddPitchAction,
                          style: const TextStyle(
                            color: KickPulseColors.accentPrimary,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _addDefaultPitch();
                            _hasUnsavedChanges = true;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

                  // Pitches Form Cards
                  ..._pitches.asMap().entries.map((entry) {
                    final index = entry.key;
                    final pitch = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: KickPulseRadiiSpacing.spaceSm,
                      ),
                      child: KickPulseCard(
                        backgroundColor: KickPulseColors.surfaceElevated,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: pitch.nameController,
                                    style: const TextStyle(
                                      color: KickPulseColors.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: l10n.venuesPitchNameLabel,
                                      hintText: l10n.venuesPitchNameHint,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                if (_pitches.length > 1)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: KickPulseColors.accentLive,
                                    ),
                                    tooltip: l10n.venuesRemovePitchAction,
                                    onPressed: () => _removePitch(index),
                                  ),
                              ],
                            ),
                            const SizedBox(
                              height: KickPulseRadiiSpacing.spaceSm,
                            ),
                            Row(
                              children: [
                                // Surface Dropdown
                                Expanded(
                                  child:
                                      DropdownButtonFormField<PitchSurfaceType>(
                                        initialValue: pitch.surfaceType,
                                        dropdownColor:
                                            KickPulseColors.surfaceElevated,
                                        style: const TextStyle(
                                          color: KickPulseColors.textPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          labelText:
                                              l10n.venuesPitchSurfaceLabel,
                                          isDense: true,
                                        ),
                                        items: [
                                          DropdownMenuItem(
                                            value:
                                                PitchSurfaceType.syntheticGrass,
                                            child: Text(
                                              l10n.surfaceSyntheticGrass,
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value:
                                                PitchSurfaceType.naturalGrass,
                                            child: Text(
                                              l10n.surfaceNaturalGrass,
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: PitchSurfaceType.dirtOrSand,
                                            child: Text(l10n.surfaceDirtOrSand),
                                          ),
                                          DropdownMenuItem(
                                            value: PitchSurfaceType.hardCourt,
                                            child: Text(l10n.surfaceHardCourt),
                                          ),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              pitch.surfaceType = val;
                                              _hasUnsavedChanges = true;
                                            });
                                          }
                                        },
                                      ),
                                ),
                                const SizedBox(
                                  width: KickPulseRadiiSpacing.spaceSm,
                                ),
                                // Format Dropdown
                                Expanded(
                                  child: DropdownButtonFormField<PitchFormat>(
                                    initialValue: pitch.format,
                                    dropdownColor:
                                        KickPulseColors.surfaceElevated,
                                    style: const TextStyle(
                                      color: KickPulseColors.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: l10n.venuesPitchFormatLabel,
                                      isDense: true,
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: PitchFormat.football5,
                                        child: Text(l10n.formatFootball5),
                                      ),
                                      DropdownMenuItem(
                                        value: PitchFormat.football7,
                                        child: Text(l10n.formatFootball7),
                                      ),
                                      DropdownMenuItem(
                                        value: PitchFormat.football8,
                                        child: Text(l10n.formatFootball8),
                                      ),
                                      DropdownMenuItem(
                                        value: PitchFormat.football11,
                                        child: Text(l10n.formatFootball11),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          pitch.format = val;
                                          _hasUnsavedChanges = true;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: KickPulseRadiiSpacing.spaceSm,
                            ),
                            Row(
                              children: [
                                // Capacity
                                Expanded(
                                  child: TextFormField(
                                    controller: pitch.capacityController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      color: KickPulseColors.textPrimary,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      labelText: l10n.venuesPitchCapacityLabel,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: KickPulseRadiiSpacing.spaceSm,
                                ),
                                // Status (Active vs Maintenance)
                                Expanded(
                                  child:
                                      DropdownButtonFormField<
                                        VenueOperationalStatus
                                      >(
                                        initialValue: pitch.status,
                                        dropdownColor:
                                            KickPulseColors.surfaceElevated,
                                        style: const TextStyle(
                                          color: KickPulseColors.textPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          labelText:
                                              l10n.venuesPitchStatusLabel,
                                          isDense: true,
                                        ),
                                        items: [
                                          DropdownMenuItem(
                                            value:
                                                VenueOperationalStatus.active,
                                            child: Text(
                                              l10n.venuesStatusActive,
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: VenueOperationalStatus
                                                .maintenance,
                                            child: Text(
                                              l10n.venuesStatusMaintenance,
                                            ),
                                          ),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              pitch.status = val;
                                              _hasUnsavedChanges = true;
                                            });
                                          }
                                        },
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: KickPulseRadiiSpacing.spaceSm,
                            ),
                            // Night lighting switch
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                pitch.hasLighting
                                    ? l10n.venuesPitchLightingYes
                                    : l10n.venuesPitchLightingNo,
                                style: const TextStyle(
                                  color: KickPulseColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              value: pitch.hasLighting,
                              activeTrackColor: KickPulseColors.accentElectric,
                              onChanged: (val) {
                                setState(() {
                                  pitch.hasLighting = val;
                                  _hasUnsavedChanges = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

                  // Submit Button
                  KickPulseButton(
                    label: l10n.venueFormSaveAction,
                    isLoading: venuesState.isSubmitting,
                    onPressed: venuesState.isSubmitting ? null : _handleSave,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
