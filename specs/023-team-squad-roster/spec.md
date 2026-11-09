# Feature Specification: Pestaña de Plantilla y Jugadores del Equipo (HU 14.3)

**Feature Branch**: `023-team-squad-roster`  
**Created**: 2026-11-09  
**Status**: Draft  
**Input**: User description: "de Notion HU 14.3 en curso - [Épica 14] HU 14.3: Pestaña de Plantilla y Jugadores del Equipo"

---

## Clarifications

### Session 2026-11-09

- Q: ¿Cuál debe ser el alcance operativo de la pestaña "Plantilla" dentro de `TeamDetailScreen` (`/teams/:id`) respecto a la consulta frente a la inscripción administrativa de jugadores? (FR-001) → A: Vista de consulta deportiva de solo lectura (nómina, organización por posición y ficha de rendimiento del jugador), manteniendo la gestión administrativa de inscripciones en `/tournaments/teams/detail`.
- Q: ¿Cómo debe determinarse el estatus de habilitación ("Habilitado" vs "Suspendido") de cada jugador en la lista y resolverse su ficha al tocar la tarjeta? (FR-005, FR-006) → A: Usar `player.isEligible` de `RegisteredPlayer` para el badge (**Habilitado** en verde / **Suspendido** en rojo) y abrir `showPlayerPerformanceProfileSheet` con el perfil de rendimiento del jugador (permitiendo además cambiar entre compañeros de plantilla dentro del modal).
- Q: ¿Cómo deben presentarse las posiciones tácticas (*Porteros*, *Defensas*, *Centrocampistas*, *Delanteros*) en la pestaña "Plantilla"? (FR-003, FR-004) → A: Agrupar la lista verticalmente en 4 bloques fijos por posición con encabezados (*Porteros*, *Defensas*, *Centrocampistas*, *Delanteros*) sin barra de chips de filtrado, manteniendo el orden ascendente por dorsal dentro de cada bloque.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Despliegue de la Nómina Oficial Completa del Equipo (Priority: P1) 🎯 MVP

Como aficionado, entrenador o reclutador en ViFutbol, quiero abrir la pestaña "Plantilla" dentro de la pantalla de detalle de un equipo (`/teams/:id`) y consultar la nómina oficial completa de los jugadores registrados en el club ordenados ascendentemente por su número de dorsal dentro de su línea táctica, para conocer los dorsales, nombres completos, posiciones tácticas y estado de habilitación de cada integrante del plantel.

**Why this priority**: Sustituye la vista de preparación en la tercera pestaña ("Plantilla") de `TeamDetailScreen` con la información nuclear de la historia de usuario: el listado completo de futbolistas inscritos en el equipo con sus datos oficiales y estatus de elegibilidad.

**Independent Test**: Ingresar al detalle de un equipo (`/teams/:id`), pulsar la pestaña "Plantilla", verificar que se listan todos los jugadores registrados en `team.players` ordenados de menor a mayor número de camiseta (`shirtNumber`) dentro de cada bloque de posición, y comprobar que cada fila muestra el dorsal con tipografía tabular, el nombre completo del jugador, su posición táctica en español (*Portero*, *Defensa*, *Centrocampista*, *Delantero*) y su indicador semántico de habilitación (*Habilitado* en verde o *Suspendido* en rojo).

**Acceptance Scenarios**:

1. **Given** que el usuario se encuentra en la pantalla de detalle de un equipo (`/teams/:id`) con jugadores inscritos, **When** pulsa la pestaña "Plantilla", **Then** se despliega la lista completa de jugadores registrados en el equipo ordenados de forma ascendente según su número de camiseta (`shirtNumber`) dentro de su bloque táctico.
2. **Given** que se visualiza la lista de jugadores en la pestaña "Plantilla", **When** el usuario inspecciona cada fila de jugador, **Then** observa la insignia del dorsal con tipografía tabular (`tabular-nums`), el nombre completo del jugador, el distintivo de su posición táctica en español (*Portero*, *Defensa*, *Centrocampista* o *Delantero*) y el distintivo de su estatus de elegibilidad.
3. **Given** un jugador cuyo estado de elegibilidad es activo (`isEligible == true`), **When** se presenta en la lista de la plantilla, **Then** exhibe un distintivo semántico en color verde con la etiqueta **"Habilitado"**.
4. **Given** un jugador que no se encuentra habilitado o está sancionado (`isEligible == false`), **When** se presenta en la lista de la plantilla, **Then** exhibe un distintivo semántico en color rojo con la etiqueta **"Suspendido"**.

---

### User Story 2 - Agrupación Vertical de la Plantilla en 4 Bloques por Posición Táctica (Priority: P2)

Como aficionado, analista o entrenador consultando la pestaña "Plantilla" de un equipo, quiero visualizar la nómina estructurada verticalmente en 4 secciones fijas por línea táctica (*Porteros*, *Defensas*, *Centrocampistas* y *Delanteros*) con sus respectivos encabezados y conteo de efectivos, para identificar de un vistazo cómo está conformada cada línea del campo sin necesidad de activar filtros manuales.

**Why this priority**: Permite escanear visualmente toda la plantilla de hasta 18 jugadores de forma continua y organizada por demarcación en el terreno de juego, siguiendo el mismo patrón de bloques verticales con encabezados de la pestaña "Partidos" (HU 14.2).

**Independent Test**: En la pestaña "Plantilla" de un equipo con jugadores en distintas demarcaciones, verificar que la lista se estructura verticalmente en los 4 bloques fijos (*Porteros*, *Defensas*, *Centrocampistas*, *Delanteros*), cada uno con su encabezado de sección, y que dentro de cada bloque los jugadores correspondientes aparecen ordenados por dorsal ascendente.

**Acceptance Scenarios**:

1. **Given** que el usuario ingresa a la pestaña "Plantilla" de un equipo con jugadores registrados, **When** la vista se renderiza, **Then** la nómina se presenta agrupada verticalmente en 4 bloques en orden táctico de atrás hacia adelante: **Porteros**, **Defensas**, **Centrocampistas** y **Delanteros**, cada uno con su encabezado de sección.
2. **Given** múltiples jugadores inscritos en una misma línea táctica (por ejemplo, varios *Defensas*), **When** se renderiza dicho bloque, **Then** los jugadores de esa línea se listan ordenados de menor a mayor número de camiseta (`shirtNumber`).
3. **Given** que un equipo tiene jugadores inscritos pero no cuenta con ningún jugador en una línea táctica específica (por ejemplo, sin *Delanteros*), **When** el usuario recorre la pestaña "Plantilla", **Then** el bloque de esa posición muestra un mensaje informativo contextual indicando que no hay jugadores registrados en esa línea sin ocultar los demás bloques.

---

### User Story 3 - Consulta de Perfil del Jugador y Estados Vacíos Informativos (Priority: P3)

Como usuario explorando la pestaña "Plantilla" de un equipo, quiero poder tocar cualquier jugador de la lista para consultar su ficha/perfil de rendimiento individual y visualizar estados vacíos claros cuando el equipo aún no tenga jugadores inscritos, para profundizar en las estadísticas del futbolista o comprender por qué no se muestran registros.

**Why this priority**: Conecta la plantilla del equipo con el perfil individual de rendimiento del jugador ya existente en la plataforma y garantiza resiliencia visual ante equipos en proceso de inscripción.

**Independent Test**: En la pestaña "Plantilla", tocar un jugador de la lista y comprobar que se abre la hoja modal de perfil de rendimiento del jugador (`PlayerPerformanceProfileCard`); adicionalmente, probar con un equipo sin jugadores inscritos para verificar el estado vacío general.

**Acceptance Scenarios**:

1. **Given** que el usuario visualiza la lista de jugadores en la pestaña "Plantilla", **When** toca la tarjeta o fila de un jugador, **Then** se abre la hoja modal con el perfil de rendimiento individual del jugador mostrando sus datos de camiseta, posición, estado disciplinario y métricas del torneo, permitiendo alternar entre los integrantes de la plantilla.
2. **Given** que un equipo aún no tiene ningún jugador registrado en su nómina (`team.players` vacío), **When** el usuario abre la pestaña "Plantilla", **Then** se muestra un estado vacío informativo general indicando que el equipo todavía no tiene jugadores inscritos en su plantilla.

---

### Edge Cases

- **Ordenamiento determinista por dorsal dentro de cada bloque táctico**: Aunque `TournamentTeam` ordena sus jugadores al construirse, cada bloque de posición (*Porteros*, *Defensas*, *Centrocampistas*, *Delanteros*) DEBE garantizar siempre el orden ascendente por `shirtNumber` (y por `fullName` alfabético en caso de empate excepcional de dorsal en datos heredados).
- **Accesibilidad sin dependencia exclusiva del color**: El estado de elegibilidad del jugador (*Habilitado* en verde / *Suspendido* en rojo) y la posición táctica DEBEN incluir siempre su etiqueta textual explícita en español y semántica accesible para lectores de pantalla, además de un área táctil mínima de `48x48 dp` por tarjeta de jugador.
- **Nombres de jugadores extensos en pantallas compactas (`320x640 px`) y escalado de texto al `130%`**: Los nombres largos de futbolistas y la combinación de dorsal + nombre + badges de posición y elegibilidad DEBEN adaptarse mediante ajuste flexible o truncamiento limpio con elipsis sin producir errores de desbordamiento (`RenderFlex overflow`).
- **Conservación de estado al cambiar de pestaña y modo Offline**: La lectura de la plantilla se realiza directamente desde el catálogo local (`team.players`), funcionando de manera 100% offline y preservando la posición de desplazamiento mediante `PageStorageKey`.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: La pestaña "Plantilla" dentro de `TeamDetailScreen` (`/teams/:id`) DEBE reemplazar la vista de preparación actual por la vista oficial de consulta deportiva de solo lectura de la plantilla del equipo (`TeamSquadTabView`), manteniendo la gestión administrativa de inscripciones y cupos intacta en `/tournaments/teams/detail` (`TeamRosterDetailScreen`).
- **FR-002**: El sistema DEBE obtener la nómina directamente de los jugadores inscritos en el equipo (`team.players` con modelo inmutable `RegisteredPlayer`), ordenados de forma ascendente según su número de camiseta (`shirtNumber`).
- **FR-003**: Cuando el equipo posea al menos un jugador inscrito, la vista DEBE estructurarse en un listado vertical continuo agrupado en 4 bloques fijos por posición táctica en el siguiente orden: **Porteros** (`goalkeeper`), **Defensas** (`defender`), **Centrocampistas** (`midfielder`) y **Delanteros** (`forward`), cada uno precedido por su encabezado de sección (sin barra de chips de filtrado).
- **FR-004**: Dentro de cada uno de los 4 bloques de posición táctica, los jugadores pertenecientes a dicha demarcación DEBEN presentarse ordenados ascendentemente por su número de camiseta (`shirtNumber`).
- **FR-005**: Cada fila o tarjeta de jugador en la lista DEBE exhibir de forma clara y estructurada:
  - **Dorsal**: Insignia con el número de camiseta (`#shirtNumber`) renderizada con tipografía numérica tabular (`tabular-nums`).
  - **Nombre Completo**: Nombre y apellidos del jugador (`fullName`).
  - **Posición Táctica**: Distintivo (`KickPulseBadge`) en español (*Portero*, *Defensa*, *Centrocampista*, *Delantero*).
  - **Estatus de Elegibilidad**: Distintivo semántico (`KickPulseBadge`) indicando **"Habilitado"** en verde (`KickPulseBadgeVariant.success`) cuando `isEligible == true`, o **"Suspendido"** en rojo (`KickPulseBadgeVariant.live`) cuando `isEligible == false`.
- **FR-006**: Cada tarjeta de jugador DEBE contar con un área táctil mínima de `48x48 dp` y semántica accesible que agrupe su dorsal, nombre completo, posición táctica y estatus de habilitación, y al ser pulsada DEBE abrir la hoja modal de perfil de rendimiento del jugador (`showPlayerPerformanceProfileSheet`) resolviendo sus métricas del torneo (o perfil base sincronizado con `isSuspended: !player.isEligible`) y habilitando el selector rápido entre los integrantes de la plantilla.
- **FR-007**: Si el equipo no cuenta con ningún jugador registrado (`team.players.isEmpty`), la pestaña "Plantilla" DEBE presentar un estado vacío general mediante `KickPulseStateView`. Si el equipo tiene jugadores inscritos pero uno de los 4 bloques de posición táctica carece de efectivos, dicho bloque DEBE mostrar un mensaje informativo vacío contextual sin ocultar los demás bloques.
- **FR-008**: Todos los textos visibles de la interfaz (encabezados de los 4 bloques de posición, etiquetas de posiciones tácticas, estados *Habilitado* / *Suspendido* y mensajes de estado vacío) DEBEN estar centralizados en español dentro de `lib/l10n/app_es.arb`, sin textos quemados en los widgets.
- **FR-009**: La vista DEBE preservar su posición de desplazamiento mediante `PageStorageKey` y renderizarse con cero errores de desbordamiento (`RenderFlex overflow`) en viewports compactos (`320x640 px`) con factor de escala tipográfica del `130%`.

---

### Key Entities *(include if feature involves data)*

- **TournamentTeam**: Entidad raíz del equipo inscrito que contiene la lista inmutable de jugadores registrados (`players`) y los metadatos del club (`id`, `tournamentId`, `name`, `shortCode`).
- **RegisteredPlayer**: Entidad inmutable de dominio que representa a cada futbolista inscrito en la plantilla (`id`, `fullName`, `documentId`, `shirtNumber`, `position`, `isEligible`).
- **PlayerPosition**: Enumeración de dominio para las posiciones tácticas en el campo (`goalkeeper`, `defender`, `midfielder`, `forward`).
- **PlayerPerformanceProfile**: Proyección de perfil de rendimiento individual del jugador (goles, asistencias, tarjetas, partidos jugados y estado disciplinario) mostrada al seleccionar un integrante de la plantilla.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Los usuarios pueden abrir la pestaña "Plantilla" en el detalle de un equipo y visualizar la nómina completa de hasta 18 jugadores agrupada en sus 4 líneas tácticas en menos de 100 ms.
- **SC-002**: El 100% de los jugadores inscritos en `team.players` se presentan dentro de su bloque de posición táctica correspondiente (*Porteros*, *Defensas*, *Centrocampistas*, *Delanteros*), ordenados ascendentemente por su número de dorsal (`shirtNumber`), mostrando su posición en español y su estatus exacto de habilitación (*Habilitado* vs *Suspendido*).
- **SC-003**: El 100% de los equipos sin jugadores inscritos muestran el estado vacío general y los bloques de posición sin efectivos muestran su estado vacío contextual sin errores visuales.
- **SC-004**: Cero errores de desbordamiento visual (`RenderFlex overflow`) en resoluciones móviles compactas (`320x640 px`) con factor de escala de texto al `130%`.

---

## Assumptions

- **A-001**: Los datos de los jugadores inscritos provienen directamente de `team.players` en el catálogo local de equipos y las estadísticas detalladas al abrir la ficha del jugador se resuelven mediante el catálogo local de rendimiento (`PlayerPerformanceProfile`), garantizando disponibilidad inmediata offline.
- **A-002**: El indicador `isEligible` de `RegisteredPlayer` determina si el jugador se muestra como **Habilitado** (`true`, variante verde) o **Suspendido** (`false`, variante roja), en coherencia con el estado disciplinario de su perfil de rendimiento (`isSuspended: !player.isEligible`).
- **A-003**: Con la implementación de la pestaña "Plantilla" (HU 14.3), las 3 pestañas de `TeamDetailScreen` ("Información", "Partidos" y "Plantilla") quedan 100% operativas, cerrando el alcance funcional de la Épica 14 mientras la ruta administrativa `/tournaments/teams/detail` permanece intacta para operaciones de inscripción.
