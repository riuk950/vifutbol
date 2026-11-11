import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/utils/search_utils.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_search_bar.dart';
import 'package:vifutbol/presentation/teams/widgets/kick_pulse_team_crest.dart';

/// Deduplicated view entry representing a club from the global platform catalog
/// alongside its enrollment status in the target competition.
class CatalogTeamEntry {
  final TournamentTeam sourceTeam;
  final String normalizedKey;
  final bool isEnrolledInCurrentTournament;

  const CatalogTeamEntry({
    required this.sourceTeam,
    required this.normalizedKey,
    required this.isEnrolledInCurrentTournament,
  });
}

/// Builds a deduplicated, alphabetically sorted list of platform clubs from [allTeams],
/// marking clubs already enrolled in [tournamentId] (by ID or case/diacritic-insensitive name).
List<CatalogTeamEntry> buildGlobalCatalogEntries({
  required List<TournamentTeam> allTeams,
  required String tournamentId,
}) {
  final currentTournamentTeams = allTeams
      .where((t) => t.tournamentId == tournamentId)
      .toList();
  final enrolledIds = currentTournamentTeams.map((t) => t.id).toSet();
  final enrolledKeys = currentTournamentTeams
      .map((t) => normalizeSearchText(t.name))
      .toSet();

  final groupedByKey = <String, List<TournamentTeam>>{};
  for (final team in allTeams) {
    final key = normalizeSearchText(team.name);
    if (key.isEmpty) continue;
    groupedByKey.putIfAbsent(key, () => <TournamentTeam>[]).add(team);
  }

  final entries = <CatalogTeamEntry>[];
  for (final entry in groupedByKey.entries) {
    final key = entry.key;
    final candidates = entry.value;

    final currentInstance = candidates
        .where((t) => t.tournamentId == tournamentId)
        .firstOrNull;
    final isEnrolled =
        currentInstance != null ||
        enrolledKeys.contains(key) ||
        candidates.any((t) => enrolledIds.contains(t.id));

    TournamentTeam representative;
    if (currentInstance != null) {
      representative = currentInstance;
    } else {
      final sortedCandidates = List<TournamentTeam>.from(candidates)
        ..sort((a, b) {
          final playerCmp = b.players.length.compareTo(a.players.length);
          if (playerCmp != 0) return playerCmp;
          return b.updatedAt.compareTo(a.updatedAt);
        });
      representative = sortedCandidates.first;
    }

    entries.add(
      CatalogTeamEntry(
        sourceTeam: representative,
        normalizedKey: key,
        isEnrolledInCurrentTournament: isEnrolled,
      ),
    );
  }

  entries.sort(
    (a, b) => a.sourceTeam.name.toLowerCase().compareTo(
      b.sourceTeam.name.toLowerCase(),
    ),
  );
  return entries;
}

/// Modal bottom sheet allowing an Organizer to search registered platform teams
/// in real time (case-insensitive and diacritic-insensitive) and enroll them into
/// [tournament] with immediate reactive updates and duplicate protection.
class AddTeamsToCompetitionModal extends ConsumerStatefulWidget {
  final ChampionshipTournament tournament;

  const AddTeamsToCompetitionModal({super.key, required this.tournament});

  static Future<void> show(
    BuildContext context, {
    required ChampionshipTournament tournament,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: KickPulseColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(KickPulseRadiiSpacing.cardRadius),
        ),
      ),
      builder: (_) => AddTeamsToCompetitionModal(tournament: tournament),
    );
  }

  @override
  ConsumerState<AddTeamsToCompetitionModal> createState() =>
      _AddTeamsToCompetitionModalState();
}

class _AddTeamsToCompetitionModalState
    extends ConsumerState<AddTeamsToCompetitionModal> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _enrollingKeys = <String>{};

  String _searchQuery = '';
  String? _feedbackMessage;
  bool _feedbackIsError = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  Future<void> _handleEnrollTeam(CatalogTeamEntry entry) async {
    if (_enrollingKeys.contains(entry.normalizedKey) ||
        entry.isEnrolledInCurrentTournament) {
      return;
    }

    final teamsState = ref.read(teamsControllerProvider);
    if (teamsState.isSaving) return;

    setState(() {
      _enrollingKeys.add(entry.normalizedKey);
      _feedbackMessage = null;
    });

    final userRole = ref.read(activeUserRoleProvider);
    final result = await ref
        .read(teamsControllerProvider.notifier)
        .enrollExistingTeamFromCatalog(
          sourceTeam: entry.sourceTeam,
          tournament: widget.tournament,
          actorRole: userRole,
        );

    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    setState(() {
      _enrollingKeys.remove(entry.normalizedKey);
      if (result != null) {
        _feedbackIsError = false;
        _feedbackMessage = result.skippedConflictingPlayersCount > 0
            ? l10n.addTeamsEnrollSuccessSkippedPlayers(
                result.enrolledTeam.name,
                result.skippedConflictingPlayersCount,
              )
            : l10n.addTeamsEnrollSuccess(result.enrolledTeam.name);
      } else {
        final failure = ref.read(teamsControllerProvider).lastFailure;
        _feedbackIsError = true;
        _feedbackMessage = failure?.message ?? l10n.addTeamsDuplicateError;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final teamsState = ref.watch(teamsControllerProvider);
    final allEntries = buildGlobalCatalogEntries(
      allTeams: teamsState.teams,
      tournamentId: widget.tournament.id,
    );

    final filteredEntries = allEntries
        .where(
          (entry) => matchesTeamQuery(
            name: entry.sourceTeam.name,
            shortCode: entry.sourceTeam.shortCode,
            query: _searchQuery,
          ),
        )
        .toList();

    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      key: const Key('add_teams_modal'),
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: EdgeInsets.only(bottom: viewInsetsBottom),
      decoration: const BoxDecoration(
        color: KickPulseColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(KickPulseRadiiSpacing.cardRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KickPulseRadiiSpacing.spaceMd,
              KickPulseRadiiSpacing.spaceMd,
              KickPulseRadiiSpacing.spaceSm,
              KickPulseRadiiSpacing.spaceSm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.addTeamsModalTitle,
                        style: KickPulseTypography.cardTitle.copyWith(
                          color: KickPulseColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        l10n.addTeamsModalSubtitle(widget.tournament.name),
                        style: KickPulseTypography.captionMeta.copyWith(
                          color: KickPulseColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('add_teams_modal_close_button'),
                  icon: const Icon(
                    Icons.close,
                    color: KickPulseColors.textSecondary,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KickPulseRadiiSpacing.spaceMd,
            ),
            child: KickPulseSearchBar(
              key: const Key('add_teams_search_field'),
              controller: _searchController,
              hintText: l10n.addTeamsSearchHint,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onClear: () {
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
          ),
          if (_feedbackMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KickPulseRadiiSpacing.spaceMd,
                KickPulseRadiiSpacing.spaceSm,
                KickPulseRadiiSpacing.spaceMd,
                0,
              ),
              child: Container(
                key: const Key('add_teams_feedback_banner'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  color:
                      (_feedbackIsError
                              ? KickPulseColors.accentWarning
                              : KickPulseColors.accentPrimary)
                          .withAlpha(28),
                  borderRadius: BorderRadius.circular(
                    KickPulseRadiiSpacing.chipRadius,
                  ),
                  border: Border.all(
                    color:
                        (_feedbackIsError
                                ? KickPulseColors.accentWarning
                                : KickPulseColors.accentPrimary)
                            .withAlpha(110),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _feedbackIsError
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      size: 18.0,
                      color: _feedbackIsError
                          ? KickPulseColors.accentWarning
                          : KickPulseColors.accentPrimary,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        _feedbackMessage!,
                        style: KickPulseTypography.captionMeta.copyWith(
                          color: KickPulseColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.close,
                        size: 16.0,
                        color: KickPulseColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _feedbackMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          const Divider(height: 1.0, color: KickPulseColors.borderSubtle),
          Expanded(
            child: _buildBody(
              l10n: l10n,
              allEntries: allEntries,
              filteredEntries: filteredEntries,
              isGlobalSaving: teamsState.isSaving,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody({
    required AppLocalizations l10n,
    required List<CatalogTeamEntry> allEntries,
    required List<CatalogTeamEntry> filteredEntries,
    required bool isGlobalSaving,
  }) {
    if (allEntries.isEmpty) {
      return Center(
        key: const Key('add_teams_empty_catalog_state'),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.groups_outlined,
                size: 40.0,
                color: KickPulseColors.textTertiary,
              ),
              const SizedBox(height: 12.0),
              Text(
                l10n.addTeamsEmptyCatalogTitle,
                textAlign: TextAlign.center,
                style: KickPulseTypography.cardTitle.copyWith(
                  color: KickPulseColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                l10n.addTeamsEmptyCatalogMessage,
                textAlign: TextAlign.center,
                style: KickPulseTypography.bodyPrimary.copyWith(
                  color: KickPulseColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredEntries.isEmpty) {
      return Center(
        key: const Key('add_teams_empty_search_state'),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 40.0,
                color: KickPulseColors.textTertiary,
              ),
              const SizedBox(height: 12.0),
              Text(
                l10n.addTeamsEmptySearchMessage(_searchQuery.trim()),
                textAlign: TextAlign.center,
                style: KickPulseTypography.bodyPrimary.copyWith(
                  color: KickPulseColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12.0),
              OutlinedButton.icon(
                key: const Key('add_teams_clear_filter_button'),
                onPressed: _clearSearch,
                icon: const Icon(Icons.clear, size: 16.0),
                label: Text(l10n.addTeamsClearSearchAction),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      key: const Key('add_teams_catalog_list'),
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      itemCount: filteredEntries.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
      itemBuilder: (context, index) {
        final entry = filteredEntries[index];
        final team = entry.sourceTeam;
        final isEnrolled = entry.isEnrolledInCurrentTournament;
        final isRowBusy = _enrollingKeys.contains(entry.normalizedKey);

        return Container(
          key: Key('add_teams_catalog_item_${team.id}'),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: KickPulseColors.surfaceBase,
            borderRadius: BorderRadius.circular(
              KickPulseRadiiSpacing.chipRadius,
            ),
            border: Border.all(
              color: isEnrolled
                  ? KickPulseColors.accentPrimary.withAlpha(70)
                  : KickPulseColors.borderSubtle,
            ),
          ),
          child: Row(
            children: [
              KickPulseTeamCrest(
                shortCode: team.shortCode,
                crestShape: team.crestShape,
                primaryColorHex: team.primaryColorHex,
                secondaryColorHex: team.secondaryColorHex,
                size: 40.0,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: KickPulseTypography.bodyPrimary.copyWith(
                        color: KickPulseColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '${team.shortCode} · ${l10n.addTeamsPlayersCountMeta(team.players.length)}',
                      style: KickPulseTypography.captionMeta.copyWith(
                        color: KickPulseColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isEnrolled) ...[
                      const SizedBox(height: 6.0),
                      KickPulseBadge(
                        key: Key('add_teams_enrolled_badge_${team.id}'),
                        label: l10n.addTeamsStatusEnrolledBadge,
                        variant: KickPulseBadgeVariant.success,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10.0),
              FilledButton(
                key: Key('add_teams_action_button_${team.id}'),
                onPressed: (isEnrolled || isRowBusy || isGlobalSaving)
                    ? null
                    : () => _handleEnrollTeam(entry),
                style: FilledButton.styleFrom(
                  backgroundColor: KickPulseColors.accentPrimary,
                  foregroundColor: KickPulseColors.surfaceBase,
                  disabledBackgroundColor: KickPulseColors.surfaceSubtle,
                  disabledForegroundColor: KickPulseColors.textTertiary,
                  minimumSize: const Size(
                    88.0,
                    KickPulseRadiiSpacing.minTouchTarget,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                ),
                child: isRowBusy
                    ? const SizedBox(
                        width: 16.0,
                        height: 16.0,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      )
                    : Text(
                        isEnrolled
                            ? l10n.addTeamsStatusEnrolledBadge
                            : l10n.addTeamsActionAdd,
                        style: KickPulseTypography.captionMeta.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
