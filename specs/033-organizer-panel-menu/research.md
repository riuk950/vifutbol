# Research: Reorganización del Panel de Organización: Menú en AppBar y Depuración de Acciones Rápidas (HU 18.2)

**Feature**: `033-organizer-panel-menu`  
**Date**: 2026-11-11  

---

## 1. Decisiones Técnicas y Arquitectónicas

### Decisión 1: Ubicación del Menú Contextual en `PanelScreen` vs. `OrganizerPanelContent`
- **Decisión**: Implementar el widget `OrganizerPanelAppBarMenu` e insertarlo dentro de la propiedad `actions` del `AppBar` en `PanelScreen`, condicionado a `activeRole == UserRole.organizer`.
- **Razón**: `PanelScreen` (`lib/presentation/panel/panel_screen.dart`) es el contenedor Scaffold de primer nivel que posee el `AppBar` del panel. Al inyectar el menú contextual en sus `actions`, se mantiene la semántica pura de Flutter (`AppBar.actions`) sin requerir arquitecturas complejas de sub-appbars o headers colapsables.
- **Alternativas consideradas**:
  - *Pasar un callback desde `OrganizerPanelContent` hacia arriba*: Innecesario y propenso a estados desincronizados, ya que `PanelScreen` ya observa `activeUserRoleProvider` con Riverpod.
  - *Crear un AppBar personalizado dentro de `OrganizerPanelContent` con Scaffold anidado*: Viola las directrices ergonómicas de KickPulse Mobile (Scaffolds anidados generan problemas de insets y safe areas).

### Decisión 2: Componente de Menú Contextual (`PopupMenuButton`)
- **Decisión**: Utilizar `PopupMenuButton<OrganizerMenuAction>` con icono `Icons.more_vert`, fondo `KickPulseColors.surfaceElevated`, bordes redondeados `KickPulseRadiiSpacing.chipBorderRadius` y borde sutil `KickPulseColors.borderSubtle`.
- **Razón**: Cumple con el Principio V de la Constitución (Fidelidad al Sistema de Diseño KickPulse) y con la clarificación Q1 (ícono alusivo + etiqueta de texto descriptivo para cada opción).
- **Ítems del Menú**:
  1. `OrganizerMenuAction.publishNews`: Ícono `Icons.campaign_outlined` con color `KickPulseColors.accentElectric` y texto `l10n.organizerActionPublishNews`.
  2. `OrganizerMenuAction.backup`: Ícono `Icons.backup_outlined` con color `KickPulseColors.accentPrimary` y texto `l10n.organizerActionBackup`.

### Decisión 3: Depuración y Retiro de Acciones Redundantes
- **Decisión**: Remover por completo del cuerpo de `OrganizerPanelContent` la sección "Acciones Rápidas" (`l10n.organizerQuickActionsTitle` y su tarjeta con los 4 botones), y eliminar definitivamente las acciones de "Generar Fixture" y "Programar Partido" del panel general.
- **Razón**: Conforme a HU 15.2 y HU 15.3, la generación de fixture pertenece al menú de acción flotante (FAB Menu) dentro del detalle de cada torneo, y la programación de partidos a la vista de jornada. Mantenerlas en el panel general generaba ambigüedad sobre a cuál competición aplicaban.

### Decisión 4: Manejo de Publicación de Noticias sin Torneos Registrados (Clarificación Q2)
- **Decisión**: Si el catálogo de torneos está vacío o no contiene torneos editables, invocar `CreateNewsDialog.show` pasando `tournamentId: 'general'` y `availableTournaments: null`.
- **Razón**: Permite al organizador emitir comunicados generales institucionales o de pretemporada sin forzar la existencia previa de un torneo, cumpliendo con la resolución de la sesión de clarificación Q2.

---

## 2. Alineación con las Guías Móviles (`docs/MOBILE_GUIDELINES.md`)

1. **Ergonomía Táctil**:
   - El botón del menú de tres puntos en el AppBar cumple con el área mínima interactiva de $44 \times 44$ pt.
   - Cada ítem del menú contextual cuenta con padding vertical generoso y separación de 8 pt entre ícono y texto.
2. **Resiliencia ante Cambios de Rol**:
   - Si el rol conmuta en tiempo de ejecución, el menú se desvincula de inmediato gracias a `ref.watch(activeUserRoleProvider)`.
3. **Flujo Visual No Destructivo**:
   - Abrir y cerrar el menú contextual mediante toque exterior no altera ningún estado subyacente del panel.
4. **Accesibilidad y Localización**:
   - Los textos provienen 100% de `AppLocalizations` (`organizerActionPublishNews`, `organizerActionBackup`).
   - El botón incluye tooltip accesible para lectores de pantalla.
