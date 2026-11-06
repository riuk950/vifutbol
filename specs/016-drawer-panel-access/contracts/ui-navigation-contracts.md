# UI & Navigation Contracts: Acceso a "Panel" en Navigation Drawer y Ocultación Temporal de "Explorar"

**Feature**: `016-drawer-panel-access`
**Date**: 2026-11-06

---

## 1. Contratos de Rutas del Router (`AppRouter`)

| Ruta | Nombre del Manejador | Widget Destino | Comportamiento |
| :--- | :--- | :--- | :--- |
| `/` | `shellHandler` | `AppShellScreen` | Contenedor principal con 3 pestañas inferiores. |
| `/explore` | `exploreRedirectHandler` | `AppShellScreen(initialSection: AppShellSection.matches)` | Redirige de forma segura a `/matches`. |
| `/panel` | `panelHandler` | `PanelScreen` | Pantalla Scaffold con AppBar ("Panel"), botón Atrás y estado preparatorio del rol. |

---

## 2. Contrato de Componente: `AppShellScreen` (3 Pestañas)

### Propiedades y Keys de Localización en Pruebas
- **`NavigationBar`**:
  - `selectedIndex`: Mapeado según `AppShellSection` activo (0 para `matches`, 1 para `news`, 2 para `profile`).
  - Total de destinos visuales en `destinations`: exactamente **3**.
  - Pestañas esperadas:
    - Destino 0: Icono `Icons.sports_soccer_outlined`, etiqueta `l10n.tabMatchday` ("Partidos").
    - Destino 1: Icono `Icons.newspaper_outlined`, etiqueta `l10n.tabNews` ("Noticias").
    - Destino 2: Icono `Icons.person_outline`, etiqueta `l10n.tabProfile` ("Perfil").

---

## 3. Contrato de Componente: `AppNavigationDrawer`

### Destino "Panel"
- **`Key` semántica**: `Key('drawer_destination_panel')`.
- **Tipo de Widget**: `ListTile`.
- **Ubicación**: Primer elemento en la lista de destinos, inmediatamente antes de `drawer_destination_competitions`.
- **Icono (`leading`)**: `Icon(Icons.dashboard_outlined, color: KickPulseColors.accentElectric)`.
- **Texto (`title`)**: `Text(l10n.drawerPanel)`.
- **Ícono posterior (`trailing`)**: `Icon(Icons.chevron_right, size: 20, color: KickPulseColors.textSecondary)`.
- **Comportamiento en `onTap`**:
  ```dart
  Navigator.of(context).pop();
  Navigator.of(context).pushNamed('/panel');
  ```
- **Condición de renderizado**:
  ```dart
  if (activeRole != UserRole.fan) ...[
    ListTile(key: const Key('drawer_destination_panel'), ...),
  ]
  ```

---

## 4. Contrato de Pantalla: `PanelScreen`

### Especificación
- **Archivo**: `lib/presentation/panel/panel_screen.dart`.
- **`Key` semántica raíz**: `Key('panel_screen')`.
- **`AppBar`**:
  - `leading`: `BackButton(key: const Key('panel_back_button'))`.
  - `title`: `Text(l10n.drawerPanel)`.
- **Cuerpo (`body`)**:
  - Contenedor con `Key('panel_placeholder_content')`.
  - Insignia de rol: `KickPulseBadge` con `label: _roleLabel(l10n, activeRole)`.
  - Título informativo: `Text(l10n.panelPlaceholderTitle)`.
  - Descripción de alcance: `Text(l10n.panelPlaceholderSubtitle)`.
