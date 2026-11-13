# Feature Specification: Persistencia de Roles, Perfiles Extensibles en Nube y Validación de Datos Incompletos

**Feature Branch**: `042-role-profile-persistence-validation`  
**Created**: 2026-11-13  
**Status**: Draft  
**Input**: Notion HU 19.4 — `[Épica 19] HU 19.4: Persistencia de Roles, Tablas Extensibles de Perfil en Nube y Validación de Datos Incompletos en Perfil`

## Clarifications

### Session 2026-11-13

- Q: Which roles should be required to provide a national identity document (`document_id`) in addition to a phone number for their profile to be marked as `"Perfil completo"`? → A: Only sports/management roles (`player`, `referee`, `coach`, `organizer`) require `document_id` + `phone` + role fields; `fan` only requires `phone` and `city`.
- Q: How should the system handle saving `"Completar mi perfil"` when the device has no internet connection? → A: Require active connectivity to submit `"Completar mi perfil"`; if offline, show a clear offline message, preserve form inputs in the modal, and allow retry without marking `"Perfil completo"`.
- Q: When a `player` or `referee` links to a pre-existing unlinked record via `document_id`, how should overlapping personal fields (such as phone number or full name) be reconciled? → A: Preserve all sports/match history and team assignments, and update personal contact fields (`phone`, `user_id`) with the values submitted by the user (only updating `full_name` if the existing record has it blank).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Registro Atómico de Rol y Vinculación Sin Duplicidad (Priority: P1)

Como usuario de KickPulse en cualquiera de los cinco roles (`organizer`, `coach`, `referee`, `player`, `fan`), quiero que al completar mi registro u onboarding se garantice la creación atómica de mi cuenta con mi rol activo y roles autorizados, vinculando automáticamente mi ficha existente si soy deportista o árbitro identificado por documento, o creando mi ficha de perfil correspondiente si soy nuevo, para evitar registros perdidos en la nube y duplicidad de historiales deportivos.

**Why this priority**: Sin persistencia atómica y vinculación única por documento, los usuarios registrados pierden su rol tras reiniciar sesión o generan historiales duplicados desconectados de actas, goles y nóminas ya registradas por entrenadores o ligas.

**Independent Test**: Registrar cuentas nuevas en cada uno de los cinco roles, incluyendo un jugador y un árbitro cuyo documento ya exista previamente sin cuenta asociada, y verificar que en todos los casos la cuenta queda persistida con su rol, los registros previos se enlazan sin duplicarse y los roles directivos/aficionados crean su ficha dedicada.

**Acceptance Scenarios**:

1. **Given** un usuario nuevo completa el registro seleccionando un rol inicial (por ejemplo `coach`, `player`, `referee`, `organizer` o `fan`), **When** finaliza el alta de cuenta, **Then** el sistema persiste de forma atómica su cuenta (con rol activo y lista de roles autorizados) junto con su registro de perfil correspondiente en la nube, sin dejar cuentas huérfanas sin rol ni perfiles desconectados.
2. **Given** un entrenador o liga registró previamente a un jugador en una nómina con su número de documento y sin cuenta de usuario asociada, **When** esa persona se registra como `player` e ingresa el mismo documento de identidad, **Then** el sistema localiza la ficha existente y la vincula a su cuenta de usuario, conectando automáticamente su equipo, goles, estadísticas y actas previas sin crear un segundo jugador.
3. **Given** una persona sin registro previo en nóminas se registra como `player` e ingresa su documento de identidad, **When** el sistema no encuentra coincidencia previa por documento, **Then** crea una nueva ficha de jugador vinculada a su cuenta de usuario en estado de agente libre (sin equipo asignado).
4. **Given** un árbitro fue registrado previamente en actas o listados arbitrales sin cuenta de usuario asociada, **When** se registra o completa su perfil como `referee` ingresando su documento de identidad, **Then** el sistema reutiliza y vincula su ficha arbitral existente a su cuenta de usuario; si no existe, crea una nueva ficha arbitral vinculada.

---

### User Story 2 - Detección Visual y Completado Adaptativo de Perfil Incompleto (Priority: P1)

Como usuario autenticado en KickPulse, quiero ver claramente en la pestaña Perfil si mis datos obligatorios están incompletos y contar con un acceso directo para diligenciar un formulario adaptado a mi rol activo, para mantener mi ficha personal y técnica completa sin fricción.

**Why this priority**: Muchos usuarios completan el registro inicial con datos mínimos; si no existe una señal clara y un flujo guiado para completar teléfono, documento y datos propios de su rol, quedan bloqueados o con fichas incompletas para futuras operaciones de torneos y nóminas.

**Independent Test**: Iniciar sesión con un usuario autenticado al que le falte teléfono, documento o campos requeridos de su rol, verificar la aparición del distintivo ámbar `"Datos incompletos"` y el banner con botón `"Completar mi perfil"`, abrir el formulario adaptativo, guardar datos válidos y confirmar que el distintivo cambia inmediatamente a verde `"Perfil completo"`.

**Acceptance Scenarios**:

1. **Given** un usuario autenticado accede a la pestaña Perfil y le falta al menos un dato obligatorio (teléfono, documento de identidad o campos requeridos específicos de su rol activo), **When** visualiza su tarjeta de usuario, **Then** el sistema muestra un distintivo en tono ámbar con el texto `"Datos incompletos"` y un banner informativo con el botón de acción `"Completar mi perfil"`.
2. **Given** el usuario presiona `"Completar mi perfil"`, **When** se despliega el formulario modal de completado, **Then** los campos presentados se adaptan dinámicamente al rol activo del usuario (mostrando los campos personales comunes más los específicos del rol).
3. **Given** el usuario diligencia todos los campos requeridos con formato válido y confirma el guardado, **When** los datos se sincronizan con la nube (incluyendo la vinculación automática por documento si aplica a `player` o `referee`), **Then** el banner desaparece y el distintivo cambia inmediatamente a verde con el texto `"Perfil completo"`.
4. **Given** un usuario autenticado ya cuenta con todos sus datos obligatorios completos para su rol activo, **When** accede a la pestaña Perfil, **Then** ve el distintivo verde `"Perfil completo"` y no se muestra el banner de alerta.

---

### User Story 3 - Fichas Satélite Dedicadas para Directivos y Aficionados (Priority: P2)

Como `coach`, `organizer` o `fan` autenticado, quiero que mis datos específicos de rol (club o escuela y licencia para entrenador; entidad organizadora y ciudad base para organizador; ciudad y preferencias para aficionado) se guarden y recuperen desde su perfil dedicado, para que cada perfil conserve la información técnica pertinente a su función.

**Why this priority**: Separa limpiamente la información propia de cada rol sin sobrecargar la ficha deportiva de jugadores ni la cuenta base, habilitando futuras funciones específicas por perfil.

**Independent Test**: Completar y consultar el perfil de un `coach`, un `organizer` y un `fan`, cerrando y reabriendo sesión para comprobar que los atributos propios de cada rol persisten y se precargan al editar.

**Acceptance Scenarios**:

1. **Given** un usuario con rol `coach` completa su perfil, **When** guarda su club o escuela, nivel de licencia y teléfono, **Then** dicha información queda persistida en su perfil de entrenador y disponible tras recargar la aplicación.
2. **Given** un usuario con rol `organizer` completa su perfil, **When** guarda su entidad organizadora, ciudad base y teléfono, **Then** dicha información queda persistida en su perfil de organizador y disponible tras recargar la aplicación.
3. **Given** un usuario con rol `fan` autenticado completa su perfil, **When** guarda su ciudad, teléfono y preferencias, **Then** dicha información queda persistida en su perfil de aficionado y disponible tras recargar la aplicación.

---

### Edge Cases

- **Documento ya vinculado a otro usuario**: Si un `player` o `referee` intenta vincular un `document_id` que ya pertenece a una ficha asociada a otra cuenta de usuario distinta, el sistema debe rechazar la vinculación con un mensaje claro en español sin sobrescribir ni fusionar cuentas ajenas.
- **Sin conexión al guardar perfil**: El guardado de `"Completar mi perfil"` requiere conectividad activa; si el usuario intenta guardar sin conexión, el sistema debe mostrar un mensaje claro de falta de conexión en español, conservar los datos ingresados dentro del formulario para permitir reintentar y mantener el estado `"Datos incompletos"` sin marcar `"Perfil completo"` ni generar falsos positivos.
- **Cambio de rol activo**: Si un usuario posee múltiples roles autorizados y cambia su rol activo desde la pestaña Perfil, la evaluación de `"Datos incompletos"` vs. `"Perfil completo"` y los campos del formulario deben recalcularse según el nuevo rol activo.
- **Usuario invitado (Guest Fan)**: Un visitante en modo invitado sin cuenta autenticada no debe recibir la alerta de `"Datos incompletos"` de cuenta registrada ni intentar persistir perfiles en la nube.
- **Fallo parcial durante el registro**: Si falla la creación del perfil tras crear la cuenta o viceversa, la operación debe comportarse de manera atómica (o recuperarse idempotente en reintento) para evitar usuarios autenticados sin rol o sin ficha.
- **Formato inválido en teléfono o documento**: El formulario debe validar campos obligatorios y formatos inválidos en línea antes de enviar, manteniendo accesible el botón de guardado y mostrando retroalimentación clara.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema MUST garantizar la persistencia atómica de la cuenta del usuario (incluyendo su rol activo y sus roles autorizados) junto con la inicialización o vinculación de su perfil de rol correspondiente al completar el registro o el onboarding de rol.
- **FR-002**: El sistema MUST mantener una única fuente de verdad para deportistas (`Player`) y una única fuente de verdad para árbitros (`Referee`), prohibiendo la creación de entidades paralelas o duplicadas para estos roles.
- **FR-003**: Al registrar o completar el perfil de un usuario con rol `player` ingresando su documento de identidad (`document_id`), el sistema MUST buscar si existe un deportista previo con ese documento; si existe sin usuario vinculado, MUST enlazarlo a la cuenta actual conservando íntegramente su equipo, goles, actas y estadísticas previas, actualizando `user_id` y `phone` con los datos del usuario (y completando `full_name` únicamente si estaba vacío en la ficha previa); si no existe coincidencia previa, MUST crear una nueva ficha de deportista vinculada en estado de agente libre (sin equipo asignado).
- **FR-004**: Al registrar o completar el perfil de un usuario con rol `referee` ingresando su documento de identidad (`document_id`), el sistema MUST aplicar la misma regla de búsqueda y reconciliación por documento: reutilizar y enlazar la ficha arbitral existente conservando su historial de partidos/actas y actualizando `user_id` y `phone` (y `full_name` solo si estaba vacío), o crear una nueva ficha arbitral vinculada si no existe.
- **FR-005**: El sistema MUST rechazar la vinculación cuando el documento ingresado ya esté asociado a una cuenta de usuario diferente, informando el conflicto al usuario sin alterar el registro existente.
- **FR-006**: El sistema MUST persistir perfiles dedicados diferenciados por rol para `coach` (club/escuela, nivel de licencia, teléfono), `organizer` (entidad organizadora, ciudad base, teléfono) y `fan` (ciudad, teléfono, preferencias), protegidos de modo que cada usuario autenticado solo pueda gestionar su propio perfil según las reglas de acceso vigentes.
- **FR-007**: El sistema MUST evaluar en la pestaña Perfil si el usuario autenticado cumple el criterio de perfil completo según su rol activo: `phone`, `document_id` y campos propios del rol para `player`, `referee`, `coach` y `organizer`; y `phone` junto con `city` (sin exigir `document_id`) para `fan`.
- **FR-008**: Cuando el usuario autenticado no cumpla el criterio de perfil completo, la pestaña Perfil MUST mostrar en la tarjeta del usuario un distintivo ámbar `"Datos incompletos"` y un banner con el botón `"Completar mi perfil"`.
- **FR-009**: Cuando el usuario autenticado cumpla el criterio de perfil completo, la pestaña Perfil MUST mostrar un distintivo verde `"Perfil completo"` y ocultar el banner de datos incompletos.
- **FR-010**: Al activar `"Completar mi perfil"`, el sistema MUST desplegar un formulario modal adaptativo que precargue los datos conocidos del usuario y solicite los campos faltantes y específicos de su rol activo, con validaciones claras en español y soporte de estados de carga, error y éxito.
- **FR-011**: El guardado del formulario adaptativo MUST requerir conectividad activa para sincronizar los cambios en la nube (ejecutando la vinculación por documento si aplica) y, únicamente tras confirmación exitosa en la nube, actualizar de inmediato el estado visual en la pestaña Perfil a `"Perfil completo"`. Si no hay conexión o falla el guardado, MUST conservar los valores ingresados en el formulario para reintento sin cambiar el estado a `"Perfil completo"`.
- **FR-012**: Todos los textos visibles para el usuario (etiquetas, distintivos, mensajes de validación, errores y acciones) MUST estar localizados en español y cumplir con las pautas de accesibilidad e interacción móvil del proyecto.

### Key Entities

- **Cuenta de Usuario (`UserAccount`)**: Representa la identidad autenticada del usuario, su `active_role`, sus `authorized_roles`, estado de completitud y vínculo con sus perfiles.
- **Deportista (`Player`)**: Entidad única de jugador en torneos y nóminas, extendida con enlace único opcional a `UserAccount` (`user_id`) y datos personales básicos (`document_id`, `phone`) para permitir la vinculación retroactiva sin duplicidad.
- **Árbitro (`Referee`)**: Entidad única arbitral asociada a partidos y designaciones, extendida con enlace único opcional a `UserAccount` (`user_id`) y datos personales básicos (`document_id`, `phone`) para reutilización sin duplicidad.
- **Perfil de Entrenador (`CoachProfile`)**: Ficha satélite vinculada 1:1 a `UserAccount` con club o escuela, nivel de licencia y teléfono.
- **Perfil de Organizador (`OrganizerProfile`)**: Ficha satélite vinculada 1:1 a `UserAccount` con entidad organizadora, ciudad base y teléfono.
- **Perfil de Aficionado (`FanProfile`)**: Ficha satélite vinculada 1:1 a `UserAccount` con ciudad, teléfono y preferencias de seguimiento.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de los registros completados en cualquiera de los 5 roles queda persistido en la nube con su cuenta, rol activo y perfil correspondiente asociado desde el primer inicio de sesión, sin cuentas huérfanas sin rol.
- **SC-002**: El 100% de los jugadores y árbitros preexistentes cuyo documento coincide al registrarse o completar perfil queda vinculado a su ficha histórica única sin generar registros duplicados, conservando 100% de sus estadísticas, equipo o actas previas.
- **SC-003**: El 100% de los usuarios autenticados con datos obligatorios faltantes visualiza el distintivo `"Datos incompletos"` y el botón `"Completar mi perfil"` al abrir la pestaña Perfil.
- **SC-004**: El usuario puede completar y guardar su perfil adaptativo desde la pestaña Perfil en menos de 60 segundos, viendo reflejado el cambio a `"Perfil completo"` inmediatamente tras la confirmación de guardado.
- **SC-005**: Cero conflictos silenciosos o sobrescrituras de fichas ajenas cuando dos usuarios intentan reclamar el mismo documento de identidad.

## Assumptions

- La evaluación de perfil completo exige `phone` y `document_id` para los roles deportivos y directivos (`player`, `referee`, `coach`, `organizer`), más sus campos obligatorios propios (`club_name` / `license_level` para `coach`; `organization_name` / `base_city` para `organizer`). Para el rol `fan`, el criterio completo exige `phone` y `city` sin requerir `document_id`.
- La búsqueda y vinculación automática por `document_id` opera únicamente sobre fichas de `Player` o `Referee` que aún no tengan un `user_id` asignado (`user_id` nulo), evitando reasignar fichas que ya pertenecen a otra cuenta.
- El usuario invitado (`guest` sin autenticación) no posee cuenta en la nube ni ficha editable, por lo que queda excluido de la alerta `"Datos incompletos"`.
