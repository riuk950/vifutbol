# Technical Research: Acceso a "Panel" en Navigation Drawer y Ocultación Temporal de "Explorar"

**Feature**: `016-drawer-panel-access`
**Date**: 2026-11-06

---

## 1. Mapeo del `NavigationBar` Inferior (3 Pestañas) y `AppShellSection`

### Contexto
Actualmente, `AppShellScreen` utiliza un `NavigationBar` con 4 destinos:
1. `Partidos` (`AppShellSection.matches`) - índice 0
2. `Explorar` (`AppShellSection.explore`) - índice 1
3. `Noticias` (`AppShellSection.news`) - índice 2
4. `Perfil` (`AppShellSection.profile`) - índice 3

Al retirar temporalmente `Explorar`, la barra inferior debe mostrar exactamente 3 destinos:
1. `Partidos`
2. `Noticias`
3. `Perfil`

### Decisión
- **Enfoque seleccionado**: Mapeo bidireccional en la capa de presentación dentro de `AppShellScreen`.
  - De `AppShellSection` a índice visual:
    - `matches` $\to$ `0`
    - `news` $\to$ `1`
    - `profile` $\to$ `2`
    - `explore` (fallback de seguridad) $\to$ `0` (redirige visualmente a `matches`).
  - De índice visual (`onDestinationSelected`) a `AppShellSection`:
    - `0` $\to$ `AppShellSection.matches`
    - `1` $\to$ `AppShellSection.news`
    - `2` $\to$ `AppShellSection.profile`
- **Impacto en el dominio**: Cero cambios en `AppShellSection` ni en `AppShellController`. Se mantiene la compatibilidad de tipos con toda la suite de pruebas existente y se facilita la reactivación futura de `explore` sin refactorizaciones destructivas.
- **Alternativas descartadas**:
  - *Eliminar `explore` del enum `AppShellSection`*: Descartado porque violaría la compatibilidad regresiva, exigiría modificar múltiples controladores (`AppShellController`, tests de integración de HU 10.1 y 10.2) y generaría retrabajo al reincorporar la sección.

---

## 2. Redirección de la Ruta `/explore` a `/matches`

### Contexto
El usuario puede ingresar a `/explore` mediante deep-link o llamadas directas en el enrutador. Al estar oculta temporalmente la sección, la navegación debe ser resiliente (Principio VII y Guías Móviles).

### Decisión
- **Enfoque seleccionado**: En `AppRouter.routes`, el manejador para la ruta `/explore` retornará una redirección o construirá `AppShellScreen` forzando la sección activa a `AppShellSection.matches`.
- **Alternativas descartadas**:
  - *Retirar la ruta `/explore` del router*: Descartado porque causaría pantalla de error 404 / ruta no encontrada ante enlaces guardados en caché o accesos previos.

---

## 3. Ítem "Panel" en `AppNavigationDrawer` y Segregación de Roles

### Contexto
La HU 12.1 requiere que el ítem "Panel" sea accesible en el Drawer lateral para los roles con responsabilidades de gestión o participación deportiva (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`) y permanezca completamente oculto para el rol `Aficionado` (`UserRole.fan`).

### Decisión
- **Ubicación en el Drawer**: Primera posición del `ListView` de navegación (arriba de "Competiciones"), con icono `Icons.dashboard_outlined`, etiqueta localizada `l10n.drawerPanel` y clave de pruebas `Key('drawer_destination_panel')`.
- **Regla de visibilidad**:
  ```dart
  final isPanelVisible = activeRole != UserRole.fan;
  ```
  O alternativamente:
  ```dart
  const allowedPanelRoles = {
    UserRole.organizer,
    UserRole.coach,
    UserRole.referee,
    UserRole.player,
  };
  final isPanelVisible = allowedPanelRoles.contains(activeRole);
  ```
- **Flujo de interacción**:
  1. El usuario pulsa sobre el `ListTile` de "Panel".
  2. Se invoca `Navigator.of(context).pop()` para cerrar el Drawer de forma inmediata.
  3. Se ejecuta `Navigator.of(context).pushNamed('/panel')`.
- **Accesibilidad**: Altura táctil mínima de $48\text{ dp}$ garantizada por el estándar Material `ListTile` y semántica descriptiva para lectores de pantalla.

---

## 4. Pantalla Contenedora de Destino `/panel` (HU 12.1 $\to$ HU 12.2)

### Contexto
La pantalla completa con dashboards dinámicos y métricas operativas por rol se construirá en la HU 12.2. Para la HU 12.1 se debe proveer una pantalla destino completamente funcional, navegable y verificable.

### Decisión
- **Ubicación de archivo**: `lib/presentation/panel/panel_screen.dart`.
- **Estructura**:
  - `Scaffold` con fondo `KickPulseColors.canvasBackground`.
  - `AppBar` con botón de retroceso (`BackButton`), título centrado "Panel" (`l10n.drawerPanel`) y estilo `KickPulseTypography.screenTitle`.
  - Cuerpo (`body`): Tarjeta estilizada (`KickPulseCard`) con badge del rol activo (`KickPulseBadge`), icono representativo de panel y mensaje informativo de preparación del panel de control deportivo.
- **Ruta registrada en AppRouter**:
  - Ruta `/panel` $\to$ `PanelScreen()`.

---

## 5. Internacionalización (`l10n`)

### Claves en `lib/l10n/app_es.arb`:
- `"drawerPanel": "Panel"` (descripción: "Etiqueta para la opción Panel en el menú lateral").
- `"panelPlaceholderTitle": "Panel de Control Operativo"` (descripción: "Título del estado preparatorio del panel").
- `"panelPlaceholderSubtitle": "Herramientas de gestión y métricas disponibles para tu rol deportivo."` (descripción: "Descripción del estado preparatorio del panel").
