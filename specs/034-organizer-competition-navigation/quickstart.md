# Quickstart & Validation Guide: Navegación a Detalles de la Competición (HU 18.3)

**Feature**: `034-organizer-competition-navigation`  
**Date**: 2026-11-11  

---

## 1. Prerrequisitos

- Rama de trabajo `develop` actualizada.
- Entorno Flutter configurado (`flutter --version`).
- Archivo de especificación y contratos revisados en `specs/034-organizer-competition-navigation/`.

---

## 2. Validación Automatizada (Pruebas de Widget e Integración)

### Ejecutar Suite de Pruebas de Competiciones del Panel
```bash
flutter test test/presentation/panel/organizer_competitions_section_test.dart
```

### Escenarios Verificados en Pruebas
1. **Navegación por tap en tarjeta**: Al pulsar `Key('organizer_competition_card_<id>')`, se invoca `selectTournament(id)` y la aplicación navega hacia `/competitions/<id>` mostrando `CompetitionDetailScreen`.
2. **Retorno al Panel**: Al pulsar el botón de regreso en la pantalla de detalle, el usuario retorna a `PanelScreen`.
3. **Aislamiento del menú de opciones**: Al pulsar `Key('organizer_competition_menu_button_<id>')`, se abre el `PopupMenuButton` con opciones ("Editar metadatos", "Cambiar estado de competición", "Eliminar competición") y no se dispara ninguna navegación.
4. **Protección contra doble toque (Debouncing)**: Al ejecutar dos toques consecutivos con un intervalo < 500 ms sobre la misma tarjeta, el navegador registra exactamente una única ruta apilada.

---

## 3. Análisis Estático y Formato
```bash
flutter analyze
dart format --output=none --set-exit-if-changed lib/ test/
```
Resultado esperado: `No issues found!` y `0 changed` en formateo.

---

## 4. Validación Manual End-to-End

1. Abrir la app como Organizador (`UserRole.organizer`).
2. Acceder al **Panel de Organización**.
3. Ubicar la sección **"Mis Competiciones"** con al menos un torneo listado.
4. Tocar sobre la tarjeta de un torneo → Confirmar transición fluida a `CompetitionDetailScreen` con título, estado y pestañas del torneo seleccionado, y herramientas de administrador (FAB).
5. Tocar botón de regreso → Confirmar retorno al Panel en el mismo estado.
6. Tocar el botón de tres puntos (`⋮`) de una tarjeta → Confirmar apertura del menú sin navegación accidental.
