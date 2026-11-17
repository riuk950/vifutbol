# Quickstart Validation Guide: Carga y Selección de Equipos del Catálogo Global (HU 18.5)

**Feature**: `043-competition-fab-catalog-enrollment`  
**Prerequisites**:
- Flutter SDK instalado (`flutter --version`)

## 1. Comandos de Verificación Automatizada

```bash
flutter gen-l10n
flutter analyze
flutter test test/unit/infrastructure/sync/hybrid_teams_repository_teams_test.dart
flutter test test/presentation/tournaments/add_teams_to_competition_modal_test.dart
```

## 2. Escenarios de Validación Funcional

1. **Carga completa del catálogo global (incluyendo clubes sin torneo previo)**:
   - Como entrenador (`coach`), registrar un club nuevo en el directorio general de equipos sin asignarlo a ningún torneo.
   - Como organizador (`organizer`), abrir `CompetitionDetailScreen` de un torneo editable -> presionar el FAB Menu -> seleccionar `"Agregar Equipos"`.
   - **Resultado esperado**: El modal consulta `loadTeams()` y lista todos los clubes de la plataforma (incluyendo el club autónomo recién creado), mostrando escudo, nombre oficial, código, categoría (`"Categoría libre"` si no tiene torneo previo), cantidad de jugadores y `"DT: <Nombre>"` cuando el nombre del entrenador esté disponible.
2. **Restricción estricta sin creación de equipos**:
   - Inspeccionar el modal con catálogo poblado, con filtro sin resultados y con catálogo vacío.
   - **Resultado esperado**: No existe ningún botón ni formulario para crear o registrar clubes nuevos; cuando el catálogo global está vacío se muestra `"No hay equipos registrados en la plataforma. Los entrenadores deben registrar sus clubes antes de poder inscribirlos en el campeonato."`.
3. **Búsqueda reactiva e inscripción con actualización instantánea**:
   - Escribir en el buscador con o sin tildes / mayúsculas -> la lista filtra en tiempo real.
   - Presionar `"Inscribir"` en un club disponible -> el modal permanece abierto, el club cambia a `"Inscrito"` (botón deshabilitado) y la pestaña `"Equipos"` del torneo refleja de inmediato al nuevo participante en estado `"Pendiente de verificación"`.
