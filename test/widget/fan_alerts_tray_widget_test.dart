import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/app_shell_controller.dart';
import 'package:vifutbol/application/controllers/fan_alerts_and_favorites_controllers.dart';
import 'package:vifutbol/application/providers/fan_alerts_and_favorites_providers.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_alert_type.dart';
import 'package:vifutbol/domain/entities/match_live_alert.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_match_alerts_repository.dart';
import 'package:vifutbol/infrastructure/services/local_notification_service.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/alerts/widgets/fan_alerts_bell_action.dart';
import 'package:vifutbol/presentation/alerts/widgets/fan_alerts_tray_sheet.dart';

class _MockAlertsStorage implements LocalStorageRepository {
  final Map<String, String> _data = {};

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);

  @override
  Future<String?> readString(String key) async => _data[key];

  @override
  Future<void> writeString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> clearNamespace() async => _data.clear();

  @override
  bool get isUsingFallbackMemory => true;
}

void main() {
  testWidgets('Fan alerts bell displays unread badge and opens tray sheet', (
    tester,
  ) async {
    final storage = _MockAlertsStorage();
    final alertsRepo = LocalMatchAlertsRepository(storage: storage);
    final notifService = LocalNotificationService(
      storage: storage,
      alertsRepository: alertsRepo,
    );

    final alert1 = MatchLiveAlert(
      id: 'alert-1',
      matchId: 'match-101',
      tournamentId: 'tourn-1',
      type: MatchAlertType.goalScored,
      title: '¡Gol de Alpha FC!',
      message: 'Gol de Alpha FC al minuto 25.',
      timestamp: DateTime(2026, 11, 5, 10, 0),
      isRead: false,
    );

    final alert2 = MatchLiveAlert(
      id: 'alert-2',
      matchId: 'match-102',
      tournamentId: 'tourn-1',
      type: MatchAlertType.matchUpcoming,
      title: 'Próximo partido en 30 minutos',
      message: 'Alpha FC vs Beta FC en Cancha 1.',
      timestamp: DateTime(2026, 11, 5, 9, 30),
      isRead: false,
    );

    await alertsRepo.saveAlert(alert1);
    await alertsRepo.saveAlert(alert2);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          matchAlertsRepositoryProvider.overrideWithValue(alertsRepo),
          notificationServiceProvider.overrideWithValue(notifService),
          fanAlertsTrayControllerProvider.overrideWith(
            (ref) => FanAlertsTrayController(
              alertsRepository: alertsRepo,
              notificationService: notifService,
            ),
          ),
          appShellControllerProvider.overrideWith(
            (ref) => AppShellController(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('es'),
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(56),
              child: SafeArea(child: FanAlertsBellAction(userId: 'test-user')),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify unread badge shows '2'
    expect(find.text('2'), findsOneWidget);

    // Tap bell button to open modal tray
    await tester.tap(find.byKey(const Key('fan_alerts_bell_button')));
    await tester.pumpAndSettle();

    // Verify Tray Sheet opened
    expect(find.byType(FanAlertsTraySheet), findsOneWidget);
    expect(find.text('Bandeja de Alertas'), findsOneWidget);
    expect(find.text('¡Gol de Alpha FC!'), findsOneWidget);
    expect(find.text('Próximo partido en 30 minutos'), findsOneWidget);

    // Tap "Marcar todo como leído"
    expect(
      find.byKey(const Key('mark_all_alerts_read_button')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('mark_all_alerts_read_button')));
    await tester.pumpAndSettle();

    // Close sheet
    Navigator.of(tester.element(find.byType(FanAlertsTraySheet))).pop();
    await tester.pumpAndSettle();

    // Badge should disappear (unread is 0)
    expect(find.text('2'), findsNothing);
  });

  testWidgets(
    'Fan alerts tray displays fallback notice when OS push permission denied',
    (tester) async {
      final storage = _MockAlertsStorage();
      final alertsRepo = LocalMatchAlertsRepository(storage: storage);
      final notifService = LocalNotificationService(
        storage: storage,
        alertsRepository: alertsRepo,
      );
      await notifService.revokePermission();

      final controller = FanAlertsTrayController(
        alertsRepository: alertsRepo,
        notificationService: notifService,
      );
      await controller.init('test-user');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchAlertsRepositoryProvider.overrideWithValue(alertsRepo),
            notificationServiceProvider.overrideWithValue(notifService),
            fanAlertsTrayControllerProvider.overrideWith((ref) => controller),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('es'),
            home: Scaffold(body: FanAlertsTraySheet(userId: 'test-user')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify warning banner without blocking UI
      expect(
        find.text(
          'Notificaciones del sistema desactivadas. Puedes consultar todas las alertas en esta bandeja.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('No tienes alertas o notificaciones pendientes.'),
        findsOneWidget,
      );
    },
  );
}
