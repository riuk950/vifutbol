import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/venues_providers.dart';
import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

/// Opens the modal bottom sheet to quickly create and register a new sports venue.
///
/// Returns the newly created [SportsVenue] if successful, or `null` if cancelled.
Future<SportsVenue?> showCreateVenueBottomSheet(BuildContext context) {
  return showModalBottomSheet<SportsVenue>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: KickPulseColors.surfaceBase,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const CreateVenueBottomSheet(),
  );
}

/// Interactive modal bottom sheet containing the streamlined venue creation form.
class CreateVenueBottomSheet extends ConsumerStatefulWidget {
  const CreateVenueBottomSheet({
    super.key,
    this.initialCoordinates = const GeoCoordinate(
      latitude: 4.6097,
      longitude: -74.0817,
    ),
  });

  final GeoCoordinate initialCoordinates;

  @override
  ConsumerState<CreateVenueBottomSheet> createState() =>
      _CreateVenueBottomSheetState();
}

class _CreateVenueBottomSheetState
    extends ConsumerState<CreateVenueBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _pitchesCountController;

  bool _isSubmitting = false;
  String? _duplicateError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _pitchesCountController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _pitchesCountController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();

    // Check duplicate name against loaded catalog
    final venues = ref.read(venuesControllerProvider).venues;
    final isDuplicate = venues.any(
      (v) => v.name.trim().toLowerCase() == name.toLowerCase(),
    );
    if (isDuplicate) {
      setState(() {
        _duplicateError = l10n.venueNameDuplicate;
      });
      _formKey.currentState?.validate();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _duplicateError = null;
    });

    final pitchesCount = int.tryParse(_pitchesCountController.text.trim()) ?? 1;
    final generatedPitches = List.generate(pitchesCount, (index) {
      return VenuePitch(
        id: 'pitch_${DateTime.now().microsecondsSinceEpoch}_$index',
        name: 'Cancha ${index + 1}',
        surfaceType: PitchSurfaceType.syntheticGrass,
        format: PitchFormat.football7,
        capacity: 14,
        hasLighting: true,
        status: VenueOperationalStatus.active,
      );
    });

    final newVenue = SportsVenue(
      id: 'venue_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      address: _addressController.text.trim(),
      urbanReference: '',
      coordinate: widget.initialCoordinates,
      pitches: generatedPitches,
      status: VenueOperationalStatus.active,
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(venuesControllerProvider.notifier)
        .saveVenue(newVenue);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(newVenue);
    } else {
      final failure = ref.read(venuesControllerProvider).lastFailure;
      setState(() {
        _isSubmitting = false;
        if (failure?.message.contains('Ya existe') == true) {
          _duplicateError = l10n.venueNameDuplicate;
          _formKey.currentState?.validate();
        }
      });
      if (_duplicateError == null && failure != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: KickPulseColors.accentLive,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: KickPulseColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l10n.createNewVenue,
                style: KickPulseTypography.screenTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('createVenueNameField'),
                controller: _nameController,
                style: const TextStyle(color: KickPulseColors.textPrimary),
                decoration: InputDecoration(
                  labelText: l10n.venueNameLabel,
                  labelStyle: const TextStyle(
                    color: KickPulseColors.textSecondary,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: KickPulseColors.borderSubtle),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: KickPulseColors.accentPrimary,
                    ),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: KickPulseColors.accentLive),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: KickPulseColors.accentLive),
                  ),
                ),
                onChanged: (_) {
                  if (_duplicateError != null) {
                    setState(() => _duplicateError = null);
                  }
                },
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.length < 3) {
                    return l10n.venueNameTooShort;
                  }
                  if (_duplicateError != null) {
                    return _duplicateError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('createVenueAddressField'),
                controller: _addressController,
                style: const TextStyle(color: KickPulseColors.textPrimary),
                decoration: InputDecoration(
                  labelText: l10n.venueAddressLabel,
                  labelStyle: const TextStyle(
                    color: KickPulseColors.textSecondary,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: KickPulseColors.borderSubtle),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: KickPulseColors.accentPrimary,
                    ),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: KickPulseColors.accentLive),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: KickPulseColors.accentLive),
                  ),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.length < 5) {
                    return l10n.venueAddressTooShort;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('createVenuePitchesCountField'),
                controller: _pitchesCountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: KickPulseColors.textPrimary),
                decoration: InputDecoration(
                  labelText: l10n.venuePitchesCountLabel,
                  labelStyle: const TextStyle(
                    color: KickPulseColors.textSecondary,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: KickPulseColors.borderSubtle),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: KickPulseColors.accentPrimary,
                    ),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: KickPulseColors.accentLive),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: KickPulseColors.accentLive),
                  ),
                ),
                validator: (value) {
                  final count = int.tryParse(value?.trim() ?? '');
                  if (count == null || count < 1) {
                    return l10n.venuePitchesInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('createVenueCancelButton'),
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: KickPulseColors.borderSubtle,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
                        ),
                      ),
                      child: Text(
                        l10n.actionCancel,
                        style: const TextStyle(
                          color: KickPulseColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('createVenueSubmitButton'),
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KickPulseColors.accentPrimary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                          : Text(l10n.createNewVenue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
