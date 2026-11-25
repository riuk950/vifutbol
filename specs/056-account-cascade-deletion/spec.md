# Feature Specification: Eliminación de Cuenta con Borrado en Cascada (Local y Nube)

**Feature Branch**: `056-account-cascade-deletion`

**Created**: 2026-11-25

**Status**: Draft

**Input**: User description: "HU 24.3 (Épica 24 - Notion): Eliminación de Cuenta con Borrado en Cascada (Local y Nube) — Como usuario autenticado de ViFutbol, quiero tener un botón de Eliminar cuenta en mi Perfil que elimine de forma permanente y en cascada toda mi información tanto en el almacenamiento local como en la nube, para ejercer mi derecho a la eliminación total de mis datos personales y de cuenta sin dejar registros huérfanos en el dispositivo ni en el servidor."

## Clarifications

### Session 2026-11-25

- Q: ¿Qué nivel de confirmación debe exigir el diálogo antes de ejecutar la eliminación permanente de la cuenta? → A: Diálogo de confirmación explícito con advertencia de irreversibilidad y botones `Cancelar` / `Eliminar cuenta` (sin escribir texto ni contraseña adicional).
- Q: Cuando un usuario elimina su cuenta, ¿qué debe suceder con los registros históricos compartidos en los que participó (torneos, equipos o actas oficiales de partidos)? → A: Eliminar todos los datos personales del usuario y desvincular (`NULL`) sus referencias en torneos, equipos y actas históricas compartidas para no alterar resultados ni tablas de terceros.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Eliminación Permanente de Cuenta en Cascada (Nube y Local) (Priority: P1)

Como usuario autenticado de ViFutbol (con cualquiera de los cinco roles del sistema), quiero encontrar un botón destructivo de **Eliminar cuenta** en mi pantalla de Perfil, confirmar explícitamente que entiendo que la acción es irreversible, y que el sistema elimine de forma permanente y en cascada toda mi cuenta, perfiles por rol, solicitudes, favoritos, archivos multimedia personales (foto de perfil y documentos escaneados) en la nube y luego limpie por completo los datos locales del dispositivo, dejándome sin sesión en la pantalla de bienvenida/inicio de sesión.

**Why this priority**: Cumple el derecho fundamental de supresión de datos personales (requisito regulatorio y de publicación en tiendas móviles) y es el núcleo funcional de HU 24.3.

**Independent Test**: Puede verificarse de forma independiente con un usuario autenticado y conexión a internet pulsando "Eliminar cuenta", confirmando en el diálogo, comprobando el estado de carga con bloqueo contra doble envío, validando que se eliminen en cascada todos los datos en la nube y archivos personales, que se limpie todo el almacenamiento local (sesión, credenciales locales, cola de sincronización pendiente y archivos cacheados) y que el usuario sea redirigido a la pantalla de inicio de sesión en estado no autenticado.

**Acceptance Scenarios**:

1. **Given** un usuario autenticado con conexión a internet en la pantalla de Perfil, **When** presiona el botón `Eliminar cuenta` y confirma la eliminación irreversible en el diálogo de confirmación, **Then** el flujo entra en estado de carga bloqueando pulsaciones repetidas, elimina en cascada en la nube su identidad, cuenta, perfiles asociados a roles, solicitudes de unión, favoritos/alertas y archivos multimedia personales, limpia por completo el almacenamiento local del dispositivo (sesión, cuentas/credenciales locales, cola de sincronización pendiente, cachés y archivos locales) y redirige al usuario a la pantalla de bienvenida/inicio de sesión sin sesión activa.
2. **Given** un usuario en modo visitante (`Aficionado` invitado) en la pantalla de Perfil, **When** revisa las acciones al final del Perfil, **Then** el botón `Eliminar cuenta` NO se muestra (solo aplica a cuentas autenticadas).
3. **Given** un usuario que completó la eliminación de su cuenta y cierra y vuelve a abrir la aplicación, **When** la aplicación inicia nuevamente, **Then** no se restaura ninguna sesión anterior ni quedan datos locales o pendientes de sincronización de la cuenta eliminada.

---

### User Story 2 - Confirmación Irreversible, Cancelación Segura y Protección contra Doble Envío (Priority: P2)

Como usuario autenticado de ViFutbol, al pulsar **Eliminar cuenta** quiero ver un diálogo de advertencia claro en español que explique que la eliminación es permanente e irreversible y me permita cancelar sin perder ningún dato; y si confirmo, quiero que la interfaz impida pulsaciones duplicadas mientras el proceso está en curso.

**Why this priority**: Al tratarse de una operación destructiva e irreversible, prevenir eliminaciones accidentales y envíos concurrentes es crítico para la seguridad del usuario y la integridad del sistema.

**Independent Test**: Puede probarse abriendo el diálogo de confirmación desde Perfil, pulsando "Cancelar" (o atrás) para comprobar que no se invoca ninguna eliminación ni se alteran datos, y simulando taps repetidos sobre el botón de confirmación mientras el borrado está en progreso para verificar que solo se ejecuta una operación (`single-flight`).

**Acceptance Scenarios**:

1. **Given** un usuario autenticado que presiona `Eliminar cuenta` en Perfil, **When** selecciona `Cancelar` o descarta el diálogo de confirmación, **Then** no se elimina ningún dato ni en el dispositivo ni en la nube, y el usuario permanece en su sesión actual en la pantalla de Perfil.
2. **Given** un usuario autenticado que presiona confirmar en el diálogo de eliminación, **When** intenta pulsar repetidamente el botón de confirmación o el botón `Eliminar cuenta` mientras la operación está en curso, **Then** las pulsaciones adicionales son ignoradas (bloqueo `single-flight`), se muestra un indicador claro de progreso y se ejecuta únicamente una solicitud de eliminación.

---

### User Story 3 - Resiliencia Offline y Manejo Seguro de Fallos Remotos (Priority: P3)

Como usuario autenticado de ViFutbol, si intento eliminar mi cuenta sin conexión a internet o si ocurre un error en el servidor durante el borrado en la nube, quiero recibir un mensaje claro en español y que mi sesión y datos locales NO se borren de forma parcial o silenciosa, permitiéndome reintentar cuando haya conectividad o contactar soporte sin dejar la cuenta huérfana en la nube.

**Why this priority**: Garantiza atomicidad funcional entre nube y dispositivo (`docs/MOBILE_GUIDELINES.md`), evitando que un usuario pierda acceso local mientras sus datos personales siguen existiendo en el servidor.

**Independent Test**: Puede verificarse simulando (a) estado sin conexión a internet y (b) error del servidor remoto durante el borrado, confirmando en ambos casos que se presenta un mensaje claro en español, se aborta la limpieza local, la sesión sigue activa y el usuario puede reintentar posteriormente.

**Acceptance Scenarios**:

1. **Given** un usuario autenticado sin conexión a internet, **When** presiona `Eliminar cuenta` y confirma la acción, **Then** el sistema muestra un mensaje claro en español indicando que se requiere conexión a internet para eliminar la cuenta y no elimina la sesión ni ningún dato local.
2. **Given** un usuario autenticado con conexión a internet cuya solicitud de eliminación remota falla por un error del servidor o de red durante la operación, **When** ocurre el fallo, **Then** el sistema aborta la limpieza local, muestra un mensaje de error claro en español (sin exponer detalles técnicos ni tokens) y mantiene la sesión local intacta para permitir reintentar.
3. **Given** un usuario operando en modo exclusivamente local (entorno sin servicio en la nube configurado), **When** confirma la eliminación de su cuenta, **Then** el sistema elimina en cascada sus datos y credenciales en el almacenamiento local y cierra la sesión redirigiendo a la pantalla de bienvenida/inicio de sesión.

---

### Edge Cases

- **Usuario con datos compartidos en torneos oficiales**: Si el usuario era organizador, entrenador, árbitro o jugador vinculado a torneos, equipos o actas oficiales históricas, la eliminación en cascada debe borrar sus datos personales y perfiles sin corromper la integridad referencial ni destruir los resultados históricos de terceros (desvinculando o anulando referencias donde corresponda).
- **Usuario sin archivos multimedia cargados**: Si el usuario nunca subió foto de perfil ni imágenes de documento, la eliminación de archivos multimedia en la nube y en local debe completarse limpiamente sin generar errores.
- **Cola de sincronización con operaciones pendientes**: Al confirmarse la eliminación exitosa en la nube, cualquier operación pendiente en la cola de sincronización local debe descartarse por completo para evitar que un reintento posterior re-cree o intente sincronizar datos de la cuenta eliminada.
- **Interrupción por segundo plano durante el borrado**: Mientras el borrado remoto está en progreso, el bloqueo impide reenvíos; si la operación falla por pérdida de red al volver a primer plano, el usuario recibe retroalimentación clara y puede reintentar.
- **Accesibilidad y contraste**: El botón destructivo `Eliminar cuenta` y el diálogo de confirmación deben comunicar la acción destructiva mediante ícono y texto explícito (no solo color rojo), mantener áreas táctiles ≥ 44 px y renderizarse sin recortes bajo escalado de texto ampliado (`1.5x`).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE mostrar un botón de `Eliminar cuenta` con estilo visual destructivo en la pantalla de Perfil únicamente para usuarios autenticados (nunca visible para usuarios en modo visitante/invitado).
- **FR-002**: El botón `Eliminar cuenta` DEBE ubicarse en la zona de acciones de cuenta al final de la pantalla de Perfil (debajo de las opciones legales/soporte y del botón de cerrar sesión), con ícono destructivo, etiqueta localizada en español y área táctil accesible (mínimo 44 px).
- **FR-003**: Al presionar `Eliminar cuenta`, el sistema DEBE presentar un diálogo de confirmación explícito en español advirtiendo que la eliminación es permanente e irreversible y ofreciendo los botones `Cancelar` y `Eliminar cuenta` (sin requerir escritura de confirmación ni reingreso de contraseña).
- **FR-004**: Si el usuario cancela o descarta el diálogo de confirmación, el sistema NO DEBE ejecutar ninguna eliminación en la nube ni en el almacenamiento local y DEBE mantener intacta la sesión actual.
- **FR-005**: Mientras la operación de eliminación está en ejecución, el sistema DEBE aplicar un bloqueo `single-flight` y mostrar un estado visual de carga que impida múltiples envíos simultáneos o duplicados.
- **FR-006**: Cuando el servicio en la nube está configurado, el sistema DEBE verificar la conectividad antes de iniciar el borrado; si no hay conexión a internet, DEBE mostrar un mensaje claro en español indicando que se requiere conexión y abortar sin eliminar datos locales ni la sesión.
- **FR-007**: El borrado en cascada en la nube DEBE ejecutarse de forma segura validando que el solicitante sea el propio titular autenticado de la cuenta, eliminando:
  - La identidad de autenticación del usuario y su registro principal de cuenta.
  - Sus perfiles satélite asociados a roles (jugador, entrenador, árbitro, organizador, aficionado).
  - Sus solicitudes de unión a equipos, favoritos, alertas y demás registros personales dependientes.
  - Desvincular (`NULL`) las referencias al usuario en registros históricos compartidos (torneos, equipos, sedes, actas oficiales o registros de participación de terceros) para preservar la integridad referencial y las tablas de posiciones sin conservar datos personales del titular.
  - Sus archivos multimedia personales almacenados en la nube (foto de perfil e imágenes de documentos escaneados), si existen.
- **FR-008**: Si la operación de eliminación en la nube falla por cualquier motivo, el sistema DEBE abortar el borrado local, mantener la sesión local activa y mostrar un mensaje de error claro en español sin exponer información técnica sensible ni credenciales.
- **FR-009**: Solo tras completarse exitosamente el borrado en la nube (o en modo exclusivamente local sin servicio remoto configurado), el sistema DEBE ejecutar el borrado en cascada en el dispositivo:
  - Limpiar el espacio de almacenamiento local del usuario, la sesión activa y las cuentas/credenciales locales almacenadas.
  - Vaciar la cola de sincronización pendiente y los cachés de repositorios locales.
  - Eliminar archivos locales/temporales de imágenes personales del usuario si existen.
- **FR-010**: Al finalizar la limpieza local, el sistema DEBE transicionar el estado de autenticación a no autenticado y redirigir inmediatamente al usuario a la pantalla de bienvenida/inicio de sesión.
- **FR-011**: Todos los textos visibles (botón, diálogo de confirmación, advertencia de irreversibilidad, estado de carga, mensaje offline y mensajes de error) DEBEN estar en español y centralizados en el sistema de localización (`l10n`), sin textos incrustados directamente.
- **FR-012**: La incorporación del botón y flujo de eliminación de cuenta NO DEBE afectar el funcionamiento de las demás secciones existentes del Perfil (tarjeta de identidad, rol en solo lectura, completitud, datos personales, permisos, botones legales/soporte y cierre de sesión).

### Key Entities *(include if feature involves data)*

- **Cuenta de Usuario y Perfiles por Rol**: Identidad principal del usuario autenticado y sus perfiles específicos de rol (jugador, entrenador, árbitro, organizador, aficionado), eliminados en cascada al confirmar la supresión.
- **Registros Personales Dependientes**: Solicitudes de unión a equipos, equipos favoritos, alertas personales y archivos multimedia (foto de perfil y documentos de identidad) pertenecientes exclusivamente al usuario.
- **Almacenamiento Local y Cola de Sincronización**: Datos en caché en el dispositivo, sesión persistida, credenciales locales y operaciones pendientes de sincronización que deben purgarse completamente tras el borrado remoto exitoso.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de los usuarios autenticados que confirman la eliminación con conexión a internet completan el borrado en cascada en la nube y en local, quedando redirigidos a la pantalla de bienvenida con 0 registros de sesión, 0 cuentas locales y 0 elementos pendientes en la cola de sincronización.
- **SC-002**: El 100% de los intentos cancelados en el diálogo de confirmación preservan intactos la sesión y todos los datos locales y remotos (0 mutaciones).
- **SC-003**: El 100% de los intentos sin conexión a internet o con fallo del servidor remoto muestran un mensaje claro en español y conservan intacta la sesión local (0 borrados locales parciales).
- **SC-004**: El 100% de los usuarios en modo visitante no visualizan el botón `Eliminar cuenta`, y ante pulsaciones repetidas rápidas durante la confirmación se ejecuta exactamente 1 solicitud de eliminación.

## Assumptions

- Para el borrado seguro de la identidad en la nube, el backend contará con una función/procedimiento protegido que valide automáticamente la identidad del usuario autenticado que invoca la solicitud y ejecute el borrado en cascada dentro de una transacción segura.
- Cuando la aplicación opera en modo puramente local (sin credenciales de nube configuradas, por ejemplo en entornos de pruebas locales sin servidor), el borrado elimina completamente la cuenta y el almacenamiento local sin fallar por ausencia de backend remoto.
