# Quickstart & Validation Guide: HU 1.1 — Fundación de la Aplicación, Aislamiento de Entornos, Localización y Sistema de Diseño

**Feature**: `001-app-foundation-design`  
**Date**: 2026-11-03

---

## 1. Prerequisites

- Flutter SDK `>= 3.11.0` y Dart SDK `>= 3.11.0`.
- Dispositivo físico, emulador Android o simulador iOS configurado en orientación vertical.

---

## 2. Setup & Code Generation

Instalar dependencias y generar los archivos de localización (`l10n`):

```bash
flutter pub get
flutter gen-l10n
```

---

## 3. Running Isolated Environments (`FR-001`)

### Entorno de Desarrollo (`dev`)
```bash
flutter run --flavor dev --target lib/env/main.dev.dart
```
**Resultado esperado**:
- La aplicación inicia en orientación vertical (*Portrait*) con el tema *KickPulse Mobile* (`#080B11`).
- Muestra la insignia no intrusiva `DEV` en la barra superior.
- Utiliza el espacio de almacenamiento local aislado `vifutbol_dev`.

### Entorno de Producción (`prod`)
```bash
flutter run --flavor prod --target lib/env/main.prod.dart
```
**Resultado esperado**:
- La aplicación inicia sin insignias de depuración ni `DEV`.
- Utiliza el espacio de almacenamiento local aislado `vifutbol_prod`.

---

## 4. Verification of Quality Gates (`Constitution Check`)

### 4.1 Análisis Estático (0 errores, 0 advertencias)
```bash
flutter analyze
```

### 4.2 Ejecución de Pruebas Automatizadas y Cobertura
```bash
flutter test --coverage
```

**Escenarios validados por la suite de pruebas**:
1. **Aislamiento de Entornos**: `EnvironmentConfig.development()` y `EnvironmentConfig.production()` mantienen prefijos de almacenamiento separados y ocultan credenciales en `toString()`.
2. **Tokens de Diseño y Ergonomía**: Colores exactos de `DESIGN.md`, `tabular-nums` activos en estilos numéricos y botones con área táctil mínima de `44x44px` y bloqueo contra pulsaciones repetidas.
3. **Localización en Español (`l10n`)**: Las 4 secciones del *App Shell* (*Jornada*, *Posiciones*, *Sedes*, *Perfil*) y los 5 estados de interfaz (*Carga*, *Contenido*, *Vacío*, *Error*, *Éxito*) se renderizan 100% en español.
4. **Banner Reactivo de Conectividad**: Oculto cuando hay red; persistente al perder conexión; y visible en verde (*"Conexión restaurada"*) durante 3 segundos al recuperar red antes de ocultarse automáticamente.
5. **Conservación de Estado y Ciclo de Vida**: La pestaña activa del *App Shell* y el estado de la vista se conservan tras eventos de paso a segundo plano y retorno a primer plano.
