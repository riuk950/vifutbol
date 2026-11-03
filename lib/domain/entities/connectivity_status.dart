/// Device network status.
enum NetworkConnectionStatus {
  connected,
  disconnected;

  /// Whether the device has active network connection.
  bool get isConnected => this == NetworkConnectionStatus.connected;

  /// Whether the device is offline.
  bool get isDisconnected => this == NetworkConnectionStatus.disconnected;
}

/// Reactive visibility state of the top connectivity banner.
enum ConnectivityBannerVisibility { hidden, offline, restored }

/// Composite state representing network connectivity and banner visibility.
class ConnectivityBannerState {
  final NetworkConnectionStatus status;
  final ConnectivityBannerVisibility visibility;

  const ConnectivityBannerState({
    required this.status,
    required this.visibility,
  });

  const ConnectivityBannerState.initial()
    : status = NetworkConnectionStatus.connected,
      visibility = ConnectivityBannerVisibility.hidden;

  ConnectivityBannerState copyWith({
    NetworkConnectionStatus? status,
    ConnectivityBannerVisibility? visibility,
  }) {
    return ConnectivityBannerState(
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectivityBannerState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          visibility == other.visibility;

  @override
  int get hashCode => Object.hash(status, visibility);

  @override
  String toString() =>
      'ConnectivityBannerState(status: $status, visibility: $visibility)';
}
