# Feature Specification: HU 3.1 — Gestión de Sedes, Canchas Urbanas y Geolocalización Deportiva

**Feature Branch**: `003-venues-pitches-geolocation`

**Created**: 2026-11-03

**Status**: Draft

**Input**: User description: "de notion HU 3.1. en curso: [Épica 3] HU 3.1: Gestión de Sedes, Canchas Urbanas y Geolocalización Deportiva"

## Clarifications

### Session 2026-11-03

- Q: ¿Cómo debe funcionar la vista de mapa urbano y la selección de coordenadas en la sección *Sedes*? → A: Lienzo interactivo *KickPulse Urban Map* (Offline-ready) (mapa visual táctico/urbano integrado con marcadores interactivos por sede, selección de coordenadas por toque o campos numéricos para el `Organizador`, cálculo geodésico de distancia en km mediante Haversine con `tabular-nums` y resumen/copia de indicaciones de llegada sin depender de llaves de API externas).
- Q: ¿Cómo debe solicitarse el permiso de localización del dispositivo y cómo se validarán sus estados (concedido, rechazado o revocado) durante el uso y las pruebas? → A: Solicitud *just-in-time* + alternativa resiliente + simulador de permisos en `dev` (pide permiso en contexto al pulsar ubicación/cercanía; ante rechazo o revocación muestra el mapa centrado en la ciudad/sede y el listado completo con aviso discreto en español sin bloqueos; y en `dev` permite alternar los estados de permiso de ubicación para validar todos los escenarios).
- Q: ¿Qué debe ocurrir cuando el `Organizador` desactiva una sede o cancha, y cómo debe inicializarse el catálogo de sedes en el entorno de desarrollo? → A: Baja lógica (*Activa* / *Mantenimiento*) + catálogo semilla en `dev` (las sedes y canchas nunca se eliminan físicamente; al desactivarse pasan a estado *Mantenimiento* con insignia de advertencia quedando bloqueadas para nuevas asignaciones de partidos; y en `vifutbol_dev` se precargan 3 sedes urbanas con múltiples canchas).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Creación, Edición y Gestión de Sedes y Canchas por el Organizador (Priority: P1)

Como `Organizador` del campeonato, quiero registrar, editar y administrar el estado operativo de las sedes deportivas urbanas junto con sus canchas internas (nombre de la cancha, tipo de superficie, formato de juego, capacidad e iluminación nocturna), definiendo su dirección física, referencia urbana y coordenadas geográficas válidas, para disponer de un catálogo oficial de canchas verificadas que puedan asignarse a los partidos del calendario.

**Why this priority**: Es el cimiento operativo de la Épica 3; sin sedes y canchas válidas registradas por el organizador, no es posible programar jornadas ni orientar a los participantes hacia el lugar de cada encuentro.

**Independent Test**: Puede probarse de forma independiente iniciando sesión con el rol `Organizador`, accediendo a la pestaña *Sedes*, creando una nueva sede deportiva con su dirección, coordenadas válidas y al menos una cancha interna configurada, verificando la prevención de envíos duplicados, la validación de campos en español y que los demás roles (`Entrenador`, `Árbitro`, `Jugador`, `Aficionado`) tengan bloqueadas las acciones de creación, edición o desactivación.

**Acceptance Scenarios**:

1. **Given** que un usuario con rol activo `Organizador` accede a la sección de *Sedes*, **When** completa el formulario de nueva sede ingresando nombre, dirección física, referencia urbana, coordenadas válidas (latitud entre `-90` y `90`, longitud entre `-180` y `180`) y agrega al menos una cancha interna (con nombre, superficie, capacidad e indicador de iluminación) y confirma el guardado, **Then** el botón entra en estado de carga bloqueando pulsaciones repetidas, el sistema persiste la sede con sus canchas y la muestra inmediatamente en el catálogo activo.
2. **Given** que un `Organizador` intenta guardar una sede sin canchas asociadas o con coordenadas fuera de rango geográfico válido, **When** presiona guardar, **Then** el sistema impide el registro, destaca los campos con mensajes de validación claros en español y conserva intactos todos los datos ya ingresados en el formulario.
3. **Given** que un `Organizador` edita los datos de una sede existente o cambia el estado de disponibilidad de una cancha (activa o en mantenimiento/inactiva), **When** confirma la actualización, **Then** los cambios se reflejan de inmediato en el detalle de la sede y solo las canchas activas quedan habilitadas para futuras asignaciones de partidos.
4. **Given** que un usuario opera con cualquier rol distinto a `Organizador` (`Entrenador`, `Árbitro`, `Jugador` o `Aficionado`), **When** navega por la sección *Sedes*, **Then** visualiza el catálogo y detalle de sedes en modo de consulta pública y los controles administrativos de crear, editar o desactivar sedes/canchas permanecen ocultos o protegidos por la guarda de control de acceso.

---

### User Story 2 - Consulta Geolocalizada de Sedes, Cálculo de Distancia y Manejo Resiliente de Permisos Móviles (Priority: P1)

Como `Jugador`, `Árbitro`, `Entrenador` o `Aficionado`, quiero explorar el directorio y vista geográfica de las sedes del campeonato, visualizar las canchas internas de cada sede, conocer la distancia aproximada desde mi ubicación actual cuando concedo el permiso de localización y contar con una experiencia completa y sin bloqueos incluso si rechazo o revoco el permiso de ubicación del dispositivo, para ubicar con rapidez el complejo deportivo donde se disputará cada partido.

**Why this priority**: Resuelve la necesidad principal de movilidad urbana de todos los actores del torneo y garantiza el cumplimiento de las directrices móviles (`docs/MOBILE_GUIDELINES.md`) frente a permisos de ubicación concedidos, denegados o revocados.

**Independent Test**: Puede probarse consultando la pestaña *Sedes* bajo dos condiciones simuladas del permiso de localización del dispositivo: (a) con permiso concedido, comprobando que se calcula y muestra la distancia aproximada en kilómetros y la opción de indicaciones; y (b) con permiso rechazado o revocado, comprobando que la vista se mantiene centrada en las coordenadas de la sede/ciudad sin errores ni bloqueos, mostrando dirección completa, referencia urbana y un aviso no intrusivo para habilitar la ubicación si el usuario lo desea.

**Acceptance Scenarios**:

1. **Given** que cualquier usuario consulta el listado o detalle de una sede deportiva por primera vez y pulsa la acción de ubicación cercana, **When** el sistema solicita el permiso de localización en contexto (*just-in-time*) y el usuario lo concede, **Then** la interfaz muestra la posición de la sede junto con la distancia aproximada desde la ubicación del usuario y habilita la acción para consultar indicaciones de llegada.
2. **Given** que un usuario rechaza el permiso de localización o lo tiene revocado en los ajustes del sistema operativo, **When** abre la sección *Sedes* o el detalle de una cancha, **Then** la aplicación NO se bloquea ni muestra pantallas de error fatales; en su lugar, centra la vista geográfica por defecto en la sede o ciudad del campeonato, muestra el listado completo con dirección física, referencia urbana y características de cada cancha, e incluye un acceso discreto y no intrusivo en español para activar la ubicación cuando lo desee.
3. **Given** que un usuario selecciona una sede del catálogo o pulsa su marcador en la vista geográfica, **When** se abre la ficha de detalle de la sede, **Then** visualiza el nombre del complejo, dirección urbana, referencia de llegada, coordenadas, estado operativo y el desglose de todas sus canchas internas (nombre, tipo de superficie como césped sintético/natural/ tierra, dimensiones/formato, aforo e iluminación).

---

### User Story 3 - Disponibilidad Offline del Directorio de Sedes y Conservación de Estado en Campo (Priority: P2)

Como participante que se desplaza hacia una sede deportiva en zonas con cobertura móvil intermitente o sin conexión a internet, quiero consultar el listado de sedes, sus direcciones urbanas, referencias de llegada y el detalle de sus canchas internas desde el almacenamiento local del dispositivo, así como conservar mis borradores de formulario o filtros activos si la aplicación pasa a segundo plano, para no perder la orientación ni el trabajo en curso.

**Why this priority**: Muchos complejos deportivos periféricos presentan señal débil; asegurar que las sedes y direcciones estén disponibles sin conexión evita que jugadores, árbitros o aficionados pierdan la referencia del lugar del partido en tránsito.

**Independent Test**: Puede probarse cargando o registrando sedes con conexión activa, desconectando la red del dispositivo y navegando por la pestaña *Sedes* y el detalle de cada cancha para verificar la lectura 100% offline desde caché local sin errores bloqueantes.

**Acceptance Scenarios**:

1. **Given** que las sedes del campeonato han sido consultadas o registradas previamente en el dispositivo, **When** el usuario accede a la pestaña *Sedes* sin conexión a internet (*offline*), **Then** el sistema carga en menos de `2` segundos el catálogo completo de sedes, direcciones urbanas, coordenadas y canchas internas desde el almacenamiento local aislado del entorno activo.
2. **Given** que un `Organizador` está completando el formulario de creación o edición de una sede y la aplicación pasa a segundo plano por una llamada o cambio de aplicación, **When** regresa a primer plano, **Then** el sistema conserva el borrador con los campos ingresados (nombre, dirección, coordenadas y canchas agregadas temporalmente) sin reiniciar el formulario.
3. **Given** que aún no existen sedes registradas en el campeonato activo, **When** cualquier usuario abre la pestaña *Sedes*, **Then** el sistema presenta el estado vacío estandarizado en español (*"Aún no hay sedes registradas"*) y, si el usuario tiene el rol `Organizador`, muestra la acción directa para registrar la primera sede.

---

### Edge Cases

- **Salida accidental con cambios sin guardar en el formulario de sede**: Si el `Organizador` ha modificado campos o agregado canchas en el formulario de creación/edición e intenta retroceder o cerrar la vista sin guardar, el sistema solicita confirmación mediante un diálogo en español (*"¿Descartar cambios de la sede?"*) antes de abandonar la pantalla.
- **Intento de guardar o editar una sede sin conexión o con corte de red**: El sistema guarda la sede de forma segura en el almacenamiento local del entorno activo o informa claramente en español el estado de la operación, desbloqueando el botón de envío y evitando registros duplicados ante reintentos.
- **Revocación del permiso de ubicación mientras la aplicación está en segundo plano**: Si el usuario revoca el permiso de localización desde los ajustes del sistema operativo y regresa a la aplicación, la vista de *Sedes* actualiza su estado de forma transparente pasando al modo de referencia urbana por defecto sin cierres inesperados.
- **Búsqueda sin coincidencias o textos largos con escalado al `130%+`**: Si el usuario filtra sedes por nombre o dirección y no hay coincidencias, se muestra un estado vacío específico con opción de limpiar el filtro; asimismo, los nombres extensos de complejos deportivos y direcciones urbanas se adaptan sin desbordamientos visuales cuando el tamaño de texto del sistema está configurado al `130%`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE permitir exclusivamente a los usuarios con rol activo `Organizador` (capacidad `manageVenues`) crear, editar y alternar mediante baja lógica el estado operativo (`Activa` / `Mantenimiento`) de las sedes deportivas y sus canchas internas sin eliminarlas físicamente (mostrando una insignia de advertencia cuando están en mantenimiento y bloqueándolas para nuevas asignaciones de partidos), e impidiendo cualquier acción de escritura para los roles `Entrenador`, `Árbitro`, `Jugador` y `Aficionado`.
- **FR-002**: Toda sede deportiva (`SportsVenue`) DEBE exigir y validar antes de su guardado: un nombre oficial (`>= 3` caracteres), dirección física urbana (`>= 5` caracteres), referencia urbana opcional, coordenadas geográficas válidas (latitud en el rango `[-90.0, 90.0]` y longitud en el rango `[-180.0, 180.0]`) y al menos `1` cancha interna activa asociada.
- **FR-003**: Cada cancha interna (`VenuePitch`) asociada a una sede DEBE registrar: identificador único inmutable, nombre identificador (ej. *"Cancha Sintética 1"*, *"Cancha Norte"*), tipo de superficie (`Césped Sintético`, `Césped Natural`, `Tierra / Arena`, `Cemento / Futsal`), formato o modalidad sugerida (ej. `Fútbol 5`, `Fútbol 7`, `Fútbol 8`, `Fútbol 11`), capacidad aproximada de espectadores, disponibilidad de iluminación nocturna (`Sí` / `No`) y estado operativo (`Activa` / `Mantenimiento`).
- **FR-004**: La sección *Sedes* del contenedor principal DEBE ofrecer a todos los roles la consulta del catálogo de sedes (con búsqueda por nombre o dirección y filtro por superficie o iluminación), un lienzo visual interactivo *KickPulse Urban Map* 100% *offline-ready* (con cuadrícula urbana estilizada, marcadores seleccionables por sede, selección de coordenadas por toque o entrada numérica para el `Organizador` y resumen/copia de indicaciones de llegada sin depender de llaves de API externas) y la vista detallada de cada sede con sus canchas internas.
- **FR-005**: El sistema DEBE solicitar el permiso de localización del dispositivo únicamente en contexto (*just-in-time*) cuando el usuario consulte las sedes o active el cálculo de cercanía; si el permiso es concedido, DEBE calcular y mostrar la distancia aproximada en línea recta o ruta urbana hacia cada sede con numerales tabulares (`tabular-nums`) y ofrecer la acción de indicaciones de llegada.
- **FR-006**: Si el permiso de localización es rechazado, denegado permanentemente o no está disponible en el dispositivo, el sistema NO DEBE bloquear la navegación ni ocultar las sedes; DEBE centrar la vista geográfica en las coordenadas por defecto de la ciudad/sede seleccionada, mostrar íntegramente las direcciones físicas y referencias urbanas, presentar un banner o control discreto en español que permita reintentar o abrir la configuración de permisos si el usuario lo desea, e incluir en el entorno de `Desarrollo` un conmutador de simulación de estados de permiso (*Concedido*, *Denegado*, *Revocado*) para verificar todos los flujos móviles.
- **FR-007**: El catálogo de sedes, sus coordenadas, direcciones y canchas internas DEBEN persistirse localmente de forma aislada por entorno (`Desarrollo` / `Producción`), garantizando lectura instantánea en modo sin conexión (*offline*) y precargando en el entorno de `Desarrollo` un catálogo semilla de `3` sedes urbanas con múltiples canchas para facilitar la verificación inmediata.
- **FR-008**: La interfaz de *Sedes* DEBE implementar explícitamente los 5 estados visuales estandarizados (*Cargando*, *Contenido*, *Vacío*, *Error* con opción de reintentar, y *Éxito* al crear/editar una sede), presentar el 100% de los textos en español mediante el catálogo de localización (`l10n`), proteger los formularios contra pulsaciones repetidas (*single-flight*), conservar borradores ante paso a segundo plano y solicitar confirmación al intentar salir del formulario con cambios sin guardar.
- **FR-009**: Ninguna coordenada privada de ubicación exacta del dispositivo del usuario DEBE almacenarse de forma permanente ni exponerse en registros (*logs*) o mensajes de error; la ubicación del dispositivo se utiliza únicamente en memoria para calcular la distancia relativa hacia las sedes públicas del torneo.

### Key Entities *(include if feature involves data)*

- **Sede Deportiva (`SportsVenue`)**: Representa un complejo, polideportivo o unidad deportiva urbana donde se disputan partidos del campeonato (identificador único, nombre, dirección física, referencia urbana, latitud, longitud, horario o teléfono de referencia opcional, estado activo/inactivo, fecha de actualización y lista de canchas internas).
- **Cancha Interna (`VenuePitch`)**: Terreno de juego específico dentro de una sede deportiva (identificador único, identificador de la sede padre, nombre de la cancha, tipo de superficie, modalidad de fútbol, capacidad de público, indicador de iluminación artificial y estado operativo).
- **Coordenada Geográfica (`GeoCoordinate`)**: Objeto de valor del dominio que encapsula latitud y longitud validadas junto con el cálculo determinista de distancia en kilómetros (fórmula de Haversine) respecto a otro punto geográfico.
- **Estado de Permiso de Ubicación (`LocationPermissionStatus`)**: Estado del permiso y servicio de localización del dispositivo (`noSolicitado`, `concedido`, `denegado`, `denegadoPermanentemente`, `servicioDeshabilitado`) junto con la coordenada actual opcional del usuario.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un `Organizador` puede registrar una nueva sede deportiva completa con sus coordenadas y al menos una cancha interna en menos de `60` segundos, con el 100% de las etiquetas, superficies y validaciones en español.
- **SC-002**: El 100% de los usuarios logran consultar la dirección completa, referencia urbana, ubicación en el mapa y canchas disponibles de cualquier sede tanto cuando conceden el permiso de localización como cuando lo rechazan o revocan, con `0` bloqueos o cierres inesperados.
- **SC-003**: En modo sin conexión (*offline*), el 100% de las sedes y canchas previamente almacenadas en el entorno activo se cargan y muestran en menos de `2` segundos.
- **SC-004**: El 100% de los intentos de crear, editar o desactivar sedes o canchas por parte de usuarios con rol distinto a `Organizador` (`Entrenador`, `Árbitro`, `Jugador`, `Aficionado`) son bloqueados por las reglas de control de acceso.
- **SC-005**: El 100% de los controles interactivos del módulo de sedes cumplen el área táctil mínima de `44x44px`, muestran distancias y capacidades con numerales tabulares (`tabular-nums`) y se adaptan sin recortes ni desbordamientos con el texto del sistema escalado al `130%`.

## Assumptions

- Para garantizar que la experiencia geográfica funcione al 100% de forma determinista, rápida, sin depender de llaves de API propietarias externas sujetas a cuotas de facturación y con soporte tanto online como offline en pruebas y simuladores, el lienzo interactivo de mapa urbano y selección de coordenadas se provee mediante un componente visual interactivo propio estilizado bajo el sistema *KickPulse Mobile* (con cuadrícula táctica/urbana, marcadores interactivos por sede, selección por toque para el organizador, cálculo real de distancia mediante fórmula geodésica de Haversine y acción para copiar dirección o abrir indicaciones externas).
- Coordenadas por defecto de la ciudad del campeonato cuando no hay permiso de GPS o se inicia el selector: centro urbano de referencia (`latitud: 4.6097`, `longitud: -74.0817` — Bogotá, Colombia), configurable por sede.
- En el entorno de desarrollo (`vifutbol_dev`), si el catálogo local de sedes está vacío al inicializar por primera vez, se puede cargar o restaurar un conjunto semilla de sedes urbanas realistas con múltiples canchas para facilitar las pruebas inmediatas de consulta, filtrado y asignación en las siguientes historias de usuario, permitiendo también vaciar o agregar nuevas sedes libremente.
