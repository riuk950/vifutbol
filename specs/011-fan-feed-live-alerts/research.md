# Research: Feed de Noticias, Marcadores en Tiempo Real y Alertas para Aficionados (HU 9.1)

**Feature Branch**: `011-fan-feed-live-alerts`  
**Date**: 2026-11-05  
**Spec Reference**: [`specs/011-fan-feed-live-alerts/spec.md`](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/011-fan-feed-live-alerts/spec.md)

---

## 1. Contexto y Objetivos Técnicos

La HU 9.1 introduce la experiencia en vivo y de información oficial para aficionados y seguidores de los torneos en `vifutbol`. Comprende tres componentes principales:
1. **Marcadores en vivo reactivos**: Visualización de partidos en juego con actualización inmediata de marcadores, insignias semánticas (`KickPulseColors.accentLive` `#EF4444`) y números con espaciado monoespaciado/tabular (`tabular-nums`) para evitar saltos visuales durante los cambios de marcador y tiempo.
2. **Feed de noticias y comunicados**: Publicación, categorización (`general`, `disciplinary`, `rescheduling`) y eliminación de comunicados oficiales por parte del organizador, con filtros por categoría y estado vacío informativo para aficionados.
3. **Equipos favoritos y alertas de partidos**: Suscripción a equipos favoritos con un interruptor global de alertas clave (recordatorio 30 min, inicio, goles y pitazo final), bandeja interna de alertas con contador en el `AppBar`, deep linking al detalle del partido y fallback sin bloqueos ante permisos push denegados.

---

## 2. Decisiones Técnicas y Arquitectónicas

### Decisión 1: Sincronización y Reactividad de Partidos en Vivo (Stream vs Polling)

- **Decisión**: Extender `TournamentMatchesRepository` con flujos reactivos basados en `Stream<List<ChampionshipMatch>> watchMatchesForTournament(String tournamentId)` respaldados por un `StreamController.broadcast()` en `LocalTournamentMatchesRepository`. El controlador `MatchesCatalogController` y los widgets correspondientes consumen el stream y liberan la suscripción automáticamente en `ref.onDispose` o `dispose()`.
- **Racional**:
  - Garantiza actualización en menos de 100 ms tras cualquier evento registrado localmente (goles, actas arbitrales, cambios de estado).
  - Cero consumo de batería o bucles de sondeo (*polling*) innecesarios.
  - Plenamente alineado con la arquitectura Offline-First y el Principio IV de la Constitución.
- **Alternativas descartadas**:
  - *Timer-based Polling*: Descartado por consumo continuo de CPU/batería y retrasos inherentes entre ciclos de consulta.
  - *EventBus Global no tipado*: Descartado por dificultar la trazabilidad y pruebas unitarias aisladas.

---

### Decisión 2: Desacoplamiento de Alertas y Notificaciones (Push OS + Bandeja Interna)

- **Decisión**: Implementar una arquitectura de alertas en dos capas:
  1. `MatchAlertsRepository` para la persistencia local de alertas recibidas (`MatchLiveAlert`) en `LocalStorageRepository`.
  2. `NotificationService` en la capa de infraestructura con una implementación `LocalNotificationService` que comprueba permisos de notificaciones del sistema operativo. Si están concedidos, emite la notificación al sistema; si están denegados o se revocan, persiste la alerta silenciosamente en la bandeja interna sin mostrar diálogos bloqueantes ni generar excepciones.
- **Racional**:
  - Cumple el criterio de aceptación de no degradar la experiencia ni bloquear al aficionado si deniega permisos del sistema operativo.
  - Permite pruebas unitarias y de widgets reproducibles y deterministas simulando el servicio de notificaciones.
- **Alternativas descartadas**:
  - *Dependencia directa y obligatoria de Firebase Cloud Messaging*: Incompatible con modo offline y dificulta la ejecución de pruebas sin emuladores con Google Play Services activos.

---

### Decisión 3: Ubicación en Shell Móvil y Cumplimiento de `MOBILE_GUIDELINES.md`

- **Decisión**:
  1. Mantener las 4 pestañas actuales de navegación inferior en `AppShellScreen` (Jornada, Posiciones, Sedes, Perfil), permaneciendo estrictamente por debajo del límite de 5 pestañas.
  2. Agregar un botón de campana en el `AppBar` superior (`FanAlertsBellAction`) con un distintivo numérico (*badge*) de alertas no leídas para abrir un panel o diálogo modal (`FanAlertsTraySheet`).
  3. En la cabecera de la pestaña Jornada (`MatchdayTabView`), incorporar un control segmentado estilizado con KickPulse Design System para alternar entre "Partidos" y "Noticias del Torneo".
- **Racional**:
  - Evita saturar la barra de navegación inferior.
  - Mantiene al aficionado en el contexto de su torneo seleccionado.
- **Alternativas descartadas**:
  - *Quinta pestaña inferior para noticias*: Restaría espacio visual en dispositivos compactos y fragmentaría la relación entre partidos y comunicados del torneo.

---

### Decisión 4: Segregación de Roles para Creación y Borrado de Noticias

- **Decisión**: El botón de acción para redactar noticias ("+ Nueva Noticia") y las opciones de borrado se renderizan de forma condicional evaluando `activeUserRoleProvider == UserRole.organizer`. Adicionalmente, el caso de uso `PublishTournamentNewsUseCase` y `DeleteTournamentNewsUseCase` verifican la autorización del rol antes de invocar el repositorio.
- **Racional**:
  - Cumple estrictamente el Principio V de la Constitución (*Segregación de Roles y Fidelidad al Sistema de Diseño*).
  - Garantiza protección en la capa de presentación y en la capa de aplicación.

---

### Decisión 5: Navegación Profunda (*Deep Linking*) a Partidos

- **Decisión**: Al pulsar una alerta de partido en la bandeja interna o en una notificación del sistema, el callback extrae el `matchId` y `tournamentId`, conmuta la sección activa del shell a `AppShellSection.matchday`, carga el partido objetivo y abre el diálogo/pantalla de detalle del partido (`MatchDetailsDialog` / vista de partido).
- **Racional**:
  - Flujo fluido sin recargas de pantalla completas ni desincronización de estado.
  - Marca automáticamente la alerta como leída (`isRead = true`).

---

## 3. Matriz de Cumplimiento de Principios de la Constitución

| Principio | Estado | Justificación técnica |
|-----------|--------|-----------------------|
| **I. La Spec Manda** | **OK** | Todo el diseño se deriva de `spec.md` (HU 9.1) y las clarificaciones acordadas en la sesión `2026-11-05`. |
| **II. Integridad de Datos** | **OK** | Identificadores únicos (`id`), relaciones consistentes entre torneo, equipo, noticia y alerta, y cálculo determinista. |
| **III. Pruebas Automatizadas** | **OK** | Cobertura integral con pruebas unitarias para entidades, servicios, casos de uso y repositorios, más pruebas de widgets para la UI en vivo, noticias y bandeja. |
| **IV. Arquitectura Limpia** | **OK** | Entidades y contratos abstractos en `domain/`, lógica de negocio en `application/`, componentes visuales en `presentation/`, adaptadores de almacenamiento en `infrastructure/`. |
| **V. Segregación de Roles** | **OK** | Solo `UserRole.organizer` puede publicar o eliminar comunicados; aficionados y otros roles tienen acceso de solo lectura al feed y favoritos. |
| **VI. Convenciones de Idioma** | **OK** | Código técnico, entidades, clases y pruebas en inglés; todos los textos visibles de UI en español en `lib/l10n/app_es.arb`. |
| **VII. Resiliencia y Experiencia Móvil** | **OK** | Manejo de desconexión sin bloquear UI, adaptación a pantallas desde 320px, 0 RenderFlex overflows con escalado a 130% y liberación garantizada de recursos. |
