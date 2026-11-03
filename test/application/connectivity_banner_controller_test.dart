import 'dart:async';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/connectivity_banner_controller.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';

class MockConnectivityRepository implements ConnectivityRepository {
  final StreamController<NetworkConnectionStatus> _controller =
      StreamController<NetworkConnectionStatus>.broadcast(sync: true);
  NetworkConnectionStatus _current = NetworkConnectionStatus.connected;

  void emit(NetworkConnectionStatus status) {
    _current = status;
    _controller.add(status);
  }

  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged =>
      _controller.stream;

  @override
  Future<NetworkConnectionStatus> checkConnectivity() async => _current;

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('ConnectivityBannerController State Transitions', () {
    test('initializes with connected status and hidden banner', () {
      final repo = MockConnectivityRepository();
      final controller = ConnectivityBannerController(repo);

      expect(controller.state.status, NetworkConnectionStatus.connected);
      expect(controller.state.visibility, ConnectivityBannerVisibility.hidden);

      controller.dispose();
      repo.dispose();
    });

    test('transitions to offline persistent banner when network is lost', () {
      final repo = MockConnectivityRepository();
      final controller = ConnectivityBannerController(repo);

      repo.emit(NetworkConnectionStatus.disconnected);

      expect(controller.state.status, NetworkConnectionStatus.disconnected);
      expect(controller.state.visibility, ConnectivityBannerVisibility.offline);

      controller.dispose();
      repo.dispose();
    });

    test(
      'shows restored banner for exactly 3 seconds upon reconnecting, then hides',
      () {
        fakeAsync((async) {
          final repo = MockConnectivityRepository();
          final controller = ConnectivityBannerController(repo);

          // Network goes down
          repo.emit(NetworkConnectionStatus.disconnected);
          async.flushMicrotasks();
          expect(
            controller.state.visibility,
            ConnectivityBannerVisibility.offline,
          );

          // Network restored
          repo.emit(NetworkConnectionStatus.connected);
          async.flushMicrotasks();
          expect(controller.state.status, NetworkConnectionStatus.connected);
          expect(
            controller.state.visibility,
            ConnectivityBannerVisibility.restored,
          );

          // Elapse 2.9 seconds - should still be restored
          async.elapse(const Duration(milliseconds: 2900));
          expect(
            controller.state.visibility,
            ConnectivityBannerVisibility.restored,
          );

          // Elapse remaining 100ms - should auto-hide
          async.elapse(const Duration(milliseconds: 100));
          expect(
            controller.state.visibility,
            ConnectivityBannerVisibility.hidden,
          );

          controller.dispose();
          repo.dispose();
        });
      },
    );

    test(
      'cancels auto-hide timer if connection is lost again before 3 seconds',
      () {
        fakeAsync((async) {
          final repo = MockConnectivityRepository();
          final controller = ConnectivityBannerController(repo);

          repo.emit(NetworkConnectionStatus.disconnected);
          async.flushMicrotasks();

          repo.emit(NetworkConnectionStatus.connected);
          async.flushMicrotasks();
          expect(
            controller.state.visibility,
            ConnectivityBannerVisibility.restored,
          );

          // Lost again after 1 second
          async.elapse(const Duration(seconds: 1));
          repo.emit(NetworkConnectionStatus.disconnected);
          async.flushMicrotasks();
          expect(
            controller.state.visibility,
            ConnectivityBannerVisibility.offline,
          );

          // Elapse another 3 seconds - should stay offline, not turn hidden
          async.elapse(const Duration(seconds: 3));
          expect(
            controller.state.visibility,
            ConnectivityBannerVisibility.offline,
          );

          controller.dispose();
          repo.dispose();
        });
      },
    );
  });
}
