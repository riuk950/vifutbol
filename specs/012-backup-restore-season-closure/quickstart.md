# Quickstart Validation Guide: Exportación e Importación de Respaldos y Cierre Histórico de Temporada (HU 9.2)

**Feature**: `012-backup-restore-season-closure`  
**Date**: 2026-11-05

---

## Prerequisites

- Flutter SDK (`>=3.41.0`) y Dart (`>=3.11.0`)
- Dependencias instaladas (`flutter pub get`)
- Archivos de localización generados (`flutter gen-l10n`)

---

## Validation Scenarios

### Scenario 1: Exportación, Rechazo de Archivo Corrupto y Restauración Atómica (US1)
1. Iniciar sesión con rol **`Organizador`** y navegar a la pestaña **Posiciones**.
2. En la tarjeta de gestión del campeonato seleccionado, pulsar **"Respaldo del torneo"**.
3. Verificar que se genera el paquete con versión de esquema (`schemaVersion: 1`) y el resumen de equipos, jugadores, partidos y noticias, permitiendo copiar/guardar el respaldo con mensaje de éxito en español.
4. En la sección **"Importar respaldo"**, introducir un JSON inválido o con un equipo huérfano y pulsar **"Validar e importar"**.
5. Verificar que la operación se aborta sin modificar los datos actuales y muestra exactamente:
   `"El archivo de respaldo no es válido o está incompleto. No se realizaron cambios."`
6. Introducir un respaldo válido, verificar que se presenta el diálogo de confirmación de dos pasos con la casilla obligatoria, marcar la casilla y confirmar la restauración.

### Scenario 2: Cierre Oficial de Temporada y Publicación del Cuadro de Honor (US2)
1. Como **`Organizador`**, seleccionar un campeonato en curso (`En Curso`) cuyos partidos obligatorios o gran final estén en estado `Finalizado`.
2. Pulsar **"Finalizar Campeonato"**.
3. Verificar que se muestra la vista previa del **Cuadro de Honor** (**Campeón**, **Subcampeón**, **Máximo Goleador** y **Valla Menos Vencida**) junto con la casilla de confirmación de seguridad de dos pasos.
4. Marcar la casilla y confirmar el cierre oficial.
5. Verificar que el estado del campeonato cambia a **`Finalizado`** y que la tarjeta destacada del **Cuadro de Honor** aparece visible para todos los roles (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`).

### Scenario 3: Modo de Consulta Histórica Permanente (US3)
1. En un campeonato en estado **`Finalizado`**, verificar que los botones de edición de reglas, inscripción de jugadores, generación de fixture y creación de noticias están bloqueados/ocultos, mientras que la consulta histórica y la opción **"Exportar respaldo del torneo"** permanecen activas para el `Organizador`.

---

## Automated Verification Commands

```bash
# 1. Regenerar localizaciones en español
flutter gen-l10n

# 2. Ejecutar pruebas unitarias de entidades, validación de respaldos y cierre de temporada
flutter test test/unit/domain/backup_and_honor_roll_entities_test.dart
flutter test test/unit/application/tournament_backup_use_cases_test.dart
flutter test test/unit/application/close_tournament_season_use_case_test.dart

# 3. Ejecutar pruebas de widgets (respaldos, cuadro de honor y responsividad 320px/130%)
flutter test test/widget/tournament_backup_restore_widget_test.dart
flutter test test/widget/season_closure_honor_roll_widget_test.dart

# 4. Ejecutar suite completa y análisis estático
flutter analyze
flutter test
```
