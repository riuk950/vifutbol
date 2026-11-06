# Feature Specification: Acceso a "Panel" en Navigation Drawer y Ocultación Temporal de "Explorar"

**Feature Branch**: `016-drawer-panel-access`

**Created**: 2026-11-06

**Status**: Draft

**Input**: User description: "/speckit-specify de Notion hu 12.1 en curso"

---

## Clarifications

### Session 2026-11-06

- Q: ¿En qué posición dentro del menú lateral (`AppNavigationDrawer`) debe ubicarse el nuevo ítem de navegación "Panel"? → A: Primera posición (arriba de "Competiciones") para priorizar el acceso operativo del rol activo.
- Q: ¿Qué contenido debe presentar la pantalla en la ruta `/panel` durante esta historia (HU 12.1), antes de implementar los widgets y dashboards específicos por rol de la HU 12.2? → A: Pantalla Scaffold base con AppBar ("Panel"), botón de retroceso (`BackButton`) y una vista informativa estilizada que muestra el rol activo y el estado preparatorio del panel.
- Q: ¿Cómo debe gestionarse la relación entre el índice visual de 3 pestañas en el `NavigationBar` y la enumeración de dominio `AppShellSection`? → A: Mantener el enum `AppShellSection` intacto y resolver el mapeo bidireccional de índices (0: `matches`, 1: `news`, 2: `profile`) en la capa de presentación (`AppShellScreen`), asegurando compatibilidad regresiva y facilitando la reactivación futura de "Explorar".

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ocultación Temporal de la Pestaña "Explorar" en el NavigationBar Inferior (Priority: P1)

Como usuario de cualquier rol en ViFutbol, quiero que la barra de navegación inferior (`NavigationBar`) muestre exclusivamente las pestañas operativas y activas ("Partidos", "Noticias" y "Perfil"), retirando temporalmente la pestaña "Explorar", para no encontrar secciones en redefinición y disfrutar de una experiencia de navegación limpia y enfocada.

**Why this priority**: Evita la frustración del usuario al acceder a una sección en redefinición arquitectónica y concentra la navegación inferior en los flujos principales (calendario de partidos, noticias y gestión de perfil).

**Independent Test**: Puede probarse de manera aislada iniciando la aplicación con cualquier rol y verificando que el `NavigationBar` inferior contiene exactamente 3 destinos visibles ("Partidos", "Noticias", "Perfil") sin la opción "Explorar", y que cualquier intento de navegación directa hacia `/explore` redirige de forma segura a `/matches`.

**Acceptance Scenarios**:

1. **Given** un usuario autenticado con cualquier rol (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`), **When** accede a la pantalla principal (`AppShellScreen`), **Then** la barra inferior muestra exactamente tres pestañas: "Partidos", "Noticias" y "Perfil".
2. **Given** la barra de navegación inferior, **When** el usuario inspecciona las opciones disponibles, **Then** la pestaña "Explorar" (`AppShellSection.explore` / `tabStandings`) no se encuentra presente ni interactuable.
3. **Given** que el usuario intenta acceder a la ruta `/explore` mediante deep-link o llamada de navegación directa, **When** el enrutador procesa la solicitud, **Then** el sistema redirige automáticamente y sin error hacia la ruta `/matches`.
4. **Given** que la aplicación se encontraba en segundo plano y se restaura el estado de navegación, **When** la sección previa no es válida o correspondía a "Explorar", **Then** el shell inicializa de forma segura en la sección predeterminada "Partidos".

---

### User Story 2 - Acceso y Visibilidad Condicionada del Ítem "Panel" en el Navigation Drawer (Priority: P1)

Como usuario con rol de gestión deportiva o participante activo (`Organizador`, `Entrenador`, `Árbitro` o `Jugador`), quiero disponer de un acceso directo llamado **"Panel"** en el Navigation Drawer lateral, para ingresar de forma rápida a las herramientas de control y administración de mi rol, manteniéndose oculto para el rol `Aficionado`.

**Why this priority**: Habilita la puerta de entrada principal hacia las funcionalidades del panel de gestión por rol (HU 12.2) y refuerza la segregación de permisos (Principio V de la Constitución), garantizando que los aficionados tengan un menú simplificado sin controles administrativos irrelevantes.

**Independent Test**: Puede probarse de forma aislada iniciando sesión con cada uno de los 5 roles, abriendo el Navigation Drawer y verificando que el ítem "Panel" (con icono alusivo y etiqueta localizada) se muestra para los 4 roles operativos y se oculta completamente para el rol Aficionado, cerrando el drawer y navegando a `/panel` al ser pulsado.

**Acceptance Scenarios**:

1. **Given** que el usuario autenticado tiene el rol `Aficionado` (`UserRole.fan`), **When** abre el Navigation Drawer lateral, **Then** se visualizan los destinos de directorio (Competiciones, Equipos, Jugadores, Sedes), pero el ítem "Panel" NO está visible ni presente en el árbol visual.
2. **Given** que el usuario autenticado tiene el rol `Organizador` (`UserRole.organizer`), **When** abre el Navigation Drawer lateral, **Then** se visualiza el ítem "Panel" con su icono distintivo (`Icons.dashboard_outlined` o equivalente visual) entre las opciones del menú.
3. **Given** que el usuario autenticado tiene el rol `Entrenador` (`UserRole.coach`), **When** abre el Navigation Drawer lateral, **Then** se visualiza el ítem "Panel".
4. **Given** que el usuario autenticado tiene el rol `Árbitro` (`UserRole.referee`), **When** abre el Navigation Drawer lateral, **Then** se visualiza el ítem "Panel".
5. **Given** que el usuario autenticado tiene el rol `Jugador` (`UserRole.player`), **When** abre el Navigation Drawer lateral, **Then** se visualiza el ítem "Panel".
6. **Given** un usuario autorizado que observa el ítem "Panel" en el Navigation Drawer, **When** pulsa sobre el ítem, **Then** el Drawer se cierra programáticamente de forma fluida y el sistema navega hacia la ruta `/panel`.

---

### Edge Cases

- **Cambio dinámico de rol en tiempo de ejecución**: Si un usuario cambia de rol (por ejemplo, desde el selector de perfil de desarrollo de `Aficionado` a `Organizador`), el Drawer debe reaccionar de forma inmediata actualizando la visibilidad del ítem "Panel" sin requerir reinicio de la aplicación.
- **Acceso por enlace profundo a `/panel` sin permisos**: Si un usuario con rol `Aficionado` intenta acceder directamente a la ruta `/panel`, el sistema debe denegar el acceso o redirigir de forma segura hacia la ruta principal con un mensaje explicativo no invasivo.
- **Transición y superposición del Drawer**: Al pulsar "Panel", el Drawer debe invocar el cierre (`pop`) antes de la navegación para evitar que la pila de rutas mantenga el menú lateral abierto al regresar con el botón atrás de Android/iOS.
- **Accesibilidad y escalado tipográfico al 130% en viewport compacto (320x640)**: Con tamaño de texto aumentado, el ítem "Panel" y sus adyacentes en el Drawer deben mantener su área táctil mínima de 48x48 dp sin provocar desbordamientos visuales (`RenderFlex overflow`).
- **Navegación con conexión intermitente u offline**: El acceso a la opción "Panel" y la redirección de "Explorar" son comportamientos de navegación locales que deben funcionar al 100% sin requerir conectividad de red.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE retirar la pestaña "Explorar" del `NavigationBar` inferior en `AppShellScreen`, manteniendo exclusivamente tres destinos visibles: "Partidos", "Noticias" y "Perfil", mediante un mapeo de índices visuales en presentación (0: `matches`, 1: `news`, 2: `profile`) que preserve intacta la enumeración de dominio `AppShellSection`.
- **FR-002**: El sistema DEBE redirigir cualquier navegación hacia la ruta `/explore` hacia la ruta predeterminada `/matches`.
- **FR-003**: El sistema DEBE incorporar en `AppNavigationDrawer` una opción de navegación denominada "Panel" en la primera posición del listado (arriba de "Competiciones"), identificada con un icono alusivo de panel/dashboard (`Icons.dashboard_outlined`).
- **FR-004**: El ítem "Panel" DEBE ser visible exclusivamente para los roles con responsabilidades de gestión o participación deportiva: `Organizador`, `Entrenador`, `Árbitro` y `Jugador`.
- **FR-005**: El ítem "Panel" DEBE permanecer oculto para el rol `Aficionado` (`UserRole.fan`).
- **FR-006**: Al interactuar con el ítem "Panel", el sistema DEBE cerrar el Navigation Drawer antes de realizar la transición hacia la ruta `/panel`.
- **FR-007**: El enrutador de la aplicación DEBE registrar la ruta `/panel` y presentar una pantalla contenedora con barra de navegación superior, título "Panel", botón de retroceso (`BackButton`) y una vista informativa estilizada que muestre el rol activo y el estado preparatorio del panel.
- **FR-008**: Todos los textos de interfaz asociados (`drawerPanel`, mensajes informativos o de restricción) DEBEN estar centralizados en los archivos de localización `app_es.arb` sin cadenas de texto codificadas directamente (*no hardcoded strings*).
- **FR-009**: El ítem de navegación "Panel" DEBE contar con un área táctil mínima accesible de $48 \times 48\text{ dp}$ y etiquetas semánticas para lectores de pantalla.

---

### Key Entities *(include if feature involves data)*

- **AppShellSection**: Enumeración de secciones de la barra inferior principal; temporalmente sus destinos visuales se restringen a `matches`, `news`, `profile`, preservando la compatibilidad de dominio si se requiere restauración futura.
- **UserRole**: Enumeración de roles del sistema (`organizer`, `coach`, `referee`, `player`, `fan`), utilizada como criterio determinante para la visibilidad condicional del destino "Panel".
- **DrawerNavigationDestination**: Estructura de presentación que modela cada ítem del Navigation Drawer (clave semántica, icono, etiqueta localizada, ruta destino y predicado de visibilidad por rol).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de los usuarios que abren la aplicación visualizan exactamente 3 pestañas en la barra inferior sin presencia de la opción "Explorar".
- **SC-002**: El 100% de los intentos de navegación directa a `/explore` son redirigidos de forma transparente y sin error a `/matches` en menos de 100 ms.
- **SC-003**: El ítem "Panel" se visualiza en el Navigation Drawer para el 100% de las sesiones con roles `Organizador`, `Entrenador`, `Árbitro` y `Jugador`, y en el 0% de las sesiones con rol `Aficionado`.
- **SC-004**: El tiempo de transición y cierre del Drawer al pulsar "Panel" se ejecuta de forma fluida sin bloqueos en la interfaz de usuario.
- **SC-005**: 0 desbordamientos visuales (`RenderFlex overflow`) en viewport compacto ($320 \times 640\text{ px}$) con escalado de texto al 130%.

---

## Assumptions

- **A-001**: La retirada de "Explorar" de la barra inferior es una medida de diseño temporal mientras se refactoriza dicha sección, por lo que la vista subyacente y sus controladores no se destruyen, solo se desacoplan de la barra visual inferior.
- **A-002**: La pantalla completa del panel administrativo por rol y sus widgets específicos corresponden a la siguiente historia (HU 12.2); en HU 12.1 se garantiza la ruta, el ítem en el Drawer y la pantalla contenedora funcional con navegación de retorno.
- **A-003**: El rol `Aficionado` seguirá teniendo acceso a los directorios generales de Competiciones, Equipos, Jugadores y Sedes desde el Navigation Drawer.
