# Feature Specification: Carga y Selección de Equipos del Catálogo Global en Competición (Inscripción sin Creación)

**Feature Branch**: `043-competition-fab-catalog-enrollment`  
**Created**: 2026-11-17  
**Status**: Draft  
**Input**: Notion HU 18.5 — `[Épica 18] HU 18.5: Carga y Selección de Equipos del Catálogo Global en el FAB Menu de Competición (Inscripción sin Creación)`

## Clarifications

### Session 2026-11-17

- Q: ¿Se debe permitir inscribir cualquier club del catálogo global en el torneo activo sin importar su categoría previa, o se debe restringir la inscripción por categoría? → A: Permitir inscribir cualquier club del catálogo global en el torneo; mostrar su categoría (o `"Categoría libre"` si aún no tiene torneo asignado) como metadato informativo.
- Q: ¿Cómo debe mostrarse el entrenador responsable en cada tarjeta de club dentro del modal `"Agregar Equipos"`? → A: Mostrar únicamente el nombre del entrenador si está disponible y ocultar por completo el dato de entrenador cuando no haya nombre resuelto.
- Q: ¿Qué debe ocurrir con el modal `"Agregar Equipos"` inmediatamente después de que el organizador inscribe un club en el torneo? → A: Mantener el modal abierto para permitir inscribir múltiples clubes seguidos; actualizar la fila del club a `"Inscrito"` (botón deshabilitado), mostrar confirmación en línea y refrescar reactivamente la pestaña `"Equipos"`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Carga del Catálogo Global e Inscripción de Equipos Preexistentes (Priority: P1)

Como organizador de una competición, quiero que al accionar `"Agregar Equipos"` desde el menú flotante de acciones del torneo se consulte y presente el catálogo global de todos los clubes registrados en la plataforma (tanto sincronizados desde la nube como disponibles localmente), permitiéndome inscribir clubes existentes en estado `"Pendiente de verificación"` sin duplicarlos, para incorporar ágilmente cualquier club del ecosistema al campeonato manteniendo intacta su plantilla de jugadores.

**Why this priority**: Es el flujo principal para poblar de equipos una competición respetando que los clubes provienen del catálogo general registrado por los entrenadores.

**Independent Test**: Abrir el detalle de un torneo editable como organizador, desplegar `"Agregar Equipos"` desde el menú flotante, verificar que aparecen todos los clubes de la plataforma (incluso aquellos sin torneo previo o participantes en otros torneos) con su escudo, nombre, categoría, cantidad de jugadores y entrenador responsable, e inscribir un club disponible comprobando que pasa a `"Inscrito"` en el modal y aparece inmediatamente en la pestaña `"Equipos"` con estado `"Pendiente de verificación"`.

**Acceptance Scenarios**:

1. **Given** el organizador se encuentra en el detalle de un torneo editable, **When** abre el menú de acciones flotante y selecciona `"Agregar Equipos"`, **Then** se despliega la vista modal que consulta y lista todos los clubes registrados en la plataforma (sin restringirlos a un torneo previo), mostrando para cada club su escudo o identificador visual, nombre oficial, categoría, cantidad de jugadores y entrenador responsable.
2. **Given** un club del catálogo global aún no pertenece al campeonato actual, **When** el organizador acciona `"Inscribir"` sobre dicho club, **Then** el sistema vincula el club a la competición activa conservando su plantilla de futbolistas, le asigna el estado inicial `"Pendiente de verificación"`, actualiza su indicador en el modal a `"Inscrito"` (con botón deshabilitado) y refleja inmediatamente el nuevo participante en la pestaña `"Equipos"` del torneo.
3. **Given** un club ya se encuentra inscrito en el campeonato actual, **When** se visualiza dentro del catálogo en el modal `"Agregar Equipos"`, **Then** muestra claramente el distintivo `"Inscrito"` y su acción de inscripción permanece deshabilitada para impedir inscripciones duplicadas.

---

### User Story 2 - Restricción Estricta de Creación de Clubes para el Organizador (Priority: P1)

Como organizador de una competición, quiero que el flujo de `"Agregar Equipos"` opere exclusivamente como un buscador y selector de clubes preexistentes sin mostrar botones ni formularios de creación de equipos, incluyendo un estado vacío orientativo cuando no existan clubes en la plataforma, para cumplir estrictamente la matriz de gobernanza deportiva donde solo los entrenadores crean clubes.

**Why this priority**: Garantiza la separación de funciones de gobernanza (HU 16.2) evitando que el organizador cree clubes huérfanos sin director técnico desde el flujo de competición.

**Independent Test**: Inspeccionar el modal `"Agregar Equipos"` tanto con catálogo poblado como con catálogo vacío y tras búsquedas sin coincidencias, verificando que en ningún estado se muestre acción o formulario alguno para crear o registrar un club nuevo.

**Acceptance Scenarios**:

1. **Given** el organizador visualiza el modal `"Agregar Equipos"` en cualquier estado (cargando, con resultados, sin coincidencias de búsqueda o con catálogo vacío), **When** inspecciona las acciones disponibles, **Then** no existe ningún botón, enlace ni formulario de `"Crear Nuevo Equipo"` o `"Registrar Club"`.
2. **Given** aún no existen clubes registrados por entrenadores en la plataforma, **When** el organizador abre el modal `"Agregar Equipos"`, **Then** se muestra el estado vacío informativo: `"No hay equipos registrados en la plataforma. Los entrenadores deben registrar sus clubes antes de poder inscribirlos en el campeonato."` sin ofrecer opción de creación manual.

---

### User Story 3 - Búsqueda Reactiva Normalizada en el Catálogo Global (Priority: P2)

Como organizador de una competición, quiero filtrar en tiempo real el catálogo global de clubes por nombre o código del club ignorando mayúsculas, minúsculas y acentos, para localizar rápidamente al equipo que deseo inscribir dentro del universo de clubes de la plataforma.

**Why this priority**: A medida que el catálogo global crece con clubes de múltiples entrenadores y torneos, la búsqueda instantánea insensible a acentos y mayúsculas evita desplazamientos extensos.

**Independent Test**: Ingresar términos con y sin tildes y en distintas combinaciones de mayúsculas/minúsculas o por código de club en el buscador del modal y comprobar que la lista filtra en tiempo real los clubes coincidentes y muestra un estado vacío de búsqueda cuando no hay resultados.

**Acceptance Scenarios**:

1. **Given** el modal `"Agregar Equipos"` presenta el catálogo global de clubes, **When** el organizador escribe en el campo de búsqueda por nombre oficial o código/sigla del club, **Then** la lista se filtra en tiempo real ignorando diferencias de mayúsculas/minúsculas y acentos diacríticos.
2. **Given** el organizador ingresó un texto de búsqueda que no coincide con ningún club del catálogo global, **When** se actualiza la vista de resultados, **Then** se muestra un mensaje informativo indicando que no se encontraron clubes para esa búsqueda, manteniendo disponible la limpieza del filtro y sin mostrar botones de creación de equipos.

---

### Edge Cases

- **Operación sin conexión a internet**: Si el dispositivo no cuenta con conexión al abrir `"Agregar Equipos"`, el sistema debe presentar el catálogo global disponible en el almacenamiento local informando de forma no intrusiva si la actualización remota no pudo completarse, y permitir vincular clubes disponibles en cola de sincronización local.
- **Intento de doble clic o inscripción concurrente**: Mientras se procesa la inscripción de un club o una vez inscrito, la acción sobre ese club debe bloquearse inmediatamente para impedir registros duplicados en el mismo torneo.
- **Torneo en estado finalizado o bloqueado para edición**: Si la competición no admite cambios de participantes, la opción `"Agregar Equipos"` no debe permitir nuevas inscripciones.
- **Club sin nombre de entrenador o sin categoría detallada**: Si un registro del catálogo no cuenta con nombre de entrenador resuelto, dicho metadato se omite limpiamente de la tarjeta (sin exponer identificadores técnicos ni etiquetas vacías); si carece de categoría de torneo previa, muestra `"Categoría libre"`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Al seleccionar `"Agregar Equipos"` desde el menú flotante de una competición editable, el sistema MUST consultar y cargar el catálogo global completo de clubes registrados en la plataforma (combinando la fuente en la nube actualizada con el respaldo local disponible), permitiendo inscribir cualquier club del catálogo sin excluir ni restringir clubes por su categoría previa o por no haber participado aún en otros torneos.
- **FR-002**: Para cada club listado en el modal `"Agregar Equipos"`, el sistema MUST mostrar su escudo (o insignia/iniciales por defecto), nombre oficial, categoría (mostrando `"Categoría libre"` cuando aún no tenga torneo previo asignado), cantidad actual de jugadores en su plantilla y, únicamente cuando exista un nombre de entrenador resuelto, el nombre del entrenador responsable (ocultando el dato si no hay nombre disponible).
- **FR-003**: El modal `"Agregar Equipos"` MUST prohibir y omitir cualquier botón, enlace o formulario para crear o registrar nuevos equipos, operando exclusivamente como buscador e inscriptor de clubes preexistentes en cumplimiento de la matriz de permisos por rol.
- **FR-004**: El modal MUST incluir un campo de búsqueda reactivo que filtre en tiempo real el catálogo global por nombre oficial o código/sigla del club, aplicando normalización insensible a mayúsculas, minúsculas y acentos (tildes/diéresis).
- **FR-005**: Cada elemento del catálogo en el modal MUST reflejar claramente su estado frente al torneo activo:
  - Si ya pertenece al torneo: mostrar el distintivo `"Inscrito"` y mantener deshabilitada la acción de inscripción.
  - Si no pertenece al torneo: mostrar activa la acción `"Inscribir"` (o `"Agregar al Torneo"`).
- **FR-006**: Al confirmar la acción `"Inscribir"` sobre un club disponible, el sistema MUST vincular el club al torneo activo de forma idempotente conservando su plantilla de jugadores y asignándole el estado reglamentario inicial `"Pendiente de verificación"`.
- **FR-007**: Tras vincular un club al torneo, el sistema MUST mantener abierto el modal `"Agregar Equipos"`, mostrar confirmación en línea, actualizar de inmediato el estado del club dentro del modal a `"Inscrito"` (con botón deshabilitado) y refrescar reactivamente el listado de participantes en la pestaña `"Equipos"` de la competición sin requerir recarga manual de pantalla.
- **FR-008**: Cuando el catálogo global de la plataforma no contenga ningún club registrado, el modal MUST presentar el mensaje de estado vacío: `"No hay equipos registrados en la plataforma. Los entrenadores deben registrar sus clubes antes de poder inscribirlos en el campeonato."` sin ofrecer acciones de creación de clubes.
- **FR-009**: Todos los textos visibles, estados de carga, error, búsqueda sin resultados y etiquetas del modal MUST presentarse en español y respetar los estándares de accesibilidad y ergonomía móvil del proyecto.

### Key Entities

- **Club del Catálogo Global (`Team`)**: Entidad deportiva creada por un entrenador en la plataforma, con identificador único, nombre oficial, código/sigla, escudo/insignia, categoría, entrenador responsable y plantilla de futbolistas asociada.
- **Inscripción de Equipo en Competición (`TournamentTeamEnrollment`)**: Vínculo único entre un club del catálogo global y una competición específica, que registra su estado reglamentario dentro del torneo (iniciando en `"Pendiente de verificación"`) sin duplicar la entidad base del club ni perder su nómina de jugadores.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de los clubes registrados en el catálogo global de la plataforma es visible y buscable desde el modal `"Agregar Equipos"` de cualquier torneo editable, independientemente de si tienen o no torneos previos asignados.
- **SC-002**: Cero (0) botones, accesos o formularios de creación de nuevos equipos son expuestos al rol organizador dentro del flujo `"Agregar Equipos"`.
- **SC-003**: El filtrado por búsqueda en el modal actualiza los resultados en menos de 100 milisegundos tras cada entrada de texto, encontrando coincidencias exactas o parciales sin importar el uso de tildes o mayúsculas.
- **SC-004**: El 100% de los clubes inscritos desde el modal queda vinculado en estado `"Pendiente de verificación"` con su plantilla preservada y se refleja instantáneamente en la pestaña `"Equipos"` del torneo, con cero inscripciones duplicadas para un mismo par club-torneo.

## Assumptions

- El rol `coach` es el único autorizado para dar de alta nuevos clubes en el directorio general de equipos (conforme a la HU 16.2).
- La verificación posterior para cambiar el estado de `"Pendiente de verificación"` a `"Aprobado"` o `"Rechazado"` continúa realizándose desde la pestaña `"Equipos"` de la competición una vez validada la cuota mínima reglamentaria de jugadores (conforme a la HU 16.3).
