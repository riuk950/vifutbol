import 'package:vifutbol/domain/entities/local_storage_status.dart';

/// Contract for isolated local key-value persistence.
abstract class LocalStorageRepository {
  /// Initializes the local storage container with the specified environment prefix.
  Future<LocalStorageStatus> initialize(String storagePrefix);

  /// Reads a string value by key within the active namespace.
  Future<String?> readString(String key);

  /// Writes a string value by key within the active namespace.
  Future<void> writeString(String key, String value);

  /// Clears all entries within the active storage namespace.
  Future<void> clearNamespace();

  /// Whether storage is currently running on in-memory fallback.
  bool get isUsingFallbackMemory;
}
