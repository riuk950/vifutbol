# Feature Specification: Reestructuración del Navigation Bar Inferior (Partidos por Fecha, Explorar, Noticias y Perfil)

**Feature Branch**: `[013-restructure-bottom-navigation]`

**Created**: 2026-11-05

**Status**: Draft

**Input**: User description: "[Épica 10] HU 10.1: Reestructuración del Navigation Bar Inferior (Partidos por Fecha, Explorar, Noticias y Perfil)"

## Clarifications

### Session 2026-11-05

- Q: ¿Cómo debe funcionar el filtrado por fecha en la primera pestaña **"Partidos"** al reemplazar la antigua vista de *"Jornada"*? → A: Exclusivamente selector de días calendario (`Hoy`, `Mañana`, fechas específicas), mostrando los partidos programados para la fecha calendario seleccionada (y los partidos `"En Juego"` destacados arriba con `"EN VIVO"`), ocultando los partidos que aún no tengan fecha/hora asignada.
- Q: Dado que la lista principal por días calendario en **"Partidos"** oculta los encuentros sin fecha/hora asignada, ¿cómo debe gestionar el rol **Organizador** los partidos recién generados que están en estado *"Por programar"*? → A: Mostrar exclusivamente para el rol `Organizador` un acceso o sección dedicada `"Por programar (N)"` en **"Partidos"** cuando existan encuentros sin fecha/hora asignada (oculto para los demás roles), de modo que al programar un partido pase automáticamente a su día calendario correspondiente.
- Q: Al separar **"Noticias"** como tercera pestaña independiente en la barra inferior junto a **"Partidos"** y **"Explorar"**, ¿cómo debe sincronizarse el campeonato activo cuando existen múltiples torneos registrados? → A: Sincronizar globalmente el campeonato seleccionado entre **"Partidos"**, **"Explorar"** y **"Noticias"**, mostrando además el selector de campeonato en **"Partidos"** y **"Noticias"** cuando existan múltiples torneos para permitir cambiarlo desde cualquiera de ellas.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Navegación Inferior Unificada con 4 Destinos para Todos los Roles (Priority: P1)

Como usuario autenticado o invitado en cualquiera de los cinco roles del ecosistema (`Organizador`, `Árbitro`, `Entrenador / Capitán`, `Jugador` o `Aficionado`), quiero contar con una barra de navegación inferior estructurada exactamente con los cuatro destinos **Partidos**, **Explorar**, **Noticias** y **Perfil**, eliminando la pestaña **"Sedes"** de la barra inferior, para acceder de forma directa y consistente a las funciones principales del campeonato desde el primer nivel de navegación.

**Why this priority**: Es la base estructural de navegación de toda la aplicación móvil; todos los flujos de usuario dependen de la barra inferior principal y su consistencia visual entre roles.

**Independent Test**: Iniciar sesión con cada uno de los cinco roles (`Organizador`, `Árbitro`, `Entrenador / Capitán`, `Jugador` y `Aficionado`), verificar que la barra de navegación inferior muestra exactamente los cuatro destinos en el orden **"Partidos"**, **"Explorar"**, **"Noticias"** y **"Perfil"**, que **"Sedes"** no aparece en la barra inferior y que el destino activo se resalta con el color de acento primario.

**Acceptance Scenarios**:

1. **Given** que un usuario con cualquiera de los roles (`Organizador`, `Árbitro`, `Entrenador / Capitán`, `Jugador` o `Aficionado`) se encuentra en la pantalla principal, **When** visualiza la barra de navegación inferior, **Then** se muestran exactamente 4 destinos en el orden: **"Partidos"**, **"Explorar"**, **"Noticias"** y **"Perfil"**, con iconografía semántica diferenciada y sin la opción **"Sedes"**.
2. **Given** que el usuario navega entre las pestañas de la barra inferior, **When** selecciona cualquiera de los 4 destinos, **Then** el destino activo se resalta visualmente con el color primario de acento y se conserva el estado de desplazamiento y filtros de las demás pestañas sin recargas innecesarias.

---

### User Story 2 - Pestaña Exclusiva de Partidos por Fecha sin Sub-pestaña de Noticias (Priority: P1)

Como usuario de la aplicación, quiero que la primera pestaña **"Partidos"** (que reemplaza a *"Jornada"*) muestre exclusivamente los encuentros programados filtrados para la fecha calendario seleccionada (`Hoy`, `Mañana`, fechas específicas) y los partidos en curso destacados en la parte superior, ocultando los partidos sin fecha/hora asignada en la vista de días calendario (y ofreciendo exclusivamente al `Organizador` un acceso o sección dedicada `"Por programar (N)"` para asignar fecha y hora) y retirando el control segmentado interno de noticias, para consultar la agenda deportiva diaria con menor fricción visual.

**Why this priority**: Simplifica la pantalla principal de entrada centrándola en la agenda por día calendario y eliminando la navegación anidada redundante (sub-pestaña segmentada) ahora que Noticias pasa a ser una pestaña de primer nivel.

**Independent Test**: Abrir la pestaña **"Partidos"**, verificar que el encabezado muestra **"Partidos"**, que los partidos en estado **"En Juego"** se destacan en la sección superior **"EN VIVO"**, que el selector filtra exclusivamente por días calendario (`Hoy`, `Mañana`, fechas específicas) mostrando solo partidos con fecha/hora asignada para ese día, que el `Organizador` dispone de un acceso o sección `"Por programar (N)"` cuando existen encuentros sin fecha/hora asignada (oculto para otros roles), y que ya no existe el botón segmentado interno de alternancia entre *"Partidos"* y *"Noticias"*.

**Acceptance Scenarios**:

1. **Given** que el usuario se encuentra en la pantalla principal, **When** selecciona o inicia en la primera pestaña **"Partidos"**, **Then** se muestra exclusivamente la vista de encuentros con los partidos **"En Juego"** destacados arriba con el indicador **"EN VIVO"** y la lista de partidos con fecha/hora programada que coinciden con la fecha calendario seleccionada.
2. **Given** que existen partidos en estado *"Por programar"* sin fecha ni hora asignada, **When** un usuario de rol distinto a `Organizador` visualiza **"Partidos"**, **Then** dichos partidos sin fecha/hora no se muestran en la lista de días calendario; y **When** el usuario tiene rol `Organizador`, **Then** visualiza un acceso o sección dedicada `"Por programar (N)"` desde donde puede asignar fecha, hora, sede/cancha y árbitro, pasando el partido automáticamente a su día calendario correspondiente.
3. **Given** que el usuario visualiza la pestaña **"Partidos"**, **When** inspecciona los controles superiores de la vista, **Then** no se muestra ningún selector segmentado interno para cambiar a *"Noticias"*.

---

### User Story 3 - Pestaña de Primer Nivel para Noticias y Renombrado de Explorar (Priority: P2)

Como usuario de la aplicación, quiero acceder directamente al feed de **"Noticias"** desde la tercera posición de la barra de navegación inferior y contar con la segunda pestaña renombrada a **"Explorar"** (antes *"Posiciones"*) y la cuarta como **"Perfil"**, para consultar comunicados oficiales con sus filtros de categoría sin depender de la pestaña de partidos y explorar las clasificaciones, llaves, cuadro de honor y estadísticas del campeonato.

**Why this priority**: Eleva la visibilidad de los comunicados oficiales del torneo a primer nivel y alinea la nomenclatura de **"Explorar"** con su contenido integral (tablas, llaves, equipos, cuadro de honor y rankings).

**Independent Test**: Tocar la segunda pestaña **"Explorar"** y comprobar que despliega las tablas de posiciones, llaves eliminatorias, cuadro de honor y rankings; luego tocar la tercera pestaña **"Noticias"** y verificar que muestra el feed de comunicados con filtros por categoría (*General*, *Reprogramación*, *Disciplinario*) y controles de publicación/eliminación exclusivos para el `Organizador` (respetando el modo de solo lectura histórica en torneos finalizados); finalmente tocar **"Perfil"** y verificar que conserva su funcionalidad intacta.

**Acceptance Scenarios**:

1. **Given** que el usuario se encuentra en la pantalla principal, **When** toca la segunda pestaña **"Explorar"**, **Then** la barra inferior marca **"Explorar"** como sección activa y despliega la vista de exploración con tablas de clasificación, llaves eliminatorias, cuadro de honor y estadísticas del campeonato.
2. **Given** que el usuario se encuentra en cualquier pestaña de la pantalla principal, **When** toca la tercera pestaña **"Noticias"**, **Then** se muestra directamente la vista del feed de noticias y comunicados del campeonato seleccionado con filtrado por categorías (*Todos*, *General*, *Reprogramación*, *Disciplinario*) sin pasar por la pestaña **"Partidos"**.
3. **Given** que el usuario toca la cuarta pestaña **"Perfil"**, **When** se activa la vista, **Then** se muestra la pantalla de perfil con su rol activo, ajustes de sesión y opciones correspondientes sin alteraciones funcionales.

---

### Edge Cases

- **Campeonatos sin partidos o sin noticias publicadas**: Tanto la pestaña **"Partidos"** como la pestaña **"Noticias"** deben mostrar sus respectivos estados vacíos informativos en español sin errores visuales ni controles huérfanos.
- **Campeonato en estado Finalizado (Modo Histórico)**: En la nueva pestaña independiente **"Noticias"**, si el campeonato activo está en estado `Finalizado`, se debe seguir mostrando el distintivo de solo lectura histórica y ocultar las acciones de creación y eliminación de comunicados para el `Organizador`.
- **Sincronización del campeonato activo entre pestañas**: Cuando existen múltiples campeonatos registrados, el campeonato seleccionado se sincroniza globalmente entre **"Partidos"**, **"Explorar"** y **"Noticias"**; cambiar el campeonato activo desde cualquiera de las tres pestañas actualiza automáticamente el contexto para las demás.
- **Pantallas estrechas (320px) y escalado de fuente al 130%**: Las 4 etiquetas de la barra de navegación inferior (**"Partidos"**, **"Explorar"**, **"Noticias"**, **"Perfil"**) y los encabezados de cada pestaña deben adaptarse sin truncamiento ilegible ni desbordamientos visuales.
- **Interrupciones de ciclo de vida y cambio de pestaña**: Al alternar entre las 4 pestañas o pasar la aplicación a segundo plano y regresar, se debe conservar la pestaña seleccionada, la posición de desplazamiento (*scroll*) y los filtros activos (fecha/jornada en **Partidos**, modo de vista en **Explorar**, categoría en **Noticias**).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE estructurar la barra de navegación inferior principal con exactamente 4 destinos en el siguiente orden fijo para los 5 roles del sistema (`Organizador`, `Entrenador / Capitán`, `Árbitro`, `Jugador` y `Aficionado`):
  1. **Partidos** (ícono semántico de balón de fútbol)
  2. **Explorar** (ícono semántico de exploración/clasificación deportiva)
  3. **Noticias** (ícono semántico de periódico/comunicados)
  4. **Perfil** (ícono semántico de perfil de usuario)
- **FR-002**: El sistema DEBE retirar el destino **"Sedes"** de la barra de navegación inferior para todos los roles, manteniendo intactos los datos y repositorios de sedes para su uso en programación de partidos y futuros accesos secundarios (como el menú lateral de directorio).
- **FR-003**: El sistema DEBE resaltar el destino activo en la barra de navegación inferior utilizando el color primario de acento del sistema de diseño y garantizar áreas táctiles mínimas de `48x48dp` (`>= 44x44px`) en cada destino.
- **FR-004**: La primera pestaña **"Partidos"** DEBE mostrar el título localizado **"Partidos"**, la sección destacada de partidos **"En Juego"** con el indicador **"EN VIVO"**, un selector exclusivo de días calendario (`Hoy`, `Mañana`, fechas específicas) y la lista de encuentros con fecha/hora programada para ese día, ocultando los partidos sin fecha/hora asignada en la vista por fecha (mostrando exclusivamente para el rol `Organizador` un acceso o sección dedicada `"Por programar (N)"` cuando existan encuentros sin fecha/hora asignada para permitir su programación) y eliminando por completo el selector segmentado interno que alternaba entre *"Partidos"* y *"Noticias"*.
- **FR-005**: La segunda pestaña **"Explorar"** DEBE reemplazar la etiqueta *"Posiciones"* en la barra de navegación inferior, conservando íntegramente las capacidades de gestión y consulta de campeonatos, reglas, equipos, cuadro de honor oficial, tablas de posiciones, llaves eliminatorias y rankings individuales/colectivos.
- **FR-006**: La tercera pestaña **"Noticias"** DEBE presentar como vista principal de primer nivel el feed de noticias y comunicados oficiales del campeonato activo sincronizado globalmente con **"Partidos"** y **"Explorar"**, incluyendo selector de campeonato (cuando existan múltiples torneos), barra de filtros por categoría (*Todos*, *General*, *Reprogramación*, *Disciplinario*), publicación/eliminación de noticias para el rol `Organizador` y respeto del modo de solo lectura histórica cuando el campeonato esté `Finalizado`.
- **FR-007**: La cuarta pestaña **"Perfil"** DEBE mantenerse en la cuarta posición de la barra de navegación inferior conservando todas sus capacidades de visualización de usuario, cambio/gestión de rol activo y cierre de sesión.
- **FR-008**: El contenedor principal de navegación DEBE preservar en memoria el estado de las 4 vistas (**Partidos**, **Explorar**, **Noticias** y **Perfil**) al alternar entre pestañas o al reanudar la aplicación desde segundo plano, evitando pérdidas de posición de desplazamiento o reinicio de filtros seleccionados.
- **FR-009**: Todos los textos visibles, etiquetas de pestañas (`"Partidos"`, `"Explorar"`, `"Noticias"`, `"Perfil"`) y encabezados de sección DEBEN estar 100% en español y gestionarse mediante el sistema centralizado de localización (`l10n`), manteniendo todos los identificadores técnicos de código en inglés.

### Key Entities *(include if feature involves data)*

- **Sección de Navegación Principal**: Representa los cuatro destinos de primer nivel de la barra inferior (*Partidos*, *Explorar*, *Noticias*, *Perfil*), determinando la vista activa y la posición seleccionada en el contenedor principal.
- **Estado de Navegación Principal**: Mantiene la sección activa seleccionada por el usuario y preserva la coherencia de navegación y el contexto del campeonato activo durante el ciclo de vida de la sesión.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de los roles del sistema (`Organizador`, `Entrenador / Capitán`, `Árbitro`, `Jugador`, `Aficionado`) visualizan exactamente los 4 destinos (**"Partidos"**, **"Explorar"**, **"Noticias"**, **"Perfil"**) en la barra inferior y 0 instancias del destino **"Sedes"** en dicha barra.
- **SC-002**: Los usuarios pueden acceder al feed de **"Noticias"** en 1 solo toque directo desde la barra de navegación inferior (reduciendo de 2 pasos a 1 paso respecto al selector segmentado anterior).
- **SC-003**: El cambio entre las 4 pestañas principales conserva el 100% de los filtros activos y posición de desplazamiento en memoria de forma inmediata (menos de 100ms de transición visual sin parpadeos ni recargas de red/almacenamiento).
- **SC-004**: Cero desbordamientos visuales o recortes de texto en resoluciones móviles de `320x640` píxeles lógicos con escalado tipográfico del sistema al `130%` en las 4 pestañas y en la barra de navegación inferior.

## Assumptions

- La gestión y catálogo de sedes deportivas se mantienen intactos en el sistema sin eliminarse destructivamente, ya que las sedes siguen utilizándose en la programación de partidos (HU 6.1) y podrán ser consultadas desde accesos secundarios en futuras historias de la Épica 10.
- El campeonato seleccionado se sincroniza globalmente entre las pestañas **"Partidos"**, **"Explorar"** y **"Noticias"**, mostrando el selector de campeonato en **"Partidos"** y **"Noticias"** cuando existan múltiples torneos registrados.
- La selección por fecha en la pestaña **"Partidos"** corresponde a un selector horizontal de días calendario (`Hoy`, `Mañana` y las fechas calendario en las que existan partidos programados), filtrando exclusivamente por el día calendario seleccionado (`scheduledStartTime`).
