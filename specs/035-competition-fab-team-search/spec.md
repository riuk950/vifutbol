# Feature Specification: Inscripción de Equipos mediante Menú Flotante con Buscador en Detalles de Competición (HU 18.4)

**Feature Branch**: `develop`  
**Feature Directory**: `specs/035-competition-fab-team-search`  
**Created**: 2026-11-11  
**Status**: Draft  
**Input**: User description: "HU 18.4: Inscripción de Equipos mediante FAB Menu con Buscador en Detalles de Competición" (Notion ID: `4158442e-3f49-8186-9672-fee8a77257ce`)

---

## Clarifications

### Session 2026-11-11

- Q: Cuando la competición ya tiene un fixture generado pero aún sigue en estado editable (no finalizada), ¿qué debe mostrar el botón flotante de acciones? → A: Mantener visible el menú flotante mostrando únicamente la opción "Agregar Equipos" mientras la competición sea editable.
- Q: Al agregar un equipo existente del catálogo global a la competición actual, ¿qué datos deben copiarse en la nueva inscripción? → A: Copiar la identidad del club junto con su plantilla base de jugadores (todos pendientes de validación) y estado inicial "Pendiente de verificación".
- Q: Después de pulsar "Agregar" sobre un equipo dentro del modal de búsqueda, ¿cómo debe comportarse el modal? → A: Mantener el modal abierto, actualizar la tarjeta a "Inscrito" (botón deshabilitado) y conservar el texto de búsqueda actual.
- Q: Si al copiar la plantilla base de un equipo del catálogo, alguno de sus jugadores ya está inscrito en otro club de la misma competición, ¿cómo debe proceder el sistema? → A: Inscribir al equipo copiando solo los jugadores sin conflicto de documento y mostrar un aviso si se omitió algún jugador ya inscrito en otro club del torneo.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Menú Flotante Expandible de Acciones de Competición (Priority: P1) 🎯 MVP

Como Organizador de una competición autenticado en la pantalla de detalles del torneo, quiero presionar un botón flotante de acción expandible (FAB Menu) para desplegar las acciones administrativas disponibles ("Generar Fixture" y "Agregar Equipos"), permitiéndome iniciar de forma rápida tanto la inscripción de participantes como la creación del calendario.

**Why this priority**: Es la puerta de entrada operativa dentro del detalle de la competición para acceder al nuevo flujo de inscripción de equipos sin perder el acceso directo a la generación del fixture.

**Independent Test**: Abrir la pantalla de detalles de una competición editable como Organizador, pulsar el botón flotante principal y verificar que se despliegan las opciones "Generar Fixture" y "Agregar Equipos", y confirmar que el menú permanece oculto para roles no organizadores y para competiciones finalizadas.

**Acceptance Scenarios**:

1. **Given** que el usuario con rol de Organizador visualiza los detalles de una competición editable sin fixture generado, **When** pulsa el botón flotante de acciones, **Then** el menú se expande mostrando exactamente las opciones "Generar Fixture" y "Agregar Equipos".
2. **Given** que el menú flotante está expandido, **When** el organizador selecciona "Generar Fixture", **Then** el menú se contrae e inicia el flujo de confirmación de generación de fixture.
3. **Given** que la competición es editable y ya cuenta con un fixture generado, **When** el organizador pulsa el botón flotante de acciones, **Then** el menú permanece visible mostrando únicamente la opción "Agregar Equipos" (ocultando "Generar Fixture" para evitar regeneraciones destructivas); si la competición está finalizada, el botón flotante no se muestra.
4. **Given** que un usuario con rol diferente al de Organizador (Entrenador, Árbitro, Jugador o Aficionado) visualiza los detalles de una competición, **When** inspecciona la pantalla, **Then** el botón flotante expandible no se renderiza.

---

### User Story 2 - Modal de Selección de Equipos con Buscador en Tiempo Real (Priority: P1) 🎯 MVP

Como Organizador de la competición, quiero que al seleccionar "Agregar Equipos" se abra una vista modal con el catálogo de todos los equipos registrados en el sistema y un campo de búsqueda en tiempo real en la parte superior, para localizar rápidamente los clubes deseados sin importar mayúsculas, minúsculas o tildes.

**Why this priority**: Resuelve directamente la necesidad principal de descubrimiento y filtrado ágil en catálogos numerosos de equipos antes de inscribirlos.

**Independent Test**: Seleccionar "Agregar Equipos" desde el menú flotante, verificar la apertura de la vista modal con la barra de búsqueda superior y el listado completo de equipos únicos registrados, e ingresar consultas con diferentes combinaciones de mayúsculas y acentos comprobando el filtrado inmediato en tiempo real.

**Acceptance Scenarios**:

1. **Given** que el organizador pulsa "Agregar Equipos" en el menú flotante, **When** se despliega la vista modal de selección, **Then** se muestra una barra de búsqueda en la parte superior y el listado alfabético de todos los equipos disponibles en la plataforma.
2. **Given** que la vista modal muestra equipos con nombres acentuados y distintas capitalizaciones (ej. "Atlético del Sur", "Águilas FC"), **When** el organizador escribe "atletico" o "AGUILAS" en el buscador, **Then** la lista se filtra instantáneamente mostrando las coincidencias ignorando mayúsculas, minúsculas y tildes.
3. **Given** que el organizador escribe un texto que no coincide con ningún equipo registrado, **When** la lista filtrada queda vacía, **Then** se presenta un mensaje claro indicando que no se encontraron equipos con ese criterio y una opción rápida para limpiar el filtro.

---

### User Story 3 - Inscripción de Equipos sin Duplicidad y con Estado Inicial Pendiente (Priority: P2)

Como Organizador de la competición, quiero pulsar el botón "Agregar" junto a cualquier equipo disponible en el modal para vincularlo de inmediato al campeonato en estado inicial "Pendiente de verificación", visualizando claramente los equipos ya inscritos con el indicador "Inscrito" y su botón deshabilitado para evitar duplicidades.

**Why this priority**: Completa el flujo transaccional de inscripción garantizando integridad referencial (cero duplicados) y cumplimiento de la regla de negocio sobre verificación de plantilla mínima.

**Independent Test**: Abrir el modal de búsqueda con una competición que ya tiene un equipo inscrito y otro disponible; confirmar que el equipo ya inscrito muestra el indicador "Inscrito" con botón deshabilitado, pulsar "Agregar" en el equipo disponible y validar que pasa a estado "Inscrito", aparece en la pestaña "Equipos" de la competición con estado "Pendiente de verificación" y persiste tras recargar.

**Acceptance Scenarios**:

1. **Given** que un equipo del catálogo aún no forma parte de la competición actual, **When** el organizador pulsa el botón "Agregar" de ese equipo dentro del modal, **Then** el equipo se inscribe en la competición en estado inicial "Pendiente de verificación", la tarjeta en el modal actualiza su estado a "Inscrito" con el botón deshabilitado, y la pestaña "Equipos" de la competición se actualiza automáticamente mostrando el nuevo equipo.
2. **Given** que un equipo ya se encuentra inscrito en la competición actual (por identificador o nombre normalizado), **When** aparece listado o filtrado en la vista modal, **Then** se muestra un indicador visible "Inscrito" y su control de adición permanece deshabilitado para impedir inscripciones duplicadas.
3. **Given** que la competición utiliza formato mixto (grupos y eliminatoria), **When** se inscribe un equipo desde el modal, **Then** el sistema le asigna automáticamente el grupo con menor cantidad de equipos inscritos para mantener el equilibrio de grupos.

---

### Edge Cases

- **Catálogo del sistema sin equipos**: Si aún no existen equipos registrados en la plataforma, la vista modal presenta un estado vacío informativo indicando que no hay clubes disponibles.
- **Pulsaciones múltiples sobre "Agregar"**: Si el organizador pulsa repetidamente el botón "Agregar" de un equipo mientras se procesa la inscripción, la acción queda bloqueada durante la operación para impedir registros duplicados.
- **Cierre del modal durante búsqueda activa**: Si el usuario cierra la vista modal mediante gesto, botón de cierre o retroceso del sistema, la consulta de búsqueda temporal se descarta sin afectar los equipos ya agregados previamente.
- **Competición con fixture generado**: Si el fixture ya fue sorteado pero la competición sigue editable, el organizador no debe ver la opción de generar un nuevo fixture, conservando únicamente "Agregar Equipos" en el menú flotante.
- **Jugadores en conflicto al copiar plantilla base**: Si algún jugador de la plantilla base del club seleccionado ya está registrado (por documento de identidad) en otro equipo de la misma competición, se omite únicamente ese jugador conflictivo al copiar la nómina y se muestra un aviso al organizador indicando cuántos jugadores se omitieron.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: La pantalla de detalles de la competición DEBE presentar un botón flotante expandible (FAB Menu) exclusivo para usuarios con rol de Organizador cuando la competición sea editable.
- **FR-002**: El menú flotante expandible DEBE mostrar las opciones "Generar Fixture" (cuando aún no exista fixture generado) y "Agregar Equipos" (mientras la competición sea editable).
- **FR-003**: Al seleccionar "Agregar Equipos", el sistema DEBE abrir una vista modal con una barra de búsqueda en la parte superior y el listado completo de equipos únicos registrados en la plataforma.
- **FR-004**: El buscador DEBE filtrar el listado de equipos en tiempo real por nombre (o sigla corta) de forma insensible a mayúsculas, minúsculas y acentos/tildes (`case-insensitive` y `diacritic-insensitive`).
- **FR-005**: Cada equipo listado en el modal que ya pertenezca a la competición actual DEBE mostrar un distintivo visible con la etiqueta "Inscrito" y tener su acción de adición deshabilitada para prevenir duplicidades.
- **FR-006**: Al pulsar "Agregar" en un equipo disponible, el sistema DEBE vincularlo a la competición actual en estado inicial `Pendiente de verificación` (conservando su identidad y copiando los jugadores no conflictivos de su plantilla base marcados como pendientes de validación, omitiendo y notificando cualquier documento ya inscrito en otro club del torneo), mantener el modal abierto conservando la búsqueda actual, cambiar la tarjeta a estado "Inscrito" (deshabilitado) y actualizar inmediatamente la pestaña "Equipos" de la competición.
- **FR-007**: En competiciones de formato mixto (grupos + eliminatoria), al inscribir un equipo desde el modal, el sistema DEBE asignarlo por defecto al grupo con menor número de participantes.
- **FR-008**: La acción de agregar equipo DEBE protegerse contra pulsaciones repetidas mientras se completa la operación de guardado y mostrar una confirmación visual al usuario.

---

### Key Entities *(include if feature involves data)*

- **Equipo de Competición (`TournamentTeam`)**: Representa un club inscrito en una competición. Posee identificador único, identificador de torneo, nombre, sigla, emblema visual, colores, nómina de jugadores y estado de elegibilidad (`pendingVerification` al inscribirse).
- **Catálogo Global de Equipos**: Conjunto consolidado de clubes registrados en la plataforma a lo largo de los distintos torneos, deduplicado por nombre normalizado para facilitar su reutilización en nuevas competiciones.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de las opciones del menú flotante ("Generar Fixture" y "Agregar Equipos") se despliegan en menos de 150 milisegundos tras pulsar el botón principal, manteniendo segregación estricta para el rol Organizador.
- **SC-002**: El filtrado de búsqueda en tiempo real actualiza los resultados de forma instantánea (< 50 milisegundos por pulsación de tecla) reconociendo coincidencias sin distinción de mayúsculas ni tildes.
- **SC-003**: Cero inscripciones duplicadas en una misma competición gracias al estado "Inscrito" y al bloqueo de la acción de adición.
- **SC-004**: El 100% de los equipos agregados mediante el modal quedan visibles inmediatamente en la pestaña "Equipos" de la competición con estado inicial "Pendiente de verificación".

---

## Assumptions

- Esta historia reemplaza la simplificación temporal previa del FAB único de generación de fixture en la pantalla de detalle, reintroduciendo el menú flotante expandible (FAB Menu) con las acciones de "Generar Fixture" y "Agregar Equipos".
- El catálogo global de equipos se obtiene del repositorio local de equipos consolidado en la plataforma, deduplicando clubes por nombre normalizado cuando un mismo club ha participado en múltiples torneos.
- Al vincular un club existente desde el catálogo hacia la nueva competición, se crea una instancia de inscripción vinculada al identificador del campeonato actual conservando nombre, sigla, emblema, colores, entrenador y los jugadores no conflictivos de su nómina base (marcados como pendientes de validación), iniciando siempre con estado `pendingVerification` hasta su validación oficial conforme a la regla de 11 jugadores (HU 16.3).
- El modal permanece abierto tras agregar un equipo (actualizando su estado a "Inscrito") para permitir inscribir varios equipos consecutivamente sin necesidad de reabrir el menú flotante cada vez.
