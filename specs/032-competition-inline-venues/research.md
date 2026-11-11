# Phase 0 Research: Creación y Vinculación de Sedes en el Formulario de Nueva Competición (HU 18.1)

**Feature**: `032-competition-inline-venues`  
**Date**: 2026-11-11  
**Context**: Integración de creación y selección en línea de sedes deportivas dentro de `TournamentFormScreen` sin perder datos ni interrumpir el flujo de alta del campeonato.

---

## 1. Patrón de Despliegue de Creación en Línea (Modal Bottom Sheet)

### Decisión
Implementar un componente modular reutilizable `CreateVenueBottomSheet` invocado mediante `showModalBottomSheet(context: context, isScrollControlled: true, ...)`.

### Justificación
- **No destructivo (Mobile Guidelines & Principio VII)**: Al ejecutarse como un modal deslizable encima de `TournamentFormScreen`, el ciclo de vida de la pantalla padre se mantiene intacto en memoria. Los `TextEditingController` de nombre, categoría, reglas y fechas del torneo no se reinician ni se ven afectados por aperturas, cancelaciones o errores dentro del modal.
- **Manejo del Teclado y Scroll**: `isScrollControlled: true` permite al Bottom Sheet redimensionarse y absorber `MediaQuery.of(context).viewInsets.bottom`, evitando desbordamientos de pantalla (*RenderFlex overflow*) cuando el usuario escribe en campos de texto en dispositivos móviles compactos.

### Alternativas Consideradas
- **Navegación completa a `VenueFormScreen` (`Navigator.push`)**: Rechazada porque requería pasar el borrador completo por parámetros de ruta o depender de callbacks complejos en el pop, aumentando el riesgo de perder el estado del formulario del torneo al regresar.
- **Expansión inline dentro del scroll del torneo**: Rechazada porque satura la pantalla verticalmente, introduce estados de validación cruzados entre el formulario del torneo y el de la sede, y dificulta la cancelación atómica.

---

## 2. Validación y Prevención de Duplicados (Unicidad de Sedes)

### Decisión
En `ManageVenuesUseCase` (o validador auxiliar en la capa de aplicación), incorporar la regla de unicidad de nombre de sede antes de la persistencia:
```dart
final existingVenues = await _venuesRepository.getVenues();
final isDuplicate = existingVenues.any(
  (v) => v.name.trim().toLowerCase() == trimmedName.toLowerCase() && v.id != venue.id,
);
if (isDuplicate) {
  throw const InvalidVenueDataFailure(
    'Ya existe una sede con este nombre. Selecciónala de la lista o elige un nombre diferente.',
  );
}
```

### Justificación
- **Integridad de Datos (Principio II)**: Evita que el usuario cree sedes redundantes o idénticas en persistencia local Hive por confusión o doble toque.
- **Feedback Inmediato**: El Modal Bottom Sheet captura el fallo de validación y resalta el mensaje de error directamente en el campo de texto de nombre sin cerrar el modal.

---

## 3. Generación Automática de Canchas Internas

### Decisión
A partir del número entero de canchas $N \ge 1$ introducido en el subformulario, generar secuencialmente las entidades `VenuePitch`:
```dart
final pitches = List.generate(
  pitchesCount,
  (index) => VenuePitch(
    id: const Uuid().v4(),
    name: 'Cancha ${index + 1}',
    surfaceType: PitchSurfaceType.syntheticTurf,
    hasLighting: true,
    status: VenueOperationalStatus.active,
  ),
);
```

### Justificación
- **Velocidad de Creación (<45s)**: Minimiza la cantidad de campos requeridos en el alta rápida sin sacrificar el modelo relacional estricto de `SportsVenue` (que exige al menos 1 cancha activa).
- **Consistencia de Dominio**: Todas las canchas quedan en estado `active`, con iluminación y superficie estándar, listas para recibir partidos del fixture. La personalización de nombres o superficies individuales puede realizarse posteriormente desde la pantalla de detalle de sede.

---

## 4. Extensión del Modelo de Competición (`ChampionshipTournament.venueIds`)

### Decisión
Incorporar el atributo inmutable `venueIds` a `ChampionshipTournament` y `TournamentDraft`:
```dart
class ChampionshipTournament {
  ...
  final List<String> venueIds;
  ...
}

class TournamentDraft {
  ...
  final List<String> venueIds;
  ...
}
```
Con valor por defecto `const <String>[]` para garantizar 100% de retrocompatibilidad con torneos ya almacenados en Hive / JSON.

### Justificación
- **Alineación con la Resolución de Clarificaciones**: Permite que un torneo tenga una o múltiples sedes oficiales asociadas, reflejando torneos metropolitanos o zonales con varias canchas simultáneas.
- **Selección Reactiva**: Al confirmarse la creación de una nueva sede, su `id` se incorpora automáticamente a la lista `_selectedVenueIds` del formulario del torneo.

---

## 5. Experiencia de Usuario y Selector de Sedes

### Decisión
Construir una sección visual en `TournamentFormScreen` compuesta por:
1. **Selector múltiple de sedes**: Presentado mediante Chips seleccionables (`FilterChip` con estilos KickPulse) o menú desplegable con checkboxes.
2. **Acción "+ Crear Nueva Sede"**: Botón tipo `KickPulseButton.secondary` o icono que abre el `CreateVenueBottomSheet`.
3. **Estado de catálogo vacío**: Si `venues.isEmpty`, se muestra un contenedor informativo con texto amigable ("No hay sedes registradas todavía") y botón primario para crear la primera sede.
4. **Localización estricta (`l10n`)**: Agregar las claves correspondientes a `app_en.arb` y `app_es.arb` sin ningún texto quemado en el código.
