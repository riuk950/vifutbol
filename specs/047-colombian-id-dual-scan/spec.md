# Feature Specification: Escaneo Dual de Cédula Colombiana, Autocompletado y Captura por Ambos Lados (HU 21.2)

**Feature Branch**: `047-colombian-id-dual-scan`

**Created**: 2026-11-17

**Status**: Draft

**Input**: User description: "[Épica 21] HU 21.2: Escaneo Dual de Cédula Colombiana (PDF417 + MRZ OCR), Autocompletado y Captura por Ambos Lados (Notion ID: 41b8442e-3f49-81ad-90d2-eced8c96c969)"

## Clarifications

### Session 2026-11-17

- Q: ¿Adjuntar las fotografías frontal y posterior de la cédula debe ser obligatorio para completar el perfil de jugador, o opcional permitiendo guardar solo con los datos manuales? → A: Obligatorio adjuntar ambas fotografías (frontal y posterior) para poder guardar y marcar completo el perfil del jugador (`UserRole.player`).
- Q: ¿El flujo `"Escanear / Capturar Cédula"` debe permitir únicamente captura en vivo con la cámara del dispositivo, o también seleccionar fotografías existentes desde la galería? → A: Solo cámara en vivo; se restringe la captura exclusivamente a la cámara del dispositivo para mayor control anti-suplantación.
- Q: ¿Cómo deben protegerse las imágenes de la cédula en el almacenamiento remoto y qué debe ocurrir si el jugador intenta guardar sin conexión cuando Supabase está activo? → A: Bucket privado autenticado con políticas RLS por propietario (`auth.uid()`); si Supabase está configurado y no hay conexión al guardar, se conserva el formulario y las fotografías locales intactas e informa el error para reintentar.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Captura Fotográfica por Ambos Lados y Previsualización con Opción de Recaptura (Priority: P1)

Como jugador completando mi ficha personal, quiero acceder desde la sección de documento de identidad del formulario a un flujo guiado para capturar la fotografía del lado frontal y del lado posterior de mi cédula colombiana, visualizando las miniaturas de ambas caras y pudiendo repetir cualquiera de las dos tomas si quedó borrosa, para respaldar mi identidad documental ante los organizadores de torneos.

**Why this priority**: Es la base visual y operativa de toda la funcionalidad: garantiza la obtención de ambas imágenes del documento antes de procesar o persistir la ficha, y permite al usuario controlar la calidad de las fotografías antes de continuar.

**Independent Test**: Se puede probar de forma independiente abriendo el flujo de captura desde el formulario de datos personales del jugador, tomando o seleccionando la cara frontal y la cara posterior, verificando que se muestran ambas miniaturas, repitiendo una de las caras y confirmando que la nueva imagen reemplaza a la anterior.

**Acceptance Scenarios**:

1. **Given** que el jugador se encuentra en el formulario de datos personales (`PlayerPersonalDataScreen`), **When** presiona la acción `"Escanear / Capturar Cédula"`, **Then** el sistema inicia el flujo guiado solicitando: (1) fotografía del lado frontal de la cédula y (2) fotografía del lado posterior (reverso con código de barras o zona de lectura mecánica).
2. **Given** que el jugador ha capturado una o ambas caras del documento, **When** visualiza el resumen de captura, **Then** ve las miniaturas de la cara frontal y posterior claramente diferenciadas y dispone de una acción para repetir individualmente cualquiera de las tomas.
3. **Given** que el usuario deniega el permiso de cámara del dispositivo, **When** intenta iniciar la captura fotográfica, **Then** el sistema informa en español de manera clara que el permiso es necesario para escanear el documento, ofrece acceso rápido a la configuración del sistema y permite continuar editando el formulario manualmente sin bloqueos.

---

### User Story 2 - Autocompletado Inteligente Dual (Código Bidimensional PDF417 y MRZ TD1 + OCR) (Priority: P1)

Como jugador con cédula colombiana de cualquier generación (cédula amarilla con hologramas y código de barras PDF417 o cédula digital de policarbonato con zona MRZ ICAO 9303 e información impresa), quiero que al capturar las caras de mi documento el sistema extraiga automáticamente mis datos personales y los rellene en el formulario, calculando inmediatamente mi edad, para agilizar mi registro y evitar errores de digitación.

**Why this priority**: Entrega el valor principal de automatización de la HU 21.2, soportando tanto el parque mayoritario de cédulas amarillas (PDF417) como las cédulas digitales modernas (MRZ de 3 líneas `I<COL...` + OCR).

**Independent Test**: Se puede probar de forma independiente entregando tramas reales de PDF417 y bloques de texto MRZ TD1/OCR al motor de análisis, verificando la extracción exacta de cada campo y la invocación reactiva de `applyDocumentScanData(...)` sobre el formulario de datos personales del jugador.

**Acceptance Scenarios**:

1. **Given** que el jugador captura el reverso de una cédula amarilla con hologramas cuyo código bidimensional PDF417 es legible, **When** finaliza el procesamiento automático, **Then** el sistema extrae y autocompleta automáticamente en el formulario: número de documento, primer nombre, segundo nombre (si existe), primer apellido, segundo apellido (si existe), sexo (`Masculino` / `Femenino`), fecha de nacimiento (disparando de inmediato el cálculo reactivo de edad) y tipo de sangre con factor RH (ej. `O+`, `A+`).
2. **Given** que el jugador captura una cédula digital de policarbonato sin PDF417 o con bloque MRZ de 3 líneas (`I<COL...`), **When** finaliza el procesamiento óptico de texto sobre las caras frontal y posterior, **Then** el analizador MRZ TD1 y las heurísticas OCR extraen y autocompletan: número de documento (NUIP), primer y segundo apellido, primer y segundo nombre, fecha de nacimiento (`YYMMDD`) con cálculo inmediato de edad, sexo y grupo sanguíneo/RH detectado en el texto impreso.
3. **Given** que el documento presenta desgaste físico, reflejos o baja iluminación que impiden leer todos los campos, **When** concluye el procesamiento, **Then** el sistema conserva las fotografías capturadas de ambos lados, autocompleta únicamente los campos que logró identificar con certeza y permite al jugador completar o corregir manualmente cualquier campo restante sin bloquear el flujo.

---

### User Story 3 - Persistencia Local y Sincronización Remota de Imágenes Documentales (Priority: P1)

Como jugador que ya capturó ambos lados de su cédula y completó su ficha personal, quiero que al guardar el formulario las imágenes frontal y posterior queden respaldadas de forma segura en mi dispositivo y sincronizadas con el almacenamiento remoto asociado a mi ficha de jugador, para que mi respaldo documental permanezca disponible tras cerrar sesión o cambiar de dispositivo.

**Why this priority**: Asegura la durabilidad y trazabilidad de la evidencia documental capturada en el servidor y en caché local, cerrando el ciclo completo de registro del jugador.

**Independent Test**: Se puede probar guardando un perfil completo con imágenes frontal y posterior capturadas, verificando la carga al almacenamiento remoto de archivos, la persistencia de las referencias en `vifutboldev.players` (`document_front_url`, `document_back_url`) y la conservación de las miniaturas al reabrir el formulario.

**Acceptance Scenarios**:

1. **Given** que el jugador capturó las imágenes frontal y posterior de su cédula y presiona guardar en el formulario completo, **When** el dispositivo cuenta con conectividad y el guardado remoto tiene éxito, **Then** las imágenes se almacenan de forma segura en el almacenamiento remoto, sus referencias (`document_front_url` y `document_back_url`) se persisten en la ficha del jugador y en caché local, y al reabrir la pantalla se visualiza que el respaldo documental está cargado.
2. **Given** que el jugador intenta guardar el formulario con imágenes recién capturadas mientras ocurre una falla de red, **When** la carga o sincronización falla, **Then** el sistema informa claramente el error en español, conserva las imágenes capturadas y los textos digitados en el formulario sin descartar el trabajo del usuario, y permite reintentar el guardado.

---

### Edge Cases

- ¿Qué ocurre si el jugador ya tenía datos diligenciados manualmente en el formulario (ej. teléfono, ubicación o posiciones) y luego presiona `"Escanear / Capturar Cédula"`? Los datos ya ingresados que no pertenecen a la cédula (teléfono, departamento, municipio, posiciones) deben preservarse intactos; solo se actualizan los campos extraídos de la cédula que hayan sido reconocidos con éxito.
- ¿Qué ocurre si el jugador envía la aplicación a segundo plano mientras está en el flujo de cámara o durante el procesamiento de las imágenes? El formulario y las caras ya capturadas no deben perderse al regresar al primer plano.
- ¿Qué ocurre si la trama PDF417 contiene caracteres especiales latinos (tildes o `Ñ`) o espacios de relleno (`padding`)? El analizador debe normalizar la codificación de caracteres y limpiar los espacios sobrantes sin introducir dobles espacios.
- ¿Qué ocurre si la fecha MRZ `YYMMDD` corresponde a personas nacidas antes o después del año 2000? El cálculo de siglo debe inferirse correctamente respecto a la fecha actual (evitando asignar años futuros como 2095 en lugar de 1995).
- ¿Qué ocurre si el usuario pulsa repetidamente el botón de escanear o guardar mientras hay una captura o subida en curso? Debe existir protección contra doble pulsación / envíos simultáneos.
- ¿Qué ocurre con la privacidad de la cédula? Ni el texto crudo de la trama PDF417/MRZ ni los datos sensibles del documento deben imprimirse en logs de consola o mensajes de error visibles.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE ofrecer en la sección de identificación de `PlayerPersonalDataScreen` una acción claramente visible para iniciar el flujo `"Escanear / Capturar Cédula"`.
- **FR-002**: El flujo de captura DEBE guiar al jugador para obtener fotografía del lado frontal y del lado posterior de la cédula colombiana, mostrando previsualizaciones (miniaturas) de ambas caras y permitiendo repetir individualmente cualquiera de las tomas.
- **FR-003**: El sistema DEBE implementar una estrategia dual de análisis documental sobre las imágenes capturadas:
  - Prioridad 1: Decodificación de código bidimensional estándar `PDF417` para extraer datos de cédulas amarillas colombianas con hologramas.
  - Prioridad 2 / Complemento: Reconocimiento óptico de texto (`OCR`) y analizador de zona legible por máquina (`MRZ` estándar ICAO 9303 TD1 de 3 líneas `I<COL...`) junto con heurísticas para campos impresos en cédulas digitales / policarbonato.
- **FR-004**: Al extraer datos válidos, el sistema DEBE autocompletar reactivamente en el formulario los campos disponibles: número de documento, primer nombre, segundo nombre, primer apellido, segundo apellido, sexo, fecha de nacimiento (disparando el cálculo inmediato de edad) y tipo de sangre con factor RH.
- **FR-005**: Ante deterioro físico del documento, reflejos o lectura parcial, el sistema NO DEBE bloquear el formulario; debe conservar las fotos tomadas, rellenar los campos identificados y permitir edición manual completa de todos los campos.
- **FR-006**: El sistema DEBE exigir obligatoriamente que el jugador adjunte tanto la fotografía frontal como la fotografía posterior de su cédula para guardar el formulario y considerar completo el perfil de jugador (`UserAccount.isProfileCompleteForActiveRole` para `UserRole.player` requerirá `documentFrontUrl` y `documentBackUrl` no vacíos).
- **FR-007**: El flujo de obtención de imágenes DEBE restringirse exclusivamente a captura en vivo mediante la cámara del dispositivo (sin selección desde galería), para fortalecer el control de autenticidad del documento físico.
- **FR-008**: Al persistir el perfil, las imágenes frontal y posterior DEBEN guardarse en caché local y sincronizarse con un bucket privado autenticado en almacenamiento remoto con políticas RLS por propietario (`auth.uid()`), asociando `document_front_url` y `document_back_url` al registro del jugador en `vifutboldev.players`. Cuando el backend remoto esté configurado y el dispositivo no tenga conexión, el sistema DEBE informar el error de conectividad conservando el formulario y las imágenes locales intactas para reintentar.
- **FR-009**: El sistema DEBE gestionar explícitamente permisos de cámara denegados o revocados, interrupciones del ciclo de vida y protección anti-doble pulsación tanto al abrir la cámara como al guardar las imágenes.
- **FR-010**: Todos los textos visibles al usuario (etiquetas, instrucciones de captura frontal/posterior, mensajes de permiso, errores de lectura o red) DEBEN estar en español centralizados mediante localización (`l10n`), mientras que clases, métodos, archivos y pruebas se escriben en inglés.

### Key Entities *(include if feature involves data)*

- **ColombianIdScanResult**: Resultado estructurado del análisis dual (PDF417 + MRZ/OCR), que encapsula los campos extraídos opcionales (`documentId`, `firstName`, `secondName`, `firstSurname`, `secondSurname`, `sex`, `birthDate`, `bloodType`), la fuente de extracción (`pdf417`, `mrzOcr`, `partial`) y las rutas locales de las imágenes capturadas (`frontImagePath`, `backImagePath`).
- **PlayerDocumentCapture**: Estado de captura de ambas caras del documento (frontal y posterior), con rutas locales temporales, estado de validación/procesamiento y URLs o referencias remotas persistidas (`documentFrontUrl`, `documentBackUrl`).
- **RoleProfileData & Players Table (`vifutboldev.players`)**: Extensión de los metadatos del jugador para almacenar y recuperar `documentFrontUrl` y `documentBackUrl`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El jugador puede capturar ambas caras de su cédula y visualizar las dos miniaturas listas para revisión en menos de 30 segundos bajo condiciones normales de iluminación.
- **SC-002**: El analizador PDF417 y MRZ TD1 extrae con 100% de exactitud los campos presentes en tramas y bloques válidos de prueba (sin espacios dobles, errores de siglo ni truncamiento de tildes/`Ñ`).
- **SC-003**: El autocompletado puebla instantáneamente el formulario tras concluir el procesamiento local de las imágenes (< 2 segundos tras la captura de ambas caras) y recalcula la edad de forma reactiva (< 100 ms).
- **SC-004**: El 100% de las pruebas unitarias (parsers PDF417, MRZ TD1, heurísticas OCR) y pruebas de widget (flujo de captura frontal/posterior, recaptura, autocompletado, manejo de permisos y responsividad en 320px/130%) se ejecutan con éxito y cero errores de análisis estático.

## Assumptions

- La pantalla dedicada `PlayerPersonalDataScreen` implementada en la HU 21.1 ya provee el hook `applyDocumentScanData(...)`, por lo que HU 21.2 se integrará directamente sobre dicha pantalla sin reestructurar el formulario base.
- Las fotografías se procesan de manera local en el dispositivo (on-device ML) sin requerir conexión a internet para la decodificación PDF417 ni el reconocimiento OCR/MRZ.
- En entornos de prueba o modo local sin Supabase remoto configurado, las rutas o respaldos de las imágenes se conservan en almacenamiento local para permitir validación funcional completa.
