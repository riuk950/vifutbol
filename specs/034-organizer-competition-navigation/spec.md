# Feature Specification: Navegación a Detalles de la Competición desde "Mis Competiciones" en el Panel (HU 18.3)

**Feature Branch**: `develop`  
**Feature Directory**: `specs/034-organizer-competition-navigation`  
**Created**: 2026-11-11  
**Status**: Draft  
**Input**: User description: "HU 18.3: Navegación a Detalles de la Competición desde 'Mis Competiciones' en el Panel" (Notion ID: `4158442e-3f49-81ba-bf7e-c0f320eb8990`)

---

## Clarifications

### Session 2026-11-11

- Q: ¿Cómo debe sincronizarse el torneo seleccionado en el estado global de la aplicación al pulsar su tarjeta desde "Mis Competiciones"? → A: Sincronizar `selectedTournamentId` en el estado global de torneos y navegar inmediatamente a `/competitions/:id`.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Navegación Directa al Detalle de la Competición (Priority: P1) 🎯 MVP

Como Organizador de torneos autenticado en la aplicación, quiero pulsar sobre cualquier tarjeta de campeonato dentro de la sección "Mis Competiciones" del Panel de Organización para abrir de inmediato la pantalla de detalle de dicha competición (`CompetitionDetailScreen`), permitiéndome acceder fluidamente a la gestión de jornadas, clasificaciones, reglas y equipos de ese torneo en particular.

**Why this priority**: Es la funcionalidad nuclear de la historia. Conecta el panel de control administrativo con la vista de gestión granular de cada torneo, permitiendo al usuario operar sus competiciones de forma ágil e intuitiva.

**Independent Test**: Desde el Panel de Organización con al menos un torneo listado en "Mis Competiciones", realizar tap sobre la superficie de la tarjeta del torneo y verificar que la aplicación realiza una transición limpia hacia la ruta de detalles de esa competición específica, mostrando sus metadatos y pestañas operativas.

**Acceptance Scenarios**:

1. **Given** que el organizador visualiza el listado en "Mis Competiciones" de su Panel de Organización, **When** pulsa sobre la superficie de la tarjeta de un torneo específico, **Then** la aplicación navega hacia la pantalla de detalles de dicha competición (`/competitions/:id`), transfiriendo el identificador y cargando su contexto completo.
2. **Given** que el organizador ingresó a la pantalla de detalles de la competición a través de la tarjeta del panel, **When** pulsa el botón de retroceso del AppBar o ejecuta el gesto nativo de regreso, **Then** la aplicación retorna al Panel de Organización preservando la posición de desplazamiento y el estado activo.

---

### User Story 2 - Aislamiento del Menú Contextual de Opciones Secundarias (Priority: P2)

Como Organizador de torneos, quiero que al interactuar con el botón de opciones secundarias (menú de tres puntos) ubicado en la esquina superior derecha de la tarjeta, se desplieguen exclusivamente las acciones de edición de metadatos, cambio de estado y eliminación sin disparar accidentalmente la navegación al detalle del torneo.

**Why this priority**: Evita disparos involuntarios de navegación cuando el usuario desea realizar tareas de mantenimiento puntual (editar metadatos, cambiar estado o eliminar) sobre la tarjeta.

**Independent Test**: Pulsar el icono de tres puntos (`PopupMenuButton`) de la tarjeta de un torneo y verificar que se despliega el menú contextual de opciones sin disparar la navegación hacia la pantalla de detalle del torneo.

**Acceptance Scenarios**:

1. **Given** que el organizador visualiza la tarjeta de un torneo en "Mis Competiciones", **When** presiona el icono de tres puntos de opciones de la tarjeta, **Then** se despliega el menú emergente con las opciones ("Editar metadatos", "Cambiar estado de competición", "Eliminar competición") y la aplicación permanece en el panel sin navegar al detalle.
2. **Given** que el menú emergente de la tarjeta está visible, **When** el usuario selecciona una acción específica (por ejemplo, "Editar metadatos") o cancela el menú pulsando fuera, **Then** se ejecuta la acción correspondiente o se cierra el menú, sin navegar al detalle de la competición.

---

### User Story 3 - Resiliencia ante Pulsaciones Rápidas o Múltiples (Priority: P3)

Como usuario móvil en condiciones reales de uso, quiero que si pulso repetidamente de forma rápida una tarjeta de competición, la aplicación procese únicamente el primer evento de navegación y descarte eventos duplicados para evitar apilar pantallas repetidas en el historial de navegación.

**Why this priority**: Garantiza una experiencia móvil sólida y predecible bajo el principio VII de la Constitución (*Resiliencia y Experiencia Móvil*).

**Independent Test**: Ejecutar dos o más toques rápidos simultáneos sobre la misma tarjeta y validar que la pantalla de detalle se abre exactamente una sola vez en la pila de navegación.

**Acceptance Scenarios**:

1. **Given** que el organizador se encuentra en "Mis Competiciones", **When** realiza pulsaciones dobles o repetidas en un intervalo inferior a 500 milisegundos sobre la tarjeta de un torneo, **Then** la aplicación efectúa una única navegación a la ruta de detalle del torneo seleccionado.

---

### Edge Cases

- **Competición con lista vacía**: Si no hay competiciones creadas, la sección muestra el estado vacío con el botón para crear la primera competición; no existen tarjetas y por ende no se ejecutan eventos de navegación por tarjeta.
- **Transición con torneo recién editado o creado**: Si el organizador edita los metadatos de un torneo desde el menú de la tarjeta y luego pulsa la tarjeta, la pantalla de detalle debe reflejar los valores actualizados.
- **Navegación mientras se refrescan los datos**: Si el catálogo de torneos está en proceso de sincronización o recarga, la tarjeta mantiene su capacidad de respuesta y navega con el identificador inmutable del torneo.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: La superficie completa de la tarjeta de torneo en "Mis Competiciones" DEBE responder al toque táctil (`onTap`) y navegar a la ruta de detalle de la competición (`/competitions/:id`).
- **FR-002**: Al pulsar una tarjeta de torneo, el sistema DEBE sincronizar el identificador del campeonato en el estado global (`selectedTournamentId`) y transferir el parámetro de ruta hacia `/competitions/:id` para que la pantalla de destino y los controladores compartan el mismo contexto activo.
- **FR-003**: El botón de opciones secundarias (menú de tres puntos) DEBE estar aislado del evento de toque de la tarjeta, garantizando que su pulsación abra únicamente las opciones administrativas sin activar la navegación.
- **FR-004**: Al retornar de la pantalla de detalle mediante el botón de regreso (`BackButton`) o el gesto de navegación del sistema operativo, el usuario DEBE regresar al Panel de Organización conservando la visibilidad del panel y la posición de visualización.
- **FR-005**: La navegación DEBE contar con protección contra toques repetidos o rápidos para evitar la apertura duplicada de rutas en la pila de navegación.
- **FR-006**: La interacción táctil sobre la tarjeta DEBE proporcionar retroalimentación visual inmediata (efecto *ink splash* o resaltado sutil) conforme al sistema de diseño KickPulse.

---

### Key Entities *(include if feature involves data)*

- **ChampionshipTournament**: Entidad que representa la competición deportiva. Posee identificador único (`id`), nombre (`name`), categoría (`category`), formato (`format`), estado (`status`) y fechas oficiales.
- **CompetitionDetailScreen**: Pantalla receptora de la navegación que presenta las pestañas de jornadas, clasificación, información/reglas y equipos inscritos asociadas al torneo seleccionado.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de los toques válidos sobre las tarjetas de torneo en "Mis Competiciones" navega exitosamente a la pantalla de detalle correspondiente.
- **SC-002**: Cero disparos accidentales de navegación al interactuar con el menú de opciones secundarias (tres puntos) de la tarjeta.
- **SC-003**: Cero duplicaciones de pantalla en el historial de navegación ante toques repetidos o rápidos sobre la tarjeta.
- **SC-004**: El tiempo de respuesta perceptivo entre el toque en la tarjeta y el inicio de la transición visual de navegación es inmediato (menor a 100 milisegundos).

---

## Assumptions

- La pantalla de destino `CompetitionDetailScreen` y la ruta `/competitions/:id` ya están configuradas en el enrutador de la aplicación y son plenamente funcionales.
- Al acceder como organizador al detalle de un torneo propio, las opciones de gestión del organizador (FAB de acciones y administración) se habilitan conforme a las reglas de control de acceso por rol existentes.
- El componente base `KickPulseCard` cuenta con soporte para el callback de toque `onTap` con efectos táctiles integrados respetando el radio de borde de 16 píxeles.
