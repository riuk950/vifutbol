# Quickstart: Validación de Acceso a "Panel" en Navigation Drawer y Ocultación de "Explorar"

**Feature**: `016-drawer-panel-access`
**Date**: 2026-11-06

---

## Escenarios de Validación Rápida

### Escenario 1: Verificación de 3 Pestañas en `AppShellScreen`
1. Iniciar la aplicación con cualquier rol (ej. `UserRole.fan` u `UserRole.organizer`).
2. Observar la barra de navegación inferior (`NavigationBar`).
3. **Resultado esperado**:
   - Se visualizan exactamente 3 pestañas: **Partidos**, **Noticias** y **Perfil**.
   - La pestaña **Explorar** no está presente.
   - Al pulsar "Noticias", el índice visual pasa a 1 y se despliega `NewsTabView`.
   - Al pulsar "Perfil", el índice visual pasa a 2 y se despliega `ProfileTabView`.
   - Al pulsar "Partidos", el índice visual pasa a 0 y se despliega `MatchdayTabView`.

### Escenario 2: Ocultación de "Panel" para Rol Aficionado
1. Configurar el rol activo en `UserRole.fan`.
2. Tocar el botón de menú hamburguesa en el AppBar (`Key('app_bar_drawer_button')`).
3. Inspeccionar las opciones desplegadas en el `AppNavigationDrawer`.
4. **Resultado esperado**:
   - Se muestran los destinos de directorios (Competiciones, Equipos, Jugadores, Sedes).
   - El widget con clave `Key('drawer_destination_panel')` **NO** existe en el árbol de widgets.

### Escenario 3: Visibilidad y Navegación de "Panel" para Roles Operativos
1. Configurar el rol activo sucesivamente en: `UserRole.organizer`, `UserRole.coach`, `UserRole.referee`, `UserRole.player`.
2. Abrir el `AppNavigationDrawer`.
3. **Resultado esperado**:
   - En la primera posición del menú (arriba de "Competiciones"), se encuentra el ítem con clave `Key('drawer_destination_panel')` y texto "Panel".
4. Tocar sobre el ítem "Panel".
5. **Resultado esperado**:
   - El Drawer se cierra.
   - Se navega a la pantalla `PanelScreen` (`/panel`).
   - El AppBar muestra el título "Panel" y el botón de regreso.
   - El cuerpo muestra la insignia del rol activo correspondiente.

### Escenario 4: Redirección de `/explore`
1. Realizar una solicitud de navegación programática hacia `/explore` (o mediante deep-link simulado).
2. **Resultado esperado**:
   - La aplicación redirige de forma inmediata y sin excepciones hacia la ruta `/matches`.

---

## Comandos de Verificación Automatizada

```bash
# Ejecución de pruebas unitarias y de widgets de la feature
flutter test test/presentation/app_shell_widget_test.dart
flutter test test/presentation/app_drawer_widget_test.dart
flutter test test/presentation/panel_screen_test.dart

# Comprobación de análisis estático y formateo
flutter analyze
dart format --output=none --set-exit-if-changed .
```
