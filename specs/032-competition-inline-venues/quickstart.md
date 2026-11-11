# Quickstart: Creación y Vinculación de Sedes en el Formulario de Nueva Competición (HU 18.1)

**Feature**: `032-competition-inline-venues`  
**Date**: 2026-11-11  

Esta guía describe cómo verificar y validar la funcionalidad de creación y vinculación en línea de sedes deportivas dentro del formulario de nueva competición.

---

## 1. Prerrequisitos

- Entorno de Flutter configurado: Flutter $\ge 3.44.0$, Dart $\ge 3.12.0$.
- Dependencias instaladas:
  ```bash
  flutter pub get
  ```

---

## 2. Ejecución de Pruebas Automatizadas

### A. Pruebas Unitarias de Dominio y Casos de Uso
Verifica que las entidades `ChampionshipTournament` y `TournamentDraft` soportan `venueIds` con valores por defecto y serialización JSON defensiva, y que `ManageVenuesUseCase` valida la unicidad de nombre:

```bash
flutter test test/domain/championship_tournament_venues_test.dart \
  test/application/use_cases/manage_venues_duplicate_validation_test.dart
```

### B. Pruebas de Widget e Interacción UI
Verifica el comportamiento del `CreateVenueBottomSheet` y la integración en `TournamentFormScreen`:

```bash
flutter test test/presentation/venues/create_venue_bottom_sheet_test.dart \
  test/presentation/tournaments/tournament_form_screen_venues_test.dart
```

### C. Análisis Estático y Formateo
```bash
flutter analyze
dart format --output=none --set-exit-if-changed lib/ test/
```

---

## 3. Escenarios de Validación Manual (Flujo en Aplicación)

1. **Iniciar la aplicación en modo desarrollo**:
   ```bash
   flutter run --flavor dev --target lib/env/main.dev.dart
   ```
2. **Navegar a la creación de torneo**:
   - Abrir el panel de organizador (`/panel`).
   - Pulsar sobre "Nueva Competición" (`/tournaments/form`).
3. **Comprobar la sección "Sedes Oficiales"**:
   - Desplazarse hacia abajo hasta encontrar la sección de sedes deportivas.
   - Si no hay sedes, observar el mensaje "No hay sedes registradas todavía" y el botón "+ Crear Nueva Sede".
4. **Probar el flujo de creación en línea**:
   - Escribir un nombre de torneo de prueba (ej. "Torneo Apertura 2026").
   - Pulsar "+ Crear Nueva Sede".
   - Verificar que emerge un Modal Bottom Sheet deslizable.
   - Ingresar datos: Nombre ("Sede Central"), Dirección ("Av. Deportiva 123"), Canchas ("3").
   - Confirmar la creación.
5. **Verificar estado resultante**:
   - El bottom sheet se cierra suavemente.
   - La nueva sede "Sede Central" aparece seleccionada en la lista del torneo.
   - El campo "Nombre del Torneo" mantiene intacto su valor ("Torneo Apertura 2026").
   - Guardar el torneo y verificar que se persiste exitosamente con la sede asignada.
