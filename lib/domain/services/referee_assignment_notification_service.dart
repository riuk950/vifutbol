import '../entities/championship_match.dart';
import '../entities/match_alert_type.dart';
import '../entities/match_live_alert.dart';
import 'colombia_time_utils.dart';

/// Pure domain service for idempotent creation of targeted referee match
/// assignment notifications.
class RefereeAssignmentNotificationService {
  const RefereeAssignmentNotificationService._();

  /// Returns true only when [newRefereeId] is non-empty and differs from
  /// [previousRefereeId], preventing duplicate notifications when editing
  /// unrelated match scheduling fields.
  static bool shouldNotify({
    required String? previousRefereeId,
    required String? newRefereeId,
  }) {
    final next = newRefereeId?.trim() ?? '';
    if (next.isEmpty) return false;
    final prev = previousRefereeId?.trim() ?? '';
    return next != prev;
  }

  /// Builds a targeted [MatchLiveAlert] for [recipientUserId] describing the
  /// assigned [match] in Spanish with Colombia time. Returns null when
  /// [recipientUserId] is absent.
  static MatchLiveAlert? buildAssignmentAlert({
    required ChampionshipMatch match,
    required String? recipientUserId,
    required String homeTeamName,
    required String awayTeamName,
    required String tournamentName,
    DateTime? now,
  }) {
    final cleanRecipient = recipientUserId?.trim() ?? '';
    if (cleanRecipient.isEmpty) {
      return null;
    }

    final effectiveNow = now ?? DateTime.now();
    final scheduleText = match.scheduledStartTime != null
        ? ColombiaTimeUtils.formatDateTime12h(match.scheduledStartTime!)
        : 'Fecha por definir';

    final parts = <String>[
      '$homeTeamName vs $awayTeamName',
      if (tournamentName.trim().isNotEmpty) tournamentName.trim(),
      scheduleText,
      if (match.pitchName != null && match.pitchName!.trim().isNotEmpty)
        match.pitchName!.trim(),
    ];

    return MatchLiveAlert(
      id: 'alert-ref-${match.id}-$cleanRecipient-${effectiveNow.millisecondsSinceEpoch}',
      matchId: match.id,
      tournamentId: match.tournamentId,
      type: MatchAlertType.refereeMatchAssigned,
      title: 'Nuevo partido asignado',
      message: parts.join(' · '),
      timestamp: effectiveNow,
      isRead: false,
      recipientUserId: cleanRecipient,
    );
  }
}
