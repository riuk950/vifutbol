/// Represents a user account with player role available to be invited to a team.
class AvailablePlayerCandidate {
  final String userAccountId;
  final String fullName;
  final String documentId;

  const AvailablePlayerCandidate({
    required this.userAccountId,
    required this.fullName,
    required this.documentId,
  });

  /// Document ID normalized for comparisons (trimmed and upper-cased).
  String get normalizedDocumentId => documentId.trim().toUpperCase();

  AvailablePlayerCandidate copyWith({
    String? userAccountId,
    String? fullName,
    String? documentId,
  }) {
    return AvailablePlayerCandidate(
      userAccountId: userAccountId ?? this.userAccountId,
      fullName: fullName ?? this.fullName,
      documentId: documentId ?? this.documentId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userAccountId': userAccountId,
      'fullName': fullName,
      'documentId': documentId,
      'normalizedDocumentId': normalizedDocumentId,
    };
  }

  factory AvailablePlayerCandidate.fromJson(Map<String, dynamic> json) {
    return AvailablePlayerCandidate(
      userAccountId: (json['userAccountId'] ?? json['user_account_id']) as String,
      fullName: (json['fullName'] ?? json['full_name']) as String,
      documentId: (json['documentId'] ?? json['document_id']) as String? ?? '',
    );
  }
}
