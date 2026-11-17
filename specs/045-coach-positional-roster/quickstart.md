# Quickstart Validation Guide: Visualización de Plantilla Agrupada por Posición (HU 20.2)

**Feature**: `045-coach-positional-roster`

## Validation Steps

1. **Regenerar localización**:
   ```bash
   flutter gen-l10n
   ```
2. **Análisis estático**:
   ```bash
   flutter analyze
   ```
   Esperado: `No issues found!`.
3. **Pruebas unitarias y de widgets**:
   ```bash
   flutter test test/unit/presentation/team_squad_roster_test.dart test/presentation/panel/coach_positional_roster_test.dart test/presentation/panel/coach_panel_widget_test.dart test/presentation/panel/coach_panel_responsive_test.dart
   ```
   Esperado: 100% de pruebas superadas sin overflow en pantallas de 320px/360px.
