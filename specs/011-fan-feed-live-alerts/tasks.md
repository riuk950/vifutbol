# Tasks: Feed de Noticias, Marcadores en Tiempo Real y Alertas de Partidos para Aficionados (HU 9.1)

**Input**: Design documents from `/specs/011-fan-feed-live-alerts/` (`spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`)  
**Prerequisites**: `spec.md`, `plan.md`, `data-model.md`, `contracts/`

---

## Phase 1: Setup (Shared Infrastructure & Localization)

**Purpose**: Localization strings and foundational setup

- [X] T001 Add localized strings for live matchday, news feed, favorite teams, and alerts tray in `lib/l10n/app_es.arb` and generate localization classes via `flutter gen-l10n`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core domain entities, enumerations, repository contracts, and notification service interfaces that all user stories depend on

**⚠️ CRITICAL**: Must complete before user story implementation can begin

- [X] T002 [P] Implement `TournamentNewsCategory` enum (`general`, `disciplinary`, `rescheduling`) in `lib/domain/entities/tournament_news_category.dart`
- [X] T003 [P] Implement `TournamentNewsItem` entity with validation rules (title: 3-120 chars, body: 5-3000 chars, `isPinned`, author metadata, JSON serialization) in `lib/domain/entities/tournament_news_item.dart`
- [X] T004 [P] Implement `FanFavoriteTeam` entity (`userId`, `tournamentId`, `teamId`, `teamName`, `notificationsEnabled` default true, `createdAt`, JSON serialization) in `lib/domain/entities/fan_favorite_team.dart`
- [X] T005 [P] Implement `MatchAlertType` enum (`matchUpcoming`, `matchStarted`, `goalScored`, `matchEnded`, `newsPublished`) in `lib/domain/entities/match_alert_type.dart`
- [X] T006 [P] Implement `MatchLiveAlert` entity (`id`, `matchId`, `tournamentId`, `type`, `title`, `message`, `timestamp`, `isRead` default false, `copyWith`, JSON serialization) in `lib/domain/entities/match_live_alert.dart`
- [X] T007 [P] Unit tests for fan feed entities, enums, and JSON serialization in `test/unit/domain/fan_feed_entities_test.dart`
- [X] T008 [P] Define `TournamentNewsRepository` contract in `lib/domain/repositories/tournament_news_repository.dart`
- [X] T009 [P] Define `FanFavoritesRepository` contract in `lib/domain/repositories/fan_favorites_repository.dart`
- [X] T010 [P] Define `MatchAlertsRepository` contract in `lib/domain/repositories/match_alerts_repository.dart`
- [X] T011 [P] Define `NotificationService` contract in `lib/domain/services/notification_service.dart`
- [X] T012 Extend `TournamentMatchesRepository` with `Stream<List<ChampionshipMatch>> watchMatchesForTournament(String tournamentId)` in `lib/domain/repositories/tournament_matches_repository.dart`

**Checkpoint**: Foundation ready - User Story 1, 2, and 3 implementation can proceed.

---

## Phase 3: User Story 1 - Marcadores en Vivo y Seguimiento en Tiempo Real (Priority: P1) 🎯 MVP

**Goal**: Permitir a aficionados y seguidores consultar partidos en juego con actualización reactiva inmediata (<100 ms) de marcadores y periodo, distintivo "EN VIVO" (`#EF4444`) y liberación limpia de suscripciones sin fugas de memoria.

**Independent Test**: Simular un gol o cambio de periodo en un partido `inProgress` y verificar que la tarjeta del partido se actualiza de inmediato con formato tabular (`tabular-nums`) y badge "EN VIVO" (`KickPulseColors.accentLive`), y que al salir de la pantalla se cancela la suscripción reactiva.

### Implementation for User Story 1

- [X] T013 [P] [US1] Unit test for reactive stream emissions in `test/unit/infrastructure/local_tournament_matches_repository_test.dart`
- [X] T014 [US1] Implement `watchMatchesForTournament` using broadcast `StreamController` in `lib/infrastructure/repositories/local_tournament_matches_repository.dart`
- [X] T015 [US1] Update `MatchesCatalogController` in `lib/application/controllers/matches_catalog_controller.dart` to subscribe to `watchMatchesForTournament` and cleanly cancel subscription on `dispose`
- [X] T016 [P] [US1] Update `MatchCard` in `lib/presentation/matches/widgets/match_card.dart` to render "EN VIVO" badge with `KickPulseColors.accentLive` (`#EF4444`) and `tabularFontFeatures` when `match.status == MatchStatus.inProgress`
- [X] T017 [US1] Add header segmented control ("Partidos" | "Noticias") in `lib/presentation/shell/tabs/matchday_tab_view.dart` and highlight live matches section
- [X] T018 [US1] Widget test for live matches card rendering, accentLive badge, tabular score updates, and unmount cleanup in `test/widget/live_matches_feed_widget_test.dart`

**Checkpoint**: User Story 1 (MVP) is fully functional and independently testable.

---

## Phase 4: User Story 2 - Feed de Noticias, Boletines Oficiales y Comunicados (Priority: P2)

**Goal**: Permitir al `Organizador` redactar, categorizar y eliminar comunicados oficiales, y a todos los roles consultar el feed cronológico con filtros por categoría y estados vacíos informativos.

**Independent Test**: Como `Organizador`, publicar un boletín disciplinario y verificar que aparece de inmediato en el feed con su categoría y fecha en español; luego cambiar a rol `Aficionado`, comprobar que no se muestran botones de creación ni borrado, y verificar el filtrado por categoría.

### Implementation for User Story 2

- [X] T019 [P] [US2] Implement `LocalTournamentNewsRepository` with local persistence (`vifutbol.tournament_news.v1`) and broadcast stream in `lib/infrastructure/repositories/local_tournament_news_repository.dart`
- [X] T020 [P] [US2] Implement `PublishTournamentNewsUseCase` and `DeleteTournamentNewsUseCase` with role-based validation in `lib/application/use_cases/manage_tournament_news_use_cases.dart`
- [X] T021 [P] [US2] Implement `TournamentNewsController` and providers in `lib/application/controllers/tournament_news_controller.dart` and `lib/application/providers/tournament_news_providers.dart`
- [X] T022 [P] [US2] Unit tests for news repository and use cases in `test/unit/application/tournament_news_use_cases_test.dart`
- [X] T023 [P] [US2] Implement `TournamentNewsCard` in `lib/presentation/news/widgets/tournament_news_card.dart` and `TournamentNewsFilterBar` in `lib/presentation/news/widgets/tournament_news_filter_bar.dart`
- [X] T024 [P] [US2] Implement `CreateNewsDialog` with validation in Spanish guarded for `UserRole.organizer` in `lib/presentation/news/widgets/create_news_dialog.dart`
- [X] T025 [US2] Implement `TournamentNewsFeedView` with category chips, empty state, and organizer action button in `lib/presentation/news/tournament_news_feed_view.dart`
- [X] T026 [US2] Embed `TournamentNewsFeedView` into the news segment of `lib/presentation/shell/tabs/matchday_tab_view.dart`
- [X] T027 [US2] Widget test for news feed view, category filters, organizer dialog, and empty state in `test/widget/tournament_news_feed_widget_test.dart`

**Checkpoint**: User Stories 1 and 2 are fully functional and independently testable.

---

## Phase 5: User Story 3 - Suscripción a Equipos Favoritos, Alertas y Navegación Profunda (Priority: P3)

**Goal**: Permitir al aficionado marcar equipos favoritos, recibir alertas clave (recordatorio 30 min, inicio, goles, final), consultar la bandeja interna desde el `AppBar` con contador de no leídos, y navegar por deep link al partido.

**Independent Test**: Marcar un equipo como favorito, simular una alerta de gol/resultado, verificar que el badge de la campana en el `AppBar` se actualiza, abrir la bandeja, verificar que al pulsar la alerta se marca como leída y abre el detalle del partido, y comprobar que si las notificaciones push del OS fueron denegadas la bandeja interna funciona con normalidad.

### Implementation for User Story 3

- [X] T028 [P] [US3] Implement `LocalFanFavoritesRepository` with persistence in `vifutbol.fan_favorites.v1` in `lib/infrastructure/repositories/local_fan_favorites_repository.dart`
- [X] T029 [P] [US3] Implement `LocalMatchAlertsRepository` with persistence in `vifutbol.match_alerts.v1` in `lib/infrastructure/repositories/local_match_alerts_repository.dart`
- [X] T030 [P] [US3] Implement `LocalNotificationService` with OS permission check and silent fallback to internal alert repository in `lib/infrastructure/services/local_notification_service.dart`
- [X] T031 [P] [US3] Implement `ToggleFanFavoriteTeamUseCase` and `DispatchMatchLiveAlertsUseCase` in `lib/application/use_cases/fan_favorites_and_alerts_use_cases.dart`
- [X] T032 [P] [US3] Implement `FanFavoritesController` and `FanAlertsTrayController` in `lib/application/controllers/fan_alerts_and_favorites_controllers.dart` and providers in `lib/application/providers/fan_alerts_and_favorites_providers.dart`
- [X] T033 [P] [US3] Unit tests for favorites toggling, alert dispatch, and notification service in `test/unit/application/fan_favorites_and_alerts_use_cases_test.dart`
- [X] T034 [P] [US3] Implement `FanAlertsBellAction` with unread counter badge in `lib/presentation/alerts/widgets/fan_alerts_bell_action.dart`
- [X] T035 [P] [US3] Implement `FanAlertsTraySheet` with "Marcar todo como leído", auto-mark read on tap, and deep link callback in `lib/presentation/alerts/widgets/fan_alerts_tray_sheet.dart`
- [X] T036 [US3] Integrate `FanAlertsBellAction` into `AppBar` in `lib/presentation/shell/app_shell_screen.dart` and wire deep linking to match details
- [X] T037 [US3] Widget test for favorite toggle, alerts bell badge, tray modal, and deep link navigation in `test/widget/fan_alerts_tray_widget_test.dart`

**Checkpoint**: All three User Stories are fully functional and independently testable.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Robustez móvil, verificación de directrices de diseño y análisis de calidad estática

- [X] T038 Verify 0 `RenderFlex` overflows at 320px width and 130% text scaling across live match cards, news cards, and alerts tray
- [X] T039 Execute full automated test suite (`flutter test`) and verify 0 analyzer issues (`flutter analyze`) and clean formatting (`dart format`)
- [X] T040 Execute end-to-end quickstart validation guide in `specs/011-fan-feed-live-alerts/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies
- **Phase 1 (Setup)**: Inicia de inmediato.
- **Phase 2 (Foundational)**: Depende de Phase 1. Bloquea las historias de usuario.
- **Phase 3 (User Story 1 - MVP)**: Depende de Phase 2. No depende de US2 ni US3.
- **Phase 4 (User Story 2)**: Depende de Phase 2. Se integra en la vista segmentada de Jornada.
- **Phase 5 (User Story 3)**: Depende de Phase 2 y consume partidos/noticias de US1 y US2.
- **Phase 6 (Polish)**: Depende de completar las historias de usuario.

### Parallel Opportunities
- Setup & Foundational: T002 a T011 pueden ejecutarse en paralelo por tratarse de archivos desacoplados.
- User Story 1: T013 y T016 pueden avanzar en paralelo antes de la integración en T017.
- User Story 2: T019, T020, T021, T023 y T024 pueden desarrollarse en paralelo.
- User Story 3: T028, T029, T030, T031, T034 y T035 pueden desarrollarse en paralelo.

---

## Implementation Strategy

### MVP First (User Story 1 Only)
1. Completar Setup (T001).
2. Completar Foundational (T002 - T012).
3. Completar User Story 1 (T013 - T018).
4. **Validar MVP**: Partidos en vivo con actualización reactiva y distintivo "EN VIVO" operando.

### Incremental Delivery
1. Foundation + US1 (MVP): Marcadores en vivo.
2. US2: Feed de noticias oficiales y boletines con control segmentado.
3. US3: Equipos favoritos, alertas automáticas, campana en AppBar y deep linking.
4. Polish: Validación a 320px, 130% texto, análisis estático y pruebas completas.
