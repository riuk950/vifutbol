import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';

/// StateNotifier controlling reactive top banner visibility based on connectivity (FR-007).
class ConnectivityBannerController
    extends StateNotifier<ConnectivityBannerState> {
  final ConnectivityRepository _repository;
  StreamSubscription<NetworkConnectionStatus>? _subscription;
  Timer? _restoredTimer;

  ConnectivityBannerController(this._repository)
    : super(const ConnectivityBannerState.initial()) {
    _init();
  }

  void _init() {
    _subscription = _repository.onConnectivityChanged.listen(
      _handleStatusChange,
    );
  }

  void _handleStatusChange(NetworkConnectionStatus newStatus) {
    if (newStatus == NetworkConnectionStatus.disconnected) {
      _restoredTimer?.cancel();
      _restoredTimer = null;
      state = state.copyWith(
        status: newStatus,
        visibility: ConnectivityBannerVisibility.offline,
      );
    } else if (newStatus == NetworkConnectionStatus.connected) {
      if (state.status == NetworkConnectionStatus.disconnected) {
        // Recovered connection: show green restored banner for 3 seconds
        _restoredTimer?.cancel();
        state = state.copyWith(
          status: newStatus,
          visibility: ConnectivityBannerVisibility.restored,
        );

        _restoredTimer = Timer(const Duration(seconds: 3), () {
          if (mounted &&
              state.visibility == ConnectivityBannerVisibility.restored) {
            state = state.copyWith(
              visibility: ConnectivityBannerVisibility.hidden,
            );
          }
        });
      } else {
        // Already connected, stay hidden
        state = state.copyWith(
          status: newStatus,
          visibility: ConnectivityBannerVisibility.hidden,
        );
      }
    }
  }

  @override
  void dispose() {
    _restoredTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider for reactive connectivity banner state.
final connectivityBannerControllerProvider =
    StateNotifierProvider<
      ConnectivityBannerController,
      ConnectivityBannerState
    >((ref) {
      final repo = ref.watch(connectivityRepositoryProvider);
      return ConnectivityBannerController(repo);
    });
