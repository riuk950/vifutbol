# Implementation Plan: Conexión e Integración del Backend Supabase DEV (Self-Hosted Docker en Oracle Cloud) (HU 17.1)

**Branch**: `031-supabase-dev-backend` | **Date**: 2026-11-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/031-supabase-dev-backend/spec.md`

---

## Summary

Integrar e inicializar el cliente oficial `supabase_flutter: ^2.18.3` dentro de la arquitectura de KickPulse (`vifutbol`), apuntando al backend self-hosted desplegado en un contenedor Docker sobre Ubuntu en Oracle Cloud (`https://supabase.artbusinesstechnology.com`). Se garantiza la inyección segura de credenciales mediante `--dart-define` (`SUPABASE_URL` y `SUPABASE_ANON_KEY`) sin secretos en el repositorio, conmutación automática y transparente al modo local (Hive) ante ausencia de credenciales o pérdida de red, y una comprobación de salud (*health check*) asíncrona no bloqueante contra PostgREST (`/rest/v1/`).

---

## Technical Context

**Language/Version**: Dart 3.x (`sdk: ^3.12.0`) & Flutter 3.x  
**Primary Dependencies**: `supabase_flutter: ^2.18.3`, `flutter_riverpod: ^2.6.1`, `hive: ^2.2.3`, `connectivity_plus: ^6.1.4`, `http: ^1.2.0`  
**Storage**: Híbrido — PostgreSQL (Supabase self-hosted en la nube) + Hive (caché local tolerante a fallos offline)  
**Testing**: `flutter_test`, `mocktail: ^1.0.4`  
**Target Platform**: Android, iOS, Web, macOS  
**Project Type**: Mobile / Web Application (Flutter)  
**Performance Goals**: Inicialización del cliente en <500 ms; verificación de salud en segundo plano con timeout máximo de 5000 ms sin bloquear la interfaz.  
**Constraints**: Cero credenciales quemadas en el código; estricto aislamiento entre desarrollo y producción; funcionamiento garantizado 100% offline.  
**Scale/Scope**: Base de backend para toda la Épica 17 (torneos, equipos, partidos, actas y noticias).

---

## Constitution Check

*GATE: Evaluado contra la Constitución del Proyecto (v2.0.0).*

1. **Principio I (La Spec Manda)**:
   - ✅ **Cumple**: Todo cambio funcional y técnico surge de `spec.md`, validado contra `docs/MOBILE_GUIDELINES.md` y con 3 clarificaciones registradas en la sesión.
2. **Principio II (Integridad de Datos y Fuente de Verdad Transparente)**:
   - ✅ **Cumple**: La integración con Supabase PostgreSQL establece la base relacional en la nube manteniendo consistencia determinista con la caché local de Hive.
3. **Principio III (Pruebas Automatizadas como Puerta de Calidad)**:
   - ✅ **Cumple**: El plan incluye pruebas unitarias para `SupabaseConfig`, `CheckSupabaseBackendHealthUseCase` y pruebas de integración para el arranque y conmutación offline.
4. **Principio IV (Arquitectura Limpia y Separación de Responsabilidades)**:
   - ✅ **Cumple**: `SupabaseConfig` y `BackendHealthStatus` en Dominio; `CheckSupabaseBackendHealthUseCase` y proveedores en Aplicación; clientes HTTP y bootstrap en Infraestructura.
5. **Principio V (Segregación de Roles y Fidelidad al Sistema de Diseño)**:
   - ✅ **Cumple**: El backend respeta el RBAC y los diagnósticos/logs no alteran la presentación visual aprobada.
6. **Principio VI (Convenciones de Idioma y Nomenclatura)**:
   - ✅ **Cumple**: Todo el código técnico, identificadores, providers, clases y pruebas están 100% en inglés; mensajes visuales y localizaciones en español (`l10n`).
7. **Principio VII (Resiliencia y Experiencia Móvil)**:
   - ✅ **Cumple**: Conmutación transparente a modo local cuando no hay red o credenciales; timeout estricto de 5s; health check en segundo plano sin bloquear el arranque.

---

## Project Structure

### Documentation (this feature)

```text
specs/031-supabase-dev-backend/
├── plan.md              # Este plan de implementación
├── spec.md              # Especificación funcional con clarificaciones
├── research.md          # Investigación técnica (SDK, Kong, OCI, seguridad)
├── data-model.md        # Modelos de datos (SupabaseConfig, BackendHealthStatus)
├── quickstart.md        # Guía paso a paso para ejecutar con --dart-define
├── contracts/           # Contratos de interfaz y protocolos de sonda HTTP
│   └── supabase-backend-contracts.md
└── checklists/          # Listas de verificación de calidad
    └── requirements.md
```

### Source Code Architecture Layout

```text
lib/
├── domain/
│   └── entities/
│       ├── app_environment.dart                  # Extensión con SupabaseConfig y validación
│       └── backend_health_status.dart             # Modelos de salud y resultado de conexión
├── application/
│   ├── providers/
│   │   └── supabase_providers.dart               # supabaseConfigProvider, supabaseClientProvider, etc.
│   └── use_cases/
│       └── check_supabase_backend_health_use_case.dart # Handshake HTTP contra PostgREST /rest/v1/
├── infrastructure/
│   └── network/
│       └── supabase_health_client.dart            # Sonda HTTP con timeout y control de excepciones
└── app_bootstrap.dart                             # Inicialización condicional de Supabase.initialize()

test/
├── unit/
│   ├── infrastructure/
│   │   └── supabase_config_test.dart              # Pruebas de inyección, valores por defecto y ofuscación
│   └── application/
│       └── check_supabase_backend_health_use_case_test.dart # Pruebas con mocks de handshake 200, 401 y timeout
```

---

## Phases & Planned Implementation Steps

### Phase 0: Research & Alignment (COMPLETED)
- Verificación de resolución de dependencias con `supabase_flutter: ^2.18.3` en Dart 3 / Flutter 3.
- Definición de topología Kong / PostgREST en Oracle Cloud.
- Elaboración de `research.md`.

### Phase 1: Design Artifacts (COMPLETED)
- Elaboración de `data-model.md` con `SupabaseConfig` y `BackendHealthStatus`.
- Especificación de contratos en `contracts/supabase-backend-contracts.md`.
- Documentación de inicio rápido en `quickstart.md`.

### Phase 2: Implementation & Quality Gates (Scheduled for `/speckit-tasks`)
- **Paso 1: Dependencias y Plantilla de Entorno**: Agregar `supabase_flutter` a `pubspec.yaml`, crear `.env.example` y actualizar `README.md`.
- **Paso 2: Modelos de Dominio**: Implementar `SupabaseConfig` en `app_environment.dart` y `BackendHealthStatus`.
- **Paso 3: Infraestructura de Red**: Crear `SupabaseHealthClient` para ejecutar el handshake con PostgREST.
- **Paso 4: Casos de Uso y Providers**: Implementar `CheckSupabaseBackendHealthUseCase` y los providers de Riverpod.
- **Paso 5: Integración en Bootstrap**: Actualizar `lib/app_bootstrap.dart` para inicialización condicional y health check no bloqueante.
- **Paso 6: Pruebas y Verificación**: Crear pruebas unitarias con mocktail, ejecutar `flutter test`, `flutter analyze` y `dart format`.
