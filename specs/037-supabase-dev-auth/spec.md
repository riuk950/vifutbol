# Feature Specification: Autenticación de Usuarios y Obtención de Sesión / Perfil en Backend DEV (HU 17.3)

**Feature Branch**: `develop`  
**Feature Directory**: `specs/037-supabase-dev-auth`  
**Created**: 2026-11-11  
**Status**: Draft  
**Input**: User description: "HU 17.3: Autenticación de Usuarios y Obtención de Sesión / Perfil en Supabase DEV (GoTrue + vifutboldev)" (Notion ID: `4158442e-3f49-816a-9139-f6e9cf204b04`)

---

## Clarifications

### Session 2026-11-11

- Q: ¿Cómo debe garantizarse la creación del perfil en `vifutboldev.user_accounts` cuando un usuario se registra en Supabase Auth (`GoTrue`)? → A: Combinar un trigger idempotente `AFTER INSERT ON auth.users` (creando la fila inicial en `vifutboldev.user_accounts` con `id = auth.uid()` y `full_name` desde metadatos) más un `upsert` idempotente de respaldo desde el cliente al iniciar o restaurar sesión.
- Q: Si el servidor de autenticación crea la cuenta nueva sin emitir sesión inmediata (por requerir confirmación de correo), ¿cómo debe resolverlo el método `registerAccount` manteniendo el contrato de `AuthRepository`? → A: Mantener `Future<AuthSession> registerAccount(...)` y, cuando `session == null`, lanzar un fallo tipado específico en español (`EmailVerificationRequiredFailure`) para mostrar el aviso en la pantalla de registro sin autenticar al usuario.
- Q: Al ejecutar `completeRoleOnboarding` o `switchActiveRole` contra `vifutboldev.user_accounts` en DEV, ¿qué regla de autorización debe regir para activar roles privilegiados (`Organizador`, `Árbitro`)? → A: En DEV (`AppEnvironment.development`), permitir seleccionar y cambiar libremente entre los 5 roles persistiendo `active_role` y `authorized_roles` en `vifutboldev.user_accounts` (exigiendo código oficial solo en producción).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Inicio de Sesión en la Nube y Mapeo de Perfil (`AuthSession` / `UserAccount`) (Priority: P1) 🎯 MVP

Como Usuario de KickPulse (`Organizador`, `Entrenador`, `Árbitro`, `Jugador` o `Aficionado`), quiero iniciar sesión con mi correo electrónico y contraseña contra el servicio de autenticación remoto de desarrollo y obtener automáticamente mi perfil y roles desde el esquema `vifutboldev`, para disponer de una sesión autenticada válida y sincronizada entre dispositivos.

**Why this priority**: Habilita el acceso con credenciales reales en la nube y entrega el token de sesión necesario para operar sobre recursos protegidos por control de acceso por fila (RLS).

**Independent Test**: Ingresar credenciales válidas registradas en el entorno DEV configurado, ejecutar el inicio de sesión y verificar que se obtiene la sesión autenticada junto con el perfil completo (`fullName`, `activeRole`, `authorizedRoles`, `onboardingCompleted`) desde `vifutboldev`, dirigiendo al usuario al flujo principal o al onboarding de rol según su estado.

**Acceptance Scenarios**:

1. **Given** que la aplicación corre en entorno DEV con configuración remota activa y el usuario ingresa correo y contraseña válidos, **When** presiona "Iniciar Sesión", **Then** el sistema autentica las credenciales en el backend remoto, recupera el token de sesión e identificador único del usuario, consulta su perfil en `vifutboldev` y construye la sesión activa con su nombre, rol activo, roles autorizados y estado de onboarding.
2. **Given** que el usuario autenticado ya completó su selección inicial de rol, **When** finaliza el inicio de sesión, **Then** ingresa directamente a la pantalla principal de la aplicación con las capacidades correspondientes a su rol activo.
3. **Given** que el usuario autenticado aún tiene pendiente completar el onboarding de rol, **When** finaliza el inicio de sesión, **Then** es dirigido al flujo de selección inicial de rol y, al completarlo, dicho rol queda persistido tanto localmente como en `vifutboldev` (y al cambiar de rol posteriormente desde el perfil).

---

### User Story 2 - Registro de Cuenta Nueva y Creación Consistente de Perfil en `vifutboldev` (Priority: P1) 🎯 MVP

Como Usuario nuevo de KickPulse, quiero registrarme con mi nombre completo, correo electrónico y contraseña en el backend DEV para crear mi cuenta de acceso en la nube y mi perfil inicial en `vifutboldev` de forma consistente, quedando listo para elegir mi rol deportivo.

**Why this priority**: Sin un registro que cree simultáneamente la identidad de autenticación y su registro de perfil en `vifutboldev`, los nuevos usuarios no podrían iniciar sesión ni operar con políticas RLS.

**Independent Test**: Enviar un registro nuevo con nombre completo, correo y contraseña; verificar la creación de la cuenta remota con el nombre en metadatos, la creación idempotente del perfil en `vifutboldev` vinculado al identificador autenticado, y la devolución de una sesión válida (o notificación clara si se requiere confirmación por correo).

**Acceptance Scenarios**:

1. **Given** que un usuario nuevo completa el formulario de registro con nombre completo, correo válido y contraseña, **When** confirma el registro, **Then** el sistema registra la cuenta en el servicio de autenticación remoto incluyendo el nombre completo en los metadatos y garantiza la existencia del perfil correspondiente en `vifutboldev` con onboarding pendiente.
2. **Given** que el servidor DEV tiene auto-confirmación habilitada, **When** finaliza el registro, **Then** el usuario recibe su sesión activa inmediatamente y avanza al onboarding de rol.
3. **Given** que el servidor requiere verificación manual de correo antes de emitir sesión, **When** finaliza el registro sin sesión inmediata, **Then** el sistema notifica claramente en español al usuario que revise su correo para confirmar su cuenta antes de iniciar sesión.

---

### User Story 3 - Restauración Automática de Sesión, Modo Invitado y Cierre de Sesión (Priority: P2)

Como Usuario recurrente o Aficionado Invitado de KickPulse, quiero que la aplicación restaure y refresque automáticamente mi sesión al volver a abrirla (respetando respaldo offline temporal), mantenga el acceso inmediato sin nube para Aficionados Invitados y limpie por completo mi sesión al cerrar sesión.

**Why this priority**: Garantiza continuidad fluida en uso móvil real con conectividad intermitente sin exigir reingresar credenciales en cada apertura ni romper el acceso público de invitados.

**Independent Test**: Probar apertura tras sesión iniciada (verificando refresh/sincronización con `vifutboldev` y fallback local sin red), probar acceso como Aficionado Invitado sin conexión y ejecutar "Cerrar Sesión" verificando limpieza remota y local.

**Acceptance Scenarios**:

1. **Given** que el usuario inició sesión previamente en el backend DEV, **When** vuelve a abrir la aplicación con conectividad activa, **Then** el sistema verifica y refresca si corresponde la sesión activa remota, sincroniza los datos actuales del perfil desde `vifutboldev` y restaura la sesión sin pedir contraseña.
2. **Given** que el usuario inició sesión previamente pero abre la aplicación temporalmente sin conexión a internet, **When** falla la sincronización remota al arrancar, **Then** el sistema recurre de forma segura al caché local de sesión guardado sin expulsar injustificadamente al usuario.
3. **Given** que el usuario selecciona "Continuar como Aficionado Invitado", **When** accede a la aplicación sin credenciales remotas, **Then** se crea una sesión local de invitado sin exigir conexión al servidor de autenticación.
4. **Given** un usuario con sesión activa en la nube, **When** pulsa "Cerrar Sesión", **Then** el sistema cierra la sesión en el backend remoto, limpia el caché local de sesión y retorna a la pantalla de bienvenida.

---

### User Story 4 - Manejo Seguro de Errores, Expiración y Privacidad en Diagnósticos (Priority: P2)

Como Usuario y Administrador de Seguridad de KickPulse, quiero que los fallos de autenticación (credenciales inválidas, correo duplicado, correo no confirmado, falta de red o expiración de sesión) se traduzcan a mensajes claros en español y que ningún token de sesión o contraseña quede expuesto en registros o mapas diagnósticos.

**Why this priority**: Protege las credenciales de los usuarios, cumple con el Principio VII de resiliencia móvil y evita mensajes técnicos crudos o fugas de JWT en logs.

**Independent Test**: Simular credenciales incorrectas, correo ya registrado, correo sin confirmar, pérdida de conexión y expiración/cierre remoto de sesión; validar que cada caso produce el fallo tipado correspondiente con mensaje en español y que los mapas diagnósticos redactan el token como `[REDACTED]`.

**Acceptance Scenarios**:

1. **Given** que el usuario ingresa credenciales erróneas o intenta registrarse con un correo ya existente o sin confirmar, **When** el servicio remoto rechaza la operación, **Then** el sistema traduce la excepción a un fallo tipado de dominio con mensaje comprensible en español sin exponer detalles internos.
2. **Given** que el dispositivo carece de conexión a internet, **When** el usuario intenta un nuevo inicio de sesión o registro remoto, **Then** se rechaza la operación con un fallo específico de operación offline y mensaje claro en español.
3. **Given** que una sesión remota expira o es revocada externamente mientras la app está abierta, **When** el sistema detecta el cambio de estado de autenticación, **Then** actualiza el estado local limpiando la sesión expirada de forma controlada.
4. **Given** una sesión autenticada con token JWT real activo, **When** se genera su representación diagnóstica o textual, **Then** el token de sesión permanece siempre redactado (`[REDACTED]`) y nunca se registran contraseñas.

---

### Edge Cases

- **Usuario autenticado sin fila aún creada en `vifutboldev.user_accounts`**: Si una cuenta existe en el servicio de autenticación remoto pero aún no tiene fila de perfil en `vifutboldev` (por ejemplo, creada manualmente desde consola), al iniciar sesión o restaurar sesión se crea/completa automáticamente su perfil base de forma idempotente vinculada a su identificador autenticado.
- **Sin configuración cloud o en pruebas locales aisladas**: Cuando el entorno DEV carece de credenciales de backend configuradas, el sistema conmuta automáticamente al repositorio local de autenticación para no bloquear el desarrollo ni las pruebas aisladas.
- **Cambios concurrentes de rol desde otro dispositivo**: Al restaurar sesión con conectividad, el rol activo y roles autorizados descargados desde `vifutboldev.user_accounts` prevalecen sobre la copia local obsoleta.
- **Confirmación de correo pendiente**: Si el registro ocurre en un entorno donde la confirmación de correo está activa y no se emite sesión inmediata, no se debe marcar la sesión como autenticada ni provocar una excepción fatal en la UI.
- **Cierre de sesión con dispositivo sin red**: Si el usuario presiona "Cerrar Sesión" estando offline, la limpieza del caché local de sesión debe completarse siempre sin quedar bloqueado esperando respuesta del servidor.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE implementar un adaptador remoto de autenticación que cumpla íntegramente el contrato existente de autenticación de dominio (`restoreSession`, `signInWithEmail`, `registerAccount`, `continueAsGuestFan`, `completeRoleOnboarding`, `switchActiveRole`, `signOut`) manteniendo intacto el repositorio local para pruebas y modo sin backend.
- **FR-002**: En entorno DEV con backend configurado, el proveedor de repositorio de autenticación DEBE seleccionar automáticamente la implementación remota conectada al servicio de autenticación de Supabase DEV y al esquema `vifutboldev`.
- **FR-003**: Al iniciar sesión con correo y contraseña, el sistema DEBE autenticar contra el servicio remoto, obtener el identificador único y token de sesión JWT, consultar o inicializar de forma idempotente el perfil en `vifutboldev.user_accounts` y retornar la sesión y cuenta de usuario mapeadas.
- **FR-004**: Al registrar una cuenta nueva, el sistema DEBE enviar el nombre completo en los metadatos del usuario, garantizar la creación del perfil en `vifutboldev.user_accounts` mediante un trigger idempotente `AFTER INSERT ON auth.users` (con respaldo `upsert` desde el cliente al iniciar/restaurar sesión si faltara) vinculado al identificador autenticado (`id = auth_user_id = auth.uid()`), retornar la sesión cuando esté confirmada o lanzar el fallo tipado `EmailVerificationRequiredFailure` con mensaje claro en español si el servidor exige confirmar el correo antes de emitir sesión.
- **FR-005**: Al completar el onboarding de rol (`completeRoleOnboarding`) o cambiar de rol activo (`switchActiveRole`), el sistema DEBE persistir el nuevo estado (`active_role`, `authorized_roles`, `onboarding_completed`) tanto en `vifutboldev.user_accounts` como en el caché local de sesión; en DEV permitirá seleccionar y alternar libremente entre los cinco roles para pruebas funcionales y de RLS, exigiendo código oficial de autorización únicamente en entorno de producción.
- **FR-006**: Al restaurar sesión (`restoreSession`), el sistema DEBE validar/refrescar la sesión remota activa, sincronizar el perfil actualizado desde `vifutboldev.user_accounts` y, ante ausencia temporal de conectividad, respaldarse de manera segura en la sesión cacheada localmente sin expulsar al usuario.
- **FR-007**: El sistema DEBE escuchar cambios remotos del ciclo de vida de sesión (refresco de token o cierre/expiración remota) para mantener sincronizado el estado local de autenticación.
- **FR-008**: La modalidad "Aficionado Invitado" (`continueAsGuestFan`) DEBE continuar funcionando de forma local y sin exigir conexión a la nube, mientras que "Cerrar Sesión" (`signOut`) DEBE cerrar la sesión remota (tolerando ausencia de red) y limpiar completamente el almacenamiento local de sesión.
- **FR-009**: Toda excepción de autenticación o red (credenciales inválidas, correo duplicado, correo no confirmado, límite de intentos, desconexión) DEBE traducirse a fallos tipados de dominio con mensajes claros en español.
- **FR-010**: Ningún token JWT, token de refresco o contraseña DEBE exponerse en logs ni diagnósticos (`toSafeDiagnosticMap()` y `toString()` deben mantener `[REDACTED]`).

---

### Key Entities *(include if feature involves data)*

- **Sesión Autenticada (`AuthSession`)**: Representa la sesión activa del usuario en el dispositivo; vincula identificador de sesión, token JWT redactado en diagnósticos, marca temporal de autenticación y la entidad de perfil `UserAccount`.
- **Cuenta de Usuario (`UserAccount`)**: Representa el perfil deportivo sincronizado en `vifutboldev.user_accounts`; contiene identificador, vínculo con identidad de autenticación remota, nombre completo, correo normalizado, rol activo, conjunto de roles autorizados, estado de invitado y bandera de onboarding completado.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de las operaciones definidas en el contrato de autenticación (`signInWithEmail`, `registerAccount`, `restoreSession`, `completeRoleOnboarding`, `switchActiveRole`, `continueAsGuestFan`, `signOut`) operan contra el backend DEV con pruebas automatizadas verificadas.
- **SC-002**: El 100% de los inicios de sesión y registros auto-confirmados en DEV sincronizan correctamente la entidad de perfil desde `vifutboldev.user_accounts` y permiten realizar consultas protegidas con token JWT válido.
- **SC-003**: El 100% de los escenarios de error contemplados (credenciales inválidas, correo duplicado, confirmación pendiente, offline y cierre remoto) devuelven fallos tipados en español sin provocar excepciones no controladas.
- **SC-004**: Cero fugas de tokens JWT, tokens de refresco o contraseñas en salidas diagnósticas o registros de consola (`100%` redactados como `[REDACTED]`).

---

## Assumptions

- Esta historia se apoya directamente en el cliente Supabase DEV configurado en **HU 17.1** (`specs/031-supabase-dev-backend`) y en la existencia de la tabla `vifutboldev.user_accounts` con sus políticas RLS definidas en **HU 17.2** (`specs/036-supabase-vifutboldev-schema`).
- Se verificó previamente en el servidor DEV (`supabase-auth`) que `GOTRUE_MAILER_AUTOCONFIRM=true` y `GOTRUE_DISABLE_SIGNUP=false`, por lo que los registros nuevos en DEV emiten sesión inmediata; aun así se contempla el caso `session == null` cuando el servidor requiera confirmación por correo.
- La escritura en `vifutboldev.user_accounts` desde el cliente autenticado operará bajo políticas RLS donde el usuario autenticado gestiona su propio perfil (`auth_user_id = (select auth.uid())`), complementado opcionalmente con upsert idempotente tras `signUp`/`signIn` o trigger en `auth.users`.
- En entornos sin backend configurado o durante pruebas de widgets aisladas, `authRepositoryProvider` mantiene el respaldo del repositorio local existente para no romper la suite actual.
