import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/team_join_requests_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/team_join_request.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';

/// Screen displaying pending team join requests for the currently authenticated player.
class PlayerTeamRequestsScreen extends ConsumerStatefulWidget {
  const PlayerTeamRequestsScreen({super.key});

  @override
  ConsumerState<PlayerTeamRequestsScreen> createState() =>
      _PlayerTeamRequestsScreenState();
}

class _PlayerTeamRequestsScreenState
    extends ConsumerState<PlayerTeamRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(teamJoinRequestsControllerProvider.notifier)
          .loadRequestsForCurrentPlayer();
    });
  }

  Future<void> _handleResponse(
    TeamJoinRequest request, {
    required bool accept,
  }) async {
    final role = ref.read(activeUserRoleProvider);
    final l10n = AppLocalizations.of(context);

    final success = await ref
        .read(teamJoinRequestsControllerProvider.notifier)
        .respondToJoinRequest(
          requestId: request.id,
          accept: accept,
          actorRole: role,
        );

    if (!mounted) return;

    if (success) {
      final message = accept
          ? l10n.profileTeamRequestAcceptedMessage(request.teamName)
          : l10n.profileTeamRequestRejectedMessage(request.teamName);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: accept
                ? KickPulseColors.accentPrimary
                : KickPulseColors.textSecondary,
          ),
        );

      if (accept) {
        ref.read(teamsControllerProvider.notifier).loadTeams();
      }
    } else {
      final lastFailure =
          ref.read(teamJoinRequestsControllerProvider).lastFailure;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              lastFailure?.message ?? 'Error al procesar la solicitud',
            ),
            backgroundColor: KickPulseColors.accentLive,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(teamJoinRequestsControllerProvider);

    return Scaffold(
      backgroundColor: KickPulseColors.canvasBackground,
      appBar: AppBar(
        backgroundColor: KickPulseColors.surfaceBase,
        title: Text(
          l10n.profileTeamRequestsTitle,
          style: KickPulseTypography.screenTitle.copyWith(
            color: KickPulseColors.textPrimary,
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: KickPulseColors.accentPrimary,
              ),
            )
          : state.playerRequests.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(
                      KickPulseRadiiSpacing.spaceLg,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.mail_outline,
                          size: 48,
                          color: KickPulseColors.textSecondary,
                        ),
                        const SizedBox(
                          height: KickPulseRadiiSpacing.spaceMd,
                        ),
                        Text(
                          l10n.profileTeamRequestsEmpty,
                          style: KickPulseTypography.bodyPrimary.copyWith(
                            color: KickPulseColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(
                    KickPulseRadiiSpacing.spaceMd,
                  ),
                  itemCount: state.playerRequests.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                  itemBuilder: (context, index) {
                    final request = state.playerRequests[index];
                    final positionLabel = switch (request.position) {
                      PlayerPosition.goalkeeper => 'Portero',
                      PlayerPosition.defender => 'Defensa',
                      PlayerPosition.midfielder => 'Centrocampista',
                      PlayerPosition.forward => 'Delantero',
                    };

                    return KickPulseCard(
                      key: Key('player_team_request_card_${request.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    KickPulseColors.surfaceElevated,
                                child: Text(
                                  request.teamShortCode.isNotEmpty
                                      ? request.teamShortCode
                                      : 'TM',
                                  style: KickPulseTypography.cardTitle.copyWith(
                                    fontSize: 14,
                                    color: KickPulseColors.accentElectric,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: KickPulseRadiiSpacing.spaceMd,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request.teamName,
                                      style: KickPulseTypography.cardTitle
                                          .copyWith(
                                        fontSize: 16,
                                        color: KickPulseColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Entrenador: ${request.coachName.isNotEmpty ? request.coachName : "Técnico"}',
                                      style: KickPulseTypography.captionMeta,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: KickPulseRadiiSpacing.spaceSm,
                                  vertical: KickPulseRadiiSpacing.spaceXs,
                                ),
                                decoration: BoxDecoration(
                                  color: KickPulseColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(
                                    KickPulseRadiiSpacing.chipRadius,
                                  ),
                                ),
                                child: Text(
                                  '#${request.shirtNumber}',
                                  style: KickPulseTypography.cardTitle.copyWith(
                                    fontSize: 14,
                                    color: KickPulseColors.accentPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: KickPulseRadiiSpacing.spaceSm,
                          ),
                          Text(
                            'Posición propuesta: $positionLabel',
                            style: KickPulseTypography.bodyPrimary.copyWith(
                              fontSize: 13,
                              color: KickPulseColors.textSecondary,
                            ),
                          ),
                          const SizedBox(
                            height: KickPulseRadiiSpacing.spaceMd,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: KickPulseButton(
                                  key: Key(
                                    'reject_join_request_${request.id}',
                                  ),
                                  label: l10n.profileTeamRequestRejectAction,
                                  variant: KickPulseButtonVariant.secondary,
                                  isLoading: state.isSaving,
                                  onPressed: () async {
                                    await _handleResponse(
                                      request,
                                      accept: false,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(
                                width: KickPulseRadiiSpacing.spaceMd,
                              ),
                              Expanded(
                                child: KickPulseButton(
                                  key: Key(
                                    'accept_join_request_${request.id}',
                                  ),
                                  label: l10n.profileTeamRequestAcceptAction,
                                  variant: KickPulseButtonVariant.primary,
                                  isLoading: state.isSaving,
                                  onPressed: () async {
                                    await _handleResponse(
                                      request,
                                      accept: true,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
