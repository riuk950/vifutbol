# Quickstart & Verification Guide: Reorganización del Panel de Organización (HU 18.2)

**Feature**: `033-organizer-panel-menu`  
**Date**: 2026-11-11  

---

## 1. Verificación Automatizada

### Ejecución de Pruebas Unitarias y de Widgets del Panel:

```bash
flutter test test/presentation/panel/organizer_panel_widget_test.dart
```

### Ejecución de Análisis Estático y Formateo:

```bash
flutter analyze
dart format --output=none --set-exit-if-changed lib/ test/
```

---

## 2. Escenarios de Verificación Manual

### Escenario 1: Verificación de Limpieza del Cuerpo del Panel
1. Iniciar sesión como usuario con rol de **Organizador** (`UserRole.organizer`).
2. Abrir el menú lateral y presionar **"Panel Administrativo"** (`/panel`).
3. Verificar visualmente que:
   - Aparece el resumen de métricas (Torneos Activos, Partidos Pendientes, Torneos sin Fixture).
   - Inmediatamente debajo se ubica la sección **"Mis Competiciones"** con la lista o estado vacío.
   - **NO** aparece ningún bloque de "Acciones Rápidas" con botones de generar fixture o programar partido.

### Escenario 2: Despliegue de Menú en AppBar y Opciones Depuradas
1. En la barra superior (`AppBar`), verificar que existe un botón con icono de tres puntos verticales (`Icons.more_vert`).
2. Presionar el botón de tres puntos.
3. Verificar que se despliega un menú con exactamente dos opciones:
   - **Publicar Noticia** (ícono de megáfono/comunicado)
   - **Copia de Seguridad** (ícono de respaldo/disco)
4. Confirmar que no hay opciones de fixture ni calendario.

### Escenario 3: Ejecución de Acciones Globales
1. Seleccionar **"Publicar Noticia"**: comprobar que se despliega el diálogo de creación de noticias (`CreateNewsDialog`).
2. Cerrar el diálogo y volver a abrir el menú de tres puntos.
3. Seleccionar **"Copia de Seguridad"**: comprobar que se despliega la hoja de exportación/importación de respaldos (`TournamentBackupSheet`).

### Escenario 4: Segregación de Roles
1. Conmutar el rol a **Entrenador**, **Árbitro** o **Jugador**.
2. Acceder al Panel Administrativo.
3. Verificar que en la barra superior **NO** aparece el menú de tres puntos del organizador.
