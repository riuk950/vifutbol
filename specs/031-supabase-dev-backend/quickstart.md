# Quickstart: Conexión e Integración del Backend Supabase DEV (HU 17.1)

**Feature**: `031-supabase-dev-backend`  
**Date**: 2026-11-10  

Esta guía explica cómo ejecutar la aplicación KickPulse (`vifutbol`) conectada a la instancia self-hosted de desarrollo de Supabase en Oracle Cloud, o en modo local desconectado.

---

## 1. Configuración de Credenciales (.env.dev y .env.prod)

El aprovisionamiento de credenciales se maneja de forma aislada por entorno:

### Desarrollo (Oracle Cloud Self-Hosted):
```bash
cp .env.dev.example .env.dev
```
Edita `.env.dev`:
```env
SUPABASE_URL=https://supabase.artbusinesstechnology.com
SUPABASE_ANON_KEY=tu_clave_anon_de_oracle_aqui
```

### Producción (Supabase Cloud Oficial):
```bash
cp .env.prod.example .env.prod
```
Edita `.env.prod`:
```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu_clave_anon_de_produccion_aqui
```

> ⚠️ **IMPORTANTE**: Nunca subas los archivos `.env.dev` ni `.env.prod` al repositorio Git. Ya están protegidos en `.gitignore`.

---

## 2. Ejecutar la Aplicación

### Modo Desarrollo (Oracle Cloud):
```bash
flutter run --flavor dev --target lib/env/main.dev.dart --dart-define-from-file=.env.dev
```

### Modo Producción (Supabase Cloud):
```bash
flutter run --flavor prod --target lib/env/main.prod.dart --dart-define-from-file=.env.prod
```

También es posible inyectar parámetros individuales directamente vía CLI si se prefiere:
```bash
flutter run --flavor dev --target lib/env/main.dev.dart \
  --dart-define=SUPABASE_URL=https://supabase.artbusinesstechnology.com \
  --dart-define=SUPABASE_ANON_KEY=tu_clave_anon_de_oracle_aqui
```

O si utilizas un archivo de configuración en tu entorno de desarrollo (VS Code / Android Studio):
```json
{
  "name": "vifutbol (DEV Supabase)",
  "type": "dart",
  "request": "launch",
  "program": "lib/main.dart",
  "toolArgs": [
    "--dart-define", "SUPABASE_URL=https://supabase.artbusinesstechnology.com",
    "--dart-define", "SUPABASE_ANON_KEY=tu_clave_anon_de_desarrollo_aqui"
  ]
}
```

---

## 3. Ejecutar en Modo Local Puro (Offline / Sin Backend)

Si no suministras variables `--dart-define`, la aplicación arrancará automáticamente en modo puramente local utilizando Hive como fuente de datos:

```bash
flutter run
```

En la consola de depuración observarás:
```text
[Supabase] No se suministraron credenciales; operando en modo local (Hive).
```

---

## 4. Verificación de Health Check

Al arrancar conectado a Supabase DEV, la aplicación valida la conectividad en segundo plano con el API Gateway (Kong):

```text
[SupabaseDev] Conectado exitosamente al host self-hosted (Latencia: 142ms)
```

---

## 5. Ejecutar la Suite de Pruebas

Para ejecutar las pruebas unitarias y de integración de Supabase:

```bash
flutter test test/unit/infrastructure/supabase_config_test.dart
flutter test test/unit/application/check_supabase_backend_health_use_case_test.dart
```
