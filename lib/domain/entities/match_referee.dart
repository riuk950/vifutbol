class MatchReferee {
  const MatchReferee({
    required this.id,
    required this.fullName,
    required this.certificationLevel,
    this.isActive = true,
  }) : assert(id.length > 0, 'Referee id cannot be empty'),
       assert(
         fullName.length >= 3,
         'Referee fullName must have at least 3 characters',
       ),
       assert(
         certificationLevel.length > 0,
         'certificationLevel cannot be empty',
       );

  final String id;
  final String fullName;
  final String certificationLevel;
  final bool isActive;

  MatchReferee copyWith({
    String? id,
    String? fullName,
    String? certificationLevel,
    bool? isActive,
  }) {
    return MatchReferee(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      certificationLevel: certificationLevel ?? this.certificationLevel,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'certificationLevel': certificationLevel,
      'isActive': isActive,
    };
  }

  factory MatchReferee.fromJson(Map<String, dynamic> json) {
    return MatchReferee(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      certificationLevel: json['certificationLevel'] as String? ?? 'Nacional',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchReferee &&
        other.id == id &&
        other.fullName == fullName &&
        other.certificationLevel == certificationLevel &&
        other.isActive == isActive;
  }

  @override
  int get hashCode => Object.hash(id, fullName, certificationLevel, isActive);
}
