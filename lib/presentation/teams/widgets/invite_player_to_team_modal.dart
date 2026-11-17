import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/team_join_requests_providers.dart';
import 'package:vifutbol/domain/entities/available_player_candidate.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';

/// Dialog allowing a coach to search registered player accounts and send a team join request.
class InvitePlayerToTeamModal extends ConsumerStatefulWidget {
  const InvitePlayerToTeamModal({
    super.key,
    required this.team,
  });

  final TournamentTeam team;

  static Future<bool?> show(BuildContext context, {required TournamentTeam team}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => InvitePlayerToTeamModal(team: team),
    );
  }

  @override
  ConsumerState<InvitePlayerToTeamModal> createState() =>
      _InvitePlayerToTeamModalState();
}

class _InvitePlayerToTeamModalState
    extends ConsumerState<InvitePlayerToTeamModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _searchController;
  late final TextEditingController _shirtNumberController;
  AvailablePlayerCandidate? _selectedCandidate;
  PlayerPosition _selectedPosition = PlayerPosition.forward;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _shirtNumberController = TextEditingController();

    // Trigger initial search for candidate players
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = ref.read(activeUserRoleProvider);
      ref.read(teamJoinRequestsControllerProvider.notifier).searchCandidates(
            query: '',
            actorRole: role,
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _shirtNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(String query) async {
    final role = ref.read(activeUserRoleProvider);
    await ref.read(teamJoinRequestsControllerProvider.notifier).searchCandidates(
          query: query,
          actorRole: role,
        );
  }

  Future<void> _handleSend() async {
    if (_selectedCandidate == null) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final shirtNumber = int.parse(_shirtNumberController.text.trim());
    final role = ref.read(activeUserRoleProvider);
    final l10n = AppLocalizations.of(context);

    final success = await ref
        .read(teamJoinRequestsControllerProvider.notifier)
        .sendJoinRequest(
          team: widget.team,
          candidate: _selectedCandidate!,
          shirtNumber: shirtNumber,
          position: _selectedPosition,
          actorRole: role,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              l10n.teamInviteSuccessMessage(_selectedCandidate!.fullName),
            ),
            backgroundColor: KickPulseColors.accentPrimary,
          ),
        );
      Navigator.of(context).pop(true);
    } else {
      final lastFailure =
          ref.read(teamJoinRequestsControllerProvider).lastFailure;
      final errorMessage = lastFailure?.message ??
          l10n.teamInviteDuplicatePlayerError;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: KickPulseColors.accentLive,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requestsState = ref.watch(teamJoinRequestsControllerProvider);
    final candidates = requestsState.candidateSearchResults;

    return Dialog(
      backgroundColor: KickPulseColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.teamInvitePlayerModalTitle,
                      style: KickPulseTypography.sectionHeader.copyWith(
                        color: KickPulseColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: KickPulseColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

              // Search bar
              TextField(
                key: const Key('invite_player_search_field'),
                controller: _searchController,
                style: KickPulseTypography.bodyPrimary,
                decoration: InputDecoration(
                  hintText: l10n.teamInviteSearchHint,
                  hintStyle: KickPulseTypography.captionMeta,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: KickPulseColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: KickPulseColors.surfaceSubtle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      KickPulseRadiiSpacing.chipRadius,
                    ),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _handleSearch,
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

              // Candidates list
              Expanded(
                child: requestsState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: KickPulseColors.accentPrimary,
                        ),
                      )
                    : candidates.isEmpty
                        ? Center(
                            child: Text(
                              _searchController.text.trim().isEmpty
                                  ? 'No hay jugadores registrados disponibles.'
                                  : l10n.teamInviteEmptySearchMessage(
                                      _searchController.text.trim(),
                                    ),
                              style: KickPulseTypography.captionMeta,
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            key: const Key('invite_player_candidates_list'),
                            itemCount: candidates.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                            itemBuilder: (context, index) {
                              final candidate = candidates[index];
                              final isSelected =
                                  _selectedCandidate?.userAccountId ==
                                      candidate.userAccountId;

                              return InkWell(
                                key: Key(
                                  'invite_player_candidate_item_${candidate.userAccountId}',
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedCandidate = candidate;
                                  });
                                },
                                borderRadius: BorderRadius.circular(
                                  KickPulseRadiiSpacing.chipRadius,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: KickPulseRadiiSpacing.spaceMd,
                                    vertical: KickPulseRadiiSpacing.spaceSm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? KickPulseColors.accentPrimary
                                            .withValues(alpha: 0.15)
                                        : KickPulseColors.surfaceSubtle,
                                    borderRadius: BorderRadius.circular(
                                      KickPulseRadiiSpacing.chipRadius,
                                    ),
                                    border: Border.all(
                                      color: isSelected
                                          ? KickPulseColors.accentPrimary
                                          : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 16,
                                        backgroundColor:
                                            KickPulseColors.borderStrong,
                                        child: Icon(
                                          Icons.person,
                                          size: 18,
                                          color: KickPulseColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: KickPulseRadiiSpacing.spaceSm,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              candidate.fullName,
                                              style: KickPulseTypography
                                                  .cardTitle
                                                  .copyWith(
                                                fontSize: 14,
                                                color: KickPulseColors.textPrimary,
                                              ),
                                            ),
                                            if (candidate.documentId.isNotEmpty)
                                              Text(
                                                'Doc: ${candidate.documentId}',
                                                style: KickPulseTypography
                                                    .captionMeta,
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: KickPulseColors.accentPrimary,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),

              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
              const Divider(color: KickPulseColors.borderSubtle),
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

              // Form for shirt number & position
              Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shirt Number
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        key: const Key('invite_player_shirt_field'),
                        controller: _shirtNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        style: KickPulseTypography.bodyPrimary,
                        decoration: InputDecoration(
                          labelText: l10n.teamInviteShirtNumberLabel,
                          labelStyle: KickPulseTypography.captionMeta,
                          filled: true,
                          fillColor: KickPulseColors.surfaceSubtle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              KickPulseRadiiSpacing.chipRadius,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Requerido';
                          }
                          final num = int.tryParse(value.trim());
                          if (num == null || num < 1 || num > 99) {
                            return '1 - 99';
                          }
                          final taken = widget.team.players.any(
                            (p) => p.shirtNumber == num,
                          );
                          if (taken) {
                            return 'Ocupado';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: KickPulseRadiiSpacing.spaceMd),

                    // Tactical position
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<PlayerPosition>(
                        key: const Key('invite_player_position_dropdown'),
                        initialValue: _selectedPosition,
                        dropdownColor: KickPulseColors.surfaceElevated,
                        style: KickPulseTypography.bodyPrimary,
                        decoration: InputDecoration(
                          labelText: l10n.teamInvitePositionLabel,
                          labelStyle: KickPulseTypography.captionMeta,
                          filled: true,
                          fillColor: KickPulseColors.surfaceSubtle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              KickPulseRadiiSpacing.chipRadius,
                            ),
                          ),
                        ),
                        items: PlayerPosition.values.map((pos) {
                          final name = switch (pos) {
                            PlayerPosition.goalkeeper => 'Portero',
                            PlayerPosition.defender => 'Defensa',
                            PlayerPosition.midfielder => 'Centrocampista',
                            PlayerPosition.forward => 'Delantero',
                          };
                          return DropdownMenuItem(
                            value: pos,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (pos) {
                          if (pos != null) {
                            setState(() {
                              _selectedPosition = pos;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: KickPulseButton(
                      key: const Key('invite_player_cancel_button'),
                      label: 'Cancelar',
                      variant: KickPulseButtonVariant.secondary,
                      onPressed: () async {
                        Navigator.of(context).pop(false);
                      },
                    ),
                  ),
                  const SizedBox(width: KickPulseRadiiSpacing.spaceMd),
                  Expanded(
                    child: KickPulseButton(
                      key: const Key('invite_player_submit_button'),
                      label: l10n.teamInviteSendAction,
                      variant: KickPulseButtonVariant.primary,
                      isLoading: requestsState.isSaving,
                      onPressed: _selectedCandidate == null
                          ? null
                          : () async {
                              await _handleSend();
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
