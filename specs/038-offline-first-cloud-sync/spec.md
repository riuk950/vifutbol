# Feature Specification: Arquitectura Offline-First, Sincronización en la Nube e Indicador de Estado de Datos (HU 17.4)

**Feature Branch**: `develop`  
**Feature Directory**: `specs/038-offline-first-cloud-sync`  
**Created**: 2026-11-11  
**Status**: Draft  
**Input**: User description: "HU 17.4: Arquitectura Offline-First, Sincronización en la Nube (vifutboldev) e Indicador de Estado de Datos en el AppBar" (Notion ID: `4158442e-3f49-8117-bb74-d718e115d853`)

---

## Clarifications

### Session 2026-11-11

- Q: When the device has an active internet connection, how should write operations behave with respect to the remote server and the local sync queue? → A: Remote-first when connected (updates local cache upon success); save locally and enqueue in the persistent sync queue on disconnection or network error.
- Q: When the FIFO sync queue encounters a permanent server rejection on one item, how should it handle the remaining queued changes behind that item? → A: Mark the rejected item in error state with manual retry/discard in the summary panel and continue syncing the remaining valid FIFO items.
- Q: What should happen if an authenticated user initiates sign-out while local changes are still pending in the sync queue? → A: Isolate pending queue items by user ID and prompt on sign-out to sync first (if online), proceed keeping items tied to that user, or cancel.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Lectura en Línea con Respaldo Local Automático en Todos los Módulos (Priority: P1) 🎯 MVP

Como Usuario de KickPulse (`Organizador`, `Entrenador`, `Árbitro`, `Jugador` o `Aficionado`), quiero que cuando exista conexión a internet en el entorno de desarrollo configurado todos los datos deportivos (competiciones, sedes, canchas, equipos, jugadores, partidos, convocatorias, actas arbitrales, alertas, noticias, cuadro de honor y favoritos) se obtengan del servidor remoto y actualicen automáticamente mi almacenamiento local, y que ante falta de red pueda consultar la copia local sin bloqueos.

**Why this priority**: Garantiza que la aplicación funcione con una única fuente de verdad remota en la nube cuando hay internet y conserve continuidad operativa inmediata en canchas con conectividad intermitente.

**Independent Test**: Abrir la aplicación con conectividad activa en entorno de desarrollo configurado y comprobar que los datos cargados provienen del servidor remoto y quedan guardados en el dispositivo; luego desconectar la red, reabrir los módulos y verificar que la información previamente descargada se muestra de forma fluida sin pantallas de error fatales.

**Acceptance Scenarios**:

1. **Given** que la aplicación opera en entorno de desarrollo con configuración remota activa y el dispositivo tiene conexión a internet, **When** cualquier pantalla o flujo solicita datos deportivos, **Then** el sistema obtiene la información actualizada desde el servidor remoto y actualiza de inmediato el respaldo local del dispositivo.
2. **Given** que el usuario ya visualizó o sincronizó datos previamente y el dispositivo pierde la conexión o el servidor no responde por tiempo de espera agotado, **When** el usuario navega o recarga cualquier sección de la aplicación, **Then** el sistema entrega transparentemente los últimos datos guardados en el almacenamiento local sin bloquear la pantalla.
3. **Given** el primer uso de la aplicación sin conexión previa y sin respaldo local guardado, **When** un módulo intenta consultar datos remotos, **Then** la interfaz presenta su estado vacío o de conectividad informativo de forma controlada sin fallos inesperados ni fabricación automática de datos ficticios.

---

### User Story 2 - Guardado Local Offline y Cola Persistente de Sincronización Automática FIFO (Priority: P1) 🎯 MVP

Como Usuario operativo (`Organizador`, `Entrenador`, `Árbitro`) o usuario autenticado con preferencias (`Aficionado`), quiero poder registrar o editar competiciones, sedes, equipos, jugadores, programaciones, convocatorias, actas arbitrales, noticias o favoritos incluso sin conexión a internet, con la garantía de que los cambios se reflejen al instante localmente y se envíen automáticamente en orden cronológico cuando vuelva la red.

**Why this priority**: En sedes y canchas deportivas la conectividad móvil suele ser inestable o nula; perder un acta arbitral, una convocatoria o una programación por caída de red comprometería la operación oficial del torneo.

**Independent Test**: Sin conexión a internet, realizar varias mutaciones consecutivas (por ejemplo: crear competición, registrar equipo y programar partido), cerrar y volver a abrir la aplicación verificando que los cambios siguen visibles localmente y pendientes en cola; posteriormente restaurar la conectividad y comprobar que las mutaciones se envían al servidor remoto en orden cronológico sin duplicados y que el contador pendiente vuelve a cero.

**Acceptance Scenarios**:

1. **Given** que el dispositivo se encuentra sin conexión o falla la respuesta de red durante un guardado, **When** el usuario realiza una operación de creación, actualización o eliminación en cualquiera de los módulos, **Then** el cambio se persiste de inmediato en el almacenamiento local reflejándose en la interfaz y se registra en una cola local persistente con su identificador único, tipo de entidad, datos de operación y marca temporal.
2. **Given** que existen operaciones pendientes en la cola local de sincronización, **When** se cierra y reabre la aplicación estando aún sin red, **Then** la cola pendiente permanece íntegra y no se pierden los cambios locales en espera de envío.
3. **Given** que existen operaciones pendientes en la cola local (`pendingSyncCount > 0`), **When** el dispositivo recupera conexión a internet, **Then** el coordinador de sincronización procesa la cola en orden cronológico estricto (primero en entrar, primero en salir) mediante envíos idempotentes al servidor remoto, elimina cada tarea confirmada, refresca el caché local y pasa el estado global a "Sincronizado".
4. **Given** que el dispositivo está en línea y el guardado remoto se completa con éxito en el acto, **When** el usuario ejecuta una operación de escritura, **Then** el cambio queda confirmado tanto en el servidor remoto como en el almacenamiento local sin dejar tareas pendientes innecesarias en la cola.

---

### User Story 3 - Indicador de Estado de Datos en el Encabezado Visible Solo por Rol Operativo (Priority: P2)

Como Usuario operativo (`Organizador`, `Entrenador` o `Árbitro`), quiero ver un icono discreto e interactivo en la barra superior principal de navegación que me indique en todo momento si mis datos están sincronizados, pendientes por subir, sincronizando o con error/sin red; mientras que para `Jugador`, `Aficionado` y `Aficionado Invitado` ese icono no debe mostrarse.

**Why this priority**: Da visibilidad y tranquilidad inmediata en campo a quienes generan información oficial del campeonato, manteniendo limpia y libre de distracciones la interfaz de jugadores y aficionados consumidores.

**Independent Test**: Iniciar sesión y alternar el rol activo entre los cinco roles del sistema (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`) y en modo `Aficionado Invitado`, comprobando que el indicador aparece únicamente para los tres roles operativos y cambia visualmente ante modificaciones en conectividad, envío en curso y tamaño de cola pendiente.

**Acceptance Scenarios**:

1. **Given** que el usuario navega dentro de la pantalla principal de la aplicación, **When** su rol activo es `Organizador`, `Entrenador` o `Árbitro`, **Then** la barra superior principal muestra el icono interactivo de estado de sincronización de datos junto a las demás acciones globales sin desplazar ni ocultar controles vecinos.
2. **Given** que el usuario navega dentro de la pantalla principal, **When** su rol activo es `Jugador`, `Aficionado` o `Aficionado Invitado`, **Then** el icono de estado de sincronización permanece completamente oculto.
3. **Given** un usuario con rol operativo observando el icono en la barra superior, **When** varía la conectividad o el estado de la cola local, **Then** el indicador comunica claramente con icono, color y etiqueta accesible uno de los cuatro estados:
   - **Sincronizado**: cero cambios pendientes de subir.
   - **Pendiente de sincronización**: insignia numérica discreta con la cantidad `N` de operaciones pendientes.
   - **Sincronizando**: indicador animado mientras el envío hacia el servidor está en curso.
   - **Sin conexión / Error**: estado diferenciado cuando falta internet teniendo cambios o cuando alguna operación falló al sincronizar.

---

### User Story 4 - Panel de Resumen de Sincronización y Disparo Manual (Priority: P2)

Como Usuario operativo (`Organizador`, `Entrenador` o `Árbitro`), quiero tocar el icono de estado de sincronización para abrir un panel de resumen con la fecha de última sincronización exitosa, el detalle de operaciones pendientes o con error y un botón "Sincronizar ahora", para verificar exactamente qué falta por respaldar o forzar el reenvío manualmente.

**Why this priority**: Permite auditoría manual antes de salir de la sede deportiva, recuperación frente a errores individuales de sincronización y confirmación explícita de respaldo.

**Independent Test**: Acumular al menos dos mutaciones offline como `Organizador`, tocar el icono de la barra superior para verificar el resumen detallado y la ausencia de última hora actualizada; al reconectar o simular fallo en una tarea, verificar los botones "Sincronizar ahora" y recuperación/descarte del ítem con error.

**Acceptance Scenarios**:

1. **Given** un usuario con rol operativo con la aplicación abierta, **When** toca el icono de estado de sincronización en la barra superior, **Then** se despliega un panel resumen que muestra el estado general actual, la fecha y hora de la última sincronización exitosa (o indicación de que aún no se ha sincronizado), y el detalle legible de las operaciones pendientes o con error.
2. **Given** que el panel de resumen está abierto y existen cambios pendientes con conexión activa, **When** el usuario presiona "Sincronizar ahora", **Then** se dispara una única ejecución de sincronización (protegida contra pulsaciones repetidas), actualiza en vivo el progreso y refleja el estado "Sincronizado" al terminar.
3. **Given** que una operación específica en cola recibió un rechazo definitivo del servidor (por permisos o regla de negocio), **When** el usuario consulta el panel de resumen, **Then** puede visualizar el motivo comprensible en español del elemento afectado y decidir reintentarlo o descartarlo para limpiar la cola sin bloquear el resto de sus operaciones válidas.

---

### Edge Cases

- **Reconexiones intermitentes o múltiples eventos simultáneos**: Cambios rápidos entre desconectado y conectado no deben iniciar envíos paralelos duplicados de la cola; solo una ronda de sincronización debe ejecutarse a la vez.
- **Interrupción durante una sincronización activa (paso a segundo plano o cierre del proceso)**: Si el proceso se detiene a mitad de una ronda, las tareas aún no confirmadas permanecen en la cola y, al reanudarse, se envían de forma idempotente mediante su identificador único sin duplicar registros en el servidor.
- **Concurrencia / Conflictos entre dispositivos**: Si un registro remoto fue modificado más recientemente que la versión local en cola, prevalece una política controlada basada en marca temporal de actualización (`updated_at`), registrando cualquier rechazo definitivo para visibilidad del usuario si el servidor deniega la escritura.
- **Modo Aficionado Invitado**: Toda lectura pública funciona y cualquier preferencia local de invitado se guarda únicamente en el dispositivo sin encolarse hacia el servidor remoto.
- **Cambio de rol o cierre de sesión con tareas pendientes**: Las operaciones en cola quedan vinculadas al identificador del usuario propietario (`userId`) para impedir que cambios creados bajo una cuenta se suban con otra; si existen pendientes al intentar cerrar sesión, se advierte al usuario ofreciéndole sincronizar antes (si hay red), salir conservando sus pendientes aislados para cuando vuelva a iniciar sesión, o cancelar.
- **Accesibilidad y escalado tipográfico móvil**: El icono en la barra superior cumple el área táctil mínima accesible, provee etiquetas descriptivas para lectores de pantalla (sin depender solo del color) y el panel resumen es legible al 130% de escala de texto sin desbordamientos.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: En entorno de desarrollo con configuración remota activa, todos los repositorios de dominio (competiciones, sedes/canchas, equipos/jugadores, partidos/árbitros, convocatorias, actas arbitrales, eventos en vivo, noticias, cuadro de honor y favoritos) DEBEN operar bajo estrategia híbrida: lectura desde almacenamiento remoto con actualización del caché local cuando hay red, y entrega automática del último caché local guardado cuando la conectividad falla o no está disponible.
- **FR-002**: En entorno local sin backend configurado o durante pruebas aisladas sin cliente remoto activo, los proveedores de repositorio DEBEN mantener la operación local existente sin requerir conexión ni romper la suite actual.
- **FR-003**: Con conexión activa, toda mutación de escritura DEBE intentar primero el guardado remoto y actualizar de inmediato el caché local al confirmarse (sin encolar pendientes); ante ausencia de red o fallo de conectividad durante el envío, DEBE persistirse al instante en el almacenamiento local y registrarse en la cola de sincronización persistente con identificador de tarea, tipo de entidad, operación, datos serializados, identificador del registro, contexto de usuario y marca temporal de creación.
- **FR-004**: El coordinador central de sincronización DEBE escuchar cambios de conectividad del dispositivo y disparar automáticamente el procesamiento en orden cronológico (FIFO) de las operaciones pendientes al recuperar conexión, garantizando exclusión mutua para evitar ejecuciones simultáneas duplicadas.
- **FR-005**: Cada operación enviada al servidor remoto desde la cola DEBE ejecutarse de manera idempotente apoyada en identificadores únicos de entidad (`uuid`), removiendo la tarea de la cola local únicamente tras confirmación remota y refrescando la entidad local afectada.
- **FR-006**: Cuando una operación en cola falle por un error transitorio de red o tiempo de espera, el elemento DEBE conservarse pendiente para reintento automático posterior; cuando falle por un rechazo no transitorio de negocio o permisos, el elemento DEBE marcarse con estado de error comprensible en español sin bloquear indefinidamente el avance de los demás ítems válidos de la cola.
- **FR-007**: El sistema DEBE exponer un estado global reactivo de sincronización con al menos cuatro estados (`synced`, `pending`, `syncing`, `offlineOrError`), contador de pendientes, conteo o listado de ítems con error y marca temporal de la última sincronización exitosa.
- **FR-008**: La pantalla principal de navegación DEBE incluir en su barra superior un indicador interactivo de estado de sincronización visible **exclusivamente** cuando el rol activo sea `Organizador`, `Entrenador` o `Árbitro`, permaneciendo oculto para `Jugador`, `Aficionado` y `Aficionado Invitado`.
- **FR-009**: El indicador DEBE actualizar su apariencia y insignia numérica en tiempo real según el estado de sincronización, cumplir criterios de accesibilidad móviles (etiqueta semántica y área táctil mínima sin depender únicamente del color) y desplegar al tocarlo un panel resumen con los detalles de pendientes, errores, última sincronización y botón de disparo manual "Sincronizar ahora" (con protección anti doble pulsación y acciones para reintentar o descartar ítems fallidos).
- **FR-010**: La cola local de sincronización y el resumen diagnóstico NO DEBEN almacenar ni exponer en logs tokens de autenticación, contraseñas ni datos sensibles de credenciales.
- **FR-011**: Cada tarea de la cola local DEBE aislarse por identificador de usuario propietario (`userId`) de modo que solo se sincronice cuando la sesión activa corresponda a ese mismo usuario; si el usuario solicita cerrar sesión teniendo pendientes (`pendingSyncCount > 0`), la aplicación DEBE mostrar un diálogo de confirmación en español con las opciones de sincronizar antes (si hay red), salir conservando las tareas vinculadas a su cuenta o cancelar.

---

### Key Entities *(include if feature involves data)*

- **Tarea Pendiente de Sincronización (`SyncOutboxItem`)**: Representa una mutación pendiente o fallida almacenada localmente en la cola; incluye identificador único de tarea, tipo de entidad de negocio, tipo de operación (guardar/eliminar), identificador único de la entidad afectada, datos serializados de la mutación, contexto de cuenta propietaria, marca temporal de creación, estado de intento (`pending`, `error`) y mensaje legible de error si aplica.
- **Estado de Sincronización (`SyncStatus` / `SyncSummaryState`)**: Representa la vista agregada del estado de datos del usuario en tiempo real; contiene estado general (`synced`, `pending`, `syncing`, `offlineOrError`), cantidad de operaciones pendientes, lista de ítems pendientes/fallidos, fecha y hora de la última sincronización exitosa y bandera de proceso manual/automático en curso.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de los módulos de datos de la aplicación leen desde el backend DEV cuando hay conectividad y conservan disponibilidad íntegra desde caché local ante pérdida de red sin excepciones fatales en la interfaz.
- **SC-002**: El 100% de las operaciones de escritura ejecutadas offline sobreviven al cierre y reapertura de la aplicación y se sincronizan en orden cronológico (FIFO) sin registros duplicados al restablecer la conectividad.
- **SC-003**: El 100% de las verificaciones de visibilidad por rol en la barra superior muestran el indicador para `Organizador`, `Entrenador` y `Árbitro` y lo ocultan para `Jugador`, `Aficionado` y `Aficionado Invitado`.
- **SC-004**: El usuario operativo puede consultar el resumen de estado y completar o verificar una sincronización manual en menos de 2 toques desde cualquier pestaña principal, con textos en español claros y cero fugas de tokens o credenciales en registros.

---

## Assumptions

- Esta historia se apoya directamente en el cliente Supabase DEV (HU 17.1), en el esquema relacional `vifutboldev` con políticas RLS por rol (HU 17.2) y en la autenticación de sesión y perfil en `vifutboldev.user_accounts` (HU 17.3).
- Cuando el usuario opera conectado con éxito, la escritura remota directa actualiza la nube en el acto y refresca el caché local; solo ante desconexión o fallo de red transitorio se encola en la cola local persistente (y los aficionados invitados operan exclusivamente en almacenamiento local sin envío remoto).
- Ante rechazos no transitorios del servidor sobre un ítem específico de la cola (por ejemplo, permiso RLS denegado o violación de restricción de negocio), dicho ítem se marca en estado de error individual visible en el resumen para reintento o descarte manual sin detener el vaciado FIFO del resto de la cola.
- Cada tarea en cola queda asociada al identificador de cuenta del usuario que la originó para evitar cruces de credenciales al cambiar de sesión; además, la cola local se mantiene limpia de credenciales o JWTs.
