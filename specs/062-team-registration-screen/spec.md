# Especificación de Funcionalidad: Nueva Página de Registro Detallado de Equipo

**Directorio de Funcionalidad**: `specs/062-team-registration-screen`  
**Creada**: 2026-11-26  
**Estado**: Borrador  
**Fuente**: Notion — `[Épica 27] HU 27.2: Nueva Página de Registro Detallado de Equipo (Nombre, Delegado, Fecha de Creación y Colores Distintivos)` (`4248442e-3f49-81ef-ade4-d9972d3ea5ac`)

## Clarifications

### Session 2026-11-26

- Q: ¿El color primario y el color secundario del equipo deben ser distintos entre sí, y cómo debe funcionar la selección de colores? → A: Paleta curada de colores deportivos; el color primario y secundario deben ser distintos entre sí (no pueden coincidir).
- Q: ¿Qué regla de longitud y precarga debe aplicarse al campo "Delegado" del equipo? → A: Cualquier texto no vacío (≥ 1 carácter tras recortar espacios); iniciar siempre vacío.

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia de Usuario 1 — Página Dedicada de Registro Detallado de Equipo (Prioridad: P1)

Como entrenador (u organizador autorizado) en ViFutbol, quiero acceder desde mi Panel o el Directorio a una página dedicada de registro de equipo que reemplace el diálogo básico anterior y me permita diligenciar nombre del equipo, código corto, delegado, fecha de creación, colores distintivos y asociación opcional a un torneo, para crear la ficha institucional completa de mi club desde el primer momento.

**Por qué esta prioridad**: Es el cambio estructural principal de la historia de usuario; reemplaza el diálogo modal limitado por un flujo cómodo a pantalla completa capaz de capturar todos los datos institucionales del equipo.

**Prueba Independiente**: Puede probarse de forma aislada iniciando sesión como entrenador u organizador, pulsando "Crear equipo" desde el Panel o el Directorio, comprobando que navega a la página dedicada con todos los campos solicitados, auto-sugerencia editable de código corto, selector de fecha localizado en español, selector opcional de torneo y diálogo de confirmación al salir con cambios sin guardar.

**Escenarios de Aceptación**:

1. **Dado** un entrenador (u organizador) autenticado que desea crear un nuevo equipo, **Cuando** presiona la acción "Crear equipo" desde su Panel o desde el Directorio de equipos, **Entonces** la aplicación navega a la nueva página dedicada de registro de equipo (en lugar de abrir un diálogo modal básico) y visualiza las secciones de vista previa de identidad, datos del equipo (nombre y código corto), delegado, fecha de creación, selector de colores distintivos e inscripción opcional a torneo.
2. **Dado** que el usuario escribe el nombre del equipo en el formulario, **Cuando** aún no ha editado manualmente el código corto, **Entonces** el sistema auto-sugiere un código corto de 2 a 4 caracteres derivado del nombre y permite al usuario modificarlo libremente dentro del rango de 2 a 4 caracteres.
3. **Dado** que el usuario abre el selector de fecha de creación, **Cuando** elige una fecha válida igual o anterior al día actual en el calendario localizado en español, **Entonces** la fecha seleccionada se muestra en formato legible en español en el formulario.
4. **Dado** que el usuario ha ingresado datos en el formulario sin guardar, **Cuando** presiona regresar para abandonar la pantalla, **Entonces** el sistema solicita confirmación explícita en español antes de descartar los cambios pendientes.

---

### Historia de Usuario 2 — Selector Visual de Colores Distintivos con Vista Previa en Vivo (Prioridad: P1)

Como entrenador u organizador registrando un equipo, quiero elegir el color primario y el color secundario de mi equipo desde un selector visual interactivo y ver reflejados los cambios en tiempo real sobre una vista previa del escudo/tarjeta del club, para validar la identidad visual antes de registrar el equipo.

**Por qué esta prioridad**: La identidad visual con colores distintivos es uno de los pilares de valor de la HU 27.2 y debe verificarse instantáneamente al elegir colores.

**Prueba Independiente**: Puede probarse directamente en la página de registro de equipo seleccionando distintos colores primario y secundario y verificando que la vista previa superior del escudo/tarjeta (junto con el nombre y código corto ingresados) se actualiza de inmediato.

**Escenarios de Aceptación**:

1. **Dado** que el entrenador se encuentra en la página de registro de equipo, **Cuando** visualiza la parte superior del formulario, **Entonces** ve una tarjeta de vista previa de identidad del club con los colores primario y secundario seleccionados por defecto, el nombre del equipo (o texto de ejemplo) y el código corto.
2. **Dado** que el entrenador selecciona un nuevo color primario o un nuevo color secundario en la paleta interactiva de colores distintivos, **Cuando** realiza la selección, **Entonces** la vista previa del escudo/tarjeta en la parte superior se actualiza inmediatamente con la nueva combinación de colores elegida y el color activo queda claramente resaltado en la paleta.

---

### Historia de Usuario 3 — Validaciones, Control de Roles y Guardado Offline-First sin Duplicados (Prioridad: P1)

Como entrenador u organizador que completó los datos del equipo, quiero que el sistema valide campos obligatorios, unicidad del nombre y fecha válida antes de guardar, bloquee envíos duplicados mientras guarda y persista el equipo tanto localmente como en la nube, para registrar mi equipo de forma confiable incluso con conectividad intermitente.

**Por qué esta prioridad**: Garantiza integridad de datos, seguridad de roles y experiencia offline-first confiable en dispositivos móviles.

**Prueba Independiente**: Puede probarse intentando guardar con campos inválidos o duplicados (verificando bloqueo y mensajes en español), intentando acceder con un rol no autorizado, probando doble toque rápido en "Registrar equipo" y completando el registro exitoso (con y sin conexión) para verificar persistencia, mensaje de éxito y aparición en el listado.

**Escenarios de Aceptación**:

1. **Dado** que el entrenador intenta enviar el formulario sin nombre, con un nombre menor a 3 caracteres, con código corto fuera de 2 a 4 caracteres, sin delegado, sin fecha de creación o con una fecha posterior a hoy, **Cuando** presiona "Registrar equipo", **Entonces** el sistema impide el envío y muestra mensajes de validación claros en español junto a cada campo inválido.
2. **Dado** que ya existe un equipo con el mismo nombre normalizado (ignorando mayúsculas, tildes o espacios adicionales), **Cuando** el usuario intenta registrar el equipo con ese nombre, **Entonces** el sistema rechaza el registro mostrando un mensaje claro en español indicando que el nombre ya existe, conservando todos los demás datos diligenciados.
3. **Dado** que el entrenador completó todos los campos válidos y presiona "Registrar equipo", **Cuando** la operación inicia, **Entonces** el botón entra en estado de carga bloqueando envíos duplicados, el equipo se persiste con su delegado, fecha de creación, colores distintivos y torneo opcional tanto en almacenamiento local como en la nube, y la aplicación regresa a la vista anterior mostrando un mensaje de éxito en español y el nuevo equipo en el listado.
4. **Dado** un usuario autenticado cuyo rol activo no es Entrenador ni Organizador (por ejemplo, Aficionado, Jugador o Árbitro), **Cuando** navega por la aplicación o intenta abrir la creación de equipo, **Entonces** no puede acceder ni enviar el formulario de registro de equipo.

---

### Historia de Usuario 4 — Visualización de Delegado, Fecha de Creación y Colores en la Ficha del Equipo (Prioridad: P2)

Como usuario consultando un equipo en ViFutbol, quiero ver en la ficha de información / detalle del equipo el nombre del delegado, la fecha de creación y los colores distintivos registrados, para conocer la identidad institucional completa del club.

**Por qué esta prioridad**: Cierra el ciclo de valor de los nuevos datos capturados al hacerlos visibles en la ficha oficial del equipo, manteniendo compatibilidad con equipos existentes.

**Prueba Independiente**: Puede probarse abriendo el detalle de un equipo recién registrado (verificando delegado, fecha de creación formateada y colores distintivos) y el detalle de un equipo creado previamente sin esos campos (verificando presentación limpia sin errores).

**Escenarios de Aceptación**:

1. **Dado** un equipo registrado con delegado, fecha de creación y colores distintivos, **Cuando** un usuario abre la pantalla de detalle / pestaña de información del equipo, **Entonces** visualiza el nombre del delegado, la fecha de creación formateada en español y los colores distintivos primario y secundario del equipo.
2. **Dado** un equipo existente creado antes de esta funcionalidad que no tiene delegado ni fecha de creación registrados, **Cuando** un usuario abre su ficha de información, **Entonces** la pantalla se renderiza sin errores mostrando un indicador discreto de dato no registrado para los campos ausentes.

---

### Casos Borde y Comportamiento Móvil

- **Registro sin conexión a internet (Offline-First)**: Si el dispositivo no tiene conectividad al presionar "Registrar equipo", el equipo se persiste localmente con todos sus nuevos atributos (delegado, fecha de creación y colores distintivos) y queda pendiente de sincronización automática con la nube al recuperar red, informando claramente al usuario en español.
- **Validación de espacios en blanco**: Textos compuestos únicamente por espacios en nombre del equipo, código corto o nombre del delegado se consideran vacíos y bloquean el envío.
- **Fecha límite de creación**: El selector de fecha impide elegir fechas posteriores a la fecha actual del dispositivo; incluso si se intenta inyectar una fecha futura, la validación de negocio la rechaza con mensaje claro en español.
- **Inscripción opcional a torneo**: El usuario puede dejar el campo de torneo vacío para crear un equipo autónomo o seleccionar uno de los torneos disponibles; ambos flujos persisten correctamente los nuevos campos institucionales.
- **Manejo de teclado y pantallas pequeñas**: Al desplegarse el teclado virtual sobre los campos de texto, el contenido se desplaza cómodamente para mantener visible el campo activo y permitir alcanzar el botón "Registrar equipo" sin desbordamientos.
- **Accesibilidad y escalado de texto**: Todas las etiquetas, muestras de color, botones y mensajes están en español, mantienen áreas táctiles cómodas y soportan escalado de fuente ampliado sin recortes ni solapamientos.

## Requisitos *(obligatorio)*

### Requisitos Funcionales

- **FR-001**: El sistema DEBE proveer una página dedicada a pantalla completa para el registro detallado de equipos, reemplazando el diálogo modal básico anterior en todos los puntos de entrada de creación de equipo (Panel y Directorio).
- **FR-002**: El formulario de registro DEBE capturar el **nombre del equipo** como campo obligatorio con longitud mínima de 3 caracteres y validar unicidad mediante nombre normalizado (insensible a mayúsculas, acentos y espacios sobrantes).
- **FR-003**: El formulario DEBE incluir el **código corto** del equipo (obligatorio, de 2 a 4 caracteres), auto-sugerido dinámicamente a partir del nombre ingresado mientras el usuario no lo haya editado manualmente, y siempre editable.
- **FR-004**: El formulario DEBE capturar el **nombre completo del delegado** como campo obligatorio que inicia siempre vacío y acepta cualquier texto no vacío (≥ 1 carácter tras recortar espacios).
- **FR-005**: El formulario DEBE capturar la **fecha de creación del equipo** como campo obligatorio mediante un selector de fecha localizado en español, impidiendo seleccionar o enviar fechas posteriores a la fecha actual.
- **FR-006**: El formulario DEBE ofrecer un selector visual interactivo basado en una paleta curada de colores deportivos que permita elegir un **color primario** y un **color secundario** distintos entre sí (no pueden coincidir), reflejándolos en tiempo real en una vista previa superior de la identidad visual del club (escudo/tarjeta con nombre y código corto).
- **FR-007**: El formulario DEBE mantener la opción de **inscripción opcional a un torneo** disponible o permitir la creación autónoma del equipo sin torneo asociado.
- **FR-008**: El sistema DEBE persistir los nuevos atributos (`delegado`, `fecha de creación`, `color primario` y `color secundario`) tanto en el almacenamiento local como en el almacenamiento remoto en la nube, preservando el comportamiento offline-first y la compatibilidad con equipos existentes sin estos campos.
- **FR-009**: El sistema DEBE restringir el acceso y envío del formulario de registro de equipo exclusivamente a roles autorizados (Entrenador y Organizador).
- **FR-010**: El sistema DEBE aplicar bloqueo de envío único (`single-flight`) con indicador de carga visible durante el registro del equipo para impedir registros duplicados por toques repetidos.
- **FR-011**: El sistema DEBE mostrar mensajes de validación claros en español junto a cada campo inválido cuando se intente enviar el formulario incompleto o con datos incorrectos, conservando los datos diligenciados.
- **FR-012**: El sistema DEBE solicitar confirmación en español antes de descartar cambios sin guardar cuando el usuario intente abandonar la página de registro de equipo con modificaciones pendientes.
- **FR-013**: La ficha de información / pantalla de detalle del equipo DEBE mostrar el nombre del delegado, la fecha de creación formateada en español y los colores distintivos del equipo, manejando de forma segura equipos existentes que carezcan de delegado o fecha.
- **FR-014**: Todos los textos visibles de la página de registro, selectores, validaciones, confirmaciones y ficha de detalle DEBEN estar redactados en español claro y consistente con la aplicación.

### Entidades Clave *(incluir si la funcionalidad maneja datos)*

- **Equipo**: Entidad institucional que representa un club o equipo deportivo. Además de su identificador, nombre, nombre normalizado, código corto y vínculo opcional a torneo/entrenador, ahora incluye **nombre del delegado**, **fecha de creación**, **color primario** y **color secundario**.
- **Identidad Visual del Equipo**: Combinación de color primario y color secundario (representados en formato hexadecimal estándar) usada tanto en la vista previa en vivo durante el registro como en la ficha de información del equipo.
- **Torneo Disponible (Opcional)**: Referencia opcional a un campeonato existente al cual el equipo puede inscribirse durante su creación o permanecer como equipo autónomo.

## Criterios de Éxito *(obligatorio)*

### Resultados Medibles

- **SC-001**: El 100% de los puntos de entrada de creación de equipo (Panel y Directorio) para Entrenador y Organizador navegan a la nueva página dedicada sin abrir el diálogo modal básico anterior.
- **SC-002**: El 100% de los cambios de color primario o secundario en la paleta actualizan la vista previa superior del club de manera inmediata en el mismo cuadro visual sin latencia perceptible ni pasos adicionales.
- **SC-003**: El 100% de los intentos de registrar un equipo sin nombre válido (≥ 3 caracteres y único normalizado), sin código corto válido (2–4 caracteres), sin delegado o con fecha de creación ausente o futura son bloqueados antes de persistir, mostrando mensajes claros en español.
- **SC-004**: El 100% de los equipos registrados exitosamente persisten delegado, fecha de creación y colores distintivos tanto en almacenamiento local como en la nube (y en modo offline-first cuando no haya red) sin crear registros duplicados ante toques rápidos.
- **SC-005**: Al abrir la ficha de detalle de cualquier equipo recién creado, el usuario visualiza correctamente su delegado, fecha de creación y colores distintivos; y al abrir equipos existentes previos a esta funcionalidad, la ficha carga sin errores.

## Supuestos y Alcance

- **Alcance de esta especificación (HU 27.2)**: Cubre la nueva página dedicada de registro detallado de equipo (nombre, código corto auto-sugerido, delegado, fecha de creación, colores distintivos con vista previa en vivo, torneo opcional), migración y persistencia local/nube offline-first, reemplazo de los puntos de entrada del diálogo modal anterior y visualización de los nuevos datos en la ficha de información del equipo.
- **Fuera de alcance**: Funcionalidades de otras historias de la Épica 27 (como carga de escudo/imagen personalizada del equipo o edición posterior del equipo si corresponden a HU 27.3), gestión de convocatorias/plantilla o pagos de inscripción.
- **Supuestos**:
  - La paleta de colores distintivos incluirá una selección curada de colores deportivos contrastados con valores por defecto preseleccionados para agilizar el registro.
  - Los equipos creados antes de esta funcionalidad mantienen sus valores actuales y muestran un estado vacío elegante para delegado y fecha de creación hasta que se actualicen en futuras historias.
  - Toda la interfaz de usuario se presenta en español.
