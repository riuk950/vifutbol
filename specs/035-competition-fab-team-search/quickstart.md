# Quickstart Validation Guide: FAB Menu y Buscador de Equipos (HU 18.4)

**Feature**: `035-competition-fab-team-search`  
**Branch**: `develop`  

---

## Prerrequisitos

1. Dependencias instaladas (`flutter pub get`) y archivos de localización generados tras editar `lib/l10n/app_es.arb`:
   ```bash
   flutter gen-l10n
   ```
2. Análisis estático y formato limpios:
   ```bash
   flutter analyze
   dart format --output=none --set-exit-if-changed lib/ test/
   ```

---

## Escenarios de Validación Automatizada

### 1. Pruebas Unitarias — Búsqueda Sin Tildes y Caso de Uso de Inscripción desde Catálogo
- Archivo de pruebas de utilidad: `test/unit/application/search_utils_test.dart`
  - Verifica que `"atletico"`, `"ATLETICO"`, `"Águilas"` y `"aguilas"` coinciden respectivamente con `"Atlético del Sur"` y `"Águilas FC"`.
- Archivo de pruebas de caso de uso: `test/application/use_cases/enroll_existing_team_from_catalog_test.dart`
  - Verifica estado inicial `TeamEligibilityStatus.pendingVerification` y jugadores copiados con `isEligible == false`.
  - Verifica omisión y conteo (`skippedConflictingPlayersCount`) cuando algún jugador de la plantilla base comparte `documentId` con otro equipo del torneo destino.
  - Verifica bloqueo ante duplicidad por nombre normalizado (incluyendo variantes con/sin tilde) y rol no autorizado.
  - Verifica auto-asignación al grupo menos poblado en competiciones `mixedGroupsAndKnockout`.

### 2. Pruebas de Widget — FAB Menu en `CompetitionDetailScreen`
- Archivo: `test/presentation/tournaments/competition_detail_fab_menu_test.dart` (reemplazando `competition_detail_fab_simplification_test.dart`).
  - Organizador + torneo editable sin fixture: muestra `competition_detail_fab_menu`; al pulsar despliega `competition_detail_fab_generate_fixture` y `competition_detail_fab_add_team`.
  - Seleccionar `"Generar Fixture"` colapsa el menú y abre el diálogo de confirmación.
  - Seleccionar `"Agregar Equipos"` colapsa el menú y abre `AddTeamsToCompetitionModal` (`add_teams_modal`).
  - Organizador + torneo editable CON fixture: mantiene visible `competition_detail_fab_menu`, muestra `competition_detail_fab_add_team` y oculta `competition_detail_fab_generate_fixture`.
  - Torneo finalizado o roles no organizadores (`coach`, `referee`, `player`, `fan`): no renderizan `competition_detail_fab_menu`.

### 3. Pruebas de Widget — `AddTeamsToCompetitionModal` e Integración Reactiva
- Archivo: `test/presentation/tournaments/add_teams_to_competition_modal_test.dart`
  - Muestra buscador superior (`add_teams_search_field`) y catálogo único alfabético de equipos.
  - Filtra en tiempo real ignorando mayúsculas/minúsculas y tildes (`"aguilas"`, `"ATLETICO"`).
  - Muestra estado vacío de búsqueda con acción `"Limpiar búsqueda"` (`add_teams_clear_filter_button`) y estado vacío cuando el catálogo global no tiene equipos.
  - Equipos ya inscritos muestran badge `"Inscrito"` y botón deshabilitado.
  - Pulsar `"Agregar"` inscribe al equipo en estado `pendingVerification`, mantiene el modal abierto y el texto de búsqueda intacto, actualiza la tarjeta a `"Inscrito"` deshabilitado y protege contra doble tap.
  - Refleja inmediatamente el nuevo equipo en `CompetitionTeamsTabView`.

---

## Comandos de Verificación Completa

```bash
flutter analyze
dart format --output=none --set-exit-if-changed lib/ test/
flutter test test/unit/application/search_utils_test.dart \
  test/application/use_cases/enroll_existing_team_from_catalog_test.dart \
  test/presentation/tournaments/competition_detail_fab_menu_test.dart \
  test/presentation/tournaments/add_teams_to_competition_modal_test.dart
```

Resultado esperado: **0 errores en `flutter analyze`**, **0 diferencias de formato**, y **100% de pruebas aprobadas**.
