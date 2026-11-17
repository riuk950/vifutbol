// lib/domain/repositories/document_storage_repository.dart

/// Contract for uploading and managing user identity document files.
abstract class DocumentStorageRepository {
  /// Uploads front and back document photos to private user-scoped storage
  /// and returns their persisted storage paths/URLs.
  ///
  /// If a side's local path is not provided, the existing URL is preserved.
  /// Throws [DocumentUploadFailure] or [OfflineAuthOperationFailure] if upload fails.
  Future<({String frontUrl, String backUrl})> uploadPlayerIdDocuments({
    required String userId,
    String? frontLocalPath,
    String? backLocalPath,
    String? existingFrontUrl,
    String? existingBackUrl,
  });

  /// Uploads a player's profile photograph to the `player-avatars` storage bucket
  /// and returns the public URL to display the avatar.
  ///
  /// Throws [DocumentUploadFailure] or [OfflineAuthOperationFailure] if upload fails.
  Future<String> uploadPlayerAvatar({
    required String userId,
    required String localPath,
    String? existingPhotoUrl,
  });

  /// Generates a signed, temporary URL for displaying private documents from `player-documents`.
  /// Returns `null` if the path is invalid or offline.
  Future<String?> getSignedDocumentUrl({
    required String storagePath,
    int expiresInSeconds = 300,
  });
}
