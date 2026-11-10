# Quickstart: Conexión e Integración del Backend Supabase DEV (HU 17.1)

**Feature**: `031-supabase-dev-backend`  
**Date**: 2026-11-10  

Esta guía explica cómo ejecutar la aplicación KickPulse (`vifutbol`) conectada a la instancia self-hosted de desarrollo de Supabase en Oracle Cloud, o en modo local desconectado.

---

## 1. Configuración de Credenciales

Copia el archivo de plantilla `.env.example` para preparar tus variables locales:

```bash
cp .env.example .env
```

Edita `.env` agregando tu clave anónima del servidor:

```env
SUPABASE_URL=https://supabase.artbusinesstechnology.com
SUPABASE_ANON_KEY=tu_clave_anon_de_desarrollo_aqui
```

> ⚠️ **IMPORTANTE**: Nunca subas el archivo `.env` al repositorio Git. Ya está protegido en `.gitignore`.

---

## 2. Ejecutar la Aplicación con Supabase DEV

Para ejecutar en modo desarrollo conectado a Oracle Cloud:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://supabase.artbusinesstechnology.com \
  --dart-define=SUPABASE_ANON_KEY=tu_clave_anon_de_desarrollo_aqui
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
