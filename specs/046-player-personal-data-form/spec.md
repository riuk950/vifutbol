# Feature Specification: Formulario de Datos Personales, Ubicación en Colombia y Posiciones Múltiples del Jugador (HU 21.1)

**Feature Branch**: `046-player-personal-data-form`

**Created**: 2026-11-17

**Status**: Draft

**Input**: User description: "de Notion HU 21.1 en curso — [Épica 21] HU 21.1: Formulario de Datos Personales, Ubicación en Colombia y Posiciones Múltiples del Jugador"

## Clarifications

### Session 2026-11-17

- Q: ¿Cómo debe presentarse el formulario de datos personales del jugador al tocar "Completar mi perfil" o "Datos Personales" en la pestaña Perfil? (FR-001) → A: Pantalla dedicada de página completa para el rol Jugador (manteniendo el diálogo modal actual para los demás roles).
- Q: ¿Qué campos deben determinar que el perfil del rol Jugador está "Completo" y cómo debe tratarse el campo "Teléfono" heredado de la HU 19.4? (FR-002, SC-004) → A: Incluir también el campo "Teléfono" como obligatorio en el formulario de Datos Personales del Jugador junto con todos los campos obligatorios de HU 21.1 para marcar el perfil como completo.
- Q: ¿Cómo debe comportarse el guardado del formulario de datos personales del jugador cuando el dispositivo no tiene conexión a internet? (FR-009, FR-011) → A: Exigir conexión cuando hay backend remoto configurado (igual que HU 19.4): si no hay internet, conserva intacto el formulario y muestra un mensaje claro para reintentar (en modo local sin Supabase guarda de inmediato).
- Q: ¿Qué nivel de cobertura debe tener el catálogo local de municipios de Colombia y cómo debe seleccionarse un municipio cuando un departamento tiene muchos? (FR-005) → A: Catálogo oficial completo de Colombia (~1.100+ municipios del DANE en los 32 departamentos + Bogotá D.C.) con selector buscable por texto.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Diligenciamiento y Guardado de Ficha Personal y Deportiva Completa (Priority: P1)

Como usuario registrado con rol de Jugador (`player`), quiero abrir desde la pestaña Perfil (mediante el banner `"Completar mi perfil"` o la opción `"Datos Personales"`) un formulario estructurado para registrar mis nombres y apellidos por separado, número de documento, sexo, fecha de nacimiento, tipo de sangre (RH), departamento y municipio de Colombia, y mis posiciones de juego, para completar mi ficha deportiva oficial y vincular mi cuenta con el catálogo de futbolistas.

**Why this priority**: Es el flujo principal que habilita la identidad deportiva completa del jugador en la plataforma, resuelve el estado de perfil incompleto del rol Jugador y permite su vinculación por documento con equipos donde haya sido preinscrito por un director técnico.

**Independent Test**: Iniciar sesión con rol `player`, abrir el formulario desde `"Completar mi perfil"` o `"Datos Personales"` en la pantalla de Perfil, completar los campos obligatorios (documento, primer nombre, primer apellido, sexo, fecha de nacimiento, departamento, municipio, RH y al menos una posición), guardar y verificar que el perfil pasa a estado completo, el nombre completo se concatena sin espacios dobles y el registro queda vinculado al usuario.

**Acceptance Scenarios**:

1. **Given** que el usuario tiene sesión activa con rol `"player"` y su perfil está incompleto o desea actualizarlo, **When** presiona `"Completar mi perfil"` o `"Datos Personales"` en la pestaña Perfil, **Then** se despliega el formulario estructurado con los campos: Número de documento, Teléfono (obligatorio), Primer apellido (obligatorio), Segundo apellido (opcional), Primer nombre (obligatorio), Segundo nombre (opcional), Sexo (`"Masculino"`, `"Femenino"`, `"Otro"`), Fecha de nacimiento, Edad (solo lectura), Departamento, Municipio, Tipo de sangre / RH (`"O+"`, `"O-"`, `"A+"`, `"A-"`, `"B+"`, `"B-"`, `"AB+"`, `"AB-"`) y Posiciones de juego en el campo.
2. **Given** que el jugador ingresa `"Juan"`, `"Carlos"`, `"Pérez"` y deja vacío el segundo apellido, **When** guarda el formulario válido, **Then** el sistema actualiza su nombre completo armonizado como `"Juan Carlos Pérez"` sin espacios dobles, persiste todos los atributos de la ficha deportiva y marca el perfil del jugador como completo.
3. **Given** que un entrenador había preinscrito previamente a un jugador con el mismo número de documento en un equipo, **When** el usuario con rol `"player"` guarda el formulario con ese número de documento, **Then** el sistema enlaza dicho registro preexistente a la cuenta del usuario autenticado conservando su pertenencia al equipo y actualizando su información personal y táctica.

---

### User Story 2 - Cálculo Reactivo de Edad y Selección en Cascada de Ubicación en Colombia (Priority: P1)

Como jugador diligenciando mi formulario de datos personales, quiero que mi edad se calcule automáticamente al elegir mi fecha de nacimiento y que el selector de municipio muestre únicamente los municipios correspondientes al departamento de Colombia seleccionado, para garantizar exactitud en mi categoría de edad y ubicación geográfica sin errores de digitación.

**Why this priority**: Evita inconsistencias entre la fecha de nacimiento y la edad declarada (crítico para reglamentos por edad en torneos) y asegura datos geográficos normalizados para los 32 departamentos de Colombia y Bogotá D.C.

**Independent Test**: Seleccionar distintas fechas de nacimiento (incluyendo fechas cuyo cumpleaños en el año en curso aún no ha ocurrido y fechas cuyo cumpleaños ya pasó) y comprobar que el campo `"Edad"` muestra los años cumplidos exactos sin permitir edición manual; luego seleccionar un departamento (ej. Antioquia o Cundinamarca) y verificar que el listado de municipios se filtra exclusivamente a dicho departamento y se reinicia si se cambia de departamento.

**Acceptance Scenarios**:

1. **Given** que el jugador está en el formulario de datos personales, **When** selecciona o modifica su `"Fecha de nacimiento"`, **Then** el sistema calcula automáticamente la edad exacta en años cumplidos hasta la fecha actual y muestra el valor en el campo `"Edad"` en modo de solo lectura.
2. **Given** que el jugador selecciona un `"Departamento"` del catálogo oficial de Colombia (32 departamentos + Bogotá D.C.), **When** interactúa con el selector de `"Municipio"`, **Then** el selector lista únicamente los municipios pertenecientes a ese departamento.
3. **Given** que el jugador ya tenía un departamento y un municipio seleccionados, **When** cambia el `"Departamento"` a uno diferente, **Then** la selección previa de `"Municipio"` se limpia automáticamente y solicita elegir un municipio válido del nuevo departamento.

---

### User Story 3 - Selección Múltiple de Posiciones Específicas de Fútbol y Derivación de Línea Táctica (Priority: P1)

Como jugador configurando mi perfil táctico, quiero seleccionar una o varias posiciones específicas del campo de fútbol (`POR`, `DFC`, `LD`, `LI`, `CAD`, `CAI`, `MCD`, `MC`, `MCO`, `MD`, `MI`, `ED`, `EI`, `MP`, `DC`), para reflejar con fidelidad mi polivalencia en la cancha mientras el sistema mantiene compatibilidad con las 4 líneas tácticas generales de las plantillas.

**Why this priority**: Los futbolistas amateur y competitivos suelen desempeñarse en más de una demarcación específica, mientras que los paneles técnicos y las plantillas de torneos agrupan a los jugadores en las 4 líneas tácticas fundamentales (`Portero`, `Defensa`, `Mediocampista`, `Delantero`).

**Independent Test**: En el selector de posiciones del formulario, marcar múltiples posiciones (ej. `LD` y `CAD`, o `MC` y `MCO`), verificar que se exige al menos una posición para guardar y comprobar que la línea táctica principal del jugador se deriva determinísticamente hacia `goalkeeper`, `defender`, `midfielder` o `forward`.

**Acceptance Scenarios**:

1. **Given** que el jugador interactúa con el selector de `"Posiciones en las que juega"`, **When** visualiza las opciones disponibles, **Then** puede marcar o desmarcar una o varias de las posiciones específicas agrupadas o identificadas con su sigla oficial: Portero (`POR`), Defensa Central (`DFC`), Lateral Derecho (`LD`), Lateral Izquierdo (`LI`), Carrilero Derecho (`CAD`), Carrilero Izquierdo (`CAI`), Mediocentro Defensivo (`MCD`), Mediocentro (`MC`), Mediocampista Ofensivo (`MCO`), Interior Derecho (`MD`), Interior Izquierdo (`MI`), Extremo Derecho (`ED`), Extremo Izquierdo (`EI`), Mediapunta (`MP`) y Delantero Centro (`DC`).
2. **Given** que el jugador intenta guardar el formulario sin haber marcado ninguna posición de juego, **When** presiona la acción de guardar, **Then** el sistema impide el envío y muestra un mensaje de validación indicando que debe seleccionar al menos una posición en el campo.
3. **Given** que el jugador selecciona una o varias posiciones específicas y guarda el formulario, **When** se persiste el perfil deportivo, **Then** el sistema almacena la lista completa de posiciones seleccionadas y deriva automáticamente la línea táctica principal (`goalkeeper`, `defender`, `midfielder` o `forward`) a partir de la posición primaria seleccionada para mantener compatibilidad con las vistas de plantilla.

---

### Edge Cases

- **Cumpleaños aún no cumplido en el año actual**: Si hoy es 17 de noviembre de 2026 y la fecha de nacimiento es 20 de diciembre de 2000, el cálculo de edad debe arrojar `25` años (y no `26`), ajustando por mes y día.
- **Nombres o apellidos con espacios adicionales y campos opcionales vacíos**: Si el jugador deja vacíos `"Segundo nombre"` y/o `"Segundo apellido"`, o introduce espacios al inicio/final de cada campo, la concatenación del nombre completo debe recortar cada parte e ignorar las vacías para no producir espacios dobles ni bordes en blanco.
- **Cambio de departamento tras haber elegido municipio**: Si el usuario cambia de departamento, el municipio anteriormente seleccionado deja de ser válido y debe restablecerse a vacío hasta que elija uno del nuevo departamento.
- **Intento de salida con cambios sin guardar**: Si el jugador ha modificado algún campo del formulario e intenta retroceder, el sistema debe solicitar confirmación antes de descartar los cambios no guardados.
- **Pulsaciones repetidas en guardar y operación sin conexión**: Durante el guardado, el botón de acción debe deshabilitarse mostrando estado de progreso para evitar envíos duplicados; si hay backend remoto configurado y el dispositivo no tiene conexión a internet, el sistema debe conservar intactos los datos del formulario y mostrar un mensaje claro para reintentar al recuperar conexión (en modo local sin servidor remoto persiste localmente de inmediato).
- **Pantallas compactas y escalado de texto**: En pantallas de 320px/360px de ancho con escalado de fuente de hasta 130%, los selectores de departamento/municipio, chips de posiciones múltiples y campos de fecha/edad deben fluir sin desbordamientos visuales (`RenderFlex overflow`).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE permitir a un usuario autenticado con rol `player` navegar a una pantalla dedicada de página completa con el formulario de datos personales tanto desde el botón `"Completar mi perfil"` del banner de perfil incompleto como desde una tarjeta/opción permanente `"Datos Personales"` en la pantalla de Perfil (conservando el diálogo modal actual para los demás roles).
- **FR-002**: El formulario DEBE capturar de forma separada: Número de documento (obligatorio), Teléfono (obligatorio, mínimo 7 dígitos), Primer nombre (obligatorio), Segundo nombre (opcional), Primer apellido (obligatorio) y Segundo apellido (opcional). El perfil del rol `player` se considerará completo únicamente cuando cuente con todos los campos obligatorios de esta ficha (documento, teléfono, primer nombre, primer apellido, sexo, fecha de nacimiento, departamento, municipio, tipo de sangre y al menos una posición de juego).
- **FR-003**: El formulario DEBE incluir un selector obligatorio de Sexo con las opciones `"Masculino"`, `"Femenino"` y `"Otro"`, y un selector obligatorio de Tipo de sangre / RH con las 8 opciones estándar (`"O+"`, `"O-"`, `"A+"`, `"A-"`, `"B+"`, `"B-"`, `"AB+"`, `"AB-"`).
- **FR-004**: El formulario DEBE incluir un selector obligatorio de Fecha de nacimiento (restringido a fechas pasadas razonables para un jugador, por ejemplo entre 5 y 100 años atrás) y un campo `"Edad"` de solo lectura que muestre en tiempo real los años cumplidos exactos a la fecha actual.
- **FR-005**: El sistema DEBE proveer un catálogo local completo con los 32 departamentos de Colombia más Bogotá D.C. y la totalidad de sus municipios oficiales (~1.100+ municipios del DANE), implementando selección obligatoria en cascada mediante selectores buscables por texto (la elección de Departamento filtra los Municipios disponibles y limpia cualquier municipio incompatible previo).
- **FR-006**: El formulario DEBE proveer un selector de selección múltiple de posiciones específicas de fútbol (`POR`, `DFC`, `LD`, `LI`, `CAD`, `CAI`, `MCD`, `MC`, `MCO`, `MD`, `MI`, `ED`, `EI`, `MP`, `DC`), exigiendo al menos una posición seleccionada para permitir el guardado.
- **FR-007**: El sistema DEBE mapear cada posición específica a una de las cuatro líneas tácticas generales (`goalkeeper`, `defender`, `midfielder`, `forward`), asignando la línea de la primera posición seleccionada como posición táctica primaria del jugador para compatibilidad con plantillas y alineaciones.
- **FR-008**: Al guardar, el sistema DEBE construir automáticamente el nombre completo (`fullName`) concatenando `primerNombre`, `segundoNombre`, `primerApellido` y `segundoApellido` (omitiendo los opcionales vacíos y eliminando espacios sobrantes) y actualizar tanto la cuenta del usuario como el registro del jugador.
- **FR-009**: Al guardar el número de documento, si ya existe un registro de jugador con ese mismo `documentId` preinscrito por un entrenador sin usuario vinculado (o vinculado al mismo usuario), el sistema DEBE enlazar dicho registro al `userId` actual y actualizar sus campos personales y tácticos; si el documento ya está vinculado a otro usuario distinto, DEBE rechazar la vinculación y notificar el conflicto sin sobrescribir la cuenta ajena; en caso contrario, DEBE crear o actualizar la ficha del jugador asociada al `userId` actual.
- **FR-010**: Si el jugador ya cuenta con datos personales previamente guardados y vuelve a abrir `"Datos Personales"`, el formulario DEBE precargar todos los valores existentes (documento, teléfono, nombres separados, sexo, fecha de nacimiento, edad calculada, departamento, municipio, RH y posiciones seleccionadas).
- **FR-011**: El formulario DEBE proteger contra pérdida accidental de datos al retroceder con cambios sin guardar y prevenir envíos duplicados deshabilitando el botón de guardado mientras la operación está en curso. Cuando hay un backend remoto configurado, el guardado DEBE requerir conexión para validar unicidad/vinculación del documento en la nube (mostrando un mensaje claro y conservando el formulario intacto si está sin conexión); en modo local sin backend remoto, DEBE guardar localmente de inmediato.

### Key Entities *(include if feature involves data)*

- **Ficha Personal y Táctica del Jugador (`PlayerPersonalProfile` / extensión de `RegisteredPlayer`)**: Representa la información detallada del futbolista: `userId`, `documentId`, `firstName`, `secondName`, `firstSurname`, `secondSurname`, `fullName`, `sex`, `birthDate`, `bloodType`, `department`, `municipality`, `primaryPosition` (línea general) y `specificPositions` (lista de demarcaciones específicas de fútbol).
- **Catálogo Geográfico de Colombia (`ColombiaLocationCatalog`)**: Estructura de referencia local que contiene los 32 departamentos oficiales de Colombia y Bogotá D.C., junto con la lista de municipios pertenecientes a cada departamento.
- **Posición Específica de Fútbol (`DetailedFootballPosition`)**: Catálogo de las 15 demarcaciones reales en cancha (`POR`, `DFC`, `LD`, `LI`, `CAD`, `CAI`, `MCD`, `MC`, `MCO`, `MD`, `MI`, `ED`, `EI`, `MP`, `DC`), cada una asociada a su sigla, nombre en español y línea táctica base (`goalkeeper`, `defender`, `midfielder`, `forward`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un usuario con rol `player` puede diligenciar todos los campos del formulario de datos personales y guardar su ficha deportiva en menos de 2 minutos.
- **SC-002**: El 100% de las modificaciones en la fecha de nacimiento actualizan de forma inmediata (en menos de 100 ms) el campo de Edad de solo lectura con el cálculo exacto en años cumplidos.
- **SC-003**: El 100% de las selecciones de cualquiera de los 32 departamentos de Colombia o Bogotá D.C. cargan instantáneamente sin necesidad de conexión a internet la lista exclusiva de municipios correspondientes.
- **SC-004**: Una vez guardado el formulario con todos los campos obligatorios, el aviso de `"Perfil incompleto"` para el rol `player` desaparece inmediatamente de la pestaña Perfil y la información persiste tras reiniciar la sesión o la aplicación.
- **SC-005**: La interfaz del formulario se visualiza y opera sin ningún desbordamiento visual en pantallas móviles desde 320px de ancho y con escalado de texto del sistema de hasta 130%.

## Assumptions

- El listado de departamentos y municipios de Colombia se incluye como un catálogo estático local dentro de la aplicación para garantizar disponibilidad inmediata en modo offline en canchas y sedes deportivas.
- Las siglas de posiciones específicas incluyen las variantes por banda indicadas en la historia de usuario (`CAD`, `CAI`, `MD`, `MI`) además de `POR`, `DFC`, `LD`, `LI`, `MCD`, `MC`, `MCO`, `ED`, `EI`, `MP` y `DC` (15 demarcaciones en total).
- La primera posición específica seleccionada por el jugador (o la primera en orden de selección) define la línea táctica principal (`PlayerPosition`) utilizada en las vistas de plantilla por posición, conservando todas las demás en la lista de posiciones del jugador.
- La captura por cámara/escaneo de la cédula colombiana (PDF417 / MRZ OCR) y la fotografía de avatar corresponden a las historias posteriores HU 21.2 y HU 21.3 respectivamente; no obstante, el estado y los campos del formulario de la HU 21.1 quedan preparados para recibir datos autocompletados.
