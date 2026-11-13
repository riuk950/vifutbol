# Feature Specification: Directorio de Equipos: Remoción de Filter Chips y Carga Dinámica desde la Nube (HU 19.2)

**Feature Branch**: `040-teams-directory-cloud-sync`

**Created**: 2026-11-13

**Status**: Draft

**Input**: User description: "Notion HU 19.2: Directorio de Equipos: Remoción de Filter Chips y Carga Dinámica desde Supabase Cloud (vifutboldev)"

## Clarifications

### Session 2026-11-13

- Q: How should the Teams Directory represent clubs that are not yet enrolled in any tournament or that participate in multiple tournaments simultaneously? → A: Show every unique club from the global `teams` catalog once (including clubs without a tournament), consolidating total registered players across enrollments.
- Q: What should the team card display for category when a club is not enrolled in any tournament or participates in multiple tournaments? → A: Show tournament category if in 1 tournament, a consolidated label (e.g., "Múltiples torneos") if in several, or "Sin torneo asignado" if not enrolled.
- Q: What should happen when a user taps a club card in the Teams Directory, particularly for a club that has no tournament enrollment yet? → A: Always open the team detail view on tap, showing basic club info and empty states when the club has no tournament enrollment yet.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Remoción de Filter Chips Horizontales y Vista Centralizada (Priority: P1)

Como usuario de la plataforma que ingresa al Directorio de Equipos, quiero que la interfaz elimine los chips horizontales de filtro por torneo y despliegue directamente la lista de clubes inmediatamente debajo de la barra de búsqueda, para explorar todo el catálogo global de equipos sin pasos intermedios ni desperdicio de espacio vertical.

**Why this priority**: Limpia la experiencia de navegación en el directorio de equipos y alinea la pantalla con la visión de catálogo unificado de clubes del ecosistema.

**Independent Test**: Abrir la pantalla del Directorio de Equipos y verificar que no existe ninguna barra o lista horizontal de chips de selección de torneo, y que la lista de tarjetas de clubes aparece inmediatamente debajo del campo de búsqueda.

**Acceptance Scenarios**:

1. **Given** que el usuario abre la pantalla de "Directorio de Equipos", **When** se dibuja la interfaz, **Then** no se muestra ningún selector horizontal ni chips de filtro por torneo.
2. **Given** que la pantalla de "Directorio de Equipos" ha cargado, **When** el usuario observa la parte superior, **Then** la barra de búsqueda ocupa la cabecera y la lista de tarjetas de equipos se despliega inmediatamente debajo de ella.

---

### User Story 2 - Carga Dinámica de Equipos desde la Nube con Caché Local y Pull-to-Refresh (Priority: P1)

Como usuario de la plataforma, quiero que el Directorio de Equipos obtenga y sincronice dinámicamente el catálogo global de clubes desde el servidor central en la nube, mostrando cada club de forma única con su nombre, escudo, categoría y cantidad de jugadores registrados, y que permita actualizar manualmente la lista o consultarla sin conexión mediante caché local.

**Why this priority**: Garantiza que los clubes recién creados por entrenadores se visualicen de inmediato sin requerir inscripción previa en un torneo, manteniendo soporte Offline-First en canchas con conectividad intermitente.

**Independent Test**: Consultar el directorio con conexión a internet verificando la llegada de los clubes actualizados desde la nube; activar modo avión y reabrir el directorio comprobando que los clubes previamente cacheados siguen visibles; deslizar hacia abajo para refrescar sin conexión y confirmar que el listado se mantiene intacto con una notificación discreta de falta de conexión.

**Acceptance Scenarios**:

1. **Given** que el dispositivo cuenta con conexión a internet en el entorno de trabajo, **When** el usuario abre o actualiza el "Directorio de Equipos", **Then** el sistema consulta el catálogo global de clubes en la nube, muestra cada equipo único con su nombre, escudo, categoría y cantidad de jugadores registrados, y actualiza la copia local del dispositivo.
2. **Given** que el usuario abre el "Directorio de Equipos" sin conexión a internet pero con datos consultados previamente, **When** se carga la pantalla, **Then** se muestran los equipos almacenados en la caché local sin errores bloqueantes ni pantalla en blanco.
3. **Given** que el usuario visualiza equipos cacheados en modo sin conexión, **When** realiza el gesto de deslizar hacia abajo (Pull-to-Refresh) para actualizar, **Then** el sistema conserva los equipos visibles en pantalla y muestra una advertencia informativa no intrusiva indicando que no se pudo actualizar por falta de conexión.

---

### User Story 3 - Búsqueda Instantánea de Clubes y Ordenamiento Alfabético (Priority: P2)

Como usuario de la plataforma, quiero buscar clubes de forma instantánea escribiendo en el buscador y visualizar los resultados ordenados alfabéticamente por nombre, para encontrar rápidamente cualquier equipo dentro del catálogo global.

**Why this priority**: Al retirar los filtros por torneo, el buscador reactivo y el ordenamiento consistente se convierten en las herramientas principales para localizar clubes en un directorio global creciente.

**Independent Test**: Ingresar términos parciales, en minúsculas o sin tildes en la barra de búsqueda y verificar el filtrado inmediato por nombre del club (y código corto si aplica), comprobando que cuando el buscador está vacío los clubes aparecen ordenados alfabéticamente (A-Z).

**Acceptance Scenarios**:

1. **Given** que el usuario visualiza el "Directorio de Equipos" con el buscador vacío, **When** se presenta la lista, **Then** los clubes aparecen ordenados alfabéticamente de la A a la Z por nombre del equipo.
2. **Given** que el usuario ingresa texto en la barra de búsqueda (por ejemplo, parte del nombre del club o su sigla), **When** el buscador procesa la consulta (insensible a mayúsculas y tildes), **Then** la lista se filtra de inmediato mostrando únicamente los clubes coincidentes.
3. **Given** que una búsqueda no produce coincidencias, **When** se actualiza la vista, **Then** se muestra un estado vacío claro indicando que no hay equipos para esa búsqueda, manteniendo disponible el gesto de actualizar.

---

### Edge Cases

- ¿Qué ocurre si un club fue creado por un entrenador pero aún no está inscrito en ningún torneo? Debe aparecer igualmente en el Directorio de Equipos gracias a la carga directa desde el catálogo global de clubes.
- ¿Qué ocurre si un club participa en múltiples torneos simultáneamente? Debe mostrarse una única vez en el directorio (unicidad de equipos) con su información consolidada.
- ¿Qué ocurre si un club no tiene escudo cargado o no tiene jugadores registrados aún? Se muestra un avatar/escudo de respaldo consistente y el contador en 0 jugadores sin provocar errores visuales.
- ¿Qué ocurre si no existen clubes en la nube ni en la caché local? Se muestra una pantalla de estado vacío informativa y amigable.
- ¿Qué ocurre si el usuario rota la pantalla o utiliza escalado de texto elevado? La cabecera de búsqueda y las tarjetas de clubes deben adaptarse sin desbordamientos ni recortes de texto.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema MUST eliminar por completo la barra o lista horizontal de chips de filtro por torneo de la pantalla del Directorio de Equipos.
- **FR-002**: La pantalla del Directorio de Equipos MUST ubicar el campo de búsqueda en la parte superior y desplegar el listado de clubes inmediatamente debajo de él.
- **FR-003**: El sistema MUST consultar dinámicamente el catálogo global de clubes desde la fuente remota en la nube al inicializar o refrescar el Directorio de Equipos.
- **FR-004**: El directorio MUST garantizar la unicidad de los equipos mostrados, presentando cada club del catálogo global (`teams`) una sola vez —incluyendo clubes recién creados sin inscripción en ningún torneo— y consolidando el total de jugadores registrados entre sus inscripciones activas.
- **FR-005**: Cada tarjeta de equipo en el directorio MUST mostrar el nombre del club, su escudo (o marcador visual por defecto), la cantidad de jugadores registrados y su categoría (mostrando la categoría/torneo si tiene una inscripción, un resumen consolidado si participa en múltiples torneos, o "Sin torneo asignado" si aún no está inscrito).
- **FR-006**: Cada consulta exitosa al servidor remoto MUST sincronizar y persistir los equipos obtenidos en la caché local del dispositivo para soportar operación sin conexión (Offline-First).
- **FR-007**: Ante ausencia de conexión o fallo de red en la carga inicial, el sistema MUST servir automáticamente los equipos desde la caché local si existen datos previos.
- **FR-008**: La lista de clubes (incluyendo el estado vacío tras búsqueda) MUST soportar actualización manual mediante gesto de deslizar hacia abajo (Pull-to-Refresh). Si falla por falta de red, MUST conservar los datos visibles y mostrar una advertencia discreta al usuario en español.
- **FR-009**: El directorio MUST ordenar los clubes alfabéticamente (A-Z) por nombre de equipo de forma predeterminada.
- **FR-010**: La barra de búsqueda MUST filtrar en tiempo real los clubes por nombre del equipo (y código corto/categoría) de manera insensible a mayúsculas, minúsculas y tildes.
- **FR-011**: El sistema MUST respetar las restricciones de acceso por rol existentes para acciones de creación o gestión desde el directorio, permitir navegar a la vista de detalle al tocar cualquier club (mostrando su resumen básico y estados vacíos si aún no pertenece a ningún torneo) y cubrir explícitamente los estados visuales de carga, contenido, vacío y error.

### Key Entities

- **Equipo / Club (Team Directory Item)**: Representa un club único del ecosistema deportivo, con identificador único, nombre oficial, código corto, URL o referencia de escudo, categoría, estado de elegibilidad/aprobación y conteo de jugadores registrados.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 0% de presencia de chips o selectores horizontales de torneos en la pantalla del Directorio de Equipos, liberando el área superior exclusivamente para el buscador y el listado.
- **SC-002**: 100% de los clubes únicos registrados en la nube (incluidos los recién creados por entrenadores sin torneo asignado) se visualizan en el directorio tras abrir o refrescar la vista con conexión.
- **SC-003**: El directorio responde y renderiza los clubes almacenados localmente en menos de 1 segundo cuando el dispositivo inicia sin conexión tras una sincronización previa.
- **SC-004**: El filtrado por texto en el buscador actualiza los resultados visibles de forma fluida (en menos de 500 ms tras finalizar la escritura) soportando búsquedas sin tildes ni distinción de mayúsculas.
- **SC-005**: 100% de las pruebas automatizadas de unidad y de interfaz para el directorio de equipos y su repositorio pasan sin errores ni advertencias de análisis estático.

## Assumptions

- Se asume que el comportamiento de actualización manual (Pull-to-Refresh) y manejo de error sin conexión sigue el mismo estándar establecido en la épica (HU 19.1): conservar los datos cacheados en pantalla y mostrar una notificación discreta (`SnackBar`) en español.
- Se asume el ordenamiento alfabético ascendente (A-Z) por nombre de equipo como orden predeterminado al eliminar el agrupamiento por torneo.
- Se asume que los textos visibles de interfaz permanecen en español mediante el sistema de localización del proyecto y que el código técnico se mantiene en inglés conforme a la Constitución.
- Se asume que la navegación al detalle del equipo al tocar una tarjeta se mantiene intacta para consultar el resumen, partidos y plantilla del club seleccionado.
