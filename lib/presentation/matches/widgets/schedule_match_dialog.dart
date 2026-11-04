import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/venues_providers.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_referee.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

class ScheduleMatchDialog extends ConsumerStatefulWidget {
  const ScheduleMatchDialog({
    super.key,
    required this.match,
    required this.tournament,
  });

  final ChampionshipMatch match;
  final ChampionshipTournament tournament;

  static Future<bool?> show({
    required BuildContext context,
    required ChampionshipMatch match,
    required ChampionshipTournament tournament,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          ScheduleMatchDialog(match: match, tournament: tournament),
    );
  }

  @override
  ConsumerState<ScheduleMatchDialog> createState() =>
      _ScheduleMatchDialogState();
}

class _ScheduleMatchDialogState extends ConsumerState<ScheduleMatchDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  SportsVenue? _selectedVenue;
  VenuePitch? _selectedPitch;
  MatchReferee? _selectedReferee;
  String? _localError;
  bool _isLoadingVenues = true;
  List<SportsVenue> _venues = [];
  List<MatchReferee> _referees = [];

  @override
  void initState() {
    super.initState();
    final initial =
        widget.match.scheduledStartTime ??
        DateTime.now().add(const Duration(days: 1));
    _selectedDate = DateTime(initial.year, initial.month, initial.day);
    _selectedTime = TimeOfDay(hour: initial.hour, minute: initial.minute);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final repository = ref.read(venuesRepositoryProvider);
      final loaded = await repository.loadVenues();
      final matchesRepo = ref.read(tournamentMatchesRepositoryProvider);
      final loadedReferees = await matchesRepo.loadOfficialReferees();

      if (mounted) {
        setState(() {
          _venues = loaded.where((v) => v.isEligibleForFixtures).toList();
          _referees = loadedReferees.where((r) => r.isActive).toList();
          _isLoadingVenues = false;

          if (_venues.isNotEmpty) {
            _selectedVenue = _venues.firstWhere(
              (v) => v.id == widget.match.venueId,
              orElse: () => _venues.first,
            );
            if (_selectedVenue!.pitches.isNotEmpty) {
              _selectedPitch = _selectedVenue!.pitches.firstWhere(
                (p) => p.id == widget.match.pitchId,
                orElse: () => _selectedVenue!.pitches.first,
              );
            }
          }
          if (_referees.isNotEmpty && _selectedReferee == null) {
            _selectedReferee = _referees.firstWhere(
              (r) => r.id == widget.match.refereeId,
              orElse: () => _referees.first,
            );
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingVenues = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedVenue == null || _selectedPitch == null) {
      setState(() => _localError = l10n.scheduleMatchSelectPitchPrompt);
      return;
    }
    if (_selectedReferee == null) {
      setState(() => _localError = l10n.scheduleMatchSelectRefereePrompt);
      return;
    }

    final scheduledStartTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final userRole = ref.read(activeUserRoleProvider);

    final controller = ref.read(matchesCatalogControllerProvider.notifier);
    final success = await controller.scheduleMatch(
      matchId: widget.match.id,
      tournament: widget.tournament,
      scheduledStartTime: scheduledStartTime,
      venue: _selectedVenue!,
      pitch: _selectedPitch!,
      referee: _selectedReferee!,
      userRole: userRole,
    );

    if (success && mounted) {
      Navigator.of(context).pop(true);
    } else if (mounted) {
      final catalogState = ref.read(matchesCatalogControllerProvider);
      setState(() {
        _localError = catalogState.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalogState = ref.watch(matchesCatalogControllerProvider);
    final referees = _referees.isNotEmpty
        ? _referees
        : catalogState.referees.where((r) => r.isActive).toList();

    if (_selectedReferee == null && referees.isNotEmpty) {
      _selectedReferee = referees.firstWhere(
        (r) => r.id == widget.match.refereeId,
        orElse: () => referees.first,
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    return AlertDialog(
      backgroundColor: KickPulseColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
        side: const BorderSide(color: KickPulseColors.borderSubtle),
      ),
      title: Text(
        l10n.scheduleMatchDialogTitle,
        style: KickPulseTypography.cardTitle,
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_localError != null) ...[
                Container(
                  padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
                  margin: const EdgeInsets.only(
                    bottom: KickPulseRadiiSpacing.spaceMd,
                  ),
                  decoration: BoxDecoration(
                    color: KickPulseColors.accentLive.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(
                      KickPulseRadiiSpacing.chipRadius,
                    ),
                    border: Border.all(color: KickPulseColors.accentLive),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: KickPulseColors.accentLive,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _localError!,
                          key: const Key('schedule_error_message'),
                          style: KickPulseTypography.captionMeta.copyWith(
                            color: KickPulseColors.accentLive,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Date Picker Field
              Text(
                l10n.scheduleMatchDateLabel,
                style: KickPulseTypography.captionMeta.copyWith(
                  color: KickPulseColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                key: const Key('pick_match_date_field'),
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(
                  KickPulseRadiiSpacing.chipRadius,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KickPulseRadiiSpacing.spaceMd,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: KickPulseColors.surfaceBase,
                    borderRadius: BorderRadius.circular(
                      KickPulseRadiiSpacing.chipRadius,
                    ),
                    border: Border.all(color: KickPulseColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateFormat.format(_selectedDate),
                        style: KickPulseTypography.bodyPrimary,
                      ),
                      const Icon(
                        Icons.calendar_month,
                        size: 18,
                        color: KickPulseColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

              // Time Picker Field
              Text(
                l10n.scheduleMatchTimeLabel,
                style: KickPulseTypography.captionMeta.copyWith(
                  color: KickPulseColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                key: const Key('pick_match_time_field'),
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(
                  KickPulseRadiiSpacing.chipRadius,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KickPulseRadiiSpacing.spaceMd,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: KickPulseColors.surfaceBase,
                    borderRadius: BorderRadius.circular(
                      KickPulseRadiiSpacing.chipRadius,
                    ),
                    border: Border.all(color: KickPulseColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(timeStr, style: KickPulseTypography.bodyPrimary),
                      const Icon(
                        Icons.access_time,
                        size: 18,
                        color: KickPulseColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

              // Venue Selector
              Text(
                l10n.scheduleMatchVenueLabel,
                style: KickPulseTypography.captionMeta.copyWith(
                  color: KickPulseColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              if (_isLoadingVenues)
                const LinearProgressIndicator()
              else if (_venues.isEmpty)
                Text(
                  'No hay sedes disponibles',
                  style: KickPulseTypography.captionMeta,
                )
              else
                DropdownButtonFormField<SportsVenue>(
                  key: const Key('select_venue_dropdown'),
                  isExpanded: true,
                  initialValue: _selectedVenue,
                  dropdownColor: KickPulseColors.surfaceElevated,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: KickPulseColors.surfaceBase,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        KickPulseRadiiSpacing.chipRadius,
                      ),
                      borderSide: const BorderSide(
                        color: KickPulseColors.borderSubtle,
                      ),
                    ),
                  ),
                  items: _venues.map((v) {
                    return DropdownMenuItem<SportsVenue>(
                      value: v,
                      child: Text(
                        v.name,
                        style: KickPulseTypography.bodyPrimary,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedVenue = val;
                        _selectedPitch = val.pitches.isNotEmpty
                            ? val.pitches.first
                            : null;
                      });
                    }
                  },
                ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

              // Pitch Selector
              if (_selectedVenue != null &&
                  _selectedVenue!.pitches.isNotEmpty) ...[
                Text(
                  l10n.scheduleMatchPitchLabel,
                  style: KickPulseTypography.captionMeta.copyWith(
                    color: KickPulseColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<VenuePitch>(
                  key: const Key('select_pitch_dropdown'),
                  isExpanded: true,
                  initialValue: _selectedPitch,
                  dropdownColor: KickPulseColors.surfaceElevated,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: KickPulseColors.surfaceBase,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        KickPulseRadiiSpacing.chipRadius,
                      ),
                      borderSide: const BorderSide(
                        color: KickPulseColors.borderSubtle,
                      ),
                    ),
                  ),
                  items: _selectedVenue!.pitches.map((p) {
                    return DropdownMenuItem<VenuePitch>(
                      value: p,
                      child: Text(
                        p.name,
                        style: KickPulseTypography.bodyPrimary,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedPitch = val);
                    }
                  },
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              ],

              // Referee Selector
              Text(
                l10n.scheduleMatchRefereeLabel,
                style: KickPulseTypography.captionMeta.copyWith(
                  color: KickPulseColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              if (referees.isEmpty)
                Text(
                  'No hay árbitros registrados',
                  style: KickPulseTypography.captionMeta,
                )
              else
                DropdownButtonFormField<MatchReferee>(
                  key: const Key('select_referee_dropdown'),
                  isExpanded: true,
                  initialValue: _selectedReferee,
                  dropdownColor: KickPulseColors.surfaceElevated,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: KickPulseColors.surfaceBase,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        KickPulseRadiiSpacing.chipRadius,
                      ),
                      borderSide: const BorderSide(
                        color: KickPulseColors.borderSubtle,
                      ),
                    ),
                  ),
                  items: referees.map((r) {
                    return DropdownMenuItem<MatchReferee>(
                      value: r,
                      child: Text(
                        '${r.fullName} (${r.certificationLevel})',
                        style: KickPulseTypography.bodyPrimary,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedReferee = val);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cancel_schedule_match_button'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            l10n.actionCancel,
            style: KickPulseTypography.captionMeta.copyWith(
              color: KickPulseColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          key: const Key('confirm_schedule_match_button'),
          onPressed: catalogState.isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: KickPulseColors.accentPrimary,
            foregroundColor: KickPulseColors.surfaceBase,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                KickPulseRadiiSpacing.chipRadius,
              ),
            ),
          ),
          child: catalogState.isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  l10n.scheduleMatchSaveButton,
                  style: KickPulseTypography.captionMeta.copyWith(
                    color: KickPulseColors.surfaceBase,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}
