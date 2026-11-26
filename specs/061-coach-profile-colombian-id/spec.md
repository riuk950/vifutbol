# Especificación de Funcionalidad: Perfil Completo del Entrenador (Cédula Colombiana, Escaneo Dual y Fotos por Ambos Lados)

**Directorio de Funcionalidad**: `specs/061-coach-profile-colombian-id`  
**Creada**: 2026-11-26  
**Estado**: Borrador  
**Fuente**: Notion — `[Épica 27] HU 27.1: Perfil Completo del Entrenador: Datos de Cédula Colombiana, Escaneo Dual y Fotos por Ambos Lados` (`4248442e-3f49-814b-8717-fd09b9dfcb2e`)

## Clarifications

### Session 2026-11-26

- Q: ¿El nombre del club y el nivel de licencia deben ser obligatorios para todos los entrenadores o deben admitir entrenadores independientes/sin licencia formal? → A: Ambos campos son obligatorios; se permite indicar "Independiente" en club y "Sin licencia" en nivel de licencia cuando aplique.
- Q: ¿Qué regla de validación de edad mínima debe aplicarse a la fecha de nacimiento del entrenador? → A: Mayor de edad (mínimo 18 años cumplidos a la fecha de registro).
- Q: ¿Cómo deben mostrarse las fotografías de ambos lados de la cédula en la pantalla resumen del entrenador? → A: Mostrar miniaturas en línea de ambos lados de la cédula (acceso privado temporal) con opción de tocar para ver en tamaño completo.

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia de Usuario 1 — Completar Perfil del Entrenador con Datos de Cédula Colombiana y Datos Técnicos (Prioridad: P1)

Como entrenador registrado en ViFutbol con el perfil incompleto, quiero acceder desde la pestaña Perfil a un formulario dedicado para ingresar mis datos personales de cédula colombiana, mi ubicación en Colombia y mis datos técnicos (club y nivel de licencia), para acreditar oficialmente mi identidad como director técnico en la plataforma.

**Por qué esta prioridad**: Es el núcleo de la historia de usuario; sin el formulario completo y la validación de campos obligatorios el entrenador no puede completar su perfil ni acreditar su identidad con la misma paridad que el rol jugador.

**Prueba Independiente**: Puede probarse de forma aislada iniciando sesión como un entrenador con perfil incompleto, accediendo desde la pestaña Perfil a "Completar perfil", verificando la presencia de todos los campos de identidad, ubicación y datos técnicos, probando la validación de campos faltantes y completando el guardado exitoso con conexión a internet.

**Escenarios de Aceptación**:

1. **Dado** un usuario autenticado con rol entrenador cuyo perfil está incompleto, **Cuando** presiona "Completar perfil" en la pestaña Perfil, **Entonces** el sistema lo dirige a la pantalla dedicada de datos personales del entrenador donde visualiza las secciones de datos de cédula colombiana, ubicación en Colombia, captura de documento por ambos lados y datos técnicos del entrenador (club y nivel de licencia).
2. **Dado** un entrenador que previamente registró parcialmente datos técnicos (como club o nivel de licencia) pero carece de datos personales o fotos de cédula, **Cuando** abre el formulario de completar perfil, **Entonces** los datos ya registrados aparecen precargados para evitar doble captura mientras los campos faltantes se muestran listos para diligenciar.
3. **Dado** que el entrenador selecciona un departamento de Colombia en el formulario, **Cuando** abre el selector de municipio, **Entonces** visualiza únicamente los municipios correspondientes al departamento seleccionado; y si cambia de departamento posteriormente, el municipio seleccionado anteriormente se limpia para evitar combinaciones inválidas.
4. **Dado** que el entrenador omite al menos un campo obligatorio (número de documento, primer nombre, primer apellido, sexo, fecha de nacimiento, tipo de sangre RH, teléfono, departamento, municipio, club o nivel de licencia) o alguna de las dos fotografías de la cédula, **Cuando** presiona "Guardar perfil", **Entonces** el sistema bloquea el envío y muestra mensajes claros en español indicando exactamente qué campos o fotografías faltan.

---

### Historia de Usuario 2 — Escaneo Dual de Cédula Colombiana y Fotografía por Ambos Lados (Prioridad: P1)

Como entrenador diligenciando mi perfil, quiero escanear mi cédula colombiana (tanto tradicional como digital) para autocompletar mis datos de identidad y capturar las fotografías del lado frontal y del lado posterior del documento con vista previa antes de guardar, para agilizar el registro y aportar respaldo visual verificable de mi documento.

**Por qué esta prioridad**: Es un requisito central de paridad con el flujo de jugador y una condición obligatoria para que el perfil del entrenador se considere completo y verificable.

**Prueba Independiente**: Puede probarse desde el formulario del entrenador ejecutando el escaneo dual de una cédula colombiana (formato tradicional o digital) y capturando/seleccionando ambas caras del documento, comprobando el autocompletado de campos, la previsualización de ambas caras y el manejo resiliente de permisos de cámara o galería.

**Escenarios de Aceptación**:

1. **Dado** que el entrenador se encuentra en el formulario de perfil, **Cuando** escanea su cédula colombiana (mediante lectura de código bidimensional de cédula tradicional o lectura óptica de cédula digital), **Entonces** el sistema autocompleta automáticamente número de documento, primer nombre, segundo nombre (si existe), primer apellido, segundo apellido (si existe), fecha de nacimiento, sexo y tipo de sangre (RH), permitiendo al entrenador revisar y ajustar cualquier dato antes de guardar.
2. **Dado** que el entrenador se encuentra en la sección de fotografías del documento, **Cuando** captura o selecciona la imagen del lado frontal y la imagen del lado posterior de su cédula, **Entonces** el sistema muestra la vista previa clara de ambos lados antes de guardar y permite reemplazar cualquiera de las dos imágenes si desea tomarla nuevamente.
3. **Dado** que el entrenador intenta escanear o fotografiar su cédula y el permiso de cámara o galería es denegado, **Cuando** el sistema detecta la falta de permiso, **Entonces** muestra un mensaje claro en español explicando por qué se necesita el permiso y ofreciendo abrir la configuración del dispositivo o continuar con el diligenciamiento manual de los campos.
4. **Dado** que el escaneo no logra leer el documento (por baja iluminación, desenfoque o formato ilegible), **Cuando** finaliza o se cancela el intento de escaneo, **Entonces** el sistema informa claramente el resultado en español sin borrar datos ya ingresados y permite reintentar el escaneo o diligenciar los campos manualmente.

---

### Historia de Usuario 3 — Persistencia Atómica, Almacenamiento Privado y Criterio de Perfil Completo (Prioridad: P1)

Como entrenador que completó todos sus datos y fotografió ambos lados de su cédula, quiero que al guardar mi perfil las fotografías se almacenen de forma privada y toda mi información se registre de manera consistente sin duplicados, para que mi estado en la plataforma pase a "Perfil completo" de forma segura.

**Por qué esta prioridad**: Garantiza la integridad de los datos, la privacidad de documentos de identidad sensibles y la transición confiable del estado del perfil del entrenador.

**Prueba Independiente**: Puede probarse completando todos los campos obligatorios y ambas fotos de la cédula, pulsando "Guardar perfil" (incluyendo toques repetidos y pruebas sin conexión) y verificando que las imágenes quedan protegidas solo para el titular, que los datos se persisten íntegramente y que la pestaña Perfil refleja inmediatamente "Perfil completo".

**Escenarios de Aceptación**:

1. **Dado** que el entrenador diligenció todos los campos obligatorios y capturó ambas caras de la cédula con conexión a internet, **Cuando** presiona "Guardar perfil", **Entonces** el sistema sube ambas fotografías a un almacenamiento privado accesible únicamente por el propio titular, guarda atómicamente los datos personales, ubicación, referencias de las fotografías y datos técnicos del entrenador, y actualiza el estado de la cuenta a "Perfil completo".
2. **Dado** que el guardado está en progreso (subiendo fotografías y registrando datos), **Cuando** el entrenador pulsa repetidamente el botón "Guardar perfil", **Entonces** el sistema ignora los toques adicionales (ejecución única en vuelo) y muestra un indicador claro de progreso hasta completar o informar un error.
3. **Dado** que ocurre una falla de conectividad o un error al subir alguna de las fotografías o al guardar los datos, **Cuando** falla la operación, **Entonces** el perfil no queda marcado como completo ni guardado parcialmente de forma inconsistente, se muestra un mensaje claro de error en español, y todos los datos diligenciados y fotos seleccionadas se conservan en pantalla para reintentar.

---

### Historia de Usuario 4 — Pantalla Resumen y Edición del Perfil del Entrenador (Prioridad: P2)

Como entrenador con el perfil completo, quiero consultar desde la pestaña Perfil una pantalla resumen con mis datos personales, ubicación, datos técnicos y fotografías de documento registradas, y poder editarlos cuando necesite actualizarlos, para mantener mi información siempre al día.

**Por qué esta prioridad**: Completa el ciclo de vida del perfil del entrenador una vez diligenciado, permitiendo verificación visual y mantenimiento continuo de los datos sin perder la integridad del perfil completo.

**Prueba Independiente**: Puede probarse con un entrenador cuyo perfil ya está completo accediendo desde la pestaña Perfil a la pantalla resumen, verificando que se muestran todos sus datos y estado de documentos, entrando en modo edición, actualizando un dato (con y sin reemplazar fotografías) y confirmando la persistencia.

**Escenarios de Aceptación**:

1. **Dado** un entrenador con perfil completo en la pestaña Perfil, **Cuando** visualiza su estado de perfil y selecciona la opción de consultar sus datos personales, **Entonces** ve el estado "Perfil completo" y navega a la pantalla resumen del entrenador con sus datos personales, ubicación, club, nivel de licencia y miniaturas en línea de ambas caras del documento (con acceso privado temporal y opción de tocar para ampliar).
2. **Dado** que el entrenador se encuentra en la pantalla resumen, **Cuando** selecciona "Editar", **Entonces** abre el formulario de perfil precargado con toda su información actual y las referencias de sus fotografías existentes.
3. **Dado** que el entrenador edita uno o más campos de texto en un perfil ya completo sin volver a fotografiar la cédula, **Cuando** presiona "Guardar perfil", **Entonces** el sistema conserva las fotografías previamente guardadas y actualiza únicamente los datos modificados sin obligarlo a recapturar el documento.
4. **Dado** que el entrenador realiza cambios en el formulario y presiona regresar sin guardar, **Cuando** intenta salir de la pantalla, **Entonces** el sistema solicita confirmación explícita en español antes de descartar los cambios pendientes.

---

### Casos Borde y Comportamiento Móvil

- **Sin conexión a internet al guardar**: Si el dispositivo pierde conectividad al pulsar "Guardar perfil", el sistema informa claramente en español que no hay conexión disponible, no limpia el formulario ni las fotos seleccionadas y permite reintentar cuando se recupere la red.
- **Interrupción por cámara o selector de archivos**: Si el sistema operativo suspende temporalmente la pantalla mientras el entrenador toma la fotografía de la cédula o selecciona una imagen de la galería, los datos ya diligenciados en el formulario deben conservarse intactos al regresar.
- **Formato de fechas y validaciones básicas**: La fecha de nacimiento debe corresponder a una persona mayor de edad (mínimo 18 años cumplidos a la fecha actual) y no puede ser futura; no se permiten textos compuestos únicamente por espacios en campos obligatorios, mientras que los campos opcionales (segundo nombre y segundo apellido) pueden quedar vacíos sin bloquear el guardado.
- **Reemplazo selectivo de fotografías en edición**: Si en modo edición el entrenador reemplaza solo la foto frontal (o solo la posterior), el sistema sube únicamente la nueva imagen y conserva la otra cara existente.
- **Privacidad de datos sensibles**: El número de documento, fecha de nacimiento, tipo de sangre, teléfono y las fotografías de la cédula no deben exponerse públicamente ni quedar accesibles a otros usuarios no autorizados; su acceso de almacenamiento queda restringido al propietario autenticado.
- **Accesibilidad y tamaños de texto**: El formulario y la pantalla resumen deben ser completamente desplazables verticalmente, mantener áreas táctiles cómodas y soportar tamaños de fuente ampliados del sistema sin recortar etiquetas ni ocultar botones de acción.

## Requisitos *(obligatorio)*

### Requisitos Funcionales

- **FR-001**: El sistema DEBE ofrecer una pantalla dedicada de formulario de datos personales para el rol entrenador, accesible desde la pestaña Perfil cuando el perfil del entrenador esté incompleto.
- **FR-002**: El formulario del entrenador DEBE capturar con paridad respecto al flujo de jugador los siguientes datos de identidad y contacto: número de documento de identidad (obligatorio), primer nombre (obligatorio), segundo nombre (opcional), primer apellido (obligatorio), segundo apellido (opcional), sexo (obligatorio), fecha de nacimiento (obligatorio, mínimo 18 años cumplidos), tipo de sangre / RH (obligatorio) y teléfono (obligatorio).
- **FR-003**: El formulario del entrenador DEBE capturar la ubicación en Colombia mediante departamento (obligatorio) y municipio dependiente del departamento seleccionado (obligatorio), limpiando el municipio cuando el usuario cambie de departamento.
- **FR-004**: El formulario del entrenador DEBE capturar los datos técnicos propios del rol: nombre del club o institución (obligatorio, permitiendo indicar "Independiente" cuando no pertenezca a un club) y nivel de licencia (obligatorio, incluyendo la opción "Sin licencia" para entrenadores sin licencia formal).
- **FR-005**: El sistema DEBE permitir el escaneo dual de la cédula colombiana (cédula tradicional con código bidimensional y cédula digital con lectura óptica) desde el formulario del entrenador, autocompletando número de documento, nombres, apellidos, fecha de nacimiento, sexo y tipo de sangre (RH) cuando estén presentes en la lectura, manteniendo editables los campos para corrección manual.
- **FR-006**: El sistema DEBE permitir capturar (desde cámara o galería) y previsualizar por separado la fotografía del lado frontal y la fotografía del lado posterior de la cédula colombiana antes de guardar, con opción de reemplazar cualquiera de ellas.
- **FR-007**: El sistema DEBE validar antes de enviar que todos los campos obligatorios (identidad, ubicación y datos técnicos) y ambas fotografías del documento (o sus versiones previamente guardadas al editar) estén presentes, mostrando mensajes de validación claros en español junto a los campos o secciones faltantes.
- **FR-008**: El sistema DEBE subir las fotografías de ambos lados de la cédula a un almacenamiento privado protegido con políticas de acceso restringidas exclusivamente al propietario de la cuenta.
- **FR-009**: El sistema DEBE persistir de forma atómica los datos personales, la ubicación, las referencias a las dos fotografías del documento y los datos técnicos del entrenador junto con la actualización de la cuenta del usuario, garantizando que un fallo no deje el perfil en estado inconsistente ni marcado erróneamente como completo.
- **FR-010**: El criterio de completitud de perfil para el rol entrenador DEBE evaluarse como verdadero únicamente cuando estén diligenciados todos los datos personales obligatorios, la ubicación en Colombia, los datos técnicos del entrenador (club y nivel de licencia) y las fotografías de ambos lados de la cédula.
- **FR-011**: La pestaña Perfil DEBE redirigir al entrenador con perfil incompleto al formulario dedicado de completar perfil, y para el entrenador con perfil completo DEBE mostrar el estado "Perfil completo" y permitir navegar a una pantalla resumen dedicada de sus datos personales.
- **FR-012**: La pantalla resumen del entrenador DEBE mostrar de forma ordenada todos los datos personales, ubicación, datos técnicos y miniaturas en línea de ambos lados de la cédula cargadas mediante acceso privado temporal del titular (con opción de tocar para ampliar en pantalla completa), ofreciendo además una acción clara para abrir el formulario en modo edición precargado con los datos actuales.
- **FR-013**: El sistema DEBE aplicar prevención de doble envío durante la subida de fotografías y el guardado del perfil, mostrando estado de carga claro y bloqueando reenvíos concurrentes hasta que la operación termine.
- **FR-014**: El sistema DEBE gestionar de forma resiliente los permisos de cámara y galería con mensajes explicativos en español, ofrecer navegación a los ajustes del dispositivo en caso de denegación permanente y permitir siempre el diligenciamiento manual si el usuario decide no escanear.
- **FR-015**: El sistema DEBE solicitar confirmación en español antes de descartar cambios sin guardar cuando el entrenador intente abandonar el formulario modificado.
- **FR-016**: Todos los textos visibles para el usuario (etiquetas, placeholders, botones, mensajes de validación, errores, estados y diálogos) DEBEN estar redactados en español claro y consistente con el resto de la aplicación.

### Entidades Clave *(incluir si la funcionalidad maneja datos)*

- **Perfil de Entrenador**: Registro de identidad y acreditación técnica asociado a la cuenta de un usuario con rol entrenador. Contiene los datos personales de cédula colombiana (número de documento, primer y segundo nombre, primer y segundo apellido, sexo, fecha de nacimiento, tipo de sangre RH, teléfono), ubicación en Colombia (departamento y municipio), datos técnicos (nombre del club y nivel de licencia) y las referencias seguras a las fotografías frontal y posterior del documento de identidad.
- **Cuenta de Usuario**: Representa al usuario autenticado y su rol activo, manteniendo la sincronización del nombre completo/datos básicos y el estado de perfil completo evaluado según las reglas del rol activo.
- **Fotografía de Documento de Identidad**: Archivo de imagen correspondiente al lado frontal o posterior de la cédula colombiana, almacenado en un espacio privado vinculado al titular de la cuenta para evitar accesos no autorizados.

## Criterios de Éxito *(obligatorio)*

### Resultados Medibles

- **SC-001**: El 100% de los entrenadores con perfil incompleto puede acceder desde la pestaña Perfil al formulario dedicado y completar su registro con datos de cédula colombiana, ubicación, datos técnicos y ambas caras del documento en un solo flujo continuo sin pasos externos.
- **SC-002**: El escaneo dual de cédula colombiana autocompleta automáticamente los campos de identidad reconocidos en menos de 3 segundos tras la lectura exitosa, reduciendo la captura manual a revisión y datos complementarios (teléfono, ubicación, club y licencia).
- **SC-003**: El 100% de los intentos de guardar sin al menos una fotografía de la cédula o sin un campo obligatorio son bloqueados antes de enviar datos al servidor, indicando claramente en español los elementos faltantes.
- **SC-004**: El 100% de las fotografías de cédula cargadas por entrenadores quedan almacenadas en acceso privado exclusivo del titular y vinculadas atómicamente al perfil, sin dejar perfiles marcados como completos cuando falte alguna foto o dato obligatorio.
- **SC-005**: Tras un guardado exitoso, el estado visible en la pestaña Perfil cambia inmediatamente a "Perfil completo" y el entrenador puede abrir su pantalla resumen y editar sus datos conservando las fotografías previamente registradas si no las reemplaza.

## Supuestos y Alcance

- **Alcance de esta especificación (HU 27.1)**: Cubre exclusivamente el perfil completo del entrenador (formulario con datos de cédula colombiana, ubicación en Colombia, escaneo dual, captura de ambas caras de la cédula, almacenamiento privado, persistencia atómica, criterio de perfil completo, pantalla resumen y edición).
- **Fuera de alcance**: Funcionalidades de otras historias de la Épica 27 (como foto de perfil/avatar del entrenador o flujos administrativos adicionales en HU 27.2 y HU 27.3), así como verificación automática externa ante registraduría o aprobación manual por parte de administradores.
- **Supuestos**:
  - El catálogo de departamentos y municipios de Colombia ya existe en la plataforma y se reutiliza para mantener consistencia con el rol jugador.
  - Los entrenadores ya existentes que solo habían diligenciado club y nivel de licencia pasarán a ver su perfil como incompleto hasta complementar sus datos personales y fotografías de cédula, conservando precargados su club y nivel de licencia actuales.
  - Se asume el idioma español para toda la experiencia de usuario final.
