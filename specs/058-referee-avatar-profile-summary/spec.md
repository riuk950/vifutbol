# Especificación de Funcionalidad: Foto de Avatar del Árbitro, Visualización en Perfil y Pantalla Resumen

**Feature Branch**: `058-referee-avatar-profile-summary`

**Created**: 2026-11-25

**Status**: Draft

**Input**: User description: "HU 25.2: Captura de Foto de Avatar del Árbitro, Visualización en Perfil y Pantalla Resumen"

## Clarifications

### Session 2026-11-25

- Q: ¿La fotografía de avatar del árbitro debe ser opcional o obligatoria para considerar su perfil como "Perfil completo"? → A: Opcional; el perfil arbitral es "Perfil completo" con los requisitos de HU 25.1 y el avatar puede agregarse o reemplazarse en cualquier momento (si no existe, se muestra el ícono de respaldo).
- Q: ¿Qué debe ocurrir si el árbitro intenta guardar una nueva fotografía de avatar mientras está sin conexión a internet? → A: Requerir conexión para guardar el avatar en la nube; si está offline, muestra un error claro en español conservando todos los datos y la vista previa local en el formulario para reintentar, mientras la consulta del avatar y resumen ya guardados sigue funcionando offline.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Captura y actualización de fotografía de avatar del árbitro (Priority: P1)

Como árbitro registrado en ViFutbol, quiero capturar o seleccionar mi fotografía de avatar desde mi formulario de perfil, ver una vista previa circular en tiempo real y poder cambiarla antes de guardar, para contar con una identificación visual oficial asociada a mi cuenta y a mi perfil arbitral.

**Why this priority**: Es la capacidad base de la historia de usuario; sin capturar y persistir el avatar del árbitro no puede mostrarse en la tarjeta de perfil ni en la pantalla resumen.

**Independent Test**: Se puede probar de forma independiente abriendo el formulario de perfil del árbitro, seleccionando una foto desde cámara o galería, verificando la vista previa circular, reemplazándola antes de guardar y confirmando que tras guardar la fotografía queda asociada a la cuenta y al perfil arbitral.

**Acceptance Scenarios**:

1. **Given** un árbitro autenticado en su formulario de perfil, **When** presiona la acción para tomar una foto de perfil o seleccionar una imagen de la galería y confirma la imagen, **Then** visualiza la vista previa circular de su avatar en el formulario con la opción de cambiarla antes de guardar.
2. **Given** un árbitro que ya tiene una fotografía de avatar cargada en el formulario, **When** selecciona una nueva imagen para reemplazarla y guarda el formulario, **Then** el sistema actualiza la fotografía de avatar en su cuenta y en su perfil arbitral, evitando mostrar versiones antiguas en caché.
3. **Given** un árbitro que presiona guardar tras capturar o cambiar su fotografía de avatar, **When** la operación de subida y guardado está en curso, **Then** el formulario bloquea envíos duplicados mostrando estado de carga hasta completar o reportar error.
4. **Given** un árbitro que intenta guardar su avatar sin conexión a internet disponible, **When** presiona guardar, **Then** el sistema informa claramente en español que se requiere conexión a internet para sincronizar los datos, conservando intactos la vista previa local del avatar y todos los datos diligenciados en el formulario para reintentar al recuperar conectividad.

---

### User Story 2 - Visualización reactiva del avatar y estado en la pestaña Perfil (Priority: P1)

Como árbitro que guardó su fotografía de avatar y completó su perfil, quiero ver mi fotografía real reflejada inmediatamente en la tarjeta de identidad de la pestaña Perfil junto con el indicador de perfil completo, para confirmar visualmente que mi identidad arbitral está actualizada.

**Why this priority**: Entrega el retorno visual inmediato al usuario en la pantalla principal de Perfil y valida la consistencia entre el formulario y la identidad mostrada en toda la aplicación.

**Independent Test**: Se puede probar de forma independiente regresando a la pestaña Perfil tras guardar el avatar y el perfil del árbitro, verificando que la tarjeta de identidad reemplaza el ícono genérico por la fotografía real y exhibe el distintivo de perfil completo.

**Acceptance Scenarios**:

1. **Given** un árbitro que acaba de guardar su fotografía de avatar y completar su perfil, **When** regresa a la pestaña Perfil, **Then** la tarjeta de identidad muestra su fotografía real en el avatar circular en lugar del ícono genérico y muestra el indicador de "Perfil completo".
2. **Given** un árbitro con perfil completo que aún no ha cargado una fotografía de avatar o cuya imagen remota falla al cargar, **When** abre la pestaña Perfil, **Then** la tarjeta de identidad muestra un respaldo visual limpio (ícono o inicial) sin errores bloqueantes ni pantalla rota.
3. **Given** un árbitro que reemplaza su avatar por una foto nueva, **When** vuelve a la pestaña Perfil, **Then** la tarjeta de identidad muestra la fotografía recién guardada de inmediato sin depender de reiniciar la aplicación.

---

### User Story 3 - Pantalla resumen del perfil arbitral y acceso a edición (Priority: P2)

Como árbitro con perfil completo, quiero acceder desde la pestaña Perfil a una pantalla resumen con mi avatar, datos personales de la cédula, ubicación, nivel de certificación y vistas previas de mis documentos (ambos lados de la cédula y documento de certificación arbitral), con una acción directa para editar, para revisar mi información oficial sin riesgo de modificarla accidentalmente y actualizarla cuando lo necesite.

**Why this priority**: Completa la experiencia de consulta y mantenimiento del perfil arbitral en paridad con el flujo de perfil completo de otros roles, separando la lectura segura de la edición.

**Independent Test**: Se puede probar de forma independiente tocando el acceso directo de datos personales en la pestaña Perfil de un árbitro con perfil completo, verificando que se muestran todas las secciones de solo lectura y que el botón "Editar" abre el formulario precargado con la información actual.

**Acceptance Scenarios**:

1. **Given** un árbitro con perfil completo en la pestaña Perfil, **When** selecciona el acceso directo de sus datos personales / perfil arbitral, **Then** navega a la pantalla resumen donde visualiza su avatar circular, sus datos personales de la cédula, su ubicación en Colombia, su nivel de certificación arbitral y las vistas previas de ambos lados de la cédula y del documento de certificación arbitral.
2. **Given** un árbitro en su pantalla resumen, **When** presiona la acción "Editar" en la barra superior, **Then** abre el formulario de edición precargado con su avatar, datos personales y documentos actuales.
3. **Given** un árbitro que guarda cambios tras entrar desde "Editar" en la pantalla resumen, **When** regresa a la pantalla resumen, **Then** los datos y la fotografía de avatar mostrados reflejan inmediatamente la versión actualizada.
4. **Given** un árbitro cuyo perfil aún está incompleto en la pestaña Perfil, **When** selecciona el acceso directo para completar su perfil, **Then** navega directamente al formulario de edición para completar los campos faltantes en lugar de una vista resumen vacía.

---

### User Story 4 - Manejo resiliente de permisos y errores de imagen (Priority: P2)

Como árbitro intentando capturar o seleccionar mi fotografía de avatar, quiero recibir mensajes claros en español si deniego permisos de cámara o galería o si ocurre un error al cargar la imagen, para saber cómo resolverlo sin que la aplicación falle ni pierda los datos que ya ingresé.

**Why this priority**: Garantiza resiliencia en dispositivos móviles reales donde los permisos pueden rechazarse, revocarse o donde la red puede ser inestable al cargar imágenes.

**Independent Test**: Se puede probar simulando rechazo temporal o permanente de permisos de cámara/galería y fallos de carga de imagen, verificando los mensajes orientativos en español, la conservación de los datos del formulario y el respaldo visual del avatar.

**Acceptance Scenarios**:

1. **Given** un árbitro que presiona tomar foto de perfil sin haber concedido permiso de cámara, **When** el sistema operativo rechaza el permiso, **Then** se muestra un mensaje claro en español indicando cómo habilitar el permiso en ajustes del dispositivo o usar la galería, sin cerrar la aplicación ni perder los datos ingresados en el formulario.
2. **Given** un árbitro que intenta seleccionar una imagen de la galería sin permiso o cancela la selección, **When** regresa al formulario, **Then** si canceló no se muestra error y se mantiene su estado previo; si el permiso fue denegado se informa en español con alternativa clara.
3. **Given** un árbitro en la pestaña Perfil o en la pantalla resumen cuya imagen de avatar o documento no puede descargarse temporalmente, **When** se renderiza la vista, **Then** se muestra un estado de respaldo visual claro sin bloquear la navegación ni impedir pulsar "Editar".

---

### Edge Cases

- **Cancelación durante la selección de foto**: Si el árbitro abre la cámara o la galería y cancela sin elegir imagen, el avatar anterior (si existía) y el resto del formulario permanecen intactos sin mostrar mensajes de error.
- **Salida con cambios sin guardar**: Si el árbitro cambia únicamente su foto de avatar en el formulario e intenta navegar hacia atrás sin guardar, el sistema solicita confirmación antes de descartar el cambio.
- **Reemplazo de avatar y caché de imagen**: Al actualizar una fotografía existente, el nuevo archivo debe reflejarse inmediatamente en el formulario, en la tarjeta de Perfil y en la pantalla resumen sin mostrar la imagen antigua almacenada en caché.
- **Operación en curso y segundo plano**: Si el árbitro minimiza la aplicación mientras edita el formulario antes de guardar, los datos no guardados permanecen mientras la pantalla siga viva; si ya pulsó guardar, se bloquean pulsaciones repetidas para evitar cargas duplicadas.
- **Usuario sin conexión al consultar el resumen**: Si el árbitro abre la pantalla resumen sin conectividad, visualiza los datos almacenados localmente y un respaldo visual apropiado para cualquier imagen remota que no esté disponible en caché local.
- **Accesibilidad y tamaños de pantalla**: El avatar circular, los botones de captura/edición y las tarjetas de documentos del resumen deben adaptarse a diferentes tamaños de pantalla y escalado de texto del sistema sin desbordamientos, ofreciendo etiquetas accesibles para lectores de pantalla.
- **Seguridad y privacidad**: Los mensajes de error y registros no deben exponer rutas internas, credenciales ni datos sensibles del documento de identidad o del certificado arbitral.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El formulario de perfil del árbitro DEBE permitir capturar una fotografía de avatar mediante la cámara del dispositivo o seleccionarla desde la galería de imágenes.
- **FR-002**: El formulario de perfil del árbitro DEBE mostrar una vista previa circular en tiempo real de la fotografía de avatar seleccionada o previamente guardada, permitiendo reemplazarla antes de guardar.
- **FR-003**: El sistema DEBE almacenar la fotografía de avatar del árbitro de forma persistente y vincularla tanto a la cuenta del usuario como al registro del perfil arbitral de manera consistente.
- **FR-004**: Al actualizar la fotografía de avatar, el sistema DEBE garantizar que la nueva versión invalide representaciones en caché previas para que se muestre de inmediato en todas las vistas de la aplicación.
- **FR-005**: El sistema DEBE mostrar una vista previa local inmediata de la fotografía de avatar seleccionada en el formulario, exigir conectividad para completar el guardado en la nube (mostrando un mensaje claro en español si no hay conexión sin perder los datos ni la selección local) y permitir consultar sin conexión el resumen y la imagen ya guardados/cacheados localmente.
- **FR-006**: La pestaña Perfil DEBE mostrar reactivamente la fotografía de avatar del árbitro en su tarjeta de identidad en reemplazo del ícono genérico tan pronto como exista una fotografía válida, junto con el indicador de "Perfil completo" cuando el perfil arbitral cumpla sus requisitos de HU 25.1 (sin exigir la fotografía de avatar como condición obligatoria para dicho estado).
- **FR-007**: Cuando el árbitro no tenga fotografía de avatar o esta no pueda cargarse, la pestaña Perfil y la pantalla resumen DEBEN mostrar un respaldo visual apropiado sin bloquear la experiencia.
- **FR-008**: La pestaña Perfil DEBE ofrecer al árbitro con perfil completo un acceso directo claramente etiquetado hacia una pantalla resumen de sus datos personales y perfil arbitral.
- **FR-009**: La pantalla resumen del árbitro DEBE presentar en modo de solo lectura: la fotografía de avatar circular, los datos personales derivados de la cédula colombiana (documento, nombres, apellidos, sexo, fecha de nacimiento, tipo de sangre, teléfono), la ubicación (departamento y municipio), el nivel de certificación arbitral y las vistas previas de ambos lados de la cédula y del documento de certificación arbitral.
- **FR-010**: La pantalla resumen del árbitro DEBE incluir una acción "Editar" en la barra superior que abra el formulario de perfil precargado con los datos y fotografías actuales, y refleje los cambios actualizados al volver tras guardar.
- **FR-011**: Si un árbitro con perfil incompleto selecciona el acceso de perfil personal desde la pestaña Perfil, el sistema DEBE dirigirlo al formulario de edición para completar su información.
- **FR-012**: El sistema DEBE aplicar protección contra envíos duplicados durante la carga del avatar y el guardado del perfil, y advertir antes de descartar cambios no guardados al salir del formulario (incluyendo cambios solo en el avatar).
- **FR-013**: Si el usuario deniega permisos de cámara o galería (temporal o permanentemente), el sistema DEBE mostrar un mensaje claro en español explicando cómo habilitar el permiso o usar la opción alternativa, sin cerrar la aplicación ni perder los campos diligenciados.
- **FR-014**: Todos los textos visibles, etiquetas, botones, estados vacíos y mensajes de error DEBEN presentarse en español centralizado y cumplir con accesibilidad básica (etiquetas semánticas, contraste legible y adaptación a escalado de texto).
- **FR-015**: El acceso a la pantalla resumen, al formulario de edición y a la actualización del avatar arbitral DEBE restringirse exclusivamente al usuario autenticado con rol activo de árbitro propietario de la cuenta.

### Key Entities *(include if feature involves data)*

- **Cuenta de Usuario (Árbitro)**: Identidad principal del usuario autenticado; almacena la referencia pública a su fotografía de avatar, nombre completo, rol activo y estado de completitud del perfil.
- **Perfil Arbitral**: Extensión específica del rol árbitro vinculada a la cuenta de usuario; almacena datos personales de identidad, ubicación, nivel de certificación, referencias a ambos lados de la cédula, referencia al documento de certificación arbitral y referencia sincronizada a la fotografía de avatar.
- **Fotografía de Avatar**: Imagen de perfil del árbitro (origen local temporal previo a sincronización o referencia pública con control de frescura de caché) mostrada en la tarjeta de Perfil, el formulario y la pantalla resumen.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un árbitro puede capturar o seleccionar su foto de avatar y guardarla desde su formulario de perfil en menos de 45 segundos en un flujo sin errores.
- **SC-002**: El 100% de los árbitros que guardan una fotografía de avatar visualizan la nueva imagen en la tarjeta de identidad de la pestaña Perfil y en la pantalla resumen inmediatamente al regresar, sin necesidad de cerrar ni reiniciar la aplicación.
- **SC-003**: El 100% de los árbitros con perfil completo pueden consultar en la pantalla resumen sus datos personales, ubicación, nivel de certificación, avatar y vistas previas de sus tres documentos (frente de cédula, reverso de cédula y certificación arbitral) en un solo toque desde la pestaña Perfil.
- **SC-004**: El 100% de los escenarios de permiso denegado (cámara o galería) y error de carga de imagen se recuperan sin cierres inesperados, conservando el 100% de los datos ingresados previamente en el formulario y mostrando mensajes comprensibles en español.
- **SC-005**: Cero operaciones duplicadas de guardado o subida de avatar cuando el usuario pulsa repetidamente el botón de guardar durante una carga en progreso.

## Assumptions

- **Opcionalidad del avatar para "Perfil completo"**: La fotografía de avatar es una mejora visual del perfil arbitral y NO bloquea el estado de "Perfil completo" definido en HU 25.1 (que exige datos personales obligatorios, ambos lados de la cédula y documento de certificación arbitral). Un árbitro con perfil completo sin avatar verá el respaldo visual genérico y podrá agregar su avatar en cualquier momento desde "Editar".
- **Dependencia de HU 25.1**: Esta funcionalidad construye directamente sobre el formulario de perfil completo del árbitro, la captura de cédula colombiana por ambos lados y el documento de certificación arbitral implementados en HU 25.1.
- **Formatos de imagen soportados**: La fotografía de avatar acepta imágenes estándar provenientes de cámara o galería del dispositivo móvil, reutilizando las restricciones de tamaño y optimización existentes para fotos de perfil de usuario.
- **Alcance exclusivo del rol árbitro**: Esta historia cubre únicamente al rol árbitro; los flujos equivalentes de jugador, entrenador, organizador o aficionado permanecen sin cambios.
- **Fuera de alcance**: Recorte avanzado con filtros fotográficos, verificación biométrica facial contra la cédula y aprobación administrativa manual de avatares están fuera del alcance de esta historia.
