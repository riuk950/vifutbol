// lib/domain/entities/detailed_football_position.dart

import 'package:vifutbol/domain/entities/team_enums.dart';

/// Represents the 15 specific tactical football positions.
enum DetailedFootballPosition {
  goalkeeper('POR', PlayerPosition.goalkeeper),
  centerBack('DFC', PlayerPosition.defender),
  rightBack('LD', PlayerPosition.defender),
  leftBack('LI', PlayerPosition.defender),
  rightWingBack('CAD', PlayerPosition.defender),
  leftWingBack('CAI', PlayerPosition.defender),
  defensiveMidfielder('MCD', PlayerPosition.midfielder),
  centralMidfielder('MC', PlayerPosition.midfielder),
  attackingMidfielder('MCO', PlayerPosition.midfielder),
  rightMidfielder('MD', PlayerPosition.midfielder),
  leftMidfielder('MI', PlayerPosition.midfielder),
  rightWinger('ED', PlayerPosition.forward),
  leftWinger('EI', PlayerPosition.forward),
  secondStriker('MP', PlayerPosition.forward),
  centerForward('DC', PlayerPosition.forward);

  const DetailedFootballPosition(this.code, this.tacticalLine);

  /// 2-3 letter international/Spanish tactical abbreviation (e.g. 'POR', 'DFC', 'LD').
  final String code;

  /// Macro tactical line mapped for roster and squad compatibility.
  final PlayerPosition tacticalLine;

  /// Tolerantly parses a raw string input into a [DetailedFootballPosition].
  ///
  /// Matches case-insensitively against [code] or enum [name].
  static DetailedFootballPosition? fromCode(String? raw) {
    if (raw == null) return null;
    final normalized = raw.trim().toUpperCase();
    for (final position in DetailedFootballPosition.values) {
      if (position.code == normalized || position.name.toUpperCase() == normalized) {
        return position;
      }
    }
    return null;
  }

  /// Positions grouped by tactical line for UI rendering.
  static List<DetailedFootballPosition> byLine(PlayerPosition line) =>
      values.where((p) => p.tacticalLine == line).toList(growable: false);
}
