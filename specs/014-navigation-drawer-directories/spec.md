# Feature Specification: Navigation Drawer y Páginas de Directorio con Buscador (Competiciones, Equipos y Jugadores)

**Feature Branch**: `014-navigation-drawer-directories`

**Created**: 2026-11-05

**Status**: Draft

**Input**: User description: "[Épica 10] HU 10.2: Incorporación de Navigation Drawer y Páginas de Directorio con Buscador (Competiciones, Equipos y Jugadores)"

## Clarifications

### Session 2026-11-05
- Q: ¿Las nuevas páginas de directorio deben ser de solo lectura o incluir accesos rápidos para crear entidades según los permisos del rol? → A: Acciones contextuales por rol: Si el usuario tiene permisos (ej. Organizador), mostrar botones de acción para crear competición, equipo o jugador directamente desde su respectivo directorio.
- Q: ¿Los directorios de Equipos y Jugadores deben mostrar los registros globales de todas las competiciones o limitarse al torneo activo? → A: Catálogo global con filtro de torneo: Muestra todos los equipos y jugadores registrados en la plataforma e incluye una fila de chips horizontal superior para filtrar por competición específica ("Todos" + torneos registrados).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Apertura del Navigation Drawer Universal para Todos los Roles (Priority: P1) 🎯 MVP

Como usuario autenticado en cualquiera de los 5 roles del sistema (`Organizador`, `Árbitro`, `Entrenador / Capitán`, `Jugador`, `Aficionado`), quiero abrir un menú lateral desplegable (`NavigationDrawer`) desde el botón de menú hamburguesa en la barra superior de `AppShellScreen`, para acceder de forma centralizada a los directorios de consulta de la aplicación independientemente de la pestaña activa en la barra de navegación inferior.

**Why this priority**: Es el punto de entrada esencial de la funcionalidad. Sin el menú lateral accesible universalmente, los usuarios no tienen ruta de acceso directa a los directorios globales de la plataforma.

**Independent Test**: Puede probarse de forma aislada iniciando sesión con cada uno de los 5 roles, tocando el icono de menú hamburguesa en el `AppBar`, verificando que el drawer se despliega con el encabezado de identidad y las opciones de menú visibles y habilitadas.

**Acceptance Scenarios**:

1. **Given** un usuario autenticado con rol `Organizador`, `Árbitro`, `Entrenador / Capitán`, `Jugador` o `Aficionado` en `AppShellScreen`, **When** pulsa el icono de menú (hamburguesa) en el extremo izquierdo de la barra superior, **Then** se despliega el menú lateral `NavigationDrawer` con el encabezado de identidad del usuario y la aplicación.
2. **Given** el menú lateral desplegado en pantalla, **When** el usuario visualiza la lista de opciones, **Then** se muestran los destinos de navegación: "Competiciones", "Equipos", "Jugadores" y "Sedes" (ofreciendo acceso directo e integrado al catálogo de canchas y recintos deportivos para todos los roles).
3. **Given** el menú lateral desplegado en pantalla, **When** el usuario toca fuera del drawer o desliza hacia la izquierda, **Then** el menú lateral se cierra suavemente regresando a la pantalla activa de `AppShellScreen` sin alterar el estado previo.

---

### User Story 2 - Directorio de Competiciones con Buscador Superior en Tiempo Real (Priority: P1)

Como usuario de cualquier rol, quiero navegar a la página dedicada de Competiciones (`CompetitionsDirectoryScreen`) desde el menú lateral y utilizar un buscador superior persistente, para explorar y encontrar rápidamente torneos activos por su nombre o categoría.

**Why this priority**: Las competiciones representan el eje estructural de ViFutbol. Permitir localizarlas rápidamente mediante búsqueda sin distinción de mayúsculas ni acentos es fundamental para la navegación deportiva.

**Independent Test**: Puede probarse de forma aislada abriendo el menú lateral, seleccionando "Competiciones", verificando la navegación a la nueva pantalla, escribiendo en el buscador y comprobando el filtrado inmediato de torneos, el botón de limpieza y el estado vacío.

**Acceptance Scenarios**:

1. **Given** el usuario con el menú lateral desplegado, **When** pulsa la opción "Competiciones", **Then** el drawer se cierra automáticamente y la aplicación navega hacia la pantalla de directorio de Competiciones.
2. **Given** el usuario en la pantalla de Competiciones, **When** la pantalla se renderiza, **Then** se muestra un campo de búsqueda fijo en la parte superior con el texto de ayuda "Buscar competiciones..." y, debajo, la lista de competiciones con su nombre, categoría, formato y distintivo de estado.
3. **Given** la lista de competiciones visibles, **When** el usuario escribe un término en el buscador (por ejemplo "juvenil" o "verano"), **Then** la lista filtra en tiempo real de forma insensible a mayúsculas y acentos mostrando únicamente las competiciones que coinciden por nombre o categoría.
4. **Given** un término de búsqueda sin coincidencias, **When** el filtro no produce resultados, **Then** se muestra un componente de estado vacío informativo con icono ilustrativo y un botón o acción rápida para limpiar la búsqueda.
5. **Given** texto ingresado en el buscador superior, **When** el usuario pulsa el icono de limpieza ("X") en el extremo del campo, **Then** el texto se borra inmediatamente, el teclado se mantiene o se oculta al desplazar y la lista restablece el catálogo completo.
6. **Given** un elemento de competición en la lista, **When** el usuario lo pulsa, **Then** el sistema selecciona dicha competición como el torneo activo global y navega de regreso a `AppShellScreen` en la pestaña `Explorar` (o la pestaña deportiva activa) para visualizar inmediatamente su fixture, estadísticas y posiciones.
7. **Given** un usuario autenticado con permisos para gestionar torneos (`Organizador`), **When** accede a la pantalla de Competiciones, **Then** se muestra un botón de acción rápida para crear un nuevo campeonato.

---

### User Story 3 - Directorio de Equipos con Buscador y Consulta de Plantilla (Priority: P2)

Como usuario de cualquier rol, quiero acceder a la página de Equipos (`TeamsDirectoryScreen`) desde el menú lateral y filtrar por nombre, abreviatura o categoría, para consultar los clubes registrados y acceder al detalle de su plantilla.

**Why this priority**: Los equipos son los participantes centrales de las competiciones. Ofrecer un directorio unificado permite a aficionados, entrenadores y árbitros revisar los clubes participantes y sus plantillas sin tener que navegar torneo por torneo.

**Independent Test**: Puede probarse navegando a "Equipos" desde el drawer, buscando por nombre (ej. "Tigres") o abreviatura (ej. "TIG"), comprobando que solo los equipos coincidentes se listan, y pulsando un equipo para ver el desglose de jugadores.

**Acceptance Scenarios**:

1. **Given** el usuario con el menú lateral desplegado, **When** selecciona la opción "Equipos", **Then** el drawer se cierra y se abre la pantalla de directorio de Equipos con su respectiva barra de navegación y botón de retroceso.
2. **Given** la pantalla de Equipos, **When** se visualiza el contenido, **Then** se presenta el buscador superior "Buscar equipos...", un selector horizontal de torneos ("Todos" + torneos disponibles) y la lista de equipos registrados con su escudo oficial (`KickPulseTeamCrest`), nombre, abreviatura y cantidad de jugadores registrados vs. cupo permitido.
3. **Given** la lista de equipos, **When** el usuario escribe en el buscador, **Then** los resultados se filtran en tiempo real por coincidencia parcial insensible a mayúsculas y diacríticos en el nombre del equipo, su código corto/abreviatura o su categoría.
4. **Given** un equipo visible en los resultados, **When** el usuario toca sobre su tarjeta, **Then** se abre la hoja modal de detalle de estadísticas y plantilla del equipo (`showTeamDetailedStatsSheet`).
5. **Given** una búsqueda sin coincidencias, **When** ningún equipo cumple el criterio, **Then** se despliega el estado vacío con mensaje descriptivo y opción para restablecer la búsqueda.
6. **Given** un usuario con permisos para registrar o gestionar equipos (`Organizador`, `Entrenador / Capitán`), **When** accede a la pantalla de Equipos, **Then** se muestra un botón de acción rápida para registrar un nuevo equipo.

---

### User Story 4 - Directorio de Jugadores con Buscador y Ficha de Rendimiento (Priority: P2)

Como usuario de cualquier rol, quiero acceder a la página de Jugadores (`PlayersDirectoryScreen`) desde el menú lateral y filtrar por nombre, dorsal, posición o equipo, para localizar a cualquier futbolista y consultar su perfil de rendimiento individual.

**Why this priority**: Los jugadores son los protagonistas deportivos. Permitir la búsqueda transversal de jugadores y el acceso inmediato a sus estadísticas y ficha de rendimiento complementa la experiencia del aficionado, ojeador y cuerpo técnico.

**Independent Test**: Puede probarse navegando a "Jugadores" desde el drawer, buscando por nombre de jugador, dorsal o nombre de equipo, comprobando los filtros reactivos y abriendo la ficha de rendimiento al pulsar la tarjeta del jugador.

**Acceptance Scenarios**:

1. **Given** el usuario con el menú lateral desplegado, **When** selecciona la opción "Jugadores", **Then** el drawer se cierra y se navega a la pantalla de directorio de Jugadores.
2. **Given** la pantalla de Jugadores, **When** se visualiza el contenido, **Then** se presenta el campo de búsqueda "Buscar jugadores...", un selector horizontal de torneos ("Todos" + torneos disponibles) y la lista con nombre completo, número de dorsal, posición en el campo, equipo al que pertenece y distintivo de elegibilidad oficial.
3. **Given** la lista de jugadores, **When** el usuario busca por nombre, dorsal (ej. "10"), posición (ej. "Delantero", "Portero") o nombre del equipo, **Then** se filtran instantáneamente los futbolistas coincidentes de forma insensible a acentos y mayúsculas.
4. **Given** un jugador en la lista filtrada, **When** el usuario pulsa sobre su fila, **Then** se despliega la hoja de perfil de rendimiento del jugador (`showPlayerPerformanceProfileSheet`) con su historial, goles, tarjetas y estadísticas individuales.
5. **Given** un criterio de búsqueda que no coincide con ningún jugador registrado, **When** la lista queda vacía, **Then** se muestra el componente de estado vacío (`KickPulseStateView`) con invitación a limpiar el filtro.
6. **Given** un usuario con permisos para gestionar plantilla (`Organizador`, `Entrenador / Capitán`), **When** accede a la pantalla de Jugadores, **Then** se muestra un botón de acción rápida para inscribir o registrar un nuevo jugador.

---

### Edge Cases

- **Búsqueda con acentos y variaciones diacríticas**: Si el usuario busca "alvarez", el sistema debe encontrar tanto "Álvarez" como "Alvarez". Si busca "gonzález", debe encontrar "Gonzalez".
- **Espacios en blanco y caracteres de puntuación**: Los términos con espacios al inicio o final (ej. `"  tigres  "`) deben limpiarse automáticamente (*trim*) para no falsear la búsqueda.
- **Transición y ciclo de vida del Drawer**: Si el usuario pulsa una opción del Drawer, el Drawer debe cerrarse programáticamente antes de la navegación para evitar que al regresar con el botón atrás el menú permanezca abierto de forma anómala.
- **Teclado virtual y desplazamiento**: Al hacer scroll sobre la lista de resultados, el foco del teclado debe liberarse automáticamente (`FocusScope.of(context).unfocus()`) evitando que el teclado tape los resultados inferiores en pantallas pequeñas (`320x640`).
- **Escalado de texto de accesibilidad (130%)**: En pantallas compactas de 320 px de ancho lógico y texto al 130%, los elementos del Drawer, el campo de búsqueda con botón de limpieza y las tarjetas de las 3 pantallas de directorio deben ajustarse sin provocar desbordamientos (`RenderFlex overflow`).
- **Base de datos vacía / Inicialización**: Si la aplicación aún no cuenta con competiciones, equipos o jugadores registrados, las pantallas de directorio deben mostrar un estado inicial amigable indicando que no hay registros disponibles, en lugar de errores o bloqueos de carga indefinidos.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE proveer un menú lateral (`NavigationDrawer`) accesible desde `AppShellScreen` para todos los roles del sistema (`Organizador`, `Árbitro`, `Entrenador / Capitán`, `Jugador`, `Aficionado`), accionado mediante el botón de menú hamburguesa ubicado en la barra superior.
- **FR-002**: El `NavigationDrawer` DEBE presentar un encabezado institucional que exhiba la identidad visual de la aplicación, el usuario conectado y su rol activo.
- **FR-003**: El `NavigationDrawer` DEBE incluir cuatro destinos de navegación directos: **Competiciones**, **Equipos**, **Jugadores** y **Sedes**.
- **FR-004**: Al seleccionar cualquiera de las opciones del Drawer, el sistema DEBE cerrar el menú lateral antes de realizar la navegación hacia la pantalla de directorio seleccionada, garantizando un botón de retroceso funcional en la barra superior de cada pantalla de destino.
- **FR-005**: La pantalla de Competiciones (`CompetitionsDirectoryScreen`) DEBE listar todas las competiciones registradas y mantener un campo de búsqueda superior fijo con texto de ayuda localizado ("Buscar competiciones...").
- **FR-006**: La pantalla de Equipos (`TeamsDirectoryScreen`) DEBE listar todos los equipos registrados con su escudo oficial, nombre, abreviatura y cantidad de futbolistas inscritos, disponiendo de un campo de búsqueda superior fijo con texto de ayuda ("Buscar equipos...").
- **FR-007**: La pantalla de Jugadores (`PlayersDirectoryScreen`) DEBE listar todos los futbolistas registrados con su nombre, dorsal, posición, nombre de equipo y estado de elegibilidad, disponiendo de un campo de búsqueda superior fijo con texto de ayuda ("Buscar jugadores...").
- **FR-008**: Los campos de búsqueda en las tres pantallas de directorio DEBEN filtrar los elementos en tiempo real de forma insensible a mayúsculas/minúsculas y a tildes/acentos ortográficos.
- **FR-009**: Cada campo de búsqueda DEBE incorporar un botón de acción rápida de borrado ("X") que se muestra únicamente cuando hay texto escrito y que, al ser pulsado, limpia el texto y reestablece la lista completa.
- **FR-010**: Las tres pantallas de directorio DEBEN implementar el componente de estado vacío (`KickPulseStateView`) cuando la búsqueda no arroje resultados coincidentes, ofreciendo retroalimentación visual clara y opción de restablecimiento.
- **FR-011**: Al pulsar sobre un equipo en el directorio de equipos, el sistema DEBE abrir la vista o modal con la información detallada de la plantilla de dicho equipo.
- **FR-012**: Al pulsar sobre un jugador en el directorio de jugadores, el sistema DEBE abrir la hoja modal con el perfil de rendimiento y estadísticas detalladas del jugador.
- **FR-013**: Todos los textos visibles en la interfaz de usuario DEBEN estar centralizados en los archivos de localización en español (`l10n`), sin textos codificados directamente en los componentes.
- **FR-014**: En las pantallas de directorio (Competiciones, Equipos, Jugadores), el sistema DEBE evaluar los permisos del rol activo (ej. capacidad de gestionar torneos o inscribir equipos) y, de estar autorizado, desplegar un botón de acción rápida para iniciar el flujo de creación correspondiente (ej. crear campeonato, registrar equipo o inscribir jugador).
- **FR-015**: Las pantallas de directorio de Equipos y Jugadores DEBEN incluir un selector horizontal de torneos (con opción inicial "Todos" y cada competición registrada) ubicado debajo del buscador superior, permitiendo alternar entre el catálogo global y los miembros de un torneo específico.

### Key Entities *(include if feature involves data)*

- **DirectorySearchFilter**: Entidad o modelo de estado de consulta que contiene el término de búsqueda ingresado, el criterio de normalización (minúsculas, remoción de acentos) y la lista de resultados filtrados correspondientes.
- **CompetitionDirectoryItem**: Representación proyectada de una competición para el directorio, incluyendo identificador único, nombre, categoría, formato de torneo, estado oficial y cantidad de equipos participantes.
- **TeamDirectoryItem**: Representación proyectada de un equipo para el directorio, incluyendo identificador único, nombre, código corto/abreviatura, escudo estilizado, categoría y conteo de jugadores.
- **PlayerDirectoryItem**: Representación proyectada de un jugador para el directorio, incluyendo identificador único, nombre completo, dorsal, posición de juego, equipo asociado, foto o iniciales y estado de elegibilidad.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El usuario puede abrir el menú lateral y acceder a cualquiera de los tres directorios en menos de 2 segundos desde cualquier sección principal.
- **SC-002**: El filtrado por texto en cualquiera de los tres directorios actualiza la lista visual en menos de 100 ms tras cada pulsación de tecla, proporcionando una sensación de respuesta instantánea.
- **SC-003**: El 100% de las búsquedas con variaciones de acentos (ej. "Pérez" vs "perez") devuelven resultados idénticos y consistentes sin falsos negativos.
- **SC-004**: El sistema mantiene un 100% de cumplimiento visual responsivo sin desbordamientos (`RenderFlex overflow`) en pantallas de 320x640 px con escalado de texto al 130%.
- **SC-005**: El 100% de los textos visibles en el drawer y las pantallas de directorio están localizados en español a través del catálogo centralizado `l10n`.

## Assumptions

- **A-001**: Los catálogos de datos (competiciones, equipos y jugadores) provienen de los controladores y repositorios existentes en la arquitectura de la aplicación (`tournamentsControllerProvider`, repositorios de equipos y jugadores), aprovechando los datos locales offline y la memoria en caché.
- **A-002**: El Drawer se integra en el `Scaffold` principal de `AppShellScreen` mediante la propiedad estándar `drawer` o mecanismo equivalente de Flutter, garantizando que el gesto de deslizamiento desde el borde izquierdo (*swipe-to-open*) y el botón de menú funcionen de manera nativa.
- **A-003**: La navegación a las pantallas de directorio se realiza mediante apilamiento estándar (`Navigator.push` / rutas nombradas de `AppRouter`), de modo que el botón atrás del sistema y de la barra superior regresa de forma natural al shell principal.
- **A-004**: La normalización de acentos se implementa mediante una función auxiliar pura y reutilizable que elimina diacríticos de las cadenas antes de comparar.
