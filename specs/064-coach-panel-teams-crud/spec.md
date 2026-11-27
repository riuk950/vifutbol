# Feature Specification: Panel Técnico del Entrenador — Listado, Edición y Eliminación de Equipos

**Feature Branch**: `064-coach-panel-teams-crud`

**Created**: 2026-11-26

**Status**: Draft

**Input**: User description: "/speckit-specify de Notion HU 27.4 en curso — [Épica 27] HU 27.4: Panel Técnico del Entrenador: Listado de Equipos Creados con Edición y Eliminación"

## Clarifications

### Session 2026-11-26

- Q: Cuando un entrenador edita un equipo que ya está inscrito en un campeonato (especialmente si el campeonato está en curso o finalizado), ¿el selector de campeonato debe quedar bloqueado como solo lectura o permitir cambiar de campeonato? → A: Bloquear el selector de campeonato como solo lectura si el equipo ya está en un campeonato en curso o finalizado (permitiendo editarlo solo si es autónomo o está en registro abierto).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Listado Exclusivo y Selección de Equipos Creados en el Panel Técnico (Priority: P1)

Como entrenador autenticado, quiero que al ingresar al Panel Técnico se muestren todos los equipos que he creado (y únicamente los míos) para poder seleccionar cualquiera de ellos y consultar sus métricas, próximo partido, acciones rápidas y plantilla agrupada por posición, además de poder registrar un equipo adicional en cualquier momento.

**Why this priority**: Es la vista principal de gestión del entrenador; actualmente el panel no muestra la lista completa de equipos propios ni permite alternar entre múltiples clubes creados por el mismo entrenador.

**Independent Test**: Se puede probar de forma independiente autenticándose como un entrenador con dos o más equipos creados (y existiendo equipos de otros entrenadores), ingresando al Panel Técnico y verificando que aparecen solo sus equipos, que al tocar cada uno se actualiza el detalle del panel, y que permanece accesible la opción para registrar un equipo adicional.

**Acceptance Scenarios**:

1. **Given** que un entrenador autenticado ha creado dos o más equipos y existen otros equipos creados por terceros, **When** ingresa al Panel Técnico, **Then** visualiza la lista completa de los equipos asociados a su cuenta (con su escudo circular, nombre, sigla, delegado, colores distintivos y resumen de plantilla), sin ver equipos de otros entrenadores.
2. **Given** que el entrenador visualiza dos o más equipos en su Panel Técnico, **When** selecciona un equipo distinto al activo actualmente, **Then** el resumen de métricas de plantilla, el próximo partido, las acciones rápidas y la plantilla por posición se actualizan de forma inmediata para reflejar al equipo seleccionado.
3. **Given** que un entrenador autenticado aún no ha creado ningún equipo, **When** ingresa al Panel Técnico, **Then** visualiza un estado vacío informativo con un botón principal para registrar su primer equipo.
4. **Given** que el entrenador ya tiene uno o más equipos creados en el Panel Técnico, **When** desea crear otro equipo, **Then** dispone de un acceso visible para iniciar el registro de un equipo adicional.

---

### User Story 2 - Edición de Equipos Creados desde el Panel Técnico (Priority: P2)

Como entrenador propietario de un equipo, quiero editar los datos institucionales y el escudo circular de cualquiera de mis equipos desde el Panel Técnico para mantener su información actualizada sin tener que recrear el club.

**Why this priority**: Permite corregir o actualizar nombre, sigla, delegado, fecha de creación, colores distintivos, torneo asociado (cuando aplique) y foto del escudo manteniendo la continuidad histórica del equipo.

**Independent Test**: Se puede probar seleccionando "Editar" en un equipo del Panel Técnico, verificando que el formulario abre precargado con todos los valores actuales, modificando campos válidos, guardando y comprobando la actualización inmediata en el panel tanto en línea como sin conexión.

**Acceptance Scenarios**:

1. **Given** que el entrenador visualiza sus equipos creados en el Panel Técnico, **When** presiona la acción "Editar" en una tarjeta de equipo, **Then** se abre la pantalla de registro/edición de equipo precargada con su nombre, sigla, delegado, fecha de creación, colores primario y secundario, campeonato asociado (si existe) y escudo circular actual.
2. **Given** que el entrenador está en modo edición y modifica campos válidos, **When** presiona "Guardar cambios", **Then** el botón muestra estado de carga bloqueando envíos duplicados, se valida la unicidad del nombre normalizado excluyendo al propio equipo, los cambios se guardan en el dispositivo y en el servidor, y regresa al Panel Técnico mostrando el equipo actualizado y un mensaje de confirmación en español.
3. **Given** que el entrenador realiza cambios en modo edición y presiona volver o cancelar sin guardar, **When** intenta salir de la pantalla, **Then** el sistema solicita confirmación antes de descartar los cambios no guardados.
4. **Given** que el entrenador edita un equipo sin conexión a internet (incluyendo un cambio de escudo), **When** guarda los cambios, **Then** los cambios quedan reflejados inmediatamente en el Panel Técnico local y se encolan para sincronización automática al recuperar conectividad.

---

### User Story 3 - Eliminación Segura de Equipos Creados con Confirmación (Priority: P3)

Como entrenador propietario, quiero poder eliminar un equipo que creé desde el Panel Técnico previa confirmación explícita para depurar clubes de prueba o equipos que ya no gestiono.

**Why this priority**: Completa el ciclo de administración del entrenador con una operación destructiva controlada mediante confirmación clara y validación de propiedad.

**Independent Test**: Se puede probar pulsando "Eliminar" en un equipo del Panel Técnico, verificando primero que al cancelar el equipo permanece intacto, y luego confirmando para comprobar que desaparece del panel y del almacenamiento local/remoto.

**Acceptance Scenarios**:

1. **Given** que el entrenador visualiza sus equipos creados en el Panel Técnico, **When** presiona la acción "Eliminar" en uno de sus equipos, **Then** se muestra un diálogo de confirmación en español indicando el nombre del equipo y advirtiendo que la acción es irreversible.
2. **Given** que el diálogo de confirmación de eliminación está visible, **When** el entrenador presiona "Cancelar", **Then** el diálogo se cierra y el equipo permanece intacto en el Panel Técnico y en sus datos guardados.
3. **Given** que el diálogo de confirmación de eliminación está visible, **When** el entrenador confirma la eliminación, **Then** la acción se ejecuta con protección contra pulsaciones repetidas, el equipo se elimina en almacenamiento local y remoto, desaparece inmediatamente de la lista, el equipo activo seleccionado se reajusta al siguiente disponible (o al estado vacío si era el último) y se muestra confirmación en español.
4. **Given** que el dispositivo está sin conexión al confirmar la eliminación, **When** se ejecuta el borrado, **Then** el equipo se elimina inmediatamente de la vista y almacenamiento local, y la eliminación remota queda encolada para sincronizarse automáticamente al reconectar.

---

### Edge Cases

- ¿Qué ocurre cuando el entrenador intenta eliminar un equipo que ya está inscrito en un campeonato en curso o finalizado, o tiene partidos asociados? El sistema debe bloquear la eliminación mostrando un mensaje claro en español explicando que no se puede eliminar un equipo con participación activa, finalizada o con partidos registrados; solo se permite eliminar equipos autónomos o inscritos en torneos con registro abierto sin partidos asociados.
- ¿Qué ocurre si el usuario autenticado cambia de rol o cierra sesión y vuelve a entrar con otra cuenta de entrenador? El Panel Técnico debe recalcular el listado filtrando estrictamente por la cuenta activa actual, sin mostrar equipos en caché pertenecientes a otra sesión.
- ¿Qué ocurre si el entrenador intenta editar el nombre de su equipo por uno que ya pertenece a otro club registrado en el mismo ámbito? El sistema debe rechazar el guardado y mostrar un mensaje claro en español, pero permitir guardar sin error cuando conserva su propio nombre o solo cambia mayúsculas/espaciado.
- ¿Qué ocurre si falla la conexión o el servidor devuelve un error de permisos al guardar una edición o confirmar una eliminación? La interfaz debe recuperarse del estado de carga, mantener la coherencia visual y mostrar un mensaje de error claro en español sin exponer detalles técnicos internos.
- ¿Qué ocurre con las áreas táctiles, accesibilidad y tamaños de pantalla pequeños al mostrar la lista de equipos con acciones de Editar y Eliminar? Cada control interactivo debe cumplir con un área táctil mínima de 48×48 dp, etiquetas semánticas claras y diseño adaptable sin recorte horizontal ni superposición de texto al escalar fuentes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El Panel Técnico del entrenador MUST consultar y mostrar todos los equipos cuyo identificador de entrenador propietario coincida estrictamente con el usuario autenticado actual, excluyendo equipos de terceros o datos semilla genéricos cuando exista sesión real.
- **FR-002**: Cada tarjeta de equipo en el Panel Técnico MUST mostrar el escudo circular del equipo, su nombre, sigla, delegado (si tiene), colores distintivos y resumen de plantilla, además de indicar visualmente cuál equipo está seleccionado como activo.
- **FR-003**: Al seleccionar cualquier equipo de la lista del Panel Técnico, las secciones dependientes (métricas de plantilla, próximo partido, acciones rápidas y plantilla por posición) MUST actualizarse reactivamente para ese equipo.
- **FR-004**: Cuando el entrenador no tenga equipos creados, el Panel Técnico MUST mostrar el estado vacío con el llamado a la acción para registrar su primer equipo; cuando tenga uno o más equipos, MUST mantener visible un acceso para registrar un equipo adicional.
- **FR-005**: Cada equipo listado en el Panel Técnico MUST ofrecer acciones explícitas de **Editar** y **Eliminar** con área táctil mínima de 48×48 dp y etiquetas accesibles.
- **FR-006**: Al activar **Editar**, el sistema MUST abrir el formulario de equipo precargado con todos los datos vigentes del equipo (nombre, sigla, delegado, fecha de creación, colores primario y secundario, campeonato asociado si aplica y escudo circular actual), manteniendo el selector de campeonato editable únicamente si el equipo es autónomo o su campeonato actual está en registro abierto (`openRegistration`), y bloqueado en modo solo lectura si el campeonato está en curso o finalizado.
- **FR-007**: Al guardar una edición, el sistema MUST validar los campos obligatorios y la unicidad del nombre normalizado excluyendo el identificador del propio equipo, aplicar protección contra envíos duplicados y persistir los cambios tanto localmente como en el servidor (incluyendo actualización del escudo si fue modificado o eliminado).
- **FR-008**: Al activar **Eliminar**, el sistema MUST presentar un diálogo de confirmación en español con el nombre del equipo y advertencia de irreversibilidad antes de ejecutar el borrado.
- **FR-009**: Solo el entrenador propietario del equipo (`coachId` coincidente con la cuenta autenticada) MUST poder editarlo o eliminarlo, tanto en las validaciones de negocio de la aplicación como en las reglas de autorización del servidor.
- **FR-010**: Al confirmar la eliminación, el sistema MUST validar que el equipo no participe en torneos en curso o finalizados ni tenga partidos registrados (bloqueando el borrado con un mensaje claro en español si aplica), y en caso contrario ejecutar el borrado con protección contra pulsaciones repetidas en almacenamiento local y remoto, retirar inmediatamente el equipo del listado, reajustar el equipo activo seleccionado (o mostrar el estado vacío si era el último) y mostrar un mensaje de confirmación en español.
- **FR-011**: Las operaciones de edición y eliminación MUST operar con resiliencia offline-first: reflejar el resultado de inmediato en el estado local y encolar la sincronización pendiente si no hay conexión disponible.
- **FR-012**: Todos los textos visibles, diálogos, etiquetas de accesibilidad y mensajes de error o éxito MUST estar en español y centralizados mediante el sistema de localización de la aplicación, sin mensajes crudos del servidor expuestos al usuario.

### Key Entities *(include if feature involves data)*

- **Equipo (Club / Inscripción de Equipo)**: Representa un equipo creado por un entrenador, identificado por su ID único, identificador del entrenador propietario, nombre, nombre normalizado, sigla, delegado, fecha de creación, colores primario y secundario, URL o ruta local del escudo circular, torneo opcional asociado y su plantilla de jugadores.
- **Entrenador Autenticado**: Usuario con rol de entrenador cuyo identificador de cuenta determina la propiedad exclusiva sobre los equipos listados, editables y eliminables en el Panel Técnico.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de los equipos mostrados en el Panel Técnico pertenecen al entrenador autenticado y se visualizan inmediatamente al abrir el panel cuando ya existen datos locales o remotos.
- **SC-002**: El entrenador puede cambiar el equipo activo seleccionado, abrir el formulario de edición precargado o iniciar el diálogo de confirmación de eliminación en un máximo de 1 toque desde la tarjeta del equipo.
- **SC-003**: El 100% de las ediciones válidas y eliminaciones confirmadas actualizan el estado visible del Panel Técnico en menos de 1 segundo en almacenamiento local y quedan sincronizadas o encoladas sin pérdida de datos ante desconexión.
- **SC-004**: El 0% de las acciones repetidas sobre guardar o confirmar eliminación generan operaciones duplicadas ni permiten que un usuario distinto al propietario modifique o elimine el equipo.

## Assumptions

- El formulario dedicado de creación de equipo ya soporta nombre, sigla, delegado, fecha de creación, colores distintivos, torneo opcional y carga/eliminación de escudo circular; para esta historia se extiende para aceptar un equipo existente en modo edición.
- Si el usuario está en modo edición y no modifica la imagen del escudo existente, se conserva la URL o ruta vigente sin volver a subir el archivo.
- Cuando se selecciona un equipo en el Panel Técnico, esa selección se mantiene en memoria durante la sesión de navegación actual y se reajusta automáticamente al primer equipo disponible si el equipo activo es eliminado.
- Todos los textos de usuario se centralizan en español y el código técnico, pruebas y mensajes de commit se mantienen en inglés según la Constitución del proyecto.
