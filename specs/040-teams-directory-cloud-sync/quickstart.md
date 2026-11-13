# Quickstart Validation Guide: Directorio de Equipos (HU 19.2)

**Feature**: `040-teams-directory-cloud-sync`  
**Date**: 2026-11-13

## Prerequisites

- Entorno Flutter configurado y emulador Android o dispositivo conectado (para validación manual).
- Configuración de entorno DEV apuntando a Supabase self-hosted (`vifutboldev`).
- Referencias: [data-model.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/040-teams-directory-cloud-sync/data-model.md) y [teams-directory-contracts.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/040-teams-directory-cloud-sync/contracts/teams-directory-contracts.md).

## 1. Automated Verification

Ejecutar análisis estático y suite de pruebas unitarias y de widgets:

```bash
flutter analyze
flutter test \
  test/unit/infrastructure/sync/hybrid_teams_repository_teams_test.dart \
  test/unit/application/teams_directory_controller_test.dart \
  test/presentation/teams_directory_screen_test.dart \
  test/presentation/directories_responsive_widget_test.dart
```

**Expected Outcome**:
- `flutter analyze` finaliza con `No issues found!`.
- 100% de las pruebas pasan verificando:
  - Ausencia total de `ChoiceChip` y `Key('teams_tournament_selector')`.
  - Consulta a `vifutboldev.teams`, hidratación en Hive y fallback offline.
  - Ordenamiento alfabético A-Z, búsqueda sin tildes/mayúsculas y Pull-to-Refresh offline con `SnackBar`.

## 2. End-to-End Validation Scenarios (Emulator / Device)

1. **Verificación visual sin chips**:
   - Abrir el menú lateral y navegar a **Equipos**.
   - Confirmar que debajo de la barra de búsqueda aparece directamente la lista de clubes sin selector horizontal de torneos.
2. **Carga dinámica desde Supabase DEV (incluyendo club sin torneo)**:
   - Confirmar que los clubes registrados en `vifutboldev.teams` (con y sin torneo asignado) se listan ordenados de la A a la Z mostrando nombre, escudo, categoría/estado y conteo de jugadores.
3. **Búsqueda reactiva**:
   - Escribir parte del nombre o sigla en el buscador (sin tildes ni mayúsculas exactas) y verificar el filtrado instantáneo.
4. **Navegación a detalle**:
   - Tocar un club (incluyendo uno sin torneo) y confirmar que abre `TeamDetailScreen` sin errores.
5. **Resiliencia Offline y Pull-to-Refresh**:
   - Activar modo avión, deslizar hacia abajo para refrescar y confirmar que los equipos cacheados permanecen visibles y aparece el `SnackBar` de advertencia offline en español.
