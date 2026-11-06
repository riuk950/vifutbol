# Technical Research: Pantalla de Panel Administrativo Dinámico por Rol (HU 12.2)

**Feature**: `017-role-dynamic-panel`
**Date**: 2026-11-06

---

## 1. Arquitectura de Desacoplamiento para `PanelScreen` y Subpaneles por Rol

### Contexto
La HU 12.1 estableció un scaffold preparatorio base en `lib/presentation/panel/panel_screen.dart` con un AppBar y un card genérico del rol activo. La HU 12.2 exige transformar esta pantalla en un centro de mando adaptativo que presente métricas específicas, tarjetas informativas y accesos directos diferenciados para los 4 roles operativos (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`), y una vista restrictiva amigable para `Aficionado`.

### Decisión
- **Enfoque seleccionado**: Composición desacoplada mediante subwidgets independientes en `lib/presentation/panel/widgets/`:
  - `OrganizerPanelContent`: Resumen de torneos activos, partidos pendientes de programación, torneos sin fixture y botones de acción rápida.
  - `CoachPanelContent`: Resumen del equipo, desglose de jugadores habilitados vs suspendidos y acceso a la convocatoria del próximo encuentro.
  - `RefereePanelContent`: Lista de partidos asignados con acceso directo al "Acta Digital" o estado vacío con mensaje neutral.
  - `PlayerPanelContent`: Insignia de elegibilidad (Habilitado / Sancionado), estadísticas acumuladas de temporada y próximo partido.
  - `FanPanelRestrictedContent`: Vista de acceso restringido basada en `KickPulseStateView` con botón *"Volver a Partidos"*.
- **Resolución dinámica del título de AppBar**:
  ```dart
  final appBarTitle = switch (activeRole) {
    UserRole.organizer => l10n.panelTitleOrganizer, // "Panel de Organización"
    UserRole.coach => l10n.panelTitleCoach,         // "Panel Técnico"
    UserRole.referee => l10n.panelTitleReferee,     // "Panel Arbitral"
    UserRole.player => l10n.panelTitlePlayer,       // "Ficha del Jugador"
    UserRole.fan => l10n.drawerPanel,              // "Panel"
  };
  ```
- **Alternativas descartadas**:
  - *Condicionales monolíticos dentro de un solo archivo `panel_screen.dart`*: Descartado por violar el Principio IV (Arquitectura Limpia y Separación de Responsabilidades), dificultar las pruebas unitarias por rol y aumentar la deuda técnica de mantenimiento.

---

## 2. Gestión de Estado y Orquestación de Datos

### Contexto
Cada rol necesita consultar datos del modelo preexistente sin duplicar estado en caché ni realizar consultas redundantes:
- Organizador: Torneos (`tournamentsControllerProvider`), partidos pendientes de fecha (`matchesCatalogControllerProvider`).
- Entrenador: Equipo activo y plantilla (`teamsControllerProvider`), próximo partido (`matchesCatalogControllerProvider`).
- Árbitro: Partidos asignados donde `m.refereeId == currentUser.id`.
- Jugador: Estadísticas individuales y ficha del jugador (`teamsControllerProvider`), próximo partido (`matchesCatalogControllerProvider`).

### Decisión
- **Enfoque seleccionado**: Crear un controlador de presentación dedicado o providers computados (`panelDashboardControllerProvider` o agregados ligeros de lectura) que consuman reactivamente los proveedores base ya inicializados (`tournamentsControllerProvider`, `matchesCatalogControllerProvider`, `teamsControllerProvider`, `authControllerProvider`).
- **Resolución de contexto en modo invitado / demo (Clarificación 1)**:
  - Cuando no haya un equipo o jugador vinculado en la sesión del usuario, se selecciona automáticamente el primer equipo disponible del repositorio sembrado (`TwentyTeamsSeedData` / `TeamsController`), poblando de inmediato la plantilla y las métricas deportivas.
- **Filtrado estricto para Árbitro (Clarificación 3)**:
  - Se filtran los partidos donde `m.refereeId == userId`. Si la lista resultante es vacía, se renderiza la tarjeta de estado vacío informativa (`emptyStateRefereeAssignedMatches`).

---

## 3. Disparadores de Acciones Rápidas y Navegación

### Contexto
Las acciones del panel deben conectar de forma fluida con las capacidades existentes del sistema (generación de fixtures, programación de partidos, actas digitales, copias de seguridad).

### Decisión
- **Organizador (Clarificación 2)**:
  - *"Generar Fixture"*: Si hay torneos sin fixture, abre el diálogo/flujo de generación de fixture para el primer torneo pendiente; si no hay pendientes, navega a `/matches` o `/competitions`.
  - *"Programar Partido"*: Si hay partidos con `scheduledStartTime == null`, abre el diálogo modal de programación (`ScheduleMatchDialog` o selector); si todos están programados, notifica o navega a `/matches`.
  - *"Copia de Seguridad"*: Abre el modal o pantalla de exportación/importación de respaldos (`/backup` o diálogo de backup).
- **Entrenador**:
  - *"Convocatoria para el Próximo Partido"*: Navega al flujo de convocatoria/alineación del equipo.
- **Árbitro**:
  - *"Acta Digital"*: Abre el acta digital oficial para el partido seleccionado (`/match-report` o pantalla de acta digital).
- **Aficionado (Clarificación 4)**:
  - Botón *"Volver a Partidos"*: Navega limpiamente a `/matches` restableciendo la sección activa del Shell en Partidos.

---

## 4. Accesibilidad, Ergonomía Táctil y Directrices Móviles

### Contexto
De acuerdo con la Constitución (Principio VII) y `MOBILE_GUIDELINES.md`, la experiencia táctil debe ser cómoda y robusta frente a diferentes tamaños de pantalla y escalado tipográfico.

### Decisión (Clarificación 5)
- **Disposición de botones**: Botones de ancho completo apilados verticalmente con altura mínima de $48\text{ dp}$ (`KickPulseButton` o `ListTile` estilizado sobre `KickPulseCard`).
- **Escalado tipográfico**: En viewports de $320 \times 640\text{ px}$ con texto al $130\%$, los contenedores utilizan `SingleChildScrollView` con espaciados elásticos y `KickPulseBadge` ajustados, garantizando 0 excepciones `RenderFlex`.
- **Protección contra toques duplicados**: Todos los botones de acción rápida implementan bloqueo de ejecución única (*single-flight lock*).
