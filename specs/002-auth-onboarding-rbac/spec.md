# Feature Specification: HU 2.1 — Autenticación, Onboarding y Control de Acceso Basado en Roles (RBAC)

**Feature Branch**: `002-auth-onboarding-rbac`

**Created**: 2026-11-03

**Status**: Draft

**Input**: User description: "de notion HU 2.1: [Épica 2] HU 2.1: Autenticación, Onboarding y Control de Acceso Basado en Roles (RBAC)"

## Clarifications

### Session 2026-11-03

- Q: ¿Cuál debe ser la pantalla inicial cuando un usuario abre la aplicación por primera vez sin una sesión guardada? → A: Pantalla de Bienvenida/Login inicial con acceso directo de Aficionado (si no hay sesión activa, presenta Iniciar sesión, Crear cuenta o "Continuar como Aficionado"; una vez elegido, guarda la sesión local y abre el App Shell).
- Q: ¿Cómo debe funcionar la selección inicial y el cambio entre los cinco roles deportivos (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`) para los usuarios registrados? → A: Onboarding de rol + cambio de rol autorizado en Perfil (en el registro el usuario elige su rol inicial; en `prod` los roles `Organizador` y `Árbitro` requieren código de autorización mientras `Aficionado`, `Jugador` y `Entrenador` son de selección directa; en `dev` los 5 roles están habilitados libremente; y el usuario puede alternar su rol activo entre sus roles autorizados desde Perfil sin cerrar sesión).
- Q: ¿Cómo debe comportarse la autenticación cuando el dispositivo está sin conexión a internet o se producen múltiples intentos fallidos de contraseña? → A: Rehidratación offline + login/registro online + bloqueo tras 5 fallos (60s) (las sesiones previamente autenticadas y el modo Aficionado operan 100% offline; iniciar sesión con cuenta distinta o registrarse requiere red activa; y tras 5 intentos fallidos consecutivos de contraseña se bloquea el envío durante 60 segundos).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Registro, Inicio de Sesión y Onboarding de Rol Deportivo (Priority: P1)

Como actor del ecosistema deportivo (`Organizador`, `Entrenador`, `Árbitro`, `Jugador` o `Aficionado`), quiero registrarme, iniciar sesión o ingresar en modo consulta pública y completar mi perfil inicial seleccionando o confirmando mi rol deportivo, para acceder al contenedor principal de la aplicación con una identidad clara y adaptada a mis funciones en el campeonato.

**Why this priority**: Es la puerta de entrada obligatoria para identificar a cada participante del campeonato y habilitar tanto la operación personalizada como el acceso rápido de consulta para aficionados.

**Independent Test**: Puede probarse de forma independiente abriendo la aplicación sin sesión activa, completando el registro o inicio de sesión con credenciales válidas (o seleccionando el acceso como `Aficionado`), verificando el bloqueo contra envíos duplicados, la validación de campos en español y la redirección al contenedor principal con el rol activo visible en la sección de *Perfil*.

**Acceptance Scenarios**:

1. **Given** que un usuario registrado se encuentra en la pantalla de inicio de sesión, **When** ingresa un correo y contraseña válidos y presiona *"Iniciar sesión"*, **Then** el botón entra en estado de carga bloqueando pulsaciones repetidas, el sistema autentica la sesión y redirige al usuario al contenedor principal mostrando su rol deportivo activo.
2. **Given** que un usuario nuevo completa su registro por primera vez sin un rol operativo preasignado, **When** accede al paso de *Onboarding de Rol*, **Then** puede seleccionar su perfil inicial permitido o continuar como `Aficionado`, quedando su perfil vinculado y listo para operar.
3. **Given** que un usuario intenta iniciar sesión con credenciales incorrectas o formato de correo inválido, **When** envía el formulario, **Then** el sistema presenta un mensaje claro en español (*"Correo o contraseña incorrectos"* o el error de validación específico del campo), mantiene el correo ingresado sin borrarlo para facilitar la corrección y nunca registra contraseñas ni credenciales en las bitácoras del dispositivo.
4. **Given** que un visitante desea consultar resultados, calendario y posiciones sin crear una cuenta administrativa, **When** selecciona la opción *"Continuar como Aficionado"* en la pantalla de bienvenida, **Then** ingresa directamente al contenedor principal con permisos exclusivos de lectura pública.

---

### User Story 2 - Control de Acceso Basado en los Cinco Roles del Campeonato (RBAC) (Priority: P1)

Como responsable de la integridad del campeonato, quiero que la aplicación controle estrictamente el acceso a las vistas y acciones de creación o edición según los cinco roles del sistema (`Organizador`, `Entrenador`, `Árbitro`, `Jugador` y `Aficionado`), para garantizar que ningún usuario no autorizado altere configuraciones de torneos, plantillas de equipos ni actas oficiales de partidos.

**Why this priority**: Cumple el Principio V de la Constitución (*Segregación de Roles*) y protege la fuente de verdad oficial del torneo frente a modificaciones no autorizadas.

**Independent Test**: Puede probarse iniciando sesión con cada uno de los 5 roles (o cambiando el rol activo en un perfil autorizado) y verificando que las acciones exclusivas de cada rol se permitan únicamente al rol correspondiente y se oculten o rechacen con un aviso claro en español para los demás roles.

**Acceptance Scenarios**:

1. **Given** que un usuario tiene una sesión activa con el rol `Organizador`, **When** accede a las opciones de gestión del campeonato, **Then** tiene permitido crear y configurar torneos, administrar sedes, aprobar inscripciones y designar árbitros.
2. **Given** que un usuario tiene una sesión activa con el rol `Entrenador`, **When** navega por la aplicación, **Then** tiene permitido gestionar la plantilla y convocatorias de su propio equipo, pero se le deniega crear torneos o editar actas arbitrales.
3. **Given** que un usuario tiene una sesión activa con el rol `Árbitro`, **When** accede a un partido asignado, **Then** tiene permitido registrar goles, asistencias, tarjetas y cerrar el acta oficial del encuentro, pero se le deniega modificar torneos o plantillas de equipos.
4. **Given** que un usuario opera con el rol `Jugador` o `Aficionado`, **When** navega por las secciones del campeonato o intenta invocar una ruta protegida de escritura, **Then** solo visualiza vistas de consulta (calendario, posiciones, sedes y estadísticas personales/públicas) y cualquier intento de acción administrativa es bloqueado mostrando un aviso en español de acceso restringido.

---

### User Story 3 - Rehidratación de Sesión Offline y Cierre de Sesión Seguro (Priority: P2)

Como usuario móvil que asiste a canchas con conectividad inestable, quiero que mi sesión y mi rol activo se conserven al cerrar o reabrir la aplicación incluso sin conexión a internet, y poder cerrar mi sesión limpiando por completo mis datos privados cuando cambie de dispositivo, para operar sin interrupciones en campo y proteger mi privacidad.

**Why this priority**: En sedes deportivas donde se pierde la señal móvil, un árbitro, entrenador u organizador no debe quedar bloqueado fuera de la aplicación al reabrirla.

**Independent Test**: Puede probarse iniciando sesión con red activa, cerrando la aplicación, desactivando la conectividad del dispositivo y reabriéndola para comprobar el ingreso directo con el rol conservado; y posteriormente ejecutando *"Cerrar sesión"* desde *Perfil* para verificar la limpieza total de credenciales locales.

**Acceptance Scenarios**:

1. **Given** que un usuario autenticado cierra la aplicación o el dispositivo pierde la conexión a internet, **When** vuelve a abrir la aplicación en modo sin conexión (*offline*), **Then** el sistema recupera la sesión y el rol activo desde el almacenamiento local seguro y permite el acceso inmediato al contenedor principal sin redirigir a la pantalla de inicio de sesión.
2. **Given** que un usuario está completando el formulario de inicio de sesión o registro y la aplicación pasa a segundo plano por una interrupción móvil, **When** regresa a primer plano, **Then** el sistema conserva los campos no sensibles ingresados (como nombre y correo electrónico) y la posición del flujo sin reiniciar la pantalla.
3. **Given** que un usuario autenticado accede a la pestaña *Perfil* y confirma la acción *"Cerrar sesión"*, **When** finaliza el proceso, **Then** el sistema elimina las credenciales y datos sensibles almacenados localmente y redirige a la pantalla de bienvenida/inicio de sesión.

---

### Edge Cases

- **Pérdida de conectividad durante el envío de inicio de sesión o registro**: Si la conexión se interrumpe mientras se valida la cuenta por primera vez, el sistema desbloquea el botón de acción, conserva los datos no sensibles escritos en el formulario y muestra un estado de error claro en español con opción de reintentar sin duplicar el registro.
- **Expiración o invalidación remota de sesión mientras se opera offline**: Si la sesión almacenada localmente fue revocada o expiró cuando el dispositivo recupera la conexión, el sistema solicita reautenticación de forma controlada sin provocar cierres inesperados ni perder datos locales pendientes de sincronización.
- **Salida accidental durante el formulario de registro u onboarding**: Si el usuario presiona volver atrás tras haber ingresado datos en el formulario de registro u onboarding de perfil, el sistema solicita confirmación antes de descartar los cambios sin guardar.
- **Teclado en pantalla y pantallas compactas o con texto ampliado (`130%+`)**: Al desplegarse el teclado virtual en los formularios de autenticación, la vista se desplaza automáticamente para mantener visibles el campo con foco y el botón de acción principal, permitiendo avanzar entre campos mediante las acciones del teclado (*"Siguiente"* y *"Enviar"*).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Cuando no exista una sesión activa guardada localmente, el sistema DEBE presentar como puerta de entrada inicial la pantalla de Bienvenida e Inicio de Sesión, permitiendo el registro de nuevos usuarios, el inicio de sesión mediante correo electrónico y contraseña, o el ingreso de un toque mediante *"Continuar como Aficionado"*, persistiendo la elección para abrir directamente el *App Shell* en aperturas posteriores.
- **FR-002**: El sistema DEBE validar en tiempo real y antes del envío el formato de correo electrónico, la longitud mínima de contraseña (`8` caracteres) y los campos obligatorios de perfil, presentando todos los mensajes de validación exclusivamente en español desde el catálogo de localización.
- **FR-003**: El sistema DEBE asignar y hacer cumplir un rol deportivo activo por sesión (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`) mediante una matriz centralizada de permisos: durante el *Onboarding* el usuario selecciona su rol inicial (con selección libre de `Aficionado`, `Jugador` y `Entrenador`, requerimiento de código de autorización para `Organizador` y `Árbitro` en `Producción`, y habilitación libre de los 5 roles en `Desarrollo`), pudiendo cambiar su rol activo entre sus roles autorizados desde la pestaña *Perfil* sin cerrar sesión.
- **FR-004**: El sistema DEBE restringir las capacidades de escritura según la matriz oficial de roles:
  - `Organizador`: creación/edición de campeonatos, sedes, aprobación de equipos/jugadores y designación arbitral.
  - `Entrenador`: gestión de plantilla, inscripciones de su equipo y convocatorias/alineaciones.
  - `Árbitro`: registro de eventos de partido en vivo (goles, asistencias, tarjetas) y cierre del acta oficial en partidos asignados.
  - `Jugador`: consulta de su perfil de rendimiento, convocatorias y estadísticas sin permisos de modificación sobre torneos o actas.
  - `Aficionado`: consulta pública de jornadas, resultados, tablas de posiciones y sedes sin permisos de escritura.
- **FR-005**: El sistema DEBE persistir localmente de forma aislada por entorno (`Desarrollo` / `Producción`) el estado de la sesión autenticada y el rol activo, permitiendo rehidratar la sesión automáticamente en menos de `2` segundos al abrir la aplicación tanto en línea como sin conexión (*offline*), mientras que el registro de cuentas nuevas o el inicio de sesión con una cuenta distinta DEBEN exigir conectividad activa.
- **FR-006**: Los formularios de inicio de sesión, registro y onboarding DEBEN bloquear pulsaciones repetidas mientras una solicitud está en curso (*single-flight*), aplicar un bloqueo temporal de `60` segundos tras `5` intentos fallidos consecutivos de inicio de sesión, gestionar el avance de foco del teclado (*"Siguiente"* → *"Enviar"*) y conservar los datos no sensibles ingresados si la aplicación pasa a segundo plano.
- **FR-007**: La sección *Perfil* del contenedor principal DEBE mostrar la identidad del usuario autenticado (o estado de visitante `Aficionado`), su rol deportivo activo con insignia visual semántica (*KickPulse Mobile*), las capacidades habilitadas para dicho rol y la acción de cierre de sesión (o inicio de sesión si opera como visitante).
- **FR-008**: El proceso de cierre de sesión (*Logout*) DEBE eliminar la sesión activa y limpiar cualquier credencial o información privada almacenada en el dispositivo dentro del entorno correspondiente, redirigiendo de forma segura a la vista de acceso.
- **FR-009**: El sistema DEBE proteger todas las rutas y acciones restringidas mediante guardas de autorización que impidan el acceso no autorizado y muestren un estado o aviso explicativo en español sin exponer detalles técnicos internos.
- **FR-010**: Ninguna contraseña, credencial de acceso ni identificador privado de sesión DEBE mostrarse en pantalla tras su captura ni registrarse en texto plano en las bitácoras (*logs*) o mensajes de fallo del sistema.

### Key Entities *(include if feature involves data)*

- **Usuario Autenticado (`UserAccount`)**: Representa la identidad del participante dentro del campeonato (identificador único inmutable, nombre completo, correo electrónico, rol deportivo activo y estado de completitud de onboarding).
- **Rol Deportivo (`UserRole`)**: Clasificación oficial del actor dentro del ecosistema (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`) que determina sus permisos de navegación y escritura.
- **Permiso Operativo (`RolePermission` / `PermissionMatrix`)**: Regla de dominio que vincula cada `UserRole` con las acciones autorizadas (gestión de torneos, gestión de sedes, gestión de equipo, arbitraje de acta oficial, consulta de perfil y consulta pública).
- **Sesión de Usuario (`AuthSession`)**: Estado persistente de autenticación vinculado al entorno activo que permite la rehidratación inmediata en modo conectado o sin conexión.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un usuario puede completar el inicio de sesión o el ingreso como `Aficionado` y llegar al contenedor principal en menos de `30` segundos, con el 100% de las etiquetas, validaciones y mensajes de estado presentados en español.
- **SC-002**: El 100% de los intentos de ejecutar acciones de escritura no autorizadas para el rol activo (`Jugador` o `Aficionado` intentando crear torneos o editar actas; `Entrenador` intentando alterar un acta arbitral) son bloqueados por las reglas de control de acceso.
- **SC-003**: El 100% de las reaperturas de la aplicación en modo sin conexión (*offline*) con una sesión previamente autenticada restauran el acceso al contenedor principal y al rol del usuario en menos de `2` segundos sin exigir conexión de red.
- **SC-004**: Al cerrar sesión, el 100% de las credenciales y datos privados de la sesión activa son eliminados del almacenamiento del entorno activo en menos de `1` segundo.
- **SC-005**: El 100% de los controles interactivos y campos de los formularios de autenticación y onboarding cumplen el área táctil mínima de `44x44px`, se adaptan sin recortes al desplegar el teclado virtual o ampliar el texto al `130%`, y previenen envíos duplicados ante pulsaciones rápidas repetidas.

## Assumptions

- Para roles administrativos u oficiales críticos (`Organizador` y `Árbitro`), durante el flujo de registro/onboarding o desde la pestaña *Perfil* en el entorno de desarrollo y primeras fases del campeonato, el sistema permite seleccionar o demostrar el rol deportivo para validar los flujos de los 5 actores definidos en el alcance del proyecto, dejando la estructura lista para aprobación por invitación de organizador en torneos cerrados.
- El acceso como `Aficionado` no requiere registro obligatorio de correo y contraseña para consultar calendarios, resultados, tablas de posiciones y sedes públicas, pero ofrece en todo momento la opción de iniciar sesión o registrarse desde la pestaña *Perfil*.
- Se reutiliza íntegramente la fundación creada en la **HU 1.1** (sistema de diseño *KickPulse Mobile*, contenedor *App Shell* de 4 pestañas, catálogo `l10n` en español y almacenamiento local aislado por entorno `dev`/`prod`).
