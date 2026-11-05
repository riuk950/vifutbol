# Implementation Plan: Feed de Noticias, Marcadores en Tiempo Real y Alertas de Partidos para Aficionados (HU 9.1)

**Branch**: `011-fan-feed-live-alerts` | **Date**: 2026-11-05 | **Spec**: [`specs/011-fan-feed-live-alerts/spec.md`](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/011-fan-feed-live-alerts/spec.md)

---

## Summary

La HU 9.1 implementa el ecosistema de seguimiento en vivo y comunicación oficial para aficionados y seguidores de torneos en `vifutbol`. Integra marcadores reactivos en tiempo real con indicador semántico `Accent Live` (`#EF4444`) e intervalos con tipografía tabular, un feed oficial de noticias y comunicados con segregación estricta de roles para publicación y borrado por el `Organizador`, y un sistema de suscripción a equipos favoritos con despacho de alertas clave (recordatorio 30 min, inicio, goles y pitazo final), bandeja interna accesible desde la barra superior (`AppBar`) y enlace profundo (*deep linking*) hacia el detalle de los partidos.

---

## Technical Context

**Language/Version**: Dart 3.5+ / Flutter 3.24+  
**Primary Dependencies**: `flutter_riverpod: ^2.5.1`, `intl: ^0.19.0`, `uuid: ^4.5.1` (o generación de ID determinista), `shared_preferences` (a través de `LocalStorageRepository`)  
**Storage**: `LocalStorageRepository` persistiendo colecciones JSON locales offline-first (`vifutbol.tournament_news.v1`, `vifutbol.fan_favorites.v1`, `vifutbol.match_alerts.v1`)  
**Testing**: `flutter_test` (unit, use case, state notifier, y widget tests)  
**Target Platform**: Android y iOS (Mobile first, pantalla desde 320px de ancho)  
**Project Type**: Mobile Application (Clean Architecture + Riverpod)  
**Performance Goals**: Latencia de actualización reactiva < 100 ms ante eventos locales, 60 fps en transiciones de lista, 0 ms de espera percibida al consultar datos cacheados sin red  
**Constraints**: 0 RenderFlex overflows con escalado de texto al 130%, máximo estricto de 5 pestañas en la barra de navegación inferior (`MOBILE_GUIDELINES.md`), 0 fugas de memoria al desmontar vistas o pausar app  
**Scale/Scope**: Múltiples torneos, decenas de equipos favoritos por usuario, cientos de comunicados y alertas históricas ordenadas cronológicamente  

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. La Spec Manda**: Alcance, historias de usuario y clarificaciones aprobadas en `spec.md` (`Session 2026-11-05`).
- [x] **II. Integridad de Datos**: Relaciones consistentes con llaves primarias únicas (`TournamentNewsItem`, `FanFavoriteTeam`, `MatchLiveAlert`), consistencia offline y cálculo determinista.
- [x] **III. Pruebas Automatizadas**: Plan de pruebas unitarias para entidades, casos de uso y repositorios, y pruebas de widgets para renderizado en vivo y bandeja de alertas.
- [x] **IV. Arquitectura Limpia**: Separación estricta entre capas (Dominio, Infraestructura, Aplicación, Presentación). Cero acoplamiento de la capa de dominio a detalles de UI o frameworks de red.
- [x] **V. Segregación de Roles**: Solo `Organizador` puede crear o eliminar noticias; aficionados y otros roles acceden en modo consulta y gestión de sus favoritos personales.
- [x] **VI. Convenciones de Idioma**: Código, métodos, clases y pruebas 100% en inglés; todos los textos visibles en español centralizados en `lib/l10n/app_es.arb`.
- [x] **VII. Resiliencia Móvil**: Soporte offline transparente, fallback elegante ante rechazo de notificaciones push, adaptación desde 320px y liberación automática de recursos en `dispose()`.

---

## Project Structure

### Documentation (this feature)

```text
specs/011-fan-feed-live-alerts/
├── plan.md              # Este plan de implementación
├── research.md          # Decisiones arquitectónicas y alternativas evaluadas (Fase 0)
├── data-model.md        # Entidades, esquemas JSON y relaciones del dominio (Fase 1)
├── quickstart.md        # Guía de validación y comandos ejecutables (Fase 1)
├── contracts/           # Contratos e interfaces abstractas (Fase 1)
│   ├── news_repository_contract.md
│   ├── favorites_and_alerts_contract.md
│   └── live_matches_stream_contract.md
└── tasks.md             # Tareas ordenadas y accionables (/speckit-tasks)
```

### Source Code (concrete layout)

```text
lib/
├── domain/
│   ├── entities/
│   │   ├── tournament_news_item.dart         # Entidad de noticia/comunicado
│   │   ├── tournament_news_category.dart     # Enum de categorías de noticias
│   │   ├── fan_favorite_team.dart            # Entidad de equipo favorito
│   │   ├── match_live_alert.dart             # Entidad de alerta de partido
│   │   └── match_alert_type.dart             # Enum de tipos de alertas
│   ├── repositories/
│   │   ├── tournament_news_repository.dart    # Contrato abstracto de noticias
│   │   ├── fan_favorites_repository.dart      # Contrato abstracto de favoritos
│   │   ├── match_alerts_repository.dart       # Contrato abstracto de alertas
│   │   └── tournament_matches_repository.dart # Extensión con watchMatchesForTournament
│   └── services/
│       └── notification_service.dart          # Abstracción de despacho de notificaciones
├── infrastructure/
│   ├── repositories/
│   │   ├── local_tournament_news_repository.dart
│   │   ├── local_fan_favorites_repository.dart
│   │   ├── local_match_alerts_repository.dart
│   │   └── local_tournament_matches_repository.dart # Emisión en watchMatchesForTournament
│   └── services/
│       └── local_notification_service.dart    # Implementación con fallback a bandeja interna
├── application/
│   ├── controllers/
│   │   ├── matches_catalog_controller.dart     # Suscripción a stream de partidos en vivo
│   │   ├── tournament_news_controller.dart     # Gestión de estado del feed de noticias
│   │   ├── fan_favorites_controller.dart       # Gestión de favoritos del aficionado
│   │   └── fan_alerts_tray_controller.dart     # Gestión de bandeja interna y contador AppBar
│   ├── providers/
│   │   ├── tournament_news_providers.dart      # Inyección de dependencias Riverpod
│   │   └── fan_alerts_and_favorites_providers.dart
│   └── use_cases/
│       ├── publish_tournament_news_use_case.dart
│       ├── delete_tournament_news_use_case.dart
│       ├── toggle_fan_favorite_team_use_case.dart
│       └── dispatch_match_live_alerts_use_case.dart
├── presentation/
│   ├── shell/
│   │   ├── app_shell_screen.dart               # Incorporación de FanAlertsBellAction en AppBar
│   │   └── tabs/
│   │       └── matchday_tab_view.dart          # Control segmentado ("Partidos" | "Noticias")
│   ├── matches/
│   │   └── widgets/
│   │       └── match_card.dart                 # Insignia "EN VIVO" (#EF4444) y tabular-nums
│   ├── news/
│   │   ├── widgets/
│   │   │   ├── tournament_news_card.dart       # Tarjeta de comunicado oficial
│   │   │   ├── tournament_news_filter_bar.dart # Filtros por categoría
│   │   │   └── create_news_dialog.dart         # Formulario modal exclusivo para Organizador
│   │   └── tournament_news_feed_view.dart      # Vista del feed de noticias
│   └── alerts/
│       └── widgets/
│           ├── fan_alerts_bell_action.dart     # Botón campana con badge en AppBar
│           └── fan_alerts_tray_sheet.dart      # Bandeja modal de notificaciones con deep link
└── l10n/
    └── app_es.arb                             # Textos localizados en español
```

---

## Architecture and Design Overview

1. **Streaming Reactivo de Partidos**:
   - `TournamentMatchesRepository` expone `watchMatchesForTournament(tournamentId)`.
   - `LocalTournamentMatchesRepository` utiliza un `StreamController<List<ChampionshipMatch>>.broadcast()`.
   - Ante llamadas a `saveMatch` o `saveMatchesBatch`, se emite la lista actualizada inmediatamente (<100 ms).
   - En `MatchdayTabView` / `MatchesCatalogController`, la suscripción se cancela automáticamente al salir de pantalla (`ref.onDispose`).
   - Las tarjetas de partido renderizan la insignia "EN VIVO" con `KickPulseColors.accentLive` (`#EF4444`) cuando `status == MatchStatus.inProgress`.

2. **Feed de Noticias Oficiales**:
   - `TournamentNewsRepository` almacena noticias con orden cronológico (`publishedAt` descendente).
   - `TournamentNewsController` mantiene el estado con filtros reactivos (`categoryFilter`).
   - `PublishTournamentNewsUseCase` valida permisos (`userRole == UserRole.organizer`) antes de persistir.
   - Si no hay noticias, muestra un estado vacío informativo centralizado en `app_es.arb`.

3. **Favoritos, Alertas y Enlace Profundo (*Deep Linking*)**:
   - El aficionado marca equipos favoritos; las alertas se activan por defecto con switch global.
   - `DispatchMatchLiveAlertsUseCase` emite alertas ante proximidad (30 min), inicio, goles y pitazo final.
   - Si las notificaciones push del OS están denegadas, `NotificationService` guarda silenciosamente la alerta en `MatchAlertsRepository`.
   - `FanAlertsBellAction` muestra el conteo de no leídas en el `AppBar`.
   - Al tocar una alerta en `FanAlertsTraySheet`:
     1. Marca la alerta como leída (`isRead = true`).
     2. Cambia el tab activo a `AppShellSection.matchday`.
     3. Abre el diálogo/vista detallada del partido correspondiente.

---

## Plan Phases

### Phase 0: Outline & Research
- Resolución de incógnitas técnicas sobre reactividad, diseño de alertas y navegación profunda en [`research.md`](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/011-fan-feed-live-alerts/research.md).

### Phase 1: Design & Contracts
- Definición de entidades, enumeraciones y diagramas en [`data-model.md`](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/011-fan-feed-live-alerts/data-model.md).
- Especificación formal de interfaces en [`contracts/`](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/011-fan-feed-live-alerts/contracts/).
- Guía de validación y escenarios ejecutables en [`quickstart.md`](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/011-fan-feed-live-alerts/quickstart.md).

### Phase 2: Tasks Deconstruction (Next Command)
- Generación del archivo accionable `tasks.md` mediante `/speckit-tasks` con dependencias ordenadas y trazabilidad a los requisitos funcionales FR-001 a FR-012.
