# Feature Specification: Creación y Aprovisionamiento del Esquema `vifutboldev` en Backend DEV (HU 17.2)

**Feature Branch**: `develop`  
**Feature Directory**: `specs/036-supabase-vifutboldev-schema`  
**Created**: 2026-11-11  
**Status**: Draft  
**Input**: User description: "HU 17.2: Creación y Aprovisionamiento del Esquema `vifutboldev` en Supabase Self-Hosted (SSH / Docker)" (Notion ID: `4158442e-3f49-81d8-8934-fb295990ac7d`)

---

## Clarifications

### Session 2026-11-11

- Q: ¿Cómo deben comportarse las políticas de seguridad por fila (RLS) en `vifutboldev` mientras la aplicación en DEV aún no tiene flujo de inicio de sesión remoto conectado a Supabase Auth? → A: Aplicar RLS estricto desde ahora (lectura pública controlada para `anon` en catálogos/resultados públicos y escrituras restringidas a `authenticated`/roles vía `(select auth.uid())`), probando escrituras DEV mediante usuario autenticado de prueba o `service_role`.
- Q: Al modelar la relación entre clubes (`teams`), inscripciones (`tournament_teams`), jugadores (`players`) y partidos (`matches`) en `vifutboldev`, ¿qué nivel de relación debe aplicarse? → A: Modelo normalizado por inscripción: `teams` guarda la identidad maestra del club (`coach_id`), `tournament_teams` representa la participación `(tournament_id, team_id, group_name, eligibility_status)`, y `players`, `matches` y `match_lineup_convocations` se vinculan a `tournament_team_id`.
- Q: Dado que `vifutboldev` tendrá RLS estricto desde el inicio, ¿cómo debe ejecutarse la validación real de lectura y escritura contra DEV y el ajuste de Kong (`403` actual en `/rest/v1/`)? → A: Habilitar `/rest/v1/` en Kong + `PGRST_DB_SCHEMAS` para `vifutboldev` en el servidor DEV, verificar lectura pública desde Flutter (`anon key`) y validar escritura/limpieza real mediante una sesión `authenticated` de prueba (GoTrue) contra `vifutboldev`.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Aislamiento e Idempotencia del Esquema Relacional `vifutboldev` (Priority: P1) 🎯 MVP

Como Arquitecto / Desarrollador de KickPulse (`vifutbol`), quiero crear y versionar un esquema aislado denominado `vifutboldev` en el entorno de desarrollo remoto, separado de `public` y de otros proyectos compartidos en el mismo servidor, para alojar de forma segura, consistente e idempotente toda la información operativa de `vifutbol` en DEV.

**Why this priority**: Es la base física y relacional del entorno de desarrollo en la nube; sin el esquema aislado ni los scripts reproducibles, ninguna entidad ni flujo remoto puede persistirse sin riesgo de colisión con otras aplicaciones del servidor.

**Independent Test**: Ejecutar los scripts de aprovisionamiento versionados sobre el entorno DEV y re-ejecutarlos una segunda vez consecutiva; verificar que el esquema `vifutboldev` queda creado de forma independiente sin crear tablas de negocio en `public`, con permisos de acceso asignados por nivel de rol y sin errores por objetos duplicados al re-ejecutarse.

**Acceptance Scenarios**:

1. **Given** que el entorno de base de datos DEV aloja otros esquemas y proyectos en la misma instancia, **When** se ejecutan los scripts de aprovisionamiento de `vifutboldev`, **Then** se crea el esquema exclusivo `vifutboldev` separado de `public` y se otorgan los permisos de uso, lectura y escritura apropiados para los niveles de acceso público anónimo, autenticado y de servicio.
2. **Given** que el esquema `vifutboldev` ya existe parcial o totalmente en el servidor DEV, **When** se vuelven a ejecutar los scripts de migración, **Then** la ejecución finaliza exitosamente de forma idempotente sin duplicar objetos ni destruir datos existentes.
3. **Given** el repositorio del proyecto, **When** un desarrollador inspecciona el control de versiones, **Then** encuentra los scripts estructurados, ordenados e idempotentes almacenados para trazabilidad y futura replicación hacia otros entornos.

---

### User Story 2 - Modelo Relacional Completo de Entidades Deportivas (Priority: P1) 🎯 MVP

Como Desarrollador de KickPulse (`vifutbol`), quiero que el esquema `vifutboldev` contenga todas las entidades relacionales del dominio actual con sus identificadores únicos, relaciones referenciales, marcas temporales e índices de consulta, para garantizar integridad de verdad única entre identidad, sedes, torneos, equipos, partidos y actas arbitrales.

**Why this priority**: Asegura la integridad referencial estricta exigida por el Principio II de la Constitución y cubre los 18 conjuntos de datos construidos hasta la fecha en la aplicación.

**Independent Test**: Inspeccionar el catálogo de tablas, restricciones referenciales e índices dentro del esquema `vifutboldev`, confirmando la presencia de las entidades de los cinco módulos del dominio, sus llaves primarias únicas, claves foráneas indexadas y datos semilla iniciales coherentes en DEV.

**Acceptance Scenarios**:

1. **Given** el dominio actual de `vifutbol`, **When** se inspecciona el esquema `vifutboldev`, **Then** existen entidades con llave primaria única y columnas de auditoría temporal (`created_at`, `updated_at`) cubriendo los cinco bloques funcionales:
   - **Identidad y Preferencias**: cuentas de usuario (`user_accounts`) y equipos favoritos de aficionados (`fan_favorite_teams`).
   - **Infraestructura Deportiva**: sedes (`sports_venues`) y canchas por sede (`venue_pitches`).
   - **Competiciones y Gobernanza**: torneos (`tournaments`), auditoría de reglas (`rule_audit_entries`), cuadro de honor (`season_honor_rolls`) y comunicados (`tournament_news`).
   - **Equipos y Plantillas**: clubes (`teams`), inscripciones por torneo (`tournament_teams`), jugadores (`players`) y seguimiento interno de entrenador (`player_internal_trackings`).
   - **Partidos y Arbitraje**: árbitros (`match_referees`), partidos (`matches`), convocatorias/alineaciones (`match_lineup_convocations`), actas digitales (`digital_match_reports`), eventos (`match_events`) y alertas en vivo (`match_live_alerts`).
2. **Given** las relaciones padre-hijo y campos de consulta frecuente entre tablas (como torneo, equipo, organizador, entrenador o fecha programada), **When** se verifica la estructura de rendimiento, **Then** cada clave foránea y filtro operativo cuenta con su índice dedicado.

---

### User Story 3 - Seguridad de Acceso por Roles (RLS) (Priority: P2)

Como Responsable de Seguridad e Integridad Deportiva, quiero que todas las tablas del esquema `vifutboldev` cuenten con control de acceso por fila (RLS) alineado con la matriz de permisos de los cinco roles (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`), para impedir lecturas o escrituras no autorizadas sobre actas, alineaciones, reglas y datos privados.

**Why this priority**: Protege la integridad de las actas oficiales, convocatorias privadas de entrenadores y administración de campeonatos desde la primera conexión de clientes remotos.

**Independent Test**: Evaluar mediante consultas simuladas o pruebas de política que todas las tablas en `vifutboldev` tienen el control por fila habilitado y que las políticas diferencian lectura pública permitida, operaciones privadas del dueño/rol autorizado y restricciones administrativas.

**Acceptance Scenarios**:

1. **Given** que todas las tablas de negocio residen en `vifutboldev`, **When** se audita la postura de seguridad del esquema, **Then** el 100% de las tablas tiene el control de acceso por fila activado y políticas explícitas asociadas.
2. **Given** un usuario autenticado con un rol determinado o un visitante anónimo, **When** intenta consultar datos públicos (torneos, equipos, tabla, calendario, noticias) versus mutar entidades restringidas (crear torneos, aprobar equipos, cerrar actas arbitrales o leer seguimiento interno de otro entrenador), **Then** las políticas solo permiten acciones acordes a su rol y titularidad.

---

### User Story 4 - Exposición de API en DEV, Vinculación del Cliente y Prueba End-to-End (Priority: P2)

Como Desarrollador móvil en entorno DEV, quiero que el servicio de datos remoto exponga el esquema `vifutboldev` (manteniendo `public` intacto para el resto del servidor) y que el cliente DEV de la aplicación apunte por defecto a `vifutboldev`, para validar lecturas y escrituras reales desde la app sin afectar otros proyectos ni producción.

**Why this priority**: Sin exponer el esquema en la puerta de enlace del servidor DEV y dirigir el cliente hacia ese perfil, la aplicación seguiría consultando `public` o recibiendo errores de acceso.

**Independent Test**: Consultar la API REST remota de DEV solicitando el perfil `vifutboldev` y ejecutar una operación real de lectura/escritura desde la configuración DEV de la aplicación comprobando respuesta exitosa, mientras el entorno de producción conserva su configuración independiente sin cambios.

**Acceptance Scenarios**:

1. **Given** que el esquema `vifutboldev` está creado y poblado con estructura y permisos en el servidor DEV, **When** se habilita el esquema en la configuración de exposición de API del servidor y se reinicia el servicio correspondiente, **Then** el esquema resulta visible para administración en la consola visual y las peticiones dirigidas al perfil `vifutboldev` responden exitosamente (`200 OK`).
2. **Given** la configuración del cliente móvil para entorno DEV, **When** la aplicación se conecta contra el backend DEV, **Then** utiliza automáticamente el esquema `vifutboldev` para sus consultas de datos y verifica una operación de lectura/escritura real, manteniendo desconectado o intacto el esquema en producción hasta su despliegue oficial.

---

### Edge Cases

- **Re-ejecución de migraciones sobre datos ya cargados**: Si se vuelve a aplicar el aprovisionamiento tras existir datos semilla o pruebas en `vifutboldev`, las tablas, índices, triggers y semillas no deben fallar ni duplicar registros.
- **Esquemas compartidos en el mismo servidor DEV**: Otros proyectos existentes en el servidor (como esquemas previos de negocio o `public`) no deben perder permisos, exposición REST ni datos al añadir `vifutboldev`.
- **Operación offline cuando DEV no responde o falta configuración**: Si el dispositivo pierde conectividad hacia el host DEV o no tiene variables de entorno configuradas, la aplicación mantiene el respaldo local sin bloquear el arranque (continuidad con HU 17.1).
- **Entorno de producción aislado**: La configuración de esquema en desarrollo no debe alterar el comportamiento ni forzar un esquema inexistente en producción si producción aún no lo aprovisiona.
- **Políticas RLS frente a rendimiento**: Las reglas por fila deben evitar re-evaluar la identidad de sesión por cada fila en listados grandes para mantener respuestas rápidas.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE aprovisionar un esquema PostgreSQL exclusivo llamado `vifutboldev` en la instancia DEV, completamente separado de `public` y de cualquier otro esquema existente en el servidor.
- **FR-002**: Todos los objetos de base de datos del proyecto en DEV (tablas, restricciones, índices, funciones auxiliares, triggers y políticas) DEBEN crearse explícitamente bajo el namespace `vifutboldev` y diseñarse de forma idempotente para poder re-ejecutarse sin errores.
- **FR-003**: El esquema `vifutboldev` DEBE definir las tablas relacionales con llave primaria UUID autogenerada, columnas de marca temporal (`created_at`, `updated_at` actualizable automáticamente) e integridad referencial mediante claves foráneas para las 18 entidades del dominio actual:
  - Identidad y Preferencias: `user_accounts`, `fan_favorite_teams`.
  - Infraestructura Deportiva: `sports_venues`, `venue_pitches`.
  - Competiciones y Gobernanza: `tournaments`, `rule_audit_entries`, `season_honor_rolls`, `tournament_news`.
  - Equipos y Plantillas: `teams`, `tournament_teams`, `players`, `player_internal_trackings`.
  - Partidos y Arbitraje: `match_referees`, `matches`, `match_lineup_convocations`, `digital_match_reports`, `match_events`, `match_live_alerts`.
- **FR-004**: Toda columna de clave foránea y campo de filtrado operativo frecuente (`tournament_id`, `team_id`, `organizer_id`, `coach_id`, `venue_id`, `pitch_id`, `referee_id`, `match_id`, `scheduled_at`) DEBE contar con su índice dedicado para garantizar tiempos de consulta eficientes.
- **FR-005**: Todas las tablas de `vifutboldev` DEBEN otorgar privilegios coherentes a los roles del servidor (`anon`, `authenticated`, `service_role`, `postgres`, incluyendo privilegios por defecto), tener habilitado el control de acceso por fila (RLS) e implementar políticas estrictas alineadas con los permisos de los cinco roles (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`): lectura pública controlada para `anon` en catálogos/resultados públicos, aislamiento de datos privados (como `player_internal_trackings` y cuentas) y escrituras restringidas a usuarios `authenticated` autorizados evaluados mediante `(select auth.uid())`.
- **FR-006**: Los scripts SQL de aprovisionamiento (esquema, tablas, índices, triggers, políticas RLS y seed inicial de desarrollo) DEBEN quedar versionados y ordenados dentro del repositorio del proyecto.
- **FR-007**: El servidor DEV DEBE actualizar la lista de esquemas expuestos por su servicio de API REST incluyendo `vifutboldev` sin eliminar los esquemas ya activos (`public`, `storage`, `graphql_public`, etc.), asegurando su visibilidad tanto por API como en la consola visual de administración.
- **FR-008**: La puerta de enlace API (Kong) del servidor DEV DEBE habilitar y permitir el consumo legítimo de `/rest/v1/` con perfil `vifutboldev` para los clientes configurados con la clave pública del entorno DEV (`200 OK`) sin afectar el aislamiento o acceso de otros proyectos del servidor.
- **FR-009**: El cliente de la aplicación en entorno DEV DEBE configurarse para dirigir sus operaciones de datos hacia el esquema `vifutboldev` por defecto, manteniendo separado el comportamiento del entorno de producción.
- **FR-010**: DEBE mantenerse un conjunto mínimo de datos semilla iniciales idempotentes en `vifutboldev`, validarse lectura pública real desde la configuración DEV de la aplicación con `anon key` y validarse un ciclo real de escritura y limpieza mediante sesión `authenticated` de prueba (GoTrue) contra `vifutboldev`.

---

### Key Entities *(include if feature involves data)*

- **Identidad y Preferencias (`user_accounts`, `fan_favorite_teams`)**: Cuentas de usuario con su rol oficial y vínculo opcional a la identidad autenticada, además de la lista de clubes seguidos por aficionados.
- **Sedes y Canchas (`sports_venues`, `venue_pitches`)**: Complejos deportivos con geolocalización y sus canchas individuales tipificadas por superficie y formato de juego.
- **Competiciones y Gobernanza (`tournaments`, `rule_audit_entries`, `season_honor_rolls`, `tournament_news`)**: Campeonatos con reglas estructuradas, bitácora auditable de modificaciones reglamentarias, cuadros de honor de cierre de temporada y noticias segmentadas.
- **Equipos y Plantillas (`teams`, `tournament_teams`, `players`, `player_internal_trackings`)**: Clubes deportivos maestros (`teams` con titularidad de `coach_id`), su participación por torneo (`tournament_teams` con grupo y estado `pendingVerification`/`eligible` sujeto a cuota mínima), futbolistas vinculados a su inscripción (`tournament_team_id`) con unicidad de dorsal por equipo y documento por torneo, y registros internos de seguimiento técnico por entrenador.
- **Partidos, Arbitraje y Eventos (`match_referees`, `matches`, `match_lineup_convocations`, `digital_match_reports`, `match_events`, `match_live_alerts`)**: Árbitros habilitados, programación completa de partidos, alineaciones por encuentro, actas digitales oficiales, eventos cronológicos de juego y alertas en tiempo real.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de las 18 entidades del dominio quedan creadas dentro del esquema aislado `vifutboldev` con `0` tablas de negocio de `vifutbol` agregadas en el esquema `public`.
- **SC-002**: El 100% de los scripts de migración versionados se ejecutan y re-ejecutan consecutivamente con `0` errores de objetos duplicados o fallos de integridad referencial.
- **SC-003**: El 100% de las tablas en `vifutboldev` cuentan con RLS habilitado, al menos una política de acceso definida e índices sobre todas sus claves foráneas.
- **SC-004**: La puerta de enlace API del entorno DEV responde con éxito (`200 OK`) al perfil `vifutboldev` sin interrumpir los esquemas preexistentes del servidor.
- **SC-005**: Se verifica exitosamente un ciclo real de lectura/escritura contra `vifutboldev` utilizando la configuración DEV de la aplicación, preservando el funcionamiento offline si el servidor no está disponible.

---

## Assumptions

- El servidor DEV self-hosted en Oracle Cloud (`https://supabase.artbusinesstechnology.com`) ya está en ejecución y accesible administrativamente mediante SSH/Docker hacia los contenedores `supabase-db`, `supabase-rest` y `supabase-kong` (verificado previamente en sesión).
- El cliente Flutter ya cuenta con la infraestructura base de conexión, `EnvironmentConfig`, `SupabaseConfig` y `CheckSupabaseBackendHealthUseCase` implementada en **HU 17.1** (`specs/031-supabase-dev-backend`).
- Actualmente el endpoint `/rest/v1/` del servidor DEV responde `403` ante peticiones con la `anon key` de `.env.dev`; parte del aprovisionamiento en el servidor DEV incluye verificar y habilitar la exposición de PostgREST/Kong para que `vifutboldev` sea consumible de forma segura desde la app DEV.
- En el servidor compartido ya existen otros esquemas de aplicaciones previas (`public`, `app_futboleros`, `app_vihome`); estos deben conservarse intactos y fuera del alcance de modificación.
- La migración completa de cada repositorio local Hive hacia persistencia remota tabla por tabla se mantiene modular; en esta historia se aprueba la creación integral del esquema `vifutboldev`, su exposición, la configuración por defecto del cliente DEV hacia `vifutboldev` y la prueba real de lectura/escritura extremo a extremo en DEV.
