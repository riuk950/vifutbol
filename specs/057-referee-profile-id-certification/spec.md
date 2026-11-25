# Feature Specification: Perfil Completo del Árbitro: Cédula Colombiana por Ambos Lados y Documento de Certificación Arbitral

**Feature Branch**: `057-referee-profile-id-certification`

**Created**: 2026-11-25

**Status**: Draft

**Input**: User description: "HU 25.1 (Épica 25 - Notion): Perfil Completo del Árbitro: Cédula Colombiana por Ambos Lados y Documento de Certificación Arbitral — Como árbitro registrado en ViFutbol, quiero completar y gestionar mi perfil con los datos de mi documento de identidad colombiano (incluyendo escaneo dual y fotografía por ambos lados, igual que el rol jugador) y adjuntar la captura de un documento que me certifique como árbitro, para acreditar oficialmente mi identidad y mi certificación arbitral dentro de la plataforma y poder ser designado en partidos y torneos oficiales."

## Clarifications

### Session 2026-11-25

- Q: ¿Qué formatos debe aceptar la captura del documento de certificación arbitral en esta entrega? → A: Solo imagen (`JPEG`, `PNG`, `WEBP`) capturada desde cámara o seleccionada desde galería, con vista previa directa en el formulario.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Formulario Dedicado de Identidad y Ubicación del Árbitro con Escaneo Dual de Cédula Colombiana (Priority: P1)

Como árbitro autenticado en ViFutbol, al pulsar **Completar mi perfil** (o el acceso de datos personales del árbitro) en mi pantalla de Perfil, quiero acceder a una pantalla dedicada con los mismos campos de identidad y ubicación en Colombia que el rol jugador (número de documento, primer nombre, segundo nombre opcional, primer apellido, segundo apellido opcional, sexo, fecha de nacimiento, tipo de sangre RH, teléfono, departamento y municipio), poder escanear mi cédula colombiana para autocompletar automáticamente mis datos y capturar la fotografía de ambas caras (frente y reverso) con vista previa y opción de reemplazo.

**Why this priority**: Establece la paridad de verificación de identidad oficial respecto al rol jugador y reduce errores de digitación mediante el escaneo automático de la cédula colombiana (código de barras trasero o zona de lectura mecánica frontal).

**Independent Test**: Puede verificarse abriendo la pantalla de Perfil con un usuario con rol `Árbitro`, ingresando al formulario dedicado, ejecutando el escaneo de cédula colombiana (con autocompletado de campos), capturando ambas caras de la cédula y verificando las vistas previas y la posibilidad de editar manualmente o reemplazar cualquiera de las dos caras.

**Acceptance Scenarios**:

1. **Given** un usuario autenticado con rol `Árbitro` cuyo perfil está incompleto en la pantalla de Perfil, **When** presiona `Completar mi perfil`, **Then** navega a la pantalla dedicada de datos personales y documentación del árbitro donde visualiza las secciones de Datos Personales, Ubicación en Colombia, Cédula (ambos lados) y Certificación Arbitral.
2. **Given** un árbitro en su formulario de perfil, **When** escanea su cédula colombiana (código de barras del reverso o lectura óptica del frente), **Then** el sistema autocompleta los campos de número de documento, nombres, apellidos, fecha de nacimiento, sexo y tipo de sangre (RH), permitiendo revisarlos o corregirlos manualmente.
3. **Given** un árbitro en la sección de documento de identidad del formulario, **When** captura o selecciona la imagen de la cara frontal y la cara posterior de su cédula, **Then** el sistema muestra la vista previa de ambas caras con opción de reemplazar cada una antes de guardar.

---

### User Story 2 - Captura del Documento de Certificación Arbitral y Categoría (Priority: P2)

Como árbitro autenticado en ViFutbol, quiero adjuntar en mi formulario de perfil la fotografía o imagen de un documento oficial que me acredite como árbitro (carnet arbitral, certificado de liga/colegio arbitral o diploma) desde cámara o galería, visualizar su vista previa con opción de reemplazo, e indicar mi nivel o categoría de certificación arbitral.

**Why this priority**: Es el elemento diferenciador clave del rol `Árbitro` en HU 25.1 para respaldar su idoneidad oficial antes de ser designado en partidos y campeonatos.

**Independent Test**: Puede verificarse en el formulario del árbitro seleccionando o capturando una imagen de documento de certificación arbitral, ingresando la categoría de certificación, verificando la vista previa y la acción de reemplazo, y comprobando que la referencia queda persistida de forma segura al guardar.

**Acceptance Scenarios**:

1. **Given** un árbitro en la sección de Certificación Arbitral del formulario, **When** presiona `Capturar documento de certificación arbitral` y elige tomar una foto con cámara o seleccionar una imagen desde galería, **Then** el sistema muestra la vista previa del documento capturado y ofrece la opción de reemplazarlo antes de guardar.
2. **Given** un árbitro en la sección de Certificación Arbitral, **When** diligencia su nivel/categoría de certificación arbitral y guarda el formulario completo, **Then** el documento de certificación se almacena en el espacio privado de la nube restringido al propietario y su referencia queda asociada al registro oficial del árbitro.

---

### User Story 3 - Validación de Completitud, Guardado Atómico, Protección contra Doble Envío y Resiliencia Móvil (Priority: P3)

Como árbitro autenticado en ViFutbol, quiero que el formulario valide que todos los datos personales obligatorios, ambas caras de la cédula y el documento de certificación arbitral estén completos antes de guardar, bloquee envíos duplicados mientras sube los documentos y guarda de forma atómica, maneje de forma clara los permisos de cámara/galería o la falta de conexión sin perder lo diligenciado, y marque mi perfil como **Perfil completo** únicamente cuando todo esté acreditado.

**Why this priority**: Garantiza la integridad de los datos oficiales de arbitraje (Principio II), previene perfiles incompletos marcados falsamente como completos y cumple los estándares de resiliencia móvil (`docs/MOBILE_GUIDELINES.md`).

**Independent Test**: Puede probarse intentando guardar con documentos o campos faltantes (verificando mensajes de validación en español), simulando pulsaciones rápidas sobre `Guardar perfil` (verificando bloqueo `single-flight`), probando denegación de permisos de cámara/galería y falta de conexión (verificando conservación de datos diligenciados), y realizando un guardado completo para confirmar que el estado pasa a `Perfil completo`.

**Acceptance Scenarios**:

1. **Given** un árbitro que intenta guardar el formulario sin adjuntar alguna de las dos caras de la cédula o sin adjuntar el documento de certificación arbitral (o con campos obligatorios vacíos), **When** presiona `Guardar perfil`, **Then** el sistema bloquea el envío y muestra mensajes de validación claros en español indicando exactamente qué campos o documentos faltan.
2. **Given** un árbitro que diligenció todos los datos personales, ubicación en Colombia, categoría arbitral, ambas caras de la cédula y el documento de certificación arbitral con conexión a internet, **When** presiona `Guardar perfil`, **Then** el botón entra en estado de carga bloqueando pulsaciones repetidas (`single-flight`), sube los documentos al almacenamiento privado en la nube, actualiza atómicamente la cuenta y el registro del árbitro, y actualiza el estado del perfil a `Perfil completo`.
3. **Given** un árbitro que niega el permiso de cámara o galería al intentar capturar un documento, **When** ocurre la denegación, **Then** el sistema muestra un mensaje orientativo en español sin cerrarse inesperadamente y permite reintentar, usar la alternativa disponible (cámara vs galería) o ingresar datos manualmente.
4. **Given** un árbitro que ya diligenció campos y capturó imágenes pero pierde conexión a internet al intentar guardar, **When** falla el guardado remoto, **Then** el sistema muestra un mensaje de error claro en español conservando todos los campos e imágenes capturadas en pantalla para permitir reintentar cuando vuelva la conexión.
5. **Given** un árbitro que tiene cambios sin guardar en el formulario, **When** intenta volver atrás, **Then** el sistema solicita confirmación antes de descartar los cambios.

---

### Edge Cases

- **Perfil de árbitro previamente creado solo con campos básicos**: Un árbitro existente que anteriormente solo tenía teléfono, documento y nivel de certificación (sin datos demográficos, sin fotos de cédula o sin documento de certificación arbitral) debe mostrarse como **Datos incompletos** hasta completar los nuevos requisitos de HU 25.1, precargando los datos que ya tenía guardados.
- **Reemplazo de imágenes ya guardadas**: Si el árbitro vuelve a abrir su formulario para actualizar su certificación arbitral o una cara de la cédula, las imágenes previamente guardadas deben mostrarse como vista previa y solo deben volver a subirse las imágenes que el usuario haya reemplazado localmente.
- **Lectura parcial o fallida del escáner de cédula**: Si la iluminación o calidad de la cédula impide leer algún campo automáticamente, los campos leídos se completan y el usuario puede diligenciar o corregir manualmente el resto sin bloqueo.
- **Imágenes grandes o formatos no soportados**: Los archivos capturados deben respetar el límite de tamaño y formatos de imagen permitidos en el almacenamiento privado, informando claramente en español si una imagen es inválida.
- **Cambio de departamento en ubicación de Colombia**: Al cambiar el departamento seleccionado, el selector de municipio debe reiniciarse y ofrecer únicamente los municipios correspondientes al nuevo departamento.
- **Accesibilidad y escalado de texto**: Todas las etiquetas, tarjetas de captura de documentos, botones y mensajes de validación deben ser legibles en español bajo escalado de texto ampliado (`1.5x`) con áreas táctiles ≥ 44 px y sin desbordamientos.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE ofrecer a los usuarios autenticados con rol `Árbitro` una pantalla dedicada para completar y editar su perfil personal y documentación oficial, accesible desde el Perfil (tanto desde el botón `Completar mi perfil` cuando está incompleto como desde un acceso directo de datos personales del árbitro).
- **FR-002**: El formulario del árbitro DEBE incluir en paridad con el rol jugador todos los campos obligatorios y opcionales de identidad y ubicación en Colombia:
  - Número de documento de identidad (obligatorio)
  - Primer nombre (obligatorio) y segundo nombre (opcional)
  - Primer apellido (obligatorio) y segundo apellido (opcional)
  - Sexo (obligatorio)
  - Fecha de nacimiento (obligatoria)
  - Tipo de sangre / RH (obligatorio)
  - Teléfono de contacto (obligatorio)
  - Departamento y municipio de Colombia (obligatorios, con lista de municipios dependiente del departamento)
- **FR-003**: El formulario del árbitro DEBE permitir escanear la cédula colombiana (código de barras del reverso o lectura óptica del frente) para autocompletar los campos de identidad, manteniendo la posibilidad de edición manual.
- **FR-004**: El formulario del árbitro DEBE incluir la captura y vista previa obligatoria de ambas caras de la cédula colombiana (cara frontal y cara posterior) con opción de reemplazo desde cámara o galería.
- **FR-005**: El formulario del árbitro DEBE incluir una sección de **Certificación Arbitral** con:
  - Nivel o categoría de certificación arbitral (obligatorio).
  - Captura y vista previa obligatoria de la imagen del documento que certifica al usuario como árbitro (carnet arbitral, certificado de liga/colegio arbitral o diploma) únicamente en formato de imagen (`JPEG`, `PNG` o `WEBP`) desde cámara o galería, con opción de reemplazo antes de guardar.
- **FR-006**: Al guardar el perfil del árbitro, el sistema DEBE validar todos los campos obligatorios, la presencia de ambas caras de la cédula y la presencia del documento de certificación arbitral; si falta alguno, DEBE impedir el envío y mostrar mensajes de validación claros en español.
- **FR-007**: Las imágenes de la cédula (ambas caras) y del documento de certificación arbitral DEBEN almacenarse en un espacio privado en la nube con acceso restringido exclusivamente al propietario autenticado, persistiendo sus referencias junto con todos los datos personales y arbitrales de forma atómica en el registro oficial del árbitro y su cuenta.
- **FR-008**: El criterio de perfil completo para el rol `Árbitro` DEBE evaluarse como verdadero únicamente cuando existan todos los datos personales obligatorios (documento, primer nombre, primer apellido, sexo, fecha de nacimiento, tipo de sangre, teléfono, departamento, municipio), el nivel de certificación arbitral, ambas caras de la cédula y el documento de certificación arbitral.
- **FR-009**: Durante la subida de imágenes y el guardado del perfil, el sistema DEBE aplicar un bloqueo `single-flight` con indicador de carga visible para evitar envíos o subidas duplicadas.
- **FR-010**: Ante permisos de cámara/galería denegados o revocados, o ante errores de red/conectividad al guardar, el sistema DEBE mostrar mensajes claros en español y conservar intactos los datos e imágenes ya capturadas en el formulario para permitir reintentar.
- **FR-011**: Al intentar salir del formulario con cambios sin guardar, el sistema DEBE mostrar un diálogo de confirmación en español antes de descartar los datos.
- **FR-012**: Todos los textos visibles de la pantalla del árbitro, validaciones, diálogos y accesos en Perfil DEBEN presentarse en español y gestionarse mediante el sistema centralizado de localización (`l10n`), sin textos incrustados directamente.

### Key Entities *(include if feature involves data)*

- **Perfil Oficial del Árbitro**: Extensión del registro del árbitro vinculada a su cuenta de usuario con atributos demográficos colombianos (primer/segundo nombre, primer/segundo apellido, documento, sexo, fecha de nacimiento, tipo de sangre, teléfono, departamento, municipio), categoría de certificación arbitral (`certificationLevel`), referencias a las dos caras de la cédula (`documentFrontUrl`, `documentBackUrl`) y referencia al documento de certificación arbitral (`certificationDocumentUrl`).
- **Documentos Privados del Árbitro**: Imágenes de cédula (frente y reverso) y documento de certificación arbitral almacenadas de forma privada bajo el ámbito exclusivo del usuario propietario.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de los árbitros autenticados con perfil incompleto pueden acceder desde Perfil al formulario dedicado, completar datos personales, ubicación en Colombia, ambas caras de la cédula y documento de certificación arbitral, y ver actualizado su estado a `Perfil completo` tras un guardado exitoso.
- **SC-002**: El 100% de los intentos de guardado con campos obligatorios vacíos o sin alguna de las 3 capturas obligatorias (cédula frente, cédula reverso, certificación arbitral) son bloqueados antes de enviar al servidor, mostrando el mensaje de validación correspondiente en español.
- **SC-003**: Ante pulsaciones rápidas repetidas sobre `Guardar perfil`, se ejecuta exactamente 1 operación de subida y persistencia (0 duplicados), y ante fallo de red se conserva el 100% de los campos e imágenes en el formulario.
- **SC-004**: El criterio de perfil completo para árbitro evalúa `false` siempre que falte cualquier campo obligatorio o cualquiera de los 3 documentos requeridos, y `true` únicamente cuando todos estén presentes, sin afectar el criterio de completitud de los demás roles (`Organizador`, `Entrenador`, `Jugador`, `Aficionado`).

## Assumptions

- La captura de foto de avatar del árbitro, su visualización en el avatar del Perfil y la pantalla dedicada de resumen del perfil del árbitro pertenecen a **HU 25.2** y quedan explícitamente fuera del alcance de esta historia.
- El almacenamiento de documentos de certificación arbitral puede residir en un bucket privado dedicado (`referee-certifications`) o en el bucket privado existente con rutas segregadas por propietario (`auth.uid()`), garantizando en ambos casos acceso privado restringido al titular.
- Si el árbitro ya existe en el registro oficial por número de documento (creado previamente por un organizador), el guardado atómico continúa enlazando y enriqueciendo dicho registro sin duplicarlo.
