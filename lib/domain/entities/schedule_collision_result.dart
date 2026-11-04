import 'match_enums.dart';

class ScheduleCollisionResult {
  const ScheduleCollisionResult({
    required this.hasCollision,
    this.collisionType,
    this.conflictingMatchId,
    this.conflictingEntityName,
    this.message,
  });

  final bool hasCollision;
  final ScheduleCollisionType? collisionType;
  final String? conflictingMatchId;
  final String? conflictingEntityName;
  final String? message;

  factory ScheduleCollisionResult.none() {
    return const ScheduleCollisionResult(hasCollision: false);
  }

  factory ScheduleCollisionResult.collision({
    required ScheduleCollisionType collisionType,
    required String conflictingMatchId,
    required String conflictingEntityName,
    required String message,
  }) {
    return ScheduleCollisionResult(
      hasCollision: true,
      collisionType: collisionType,
      conflictingMatchId: conflictingMatchId,
      conflictingEntityName: conflictingEntityName,
      message: message,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleCollisionResult &&
        other.hasCollision == hasCollision &&
        other.collisionType == collisionType &&
        other.conflictingMatchId == conflictingMatchId &&
        other.conflictingEntityName == conflictingEntityName &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(
    hasCollision,
    collisionType,
    conflictingMatchId,
    conflictingEntityName,
    message,
  );
}
