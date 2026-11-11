# Research: Navegación a Detalles de la Competición desde "Mis Competiciones" en el Panel (HU 18.3)

**Feature**: `034-organizer-competition-navigation`  
**Date**: 2026-11-11  

---

## 1. Integración Táctil en Tarjetas de Competición

### Contexto y Decisión
En `OrganizerCompetitionsSection` (`lib/presentation/panel/widgets/organizer_competitions_section.dart`), cada torneo es renderizado mediante `_buildTournamentCard`. La tarjeta se implementa usando `KickPulseCard`, la cual ya posee soporte nativo para el parámetro `onTap: VoidCallback?`. Al recibir `onTap`, `KickPulseCard` envuelve internamente el contenido en un `Material` transparente con `InkWell` respetando el radio de curvatura oficial (`KickPulseRadiiSpacing.cardBorderRadius` = 16px).

### Aislamiento de Eventos (Hit Testing)
La tarjeta contiene un `PopupMenuButton<String>` para las acciones de edición, cambio de estado y eliminación. En Flutter, los botones como `PopupMenuButton` capturan sus propios eventos de puntero (`PointerDownEvent`), impidiendo la propagación hacia el `InkWell` ancestral cuando se interactúa con el menú. Por tanto, pulsar los tres puntos abre el menú contextual sin disparar la navegación al detalle del torneo.

---

## 2. Sincronización del Estado Global de Torneo

### Contexto y Decisión
Al pulsar la tarjeta, se debe sincronizar el torneo seleccionado en `tournamentsControllerProvider` invocando `selectTournament(tournament.id)`. Esto garantiza que los proveedores dependientes (`tournamentNewsControllerProvider`, `matchesCatalogControllerProvider`, etc.) operen en el contexto del torneo seleccionado de manera transparente.

### Navegación Parametrizada
La navegación se efectúa hacia `/competitions/${tournament.id}` mediante el enrutador central `Navigator.of(context).pushNamed('/competitions/${tournament.id}')` (o un callback opcional `onTapTournament: (tournament) => ...` para permitir inyección y pruebas de widget aisladas).

---

## 3. Resiliencia Móvil: Prevención de Toques Dobles / Múltiples (Debouncing)

### Contexto y Decisión
Bajo el Principio VII de la Constitución (*Resiliencia y Experiencia Móvil*), pulsaciones rápidas y consecutivas sobre una tarjeta podrían apilar múltiples instancias de `CompetitionDetailScreen` en el historial de navegación.
Se adopta una guarda basada en marca de tiempo (`DateTime _lastTapTime`) con un umbral de 500 ms en el manejador de toque, descartando cualquier toque subsiguiente que ocurra antes de cumplirse la ventana de tiempo.

---

## 4. Retorno y Preservación de Estado

### Contexto y Decisión
Cuando el organizador presiona el botón de regreso (`BackButton`) en `CompetitionDetailScreen` o efectúa el gesto nativo del sistema operativo, el `Navigator` realiza un `pop()` devolviendo el control a `PanelScreen`. Dado que `PanelScreen` y `OrganizerPanelContent` mantienen su estado a través de Riverpod y `SingleChildScrollView`, la posición de desplazamiento y los datos del panel permanecen intactos sin necesidad de reconstrucción destructiva.
