# Feature Specification: Creación y Vinculación de Sedes en el Formulario de Nueva Competición (HU 18.1)

**Feature Branch**: `032-competition-inline-venues`  
**Created**: 2026-11-11  
**Status**: Draft  
**Notion Target**: [Épica 18] HU 18.1 (Page ID: `4158442e-3f49-818f-82ef-d7e344f9bba4`)  
**Input**: Petición de usuario: "/speckit-specify de notion HU 18.1 en curso"

---

## Clarifications

### Session 2026-11-11

- Q: ¿Cómo debe presentarse visualmente el subformulario de registro de nueva sede dentro del flujo de creación de la competición? → A: Modal Bottom Sheet interactivo deslizable que emerge desde la parte inferior de la pantalla sobre el formulario del torneo, cerrándose limpiamente al confirmar o cancelar y preservando el scroll, foco y estado del formulario del torneo.
- Q: ¿Una competición debe permitir asociar una única sede principal o múltiples sedes oficiales vinculadas al torneo? → A: Múltiples sedes (`List<String> venueIds`), donde el selector de la competición permite selección múltiple y la sede recién creada se añade automáticamente a la lista de seleccionadas.
- Q: ¿Cómo deben generarse las canchas internas a partir del número de canchas introducido en el formulario rápido de sede? → A: Generación secuencial automática ("Cancha 1", ..., "Cancha N") a partir del número $N \ge 1$, con superficie de césped sintético estándar (`PitchSurfaceType.syntheticTurf`), iluminación habilitada por defecto y estado operativo activo (`VenueOperationalStatus.active`), con posibilidad de ajuste fino posterior desde el módulo de sedes.
- Q: ¿Cómo debe responder el sistema si el organizador intenta registrar una nueva sede con un nombre idéntico al de una sede ya existente en el catálogo? → A: Bloquear la creación de la sede y mostrar un mensaje de error descriptivo en español ("Ya existe una sede con este nombre. Selecciónala de la lista o elige un nombre diferente") para evitar duplicados accidentales en la persistencia local.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Despliegue de Selector y Registro en Línea de Nueva Sede (Priority: P1) 🎯 MVP

Como **organizador de torneos** (`UserRole.organizer`),  
quiero visualizar el catálogo de sedes existentes y disponer de una acción directa "Crear Nueva Sede" dentro del formulario de nueva competición,  
para registrar o asociar una sede deportiva sin abandonar ni reiniciar el flujo de creación del campeonato.

**Why this priority**: Es el núcleo de valor de la HU 18.1. Elimina la fricción de tener que salir a la sección de sedes antes de configurar un torneo, permitiendo un flujo de alta unificado.

**Independent Test**: Acceder a la pantalla de creación de torneo (`TournamentFormScreen`), desplazarse a la sección de asignación de sedes, presionar "Crear Nueva Sede", completar nombre, dirección y canchas, y verificar que la sede se crea y queda seleccionada automáticamente.

**Acceptance Scenarios**:

1. **Given** que el organizador se encuentra en el formulario "Crear Competición",  
   **When** visualiza la sección de asignación de sedes deportivas,  
   **Then** observa un selector con las sedes previamente registradas y un botón interactivo claramente visible "Crear Nueva Sede".

2. **Given** que el organizador presiona "Crear Nueva Sede",  
   **When** se despliega el subformulario con los campos de nombre de la sede, dirección y número de canchas,  
   **And** completa los campos con información válida y confirma,  
   **Then** el sistema da de alta la sede deportiva en el repositorio local,  
   **And** selecciona automáticamente la nueva sede como sede vinculada al campeonato sin reiniciar los campos ya diligenciados del torneo.

---

### User Story 2 - Validación Robusta y Preservación Atómica del Estado del Torneo (Priority: P2)

Como **organizador de torneos**,  
quiero que la validación de la nueva sede sea estricta y atómica,  
para evitar sedes incompletas o corruptas y garantizar que si cometo un error o cancelo la creación de la sede, los datos ya escritos en el torneo (nombre, categoría, reglas, fechas) permanezcan intactos.

**Why this priority**: Asegura la resiliencia y confiabilidad móvil (Principio VII y Mobile Guidelines), impidiendo pérdida accidental de datos ingresados por el usuario.

**Independent Test**: Diligenciar el formulario del torneo hasta la mitad, abrir el subformulario de nueva sede, ingresar datos inválidos (nombre de 1 caracter o 0 canchas), verificar los mensajes de error en español, cancelar la operación y confirmar que el formulario principal del torneo conserva el 100% de sus datos.

**Acceptance Scenarios**:

1. **Given** que el organizador activa el formulario de nueva sede,  
   **When** deja campos obligatorios vacíos o ingresa valores inválidos (ej. menos de 3 caracteres en nombre, menos de 5 en dirección o menos de 1 cancha),  
   **Then** el sistema resalta los mensajes de validación específicos en español y bloquea la confirmación de la sede hasta que se corrijan.

2. **Given** que el organizador ha diligenciado nombre, categoría y reglas de un nuevo torneo,  
   **When** abre y posteriormente cancela o cierra el subformulario de creación de sede,  
   **Then** los datos previamente escritos en el formulario de competición se mantienen íntegros y sin reiniciarse.

---

### User Story 3 - Persistencia Global y Vinculación Oficial en la Competición (Priority: P3)

Como **organizador y administrador del sistema**,  
quiero que la sede creada en el flujo rápido esté disponible tanto en la lista oficial del torneo como en el catálogo general de sedes de la aplicación,  
para poder reutilizarla en partidos futuros, programación de fixtures y nuevas competiciones.

**Why this priority**: Cumple el Principio II de la Constitución (Integridad de Datos y Fuente de Verdad), asegurando que la sede no quede aislada como texto plano sino como entidad formal en el catálogo.

**Independent Test**: Crear una sede dentro del formulario de competición, guardar el torneo, y posteriormente navegar al catálogo general de sedes en la sección correspondiente; verificar que la nueva sede figura con sus canchas activas registradas.

**Acceptance Scenarios**:

1. **Given** que una nueva sede es creada exitosamente desde el formulario de competición,  
   **When** se guarda la competición,  
   **Then** la competición almacena la referencia (`venueIds`) a dicha sede,  
   **And** la sede queda persistida en el repositorio general de sedes (`VenuesRepository`) con estado operativo activo y sus canchas internas habilitadas.

---

### Edge Cases

- **Catálogo de sedes vacío (primer uso)**: Si la aplicación no tiene ninguna sede creada aún, el selector debe mostrar un estado indicando "Sin sedes registradas" e invitar inmediatamente a "Crear Nueva Sede" sin fallos de renderizado.
- **Interrupción o paso a segundo plano (Ciclo de Vida)**: Si la app pasa a segundo plano mientras el usuario completa la nueva sede o el torneo, el borrador del torneo debe conservarse mediante el mecanismo de draft de la aplicación.
- **Pulsaciones repetidas (Doble Tap)**: El botón de confirmar sede debe desactivarse durante el guardado para prevenir la creación de sedes duplicadas con el mismo nombre y ubicación.
- **Conflicto por nombre duplicado de sede**: Si el organizador intenta registrar una sede con un nombre ya existente en el catálogo (coincidencia insensible a mayúsculas/minúsculas y espacios en blanco), el subformulario debe marcar el campo de nombre con error descriptivo impidiendo el guardado para evitar duplicados en el catálogo general.
- **Número de canchas superior a 1**: Si el usuario especifica $N$ canchas (ej. 3), el sistema debe generar de forma predeterminada las canchas correspondientes con identificadores únicos y nombres secuenciales ("Cancha 1", "Cancha 2", etc.).
- **Modo edición vs creación**: Si el formulario se abre para editar una competición existente, debe permitir vincular sedes adicionales o crear una nueva con el mismo flujo no destructivo.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El formulario de competición DEBE incluir una sección dedicada a la gestión y asignación de sedes deportivas oficiales.
- **FR-002**: El selector de sedes DEBE listar todas las sedes deportivas activas registradas en el catálogo local (`VenuesRepository`).
- **FR-003**: El formulario DEBE proporcionar un botón interactivo "Crear Nueva Sede" visible tanto si existen sedes registradas como si el catálogo está vacío.
- **FR-004**: Al presionar "Crear Nueva Sede", el sistema DEBE desplegar un subformulario interactivo presentado como un Modal Bottom Sheet interactivo deslizable que emerge desde la parte inferior de la pantalla sobre el formulario del torneo, cerrándose limpiamente al confirmar o cancelar y preservando el scroll, foco y estado del formulario del torneo.
- **FR-005**: El subformulario de sede DEBE solicitar obligatoriamente: Nombre de la sede (mínimo 3 caracteres), Dirección (mínimo 5 caracteres) y Número de canchas (número entero $\ge 1$).
- **FR-006**: El sistema DEBE validar los campos de la sede en tiempo real y mostrar mensajes de error descriptivos en español antes de permitir su confirmación.
- **FR-007**: Al confirmar la creación de la sede con datos válidos, el sistema DEBE persistirla inmediatamente en `VenuesRepository` y seleccionarla automáticamente como la sede asignada para la competición.
- **FR-008**: La creación o cancelación de la nueva sede NO DEBE alterar, limpiar ni reiniciar los campos ya diligenciados en el formulario de la competición (*flujo no destructivo*).
- **FR-009**: La entidad de competición (`ChampionshipTournament`) DEBE soportar la vinculación de múltiples sedes oficiales (`List<String> venueIds`), donde el selector de la competición permite selección múltiple y la sede recién creada se añade automáticamente a la lista de seleccionadas.
- **FR-010**: Las canchas internas creadas a través del flujo rápido de sede DEBEN inicializarse automáticamente como canchas secuenciales ("Cancha 1", ..., "Cancha N") a partir del número $N \ge 1$ ingresado, con superficie de césped sintético estándar (`PitchSurfaceType.syntheticTurf`), iluminación habilitada por defecto y estado operativo activo (`VenueOperationalStatus.active`), con posibilidad de ajuste fino posterior desde el módulo de sedes.
- **FR-011**: Todos los textos visibles, etiquetas, botones y mensajes de error DEBEN estar en español y centralizados en el sistema de localización (`l10n`), cumpliendo el Principio VI de la Constitución.
- **FR-012**: La funcionalidad DEBE ser accesible exclusivamente para usuarios con rol de Organizador (`UserRole.organizer`), respetando el Principio V de la Constitución.
- **FR-013**: El sistema DEBE validar la unicidad del nombre de la sede frente al catálogo existente (comparación insensible a mayúsculas/minúsculas y espacios en blanco); si ya existe una sede con el mismo nombre, DEBE bloquear la creación y presentar el mensaje descriptivo correspondiente indicando al usuario que puede seleccionarla de la lista existente o usar otro nombre.

---

### Key Entities *(include if feature involves data)*

- **`SportsVenue`**: Complejo deportivo que agrupa una o más canchas, con identificador único, nombre, dirección, coordenadas y estado operativo.
- **`VenuePitch`**: Cancha deportiva individual perteneciente a una sede, con nombre, tipo de superficie, iluminación y estado activo.
- **`ChampionshipTournament`**: Entidad raíz del campeonato que almacena las reglas, fechas, formato y la referencia a las sedes asignadas (`venueIds`).
- **`TournamentDraft`**: Objeto de valor temporal que preserva los datos del formulario de torneo ante interrupciones móviles o pasos a segundo plano.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un organizador puede crear una nueva sede deportiva y vincularla a su competición en menos de 45 segundos sin salir del formulario.
- **SC-002**: El 100% de los datos del torneo previamente ingresados se conservan intactos tras abrir, cancelar o completar la creación de una sede.
- **SC-003**: El 100% de las nuevas sedes creadas en línea quedan disponibles inmediatamente para selección en el torneo y persistidas en el catálogo general.
- **SC-004**: Los errores de validación de sede se señalan con mensajes contextuales claros en el 100% de los casos de campos inválidos o vacíos.

---

## Assumptions

- Se asume que en el flujo rápido de creación de sede no se requiere selector GPS interactivo obligatorio; se pueden asignar coordenadas geográficas predeterminadas (o las coordenadas del centro urbano configurado) y permitir su posterior ajuste fino desde el módulo de sedes.
- Se asume que el rol activo durante la creación de torneo es Organizador (`UserRole.organizer`).
- Se asume persistencia offline inmediata mediante el repositorio local de sedes existente (`LocalVenuesRepository` / `Hive`).
