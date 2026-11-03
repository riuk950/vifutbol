import 'dart:io';
import 'package:hive/hive.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';

/// Hive implementation of LocalStorageRepository with strict prefix isolation
/// and safe in-memory fallback.
class HiveLocalStorageRepository implements LocalStorageRepository {
  final String? basePath;
  String _activePrefix = '';
  Box<dynamic>? _box;
  final Map<String, String> _memoryFallbackStore = {};
  bool _fallbackToMemory = false;

  HiveLocalStorageRepository({this.basePath});

  @override
  bool get isUsingFallbackMemory => _fallbackToMemory;

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async {
    _activePrefix = storagePrefix;

    try {
      if (basePath != null) {
        final dir = Directory('$basePath/$_activePrefix');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        Hive.init(dir.path);
      }
      _box = await Hive.openBox('${_activePrefix}_preferences');
      _fallbackToMemory = false;
      return LocalStorageStatus(
        isPersistent: true,
        storageNamespace: _activePrefix,
      );
    } catch (_) {
      _fallbackToMemory = true;
      return LocalStorageStatus(
        isPersistent: false,
        storageNamespace: _activePrefix,
      );
    }
  }

  @override
  Future<String?> readString(String key) async {
    if (_fallbackToMemory || _box == null) {
      return _memoryFallbackStore['${_activePrefix}_$key'];
    }
    final value = _box!.get(key);
    return value as String?;
  }

  @override
  Future<void> writeString(String key, String value) async {
    if (_fallbackToMemory || _box == null) {
      _memoryFallbackStore['${_activePrefix}_$key'] = value;
      return;
    }
    await _box!.put(key, value);
  }

  @override
  Future<void> clearNamespace() async {
    if (_fallbackToMemory || _box == null) {
      _memoryFallbackStore.removeWhere(
        (k, _) => k.startsWith('${_activePrefix}_'),
      );
      return;
    }
    await _box!.clear();
  }
}
