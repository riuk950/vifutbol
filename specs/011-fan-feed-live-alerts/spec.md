# Feature Specification: Feed de Noticias, Marcadores en Tiempo Real y Alertas para Aficionados (HU 9.1)

**Feature Branch**: `011-fan-feed-live-alerts`

**Created**: 2026-11-05

**Status**: Draft

**Input**: User description: "en notion HU 9.1 en curso" (Notion Page ID: `4078442e-3f49-8148-8bd5-dd557db85e34`: "[Épica 9] HU 9.1: Feed de Noticias, Marcadores en Tiempo Real y Alertas de Partidos para Aficionados")

---

## Clarifications

### Session 2026-11-05

- Q: ¿Dónde deben ubicarse en la interfaz móvil el Feed de Noticias y el acceso a la Bandeja de Alertas para respetar el límite estricto de 5 pestañas inferiores? → A: Icono de campana en la barra superior (`AppBar`) con contador de no leídos para abrir la bandeja interna de alertas, y control segmentado ("Partidos" / "Noticias") en la cabecera de la jornada/torneo para alternar entre marcadores y noticias sin exceder las 5 pestañas inferiores.
- Q: ¿Qué nivel de granularidad y configuración de eventos deben tener las alertas de los equipos favoritos para los aficionados? → A: Conjunto predeterminado de eventos clave de alto impacto (recordatorio 30 minutos antes del inicio, inicio de encuentro, goles en tiempo real y pitazo final con resultado), activables/desactivables por equipo mediante un único interruptor general (`notificationsEnabled`).
- Q: ¿Qué mecanismo de reactividad y sincronización debe emplear el controlador de la jornada para reflejar los marcadores en vivo sin fugas de memoria? → A: Flujo reactivo desacoplado en el repositorio (`Stream<List<TournamentMatch>>`) consumido por el controlador de la jornada con cancelación automática de suscripción al desmontar la vista (`ref.onDispose` / `dispose`).
- Q: ¿Cómo debe gestionarse el estado de lectura (`isRead`) de las alertas en la bandeja interna al interactuar con ellas? → A: Marcar automáticamente como leída la alerta individual al ser pulsada para abrir su detalle (`isRead = true`), con un botón de acción en la cabecera de la bandeja interna para "Marcar todo como leído" de forma instantánea.
- Q: ¿Cómo debe presentarse la experiencia de creación y eliminación de noticias para el rol `Organizador` dentro del Feed de Noticias? → A: Botón de acción de publicación visible exclusivamente para usuarios con rol `Organizador` dentro del feed para abrir el formulario modal de redacción, y opción de borrado contextual en cada tarjeta de noticia garantizando segregación estricta de roles.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Marcadores en Vivo y Seguimiento en Tiempo Real de Partidos en Juego (Priority: P1) 🎯 MVP

Como `Aficionado` (o cualquier usuario que consulta la jornada), quiero seguir los partidos que están `En Juego` con actualización inmediata de marcador y periodo sin necesidad de recargar la pantalla manualmente, visualizando el distintivo en vivo con semántica visual `Accent Live` (`#EF4444`) y eventos clave destacados al instante, para vivir la emoción del campeonato en tiempo real.

**Why this priority**: Es la propuesta de valor fundamental para la experiencia del aficionado durante el transcurso de los partidos, conectando la captura en vivo del árbitro (HU 7.1) con la audiencia del torneo.

**Independent Test**: Simular o registrar eventos de gol o cambio de periodo en un partido en juego desde el acta digital arbitral y verificar que en la vista del aficionado la tarjeta del partido refleja el nuevo marcador de forma reactiva en menos de 100 ms, con la insignia "EN VIVO" (`#EF4444`) y sin desbordamientos de pantalla.

**Acceptance Scenarios**:

1. **Given** un aficionado visualizando la jornada de partidos de un campeonato, **When** un partido pasa a estado `En Juego` (`MatchStatus.inProgress`), **Then** la tarjeta del partido se destaca en la sección en vivo con la insignia semántica "EN VIVO" en color `Accent Live` (`#EF4444`) y el tiempo transcurrido o periodo actual.
2. **Given** un partido en juego con marcador `1 - 0`, **When** el árbitro registra un nuevo gol para el equipo visitante, **Then** el marcador de la tarjeta del partido se actualiza de forma reactiva e inmediata a `1 - 1` con formato tabular (`tabular-nums`) sin que el usuario deba realizar recarga manual ni cambiar de pestaña.
3. **Given** que el usuario abandona la vista de partidos o envía la aplicación a segundo plano, **When** se desmonta la pantalla, **Then** el sistema libera de inmediato las suscripciones y temporizadores en tiempo real para evitar consumos innecesarios de memoria y batería.

---

### User Story 2 - Feed de Noticias, Boletines Oficiales y Comunicados del Campeonato (Priority: P2)

Como `Aficionado`, `Entrenador` o `Jugador`, quiero acceder a un feed cronológico de noticias, boletines disciplinarios y avisos de reprogramación publicados por el `Organizador`, con filtros por categoría o torneo, para estar enterado oportunamente de las decisiones, comunicados y novedades del campeonato.

**Why this priority**: Garantiza la transparencia y comunicación oficial entre el comité organizador y todos los clubes, familias y aficionados del torneo barrial o metropolitano.

**Independent Test**: Iniciar sesión como `Organizador`, crear y publicar una noticia con título, cuerpo y categoría (boletín disciplinario o reprogramación); luego ingresar con rol `Aficionado` al feed de noticias y comprobar que la publicación aparece ordenada cronológicamente con su fecha, etiqueta de categoría y contenido formateado en español.

**Acceptance Scenarios**:

1. **Given** un usuario con rol `Organizador` en el módulo de torneos, **When** redacta y publica un comunicado oficial con título, contenido, categoría y torneo asociado, **Then** la publicación se guarda con marca de tiempo oficial y queda visible para todos los roles en el feed de noticias.
2. **Given** un aficionado consultando el feed de noticias del torneo, **When** aplica un filtro por categoría (ej. "Boletines Disciplinarios" o "Avisos Generales"), **Then** la lista muestra únicamente los comunicados correspondientes ordenados del más reciente al más antiguo.
3. **Given** un torneo nuevo o sin publicaciones oficiales registradas, **When** el aficionado abre el feed de noticias, **Then** la pantalla muestra un estado vacío informativo en español indicando que aún no existen noticias publicadas.

---

### User Story 3 - Suscripción a Equipos Favoritos, Alertas de Partidos y Navegación Profunda (Priority: P3)

Como `Aficionado`, quiero marcar equipos como favoritos en el campeonato para recibir alertas informativas previas al inicio de sus encuentros (recordatorio de sede y horario), alertas de gol y pitazo final, pudiendo tocar una notificación para abrir directamente el detalle del partido, incluso si la app estaba cerrada o en segundo plano, sin bloqueos si no otorgué permiso para notificaciones push del sistema.

**Why this priority**: Fideliza a los seguidores de los clubes locales permitiéndoles dar seguimiento prioritario a sus equipos familiares o de amigos sin perderse ningún encuentro.

**Independent Test**: Marcar un equipo como favorito, simular la emisión de una alerta de proximidad de partido o finalización, y verificar que aparece la notificación en la bandeja interna y/o del sistema; al interactuar con ella, la app navega directamente al detalle del partido seleccionado. Además, si el permiso de notificaciones push del sistema operativo fue denegado, verificar que la app permite consultar todas las alertas en la bandeja interna sin fallos ni solicitudes repetidas bloqueantes.

**Acceptance Scenarios**:

1. **Given** un usuario que marca a `Alpha FC` como equipo favorito, **When** faltan menos de 30 minutos para su partido programado o se registra el pitazo inicial, **Then** el sistema genera una alerta en español indicando los equipos rivales, la sede, la cancha y la hora de inicio.
2. **Given** que el usuario recibe una notificación de partido o resultado y toca sobre ella, **When** la aplicación se abre desde segundo plano o inicio en frío, **Then** el sistema navega directamente (*deep link*) al detalle de ese partido específico.
3. **Given** que el usuario denegó los permisos de notificaciones push del sistema operativo, **When** navega por la aplicación, **Then** el feed, los marcadores en vivo y la bandeja de alertas internas siguen plenamente funcionales sin diálogos modales intrusivos o bloqueantes.

---

### Edge Cases

- **Pérdida de conexión a internet durante un partido en vivo**: Si la red se interrumpe mientras el aficionado sigue un partido en tiempo real, el sistema debe indicar con una insignia sutil el estado desconectado y mostrar el último marcador cacheado sin bloquear la interfaz; al restaurarse la red, reconecta automáticamente y sincroniza el marcador más reciente.
- **Ráfaga de goles o eventos simultáneos**: La UI debe actualizar de forma determinista la tarjeta del partido sin estados de carrera ni parpadeos destructivos de la lista.
- **Texto largo en titulares de noticias o nombres de clubes a 130% de escalado de texto**: Los titulares y resúmenes de noticias deben envolverse limpiamente sin provocar desbordamientos (`0 RenderFlex overflows`) en pantallas compactas desde 320px de ancho.
- **Permiso de notificaciones denegado permanentemente**: No se deben invocar repetidamente solicitudes del sistema; se debe respetar la decisión del usuario y mantener la bandeja interna de notificaciones accesible.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE mostrar una sección destacada de partidos en juego dentro de la pestaña de Jornada (`tabMatchday`) con la insignia "EN VIVO" en color `KickPulseColors.accentLive` (`#EF4444`) para todos los partidos con estado `inProgress`.
- **FR-002**: Las tarjetas de partidos en vivo DEBEN actualizar el marcador, periodo y minutos transcurridos en tiempo real ante nuevos eventos de gol o cambios de periodo, utilizando números con tipografía tabular (`tabular-nums`).
- **FR-003**: El sistema DEBE implementar la reactividad de partidos en vivo mediante flujos reactivos desacoplados en el repositorio (`Stream<List<TournamentMatch>>`) con cancelación automática de suscripción al desmontar la vista (`ref.onDispose` / `dispose`) o al pasar la app a segundo plano, garantizando 0 fugas de memoria y optimizando el consumo de batería.
- **FR-004**: Los usuarios con rol `Organizador` DEBEN contar con un botón de publicación visible exclusivamente para su rol dentro del Feed de Noticias para redactar, categorizar (`general`, `disciplinary`, `rescheduling`), publicar y eliminar noticias o comunicados oficiales vinculados a un campeonato, protegiendo la acción contra acceso no autorizado por otros roles.
- **FR-005**: El sistema DEBE presentar un Feed de Noticias accesible desde un control segmentado en la cabecera de la jornada/torneo ("Partidos" / "Noticias") y ordenado cronológicamente (más recientes primero) para todos los roles, con soporte de filtrado por categoría y torneo.
- **FR-006**: Si no existen noticias publicadas para el torneo seleccionado, el feed DEBE mostrar un estado vacío informativo en español.
- **FR-007**: Los usuarios DEBEN poder marcar y desmarcar equipos como favoritos en el torneo para personalizar sus alertas informativas.
- **FR-008**: El sistema DEBE despachar alertas para los equipos favoritos con `notificationsEnabled = true` cubriendo un conjunto predeterminado de eventos clave (recordatorio 30 minutos antes del inicio, pitazo inicial, goles anotados en tiempo real y pitazo final con marcador definitivo).
- **FR-009**: Al tocar una alerta o notificación de partido, el sistema DEBE navegar de forma directa y profunda (*deep link*) a la vista de detalle de ese partido.
- **FR-010**: El sistema DEBE incluir un botón de campana en la barra superior (`AppBar`) con indicador numérico de alertas no leídas para abrir la bandeja interna de alertas; al pulsar una alerta individual debe marcarse automáticamente como leída (`isRead = true`) y navegar a su detalle, ofreciendo además una acción para marcar todas como leídas en bloque y garantizando funcionalidad completa incluso si las notificaciones push del sistema operativo fueron denegadas.
- **FR-011**: Todas las noticias, alertas guardadas y últimos marcadores DEBEN persistirse localmente para permitir su lectura en modo sin conexión (offline-first).
- **FR-012**: Todos los textos de la interfaz, etiquetas de categorías, estados de alertas y mensajes de confirmación DEBEN estar centralizados en español en `app_es.arb`.

---

### Key Entities *(include if feature involves data)*

- **`TournamentNewsItem`**: Noticia o comunicado oficial emitido para un campeonato: `id`, `tournamentId`, `title`, `body`, `category` (`TournamentNewsCategory`: `general`, `disciplinary`, `rescheduling`), `publishedAt`, `authorUserId`, `authorName`, `isPinned`.
- **`FanFavoriteTeam`**: Preferencia guardada del aficionado: `userId`, `tournamentId`, `teamId`, `teamName`, `notificationsEnabled` (control global de alertas para eventos clave: recordatorio 30 min, inicio, goles y resultado final), `createdAt`.
- **`MatchLiveAlert`**: Alerta o notificación de partido generada para el usuario: `id`, `matchId`, `tournamentId`, `type` (`MatchAlertType`: `matchUpcoming`, `matchStarted`, `goalScored`, `matchEnded`, `newsPublished`), `title`, `message`, `timestamp`, `isRead`.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Los cambios de marcador y eventos de partidos en juego se reflejan en la interfaz del aficionado en menos de 100 milisegundos tras registrarse el evento localmente.
- **SC-002**: Las suscripciones en tiempo real y temporizadores activos se liberan al 100% al cambiar de vista o pausar la app, manteniendo 0 fugas de memoria (*0 memory leaks*).
- **SC-003**: La navegación desde una notificación hacia el detalle del partido (*deep link*) se completa de forma instantánea sin pantallas en blanco ni desincronización de estado.
- **SC-004**: El feed de noticias y las tarjetas de partidos en vivo se renderizan con 0 desbordamientos de interfaz (`0 RenderFlex overflows`) en dispositivos móviles desde 320px de ancho y con escalado de texto de hasta 130%.
- **SC-005**: El 100% de las noticias y alertas cacheadas previamente se visualizan de inmediato (0 segundos de espera percibida) cuando el dispositivo no tiene conexión a internet.

---

## Assumptions

- Se aprovecha la infraestructura existente de `MatchReportsRepository`, `TournamentMatchesRepository` y `LocalStorageRepository` para la sincronización reactiva local y la persistencia en dispositivo.
- El envío de notificaciones push del sistema operativo se modela con abstracciones desacopladas (`NotificationService` / `LocalNotificationsRepository`), garantizando que la bandeja interna de alertas funcione plenamente en entornos móviles y pruebas sin requerir servicios de nube externos obligatorios.
- Los aficionados pueden seleccionar favoritos sin requerir autenticación federada forzosa, almacenándose en el dispositivo del usuario (`LocalStorageRepository`) si navega como aficionado invitado (`UserRole.fan`).
- La sección de noticias se integra mediante control segmentado en la jornada/torneo y las alertas en la barra superior (`AppBar`), cumpliendo estrictamente con el máximo de 5 pestañas de `MOBILE_GUIDELINES.md`.
