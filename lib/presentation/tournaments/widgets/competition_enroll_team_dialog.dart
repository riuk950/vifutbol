import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/services/standings_calculator_service.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

class CompetitionEnrollTeamDialog extends ConsumerStatefulWidget {
  const CompetitionEnrollTeamDialog({super.key, required this.tournament});

  final ChampionshipTournament tournament;

  static Future<bool?> show(
    BuildContext context, {
    required ChampionshipTournament tournament,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => CompetitionEnrollTeamDialog(tournament: tournament),
    );
  }

  @override
  ConsumerState<CompetitionEnrollTeamDialog> createState() =>
      _CompetitionEnrollTeamDialogState();
}

class _CompetitionEnrollTeamDialogState
    extends ConsumerState<CompetitionEnrollTeamDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _shortCodeController = TextEditingController();

  TeamCrestShape _crestShape = TeamCrestShape.shield;
  int _primaryColorHex = 0xFF00E676;
  String? _selectedGroup;
  String? _selectedExistingClubId;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _shortCodeController.dispose();
    super.dispose();
  }

  void _initGroupAndClubs(List<TournamentTeam> allTeams) {
    if (_initialized) return;
    _initialized = true;

    if (widget.tournament.format == TournamentFormat.mixedGroupsAndKnockout) {
      final validGroups = StandingsCalculatorService.buildValidGroupNames(
        widget.tournament.rules.groupStageConfig.groupCount,
      );
      final tournamentTeams = allTeams
          .where((t) => t.tournamentId == widget.tournament.id)
          .toList();
      final counts = <String, int>{for (final g in validGroups) g: 0};
      for (final t in tournamentTeams) {
        final g = StandingsCalculatorService.resolveEffectiveGroupName(
          team: t,
          allTournamentTeams: tournamentTeams,
          groupCount: widget.tournament.rules.groupStageConfig.groupCount,
        );
        if (counts.containsKey(g)) {
          counts[g] = (counts[g] ?? 0) + 1;
        }
      }

      String leastPopulatedGroup = validGroups.first;
      int minCount = counts[leastPopulatedGroup] ?? 0;
      for (final g in validGroups) {
        final c = counts[g] ?? 0;
        if (c < minCount) {
          minCount = c;
          leastPopulatedGroup = g;
        }
      }
      _selectedGroup = leastPopulatedGroup;
    }
  }

  void _onSelectExistingClub(TournamentTeam? club) {
    if (club == null) {
      setState(() {
        _selectedExistingClubId = null;
      });
      return;
    }

    setState(() {
      _selectedExistingClubId = club.id;
      _nameController.text = club.name;
      _shortCodeController.text = club.shortCode;
      _crestShape = club.crestShape;
      _primaryColorHex = club.primaryColorHex;
    });
  }

  Future<void> _onSubmit() async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final shortCode = _shortCodeController.text.trim().toUpperCase();
    final userRole = ref.read(activeUserRoleProvider);

    final newTeam = TournamentTeam(
      id: 'team-${DateTime.now().millisecondsSinceEpoch}',
      tournamentId: widget.tournament.id,
      name: name,
      shortCode: shortCode,
      crestShape: _crestShape,
      primaryColorHex: _primaryColorHex,
      groupName: _selectedGroup,
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(teamsControllerProvider.notifier)
        .enrollTeamInCompetition(
          team: newTeam,
          tournament: widget.tournament,
          actorRole: userRole,
        );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.competitionEnrollTeamSuccess(newTeam.name)),
          backgroundColor: KickPulseColors.accentPrimary,
        ),
      );
    } else {
      final teamsState = ref.read(teamsControllerProvider);
      final message =
          teamsState.lastFailure?.message ??
          'Error al inscribir el equipo en el campeonato';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: KickPulseColors.accentWarning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final teamsState = ref.watch(teamsControllerProvider);
    final allTeams = teamsState.teams;

    _initGroupAndClubs(allTeams);

    final isMixed =
        widget.tournament.format == TournamentFormat.mixedGroupsAndKnockout;
    final validGroups = isMixed
        ? StandingsCalculatorService.buildValidGroupNames(
            widget.tournament.rules.groupStageConfig.groupCount,
          )
        : const <String>[];

    // Candidate existing clubs from other tournaments not yet enrolled in this tournament
    final currentTournamentTeamNames = allTeams
        .where((t) => t.tournamentId == widget.tournament.id)
        .map((t) => t.normalizedName)
        .toSet();

    final seenIds = <String>{};
    final seenNames = <String>{};
    final existingClubsList = <TournamentTeam>[];
    for (final t in allTeams) {
      if (t.tournamentId != widget.tournament.id &&
          !currentTournamentTeamNames.contains(t.normalizedName) &&
          !seenIds.contains(t.id) &&
          !seenNames.contains(t.normalizedName)) {
        seenIds.add(t.id);
        seenNames.add(t.normalizedName);
        existingClubsList.add(t);
      }
    }

    final effectiveClubId =
        existingClubsList.any((c) => c.id == _selectedExistingClubId)
        ? _selectedExistingClubId
        : null;

    final effectiveGroup = validGroups.contains(_selectedGroup)
        ? _selectedGroup
        : (validGroups.isNotEmpty ? validGroups.first : null);

    return AlertDialog(
      key: const Key('competition_enroll_team_dialog'),
      backgroundColor: KickPulseColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
      ),
      title: Text(
        l10n.competitionEnrollTeamDialogTitle,
        style: KickPulseTypography.cardTitle,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (existingClubsList.isNotEmpty) ...[
                KeyedSubtree(
                  key: ValueKey(
                    'enroll_team_existing_club_sub_$effectiveClubId',
                  ),
                  child: DropdownButtonFormField<String?>(
                    key: const Key('enroll_team_existing_club_dropdown'),
                    initialValue: effectiveClubId,
                    decoration: InputDecoration(
                      labelText: l10n.competitionEnrollTeamExistingClubLabel,
                      labelStyle: KickPulseTypography.captionMeta,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          l10n.competitionEnrollTeamNewClubOption,
                          style: KickPulseTypography.bodyPrimary,
                        ),
                      ),
                      ...existingClubsList.map((club) {
                        return DropdownMenuItem<String?>(
                          value: club.id,
                          child: Text(
                            '${club.name} (${club.shortCode})',
                            style: KickPulseTypography.bodyPrimary,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (clubId) {
                      final selected = clubId == null
                          ? null
                          : existingClubsList
                                .where((c) => c.id == clubId)
                                .firstOrNull;
                      _onSelectExistingClub(selected);
                    },
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              ],

              // Team Name Field
              TextFormField(
                key: const Key('enroll_team_name_field'),
                controller: _nameController,
                style: KickPulseTypography.bodyPrimary,
                decoration: const InputDecoration(
                  labelText: 'Nombre del equipo',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  final text = val?.trim() ?? '';
                  if (text.length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
                  }
                  if (text.length > 60) {
                    return 'El nombre no puede exceder 60 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

              // Team ShortCode Field
              TextFormField(
                key: const Key('enroll_team_short_code_field'),
                controller: _shortCodeController,
                style: KickPulseTypography.bodyPrimary,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Sigla / Código (2-4 caracteres)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  final text = val?.trim() ?? '';
                  if (text.length < 2 || text.length > 4) {
                    return 'La sigla debe tener entre 2 y 4 caracteres';
                  }
                  return null;
                },
              ),

              // Group Selection if Mixed Format
              if (isMixed) ...[
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                KeyedSubtree(
                  key: ValueKey('enroll_team_group_sub_$effectiveGroup'),
                  child: DropdownButtonFormField<String>(
                    key: const Key('enroll_team_group_dropdown'),
                    initialValue: effectiveGroup,
                    decoration: InputDecoration(
                      labelText: l10n.competitionEnrollTeamGroupLabel,
                      labelStyle: KickPulseTypography.captionMeta,
                      border: const OutlineInputBorder(),
                    ),
                    items: validGroups.map((groupName) {
                      return DropdownMenuItem<String>(
                        value: groupName,
                        child: Text(
                          groupName,
                          style: KickPulseTypography.bodyPrimary,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedGroup = val;
                        });
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancelar',
            style: KickPulseTypography.captionMeta.copyWith(
              color: KickPulseColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          key: const Key('enroll_team_submit_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: KickPulseColors.accentPrimary,
            foregroundColor: KickPulseColors.surfaceBase,
          ),
          onPressed: teamsState.isSaving ? null : _onSubmit,
          child: Text(
            l10n.competitionEnrollTeamSubmitAction,
            style: KickPulseTypography.captionMeta.copyWith(
              fontWeight: FontWeight.bold,
              color: KickPulseColors.surfaceBase,
            ),
          ),
        ),
      ],
    );
  }
}
