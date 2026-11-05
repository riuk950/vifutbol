import 'dart:async';
import 'dart:convert';
import 'package:vifutbol/domain/entities/match_live_alert.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/match_alerts_repository.dart';

class LocalMatchAlertsRepository implements MatchAlertsRepository {
  LocalMatchAlertsRepository({required this.storage});

  final LocalStorageRepository storage;
  final StreamController<List<MatchLiveAlert>> _alertsStreamController =
      StreamController<List<MatchLiveAlert>>.broadcast();

  static const String alertsStorageKey = 'vifutbol.match_alerts.v1';

  @override
  Future<List<MatchLiveAlert>> loadAlerts(
    String userId, {
    String? tournamentId,
  }) async {
    final all = await _loadAll();
    final filtered = all.where((a) {
      if (tournamentId != null && a.tournamentId != tournamentId) {
        return false;
      }
      return true;
    }).toList();
    _sortAlerts(filtered);
    return filtered;
  }

  @override
  Stream<List<MatchLiveAlert>> watchAlerts(
    String userId, {
    String? tournamentId,
  }) async* {
    final initial = await loadAlerts(userId, tournamentId: tournamentId);
    yield initial;
    yield* _alertsStreamController.stream.map((all) {
      final filtered = all.where((a) {
        if (tournamentId != null && a.tournamentId != tournamentId) {
          return false;
        }
        return true;
      }).toList();
      _sortAlerts(filtered);
      return filtered;
    });
  }

  @override
  Future<void> saveAlert(MatchLiveAlert alert) async {
    final all = await _loadAll();
    final updated = List<MatchLiveAlert>.from(all);
    final index = updated.indexWhere((a) => a.id == alert.id);
    if (index >= 0) {
      updated[index] = alert;
    } else {
      updated.add(alert);
    }
    await _persist(updated);
  }

  @override
  Future<void> markAsRead(String alertId) async {
    final all = await _loadAll();
    final updated = all.map((a) {
      if (a.id == alertId) {
        return a.copyWith(isRead: true);
      }
      return a;
    }).toList();
    await _persist(updated);
  }

  @override
  Future<void> markAllAsRead(String userId, {String? tournamentId}) async {
    final all = await _loadAll();
    final updated = all.map((a) {
      if (tournamentId != null && a.tournamentId != tournamentId) {
        return a;
      }
      return a.copyWith(isRead: true);
    }).toList();
    await _persist(updated);
  }

  @override
  Future<void> clearAlerts(String userId) async {
    await _persist([]);
  }

  void _sortAlerts(List<MatchLiveAlert> list) {
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<List<MatchLiveAlert>> _loadAll() async {
    try {
      final dynamic future = storage.readString(alertsStorageKey);
      final raw = future is Future ? await future : null;
      if (raw != null && raw.trim().isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(MatchLiveAlert.fromJson)
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<void> _persist(List<MatchLiveAlert> list) async {
    final jsonList = list.map((a) => a.toJson()).toList();
    await storage.writeString(alertsStorageKey, jsonEncode(jsonList));
    if (!_alertsStreamController.isClosed) {
      _alertsStreamController.add(list);
    }
  }
}
