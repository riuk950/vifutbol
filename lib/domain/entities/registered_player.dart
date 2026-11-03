import 'team_enums.dart';

/// Represents an officially enrolled player in a team roster.
class RegisteredPlayer {
  final String id;
  final String fullName;
  final String documentId;
  final int shirtNumber;
  final PlayerPosition position;
  final bool isEligible;

  const RegisteredPlayer({
    required this.id,
    required this.fullName,
    required this.documentId,
    required this.shirtNumber,
    required this.position,
    this.isEligible = false,
  });

  /// Document identifier normalized for case-insensitive and trimmed uniqueness checks.
  String get normalizedDocumentId => documentId.trim().toUpperCase();

  RegisteredPlayer copyWith({
    String? id,
    String? fullName,
    String? documentId,
    int? shirtNumber,
    PlayerPosition? position,
    bool? isEligible,
  }) {
    return RegisteredPlayer(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      documentId: documentId ?? this.documentId,
      shirtNumber: shirtNumber ?? this.shirtNumber,
      position: position ?? this.position,
      isEligible: isEligible ?? this.isEligible,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'documentId': documentId,
      'shirtNumber': shirtNumber,
      'position': position.name,
      'isEligible': isEligible,
    };
  }

  factory RegisteredPlayer.fromJson(Map<String, dynamic> json) {
    return RegisteredPlayer(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      documentId: json['documentId'] as String,
      shirtNumber: (json['shirtNumber'] as num).toInt(),
      position: PlayerPosition.values.firstWhere(
        (e) => e.name == json['position'],
        orElse: () => PlayerPosition.midfielder,
      ),
      isEligible: json['isEligible'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RegisteredPlayer &&
        other.id == id &&
        other.fullName == fullName &&
        other.documentId == documentId &&
        other.shirtNumber == shirtNumber &&
        other.position == position &&
        other.isEligible == isEligible;
  }

  @override
  int get hashCode =>
      Object.hash(id, fullName, documentId, shirtNumber, position, isEligible);
}
