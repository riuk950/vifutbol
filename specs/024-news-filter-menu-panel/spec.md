# Feature Specification: Refactorización de Noticias (Filtros en Menú de 3 Puntos del AppBar y Creación de Noticia desde el Panel)

**Feature Branch**: `024-news-filter-menu-panel`  
**Created**: 2026-11-09  
**Status**: Draft  
**Input**: User description: "Notion HU 15.1 en curso: [Épica 15] HU 15.1: Refactorización de Noticias (Filtros en Menú de 3 Puntos del AppBar y Creación de Noticia desde el Panel)"

## Clarifications

### Session 2026-11-09

- Q: ¿Qué formato visual se prefiere para desplegar las opciones de filtrado (competición y categoría) al pulsar el icono `more_vert`? → A: Modal Bottom Sheet inferior (`news_filter_bottom_sheet`) con secciones claras para elegir torneo y categoría.
- Q: Al centralizar los filtros en el menú de 3 puntos del `AppBar`, ¿qué debe ocurrir con los chips horizontales de torneos y categorías que actualmente ocupan espacio en el feed de noticias? → A: Retirar las barras horizontales por completo del feed para máxima limpieza visual, mostrando únicamente el chip de filtro activo cuando se aplique un filtro.
- Q: ¿Cómo debe el organizador indicar a qué torneo pertenece la noticia cuando pulsa la acción rápida "Publicar Noticia" en `/panel`? → A: Selector de torneo integrado dentro del formulario `CreateNewsDialog` mediante un desplegable para resolver la publicación en un único paso.
- Q: ¿Qué competiciones deben habilitarse en el selector desplegable de torneo dentro de `CreateNewsDialog` cuando el Organizador pulsa "Publicar Noticia" desde el Panel (`/panel`)? → A: Solo competiciones no finalizadas (excluyendo `TournamentStatus.finished`), preseleccionando el torneo activo actual si es editable.
- Q: Al retirar las barras horizontales de chips del feed de noticias, ¿cómo debe mostrarse en la cabecera de `NewsTabView` el torneo actualmente seleccionado junto al chip de filtro de categoría activa? → A: Mostrar siempre el nombre del torneo activo como subtítulo fijo de contexto bajo el encabezado "Noticias", y renderizar el chip removible `news_active_filter_chip` únicamente cuando haya una categoría filtrada distinta de "Todas".
- Q: Cuando el usuario selecciona un torneo o una categoría dentro de la hoja modal de filtros (`news_filter_bottom_sheet`), ¿cómo debe aplicarse el cambio y cerrarse el modal? → A: Actualización reactiva inmediata en tiempo real al tocar cada opción, manteniendo el modal abierto para permitir combinar torneo y categoría antes de cerrarlo mediante su botón de cierre o toque fuera.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reubicación de la Publicación de Noticias al Panel Administrativo del Organizador (Priority: P1) 🎯 MVP

Como Organizador de torneos,  
quiero gestionar la creación y publicación de noticias oficiales exclusivamente desde el Panel Administrativo (`/panel`) en lugar de tener un botón de creación en el feed público,  
para separar las facultades operativas de gestión de la experiencia de lectura pública y mantener un feed limpio.

**Why this priority**: Es la separación fundamental de roles y arquitectura solicitada en la HU 15.1. Elimina la polución visual en la vista de noticias para usuarios generales y concentra la acción de publicación en el panel de control correspondiente a los roles administrativos.

**Independent Test**:
1. Iniciar sesión como Organizador y navegar a la pestaña "Noticias" en `AppShellScreen`: verificar que **no** existe el botón "Nueva Noticia" (`create_news_button`) en el feed público.
2. Navegar a "/panel" (`OrganizerPanelContent`) y verificar la presencia de la acción rápida "Publicar Noticia" (`organizer_action_publish_news`).
3. Pulsar la acción, seleccionar la competición destino, completar el formulario y confirmar la publicación; verificar que la noticia aparece en el feed del torneo correspondiente con un mensaje de éxito.

**Acceptance Scenarios**:
1. **Given** un usuario autenticado con cualquier rol (incluyendo Organizador) en la pestaña "Noticias", **When** visualiza el feed de comunicados, **Then** no se renderiza ningún botón para crear noticias dentro del feed público.
2. **Given** un usuario con rol Organizador en la pantalla del Panel (`/panel`), **When** visualiza la sección de "Acciones Rápidas", **Then** se muestra la acción "Publicar Noticia" (`organizer_action_publish_news`).
3. **Given** el Organizador pulsando "Publicar Noticia" en `/panel`, **When** selecciona el torneo correspondiente y completa los datos válidos en el formulario de creación, **Then** la noticia queda registrada y disponible en el catálogo de noticias del torneo.

---

### User Story 2 - Menú de Opciones de Tres Puntos en AppBar para Configuración de Filtros (Priority: P2)

Como lector o aficionado de ViFutbol,  
quiero acceder a las configuraciones de filtrado de noticias (por competición y categoría) mediante un menú de opciones de tres puntos (`more_vert`) en la barra superior (`AppBar`) cuando me encuentro en la pestaña de Noticias,  
para descubrir comunicados relevantes sin sobrecargar el espacio visual de lectura en la pantalla.

**Why this priority**: Centraliza los controles de consulta y filtrado en la barra superior contextual, liberando el área de contenido principal para la lectura fluida de los comunicados oficiales.

**Independent Test**:
1. Abrir la app en la pestaña "Noticias" (`AppShellSection.news`) y verificar que el `AppBar` superior renderiza el botón de acción contextual con el icono de tres puntos (`more_vert`, `Key('app_bar_news_filter_action')`).
2. Cambiar a otra pestaña (p. ej., "Partidos" o "Perfil") y verificar que el botón de tres puntos desaparece automáticamente del `AppBar`.
3. Volver a "Noticias", pulsar el botón de tres puntos y verificar que se despliega la interfaz de configuración de filtros permitiendo seleccionar torneo y categoría de noticia.
4. Seleccionar un filtro y verificar que el feed de noticias se actualiza inmediatamente mostrando únicamente los comunicados coincidentes.

**Acceptance Scenarios**:
1. **Given** que la sección activa en `AppShellScreen` es "Noticias", **When** se renderiza el `AppBar`, **Then** se exhibe el botón de acción de tres puntos (`app_bar_news_filter_action`) junto al icono de notificaciones.
2. **Given** que la sección activa en `AppShellScreen` no es "Noticias", **When** se evalúan las acciones del `AppBar`, **Then** el botón `app_bar_news_filter_action` no está presente.
3. **Given** el usuario en la pestaña "Noticias", **When** pulsa el botón de tres puntos, **Then** se despliega el menú/hoja modal de filtrado (`news_filter_modal`) mostrando la lista de competiciones y categorías disponibles.
4. **Given** el usuario seleccionando un torneo o una categoría diferente en el modal de filtrado, **When** confirma o selecciona la opción, **Then** el estado de filtrado se actualiza reactivamente y el feed refleja únicamente las noticias coincidentes.

---

### User Story 3 - Indicador Visual de Filtro Activo y Limpieza Rápida en el Feed (Priority: P3)

Como usuario que ha configurado un filtro específico de noticias,  
quiero visualizar un indicador compacto o chip de filtro activo bajo la cabecera del feed con un botón de borrado rápido,  
para saber en todo momento qué filtro está restringiendo las noticias visibles y poder restablecer el feed completo con un solo toque.

**Why this priority**: Garantiza la transparencia informativa y evita que el usuario quede desorientado pensando que no existen noticias cuando en realidad hay un filtro restrictivo aplicado en segundo plano.

**Independent Test**:
1. Aplicar un filtro de categoría específico (p. ej., "Sanciones") desde el menú de tres puntos del `AppBar`.
2. Verificar que en la cabecera de la vista de noticias se renderiza un chip compacto (`Key('news_active_filter_chip')`) que indica la categoría filtrada.
3. Pulsar el icono de remoción/limpieza en el chip y verificar que el filtro se restablece a "Todas" y el feed muestra nuevamente la totalidad de las noticias.

**Acceptance Scenarios**:
1. **Given** que el usuario aplica un filtro de categoría diferente a "Todas", **When** se renderiza la vista de noticias, **Then** se muestra un chip indicador de filtro activo (`news_active_filter_chip`) que detalla la categoría seleccionada.
2. **Given** el chip de filtro activo visible, **When** el usuario pulsa el botón de eliminar o limpiar del chip, **Then** el filtro de categoría se restablece a "Todas" y el chip desaparece.
3. **Given** que el filtro de categoría es "Todas" y no hay restricciones personalizadas adicionales, **When** se visualiza la cabecera de noticias, **Then** no se muestra ningún chip de filtro residual.

---

### Edge Cases

- **Organizador sin competiciones registradas**: Si un organizador pulsa "Publicar Noticia" en el panel pero no existen torneos creados, el sistema debe mostrar un estado informativo o diálogo que indique que debe crear primero una competición antes de publicar un comunicado.
- **Filtro sin resultados coincidentes**: Si el usuario aplica un filtro de categoría que no contiene comunicados en el torneo seleccionado, el feed debe mostrar un estado vacío claro y accesible (`news_feed_empty_filter`), informando que no hay noticias para la categoría elegida, junto a un botón para restablecer el filtro.
- **Navegación y persistencia de pestaña**: Al navegar entre secciones de `AppShellScreen` y volver a Noticias, el torneo y categoría previamente filtrados deben mantenerse consistentes en el estado de la sesión.
- **Dispositivos ultracompactos ($320 \times 640\text{ px}$) con escalado de texto al 130%**: El menú de tres puntos, el modal de filtrado y el chip de filtro activo deben ajustarse fluidamente sin provocar desbordamientos `RenderFlex`.
- **Modo sin conexión (Offline)**: Las noticias previamente cargadas en caché deben seguir mostrándose y filtrándose localmente sin requerir conexión a internet.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE remover el botón de creación de noticias (`create_news_button`) de la vista pública de noticias (`NewsTabView` / `TournamentNewsFeedView`).
- **FR-002**: El sistema DEBE proveer en `OrganizerPanelContent` (`/panel`) una acción rápida "Publicar Noticia" (`organizer_action_publish_news`), visible únicamente para usuarios con rol `UserRole.organizer`.
- **FR-003**: Al pulsar "Publicar Noticia" en el panel, el sistema DEBE permitir seleccionar la competición activa de destino y desplegar el formulario de creación de noticia (`CreateNewsDialog`).
- **FR-004**: Al confirmar la creación con datos válidos, el sistema DEBE persistir la noticia en el repositorio correspondiente y mostrar una confirmación accesible (`SnackBar`).
- **FR-005**: El sistema DEBE renderizar en el `AppBar` de `AppShellScreen` un botón de acción de tres puntos (`Key('app_bar_news_filter_action')`) con icono `Icons.more_vert`, el cual DEBE ser visible única y exclusivamente cuando `activeSection == AppShellSection.news`.
- **FR-006**: Al pulsar el botón de tres puntos del `AppBar`, el sistema DEBE desplegar una hoja modal inferior (*Modal Bottom Sheet*, `Key('news_filter_bottom_sheet')`) ergonómica y accesible con secciones claramente divididas para configurar el torneo activo y la categoría de comunicado, aplicando los cambios reactivamente en tiempo real al tocar cada opción y manteniendo el modal abierto hasta que el usuario lo cierre explícitamente.
- **FR-007**: El componente de filtrado DEBE permitir seleccionar el torneo activo entre las competiciones disponibles en el catálogo (`Key('news_filter_tournament_chip_${id}')`), actualizando `tournamentsControllerProvider` de inmediato.
- **FR-008**: El componente de filtrado DEBE permitir seleccionar la categoría de noticia (`TournamentNewsCategory`, `Key('news_filter_category_chip_${name}')`), incluyendo la opción "Todas" (`Key('news_filter_category_chip_all')`) y las categorías específicas (*General*, *Comunicado Oficial*, *Sanciones*, *Resultados / Jornada*, etc.), actualizando `tournamentNewsControllerProvider` de inmediato.
- **FR-009**: Las barras horizontales de chips de torneo y de categorías en el cuerpo del feed DEBEN retirarse por completo, manteniendo bajo el título "Noticias" el nombre del torneo actualmente seleccionado como subtítulo fijo de contexto (`Key('news_active_tournament_subtitle')`) para una lectura limpia y vertical.
- **FR-010**: El sistema DEBE renderizar en `NewsTabView` un chip indicador de filtro activo (`Key('news_active_filter_chip')`) únicamente cuando exista una categoría de filtro distinta de "Todas", mostrando el nombre localizado de la categoría y un botón para eliminar el filtro.
- **FR-011**: Al pulsar el botón de eliminación en `news_active_filter_chip`, el sistema DEBE restablecer de inmediato el filtro a "Todas" y actualizar el feed reactivamente.
- **FR-012**: En el flujo de "Publicar Noticia" desde el panel de control del organizador (`OrganizerPanelContent`), el formulario `CreateNewsDialog` DEBE integrar un selector desplegable de competición destino que liste exclusivamente los torneos editables (excluyendo aquellos en estado `TournamentStatus.finished`), preseleccionando el torneo activo actual si es editable y permitiendo al organizador completar la asignación y publicación en un único paso.
- **FR-013**: Todos los textos visibles, etiquetas de accesibilidad y opciones de filtrado DEBEN estar centralizados en español en `lib/l10n/app_es.arb`.
- **FR-014**: Toda la lógica técnica, identificadores, providers y pruebas DEBEN estar redactados en inglés conforme a la Constitución del proyecto.

---

### Key Entities *(include if feature involves data)*

- **TournamentNewsItem**: Entidad inmutable que representa un comunicado oficial o noticia (`id`, `tournamentId`, `title`, `content`, `category`, `publishedAt`, `authorUserId`, `authorName`, `isPinned`).
- **TournamentNewsCategory**: Enumeración de categorías de comunicados (`general`, `officialStatement`, `disciplinarySanctions`, `matchdayResults`, `rulesUpdate`).
- **ChampionshipTournament**: Entidad inmutable del torneo al que pertenecen los comunicados (`id`, `name`, `status`, etc.).
- **AppShellSection**: Enumeración de secciones principales de navegación (`matches`, `news`, `profile`, `explore`).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Los usuarios con rol no administrativo (o administradores en modo lectura) experimentan un feed de noticias 100% libre de controles de creación y edición directa.
- **SC-002**: Un organizador puede iniciar el flujo de publicación de una noticia desde `/panel` y completar la publicación en menos de 30 segundos.
- **SC-003**: El cambio de filtro de torneo o categoría desde el menú de tres puntos actualiza el listado visible de comunicados en menos de 100 milisegundos tras la selección.
- **SC-004**: El restablecimiento del filtro activo mediante un toque en el chip indicador toma menos de 1 segundo y devuelve la visualización completa del feed sin recargar la pantalla.
- **SC-005**: 100% de cumplimiento con accesibilidad móvil (touch targets $\ge 48\times 48\text{ dp}$, soporte para lectores de pantalla y cero desbordamientos `RenderFlex` a $320 \times 640\text{ px}$ con 130% text scaling).

---

## Assumptions

- Se asume que el usuario organizador autenticado cuenta con los permisos necesarios para publicar en los torneos activos existentes en el catálogo.
- Se asume que si no hay torneos registrados, la acción rápida de publicar noticias en el panel informará al organizador de la necesidad de crear un torneo primero.
- Se asume que la campana de notificaciones del aficionado (`FanAlertsBellAction`) en el `AppBar` permanece intacta y el botón `more_vert` se ubica de forma contigua a ella.
- Se asume que la categorización de noticias utiliza la entidad `TournamentNewsCategory` ya establecida en el dominio.
