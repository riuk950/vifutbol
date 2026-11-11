# Contracts: Creación y Vinculación de Sedes en el Formulario de Nueva Competición (HU 18.1)

**Feature**: `032-competition-inline-venues`  
**Date**: 2026-11-11  

---

## 1. Contratos de Componentes de Presentación

### `CreateVenueBottomSheet`

Modal Bottom Sheet deslizable que encapsula el formulario de creación rápida de sede deportiva.

```dart
/// Despliega el bottom sheet modal para registrar una nueva sede deportiva.
/// Retorna la [SportsVenue] creada si el flujo fue exitoso, o `null` si fue cancelado.
Future<SportsVenue?> showCreateVenueBottomSheet(BuildContext context);
```

#### Propiedades y Parámetros del Widget:
```dart
class CreateVenueBottomSheet extends ConsumerStatefulWidget {
  const CreateVenueBottomSheet({
    super.key,
    this.initialCoordinates = const GeoCoordinate(
      latitude: 4.6097,
      longitude: -74.0817,
    ),
  });

  final GeoCoordinate initialCoordinates;

  @override
  ConsumerState<CreateVenueBottomSheet> createState() =>
      _CreateVenueBottomSheetState();
}
```

#### Inputs requeridos en el modal:
- `nameController`: `TextEditingController` (mínimo 3 caracteres, obligatorio).
- `addressController`: `TextEditingController` (mínimo 5 caracteres, obligatorio).
- `pitchesCountController`: `TextEditingController` (entero $\ge 1$, obligatorio).

#### Acciones:
- **Confirmar ("Crear Sede")**:
  1. Valida campos en el cliente.
  2. Valida unicidad contra `venuesControllerProvider` / `VenuesRepository`.
  3. Genera las canchas secuenciales ("Cancha 1", ..., "Cancha N").
  4. Persiste la sede mediante `venuesControllerProvider.notifier.saveVenue(...)` o `ManageVenuesUseCase`.
  5. Cierra el modal retornando la instancia creada (`Navigator.of(context).pop(createdVenue)`).
- **Cancelar ("Cancelar" o deslizar hacia abajo)**:
  1. Cierra el modal sin persistir (`Navigator.of(context).pop(null)`).

---

## 2. Contrato de Integración en `TournamentFormScreen`

### Estado Interno del Formulario:
```dart
class _TournamentFormScreenState extends ConsumerState<TournamentFormScreen> {
  ...
  late List<String> _selectedVenueIds; // Lista de IDs de sedes vinculadas al torneo
  ...
}
```

### Invocación desde el botón "+ Crear Nueva Sede":
```dart
Future<void> _handleCreateNewVenue() async {
  final newVenue = await showCreateVenueBottomSheet(context);
  if (newVenue != null && mounted) {
    setState(() {
      if (!_selectedVenueIds.contains(newVenue.id)) {
        _selectedVenueIds.add(newVenue.id);
      }
      _isDirty = true;
    });
  }
}
```

---

## 3. Contrato de Caso de Uso y Repositorio

### `ManageVenuesUseCase.saveVenue`
```dart
class ManageVenuesUseCase {
  /// Guarda o actualiza una sede validando longitud mínima, coordenadas,
  /// al menos 1 cancha activa y unicidad de nombre de sede en el repositorio.
  Future<void> saveVenue(SportsVenue venue);
}
```

### `TournamentsController.saveTournament`
```dart
Future<void> saveTournament({
  required String name,
  required String category,
  required DateTime startDate,
  required DateTime endDate,
  required TournamentFormat format,
  required TournamentRulesConfig rules,
  required List<String> venueIds, // <-- NUEVO PARÁMETRO
  String? existingId,
});
```

---

## 4. Contrato de Localización (`l10n`)

Claves requeridas en `lib/l10n/app_es.arb` y `lib/l10n/app_en.arb`:

| Clave | Español (`app_es.arb`) | Inglés (`app_en.arb`) |
|---|---|---|
| `venuesSectionTitle` | "Sedes Oficiales" | "Official Venues" |
| `venuesSectionSubtitle` | "Selecciona las sedes donde se disputarán los partidos" | "Select the venues where matches will take place" |
| `noVenuesRegistered` | "No hay sedes registradas todavía" | "No registered venues yet" |
| `createNewVenue` | "Crear Nueva Sede" | "Create New Venue" |
| `venueNameLabel` | "Nombre de la Sede" | "Venue Name" |
| `venueAddressLabel` | "Dirección" | "Address" |
| `venuePitchesCountLabel` | "Número de Canchas" | "Number of Pitches" |
| `venueNameTooShort` | "El nombre debe tener al menos 3 caracteres" | "Name must have at least 3 characters" |
| `venueAddressTooShort` | "La dirección debe tener al menos 5 caracteres" | "Address must have at least 5 characters" |
| `venuePitchesInvalid` | "Debe tener al menos 1 cancha" | "Must have at least 1 pitch" |
| `venueNameDuplicate` | "Ya existe una sede con este nombre. Selecciónala de la lista o elige otro nombre." | "A venue with this name already exists. Select it from the list or choose another name." |
