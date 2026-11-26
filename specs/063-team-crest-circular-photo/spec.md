# Especificación de Funcionalidad: Carga de Foto del Escudo del Equipo con Visualización Circular en Toda la App

**Directorio de Funcionalidad**: `specs/063-team-crest-circular-photo`  
**Creada**: 2026-11-26  
**Estado**: Borrador  
**Fuente**: Notion — `[Épica 27] HU 27.3: Carga de Foto del Escudo del Equipo con Visualización Circular en Toda la App` (`4248442e-3f49-8150-8920-c7bcf0b7609f`)

## Clarifications

### Session 2026-11-26

- Q: ¿Qué comportamiento debe seguir el sistema si falla la subida de la foto del escudo a la nube durante el registro del equipo (por red inestable o error temporal)? → A: Continuidad offline-first: guardar el equipo localmente con la foto local visible de inmediato y reintentar la subida del escudo automáticamente al sincronizar.
- Q: ¿El formato circular obligatorio debe aplicarse a todos los escudos en la app (incluyendo equipos creados previamente sin foto que tenían forma de escudo clásico), o únicamente a equipos con foto y equipos nuevos? → A: Unificar 100% circular en toda la app (todos los equipos, nuevos y existentes, se muestran en circunferencia tanto con foto como con monograma de respaldo).

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia de Usuario 1 — Subida, Captura y Vista Previa Circular del Escudo en el Registro de Equipo (Prioridad: P1)

Como entrenador (u organizador autorizado) registrando un equipo en ViFutbol, quiero poder seleccionar una fotografía desde mi galería o tomarla con la cámara para usarla como escudo del equipo, verla en tiempo real dentro de una circunferencia con el borde en los colores distintivos elegidos y poder cambiarla o quitarla antes de guardar, para personalizar la identidad visual de mi club desde el primer momento.

**Por qué esta prioridad**: Es el punto de entrada de la funcionalidad; permite adjuntar la imagen real del escudo directamente en el flujo de registro de equipo con retroalimentación visual inmediata.

**Prueba Independiente**: Puede probarse en la página de registro de equipo pulsando "Subir escudo", eligiendo galería o cámara, verificando que la vista previa muestra la imagen recortada dentro de una circunferencia con los colores distintivos del equipo, probando reemplazarla y eliminarla antes de guardar.

**Escenarios de Aceptación**:

1. **Dado** que el usuario autorizado se encuentra en la página de registro de equipo, **Cuando** presiona "Subir escudo" y elige una imagen válida desde la galería o la cámara, **Entonces** la vista previa superior muestra la fotografía del escudo recortada dentro de una circunferencia perfecta con borde en los colores distintivos seleccionados del equipo.
2. **Dado** que ya se cargó una fotografía de escudo en el formulario de registro, **Cuando** el usuario selecciona "Cambiar escudo" y elige otra imagen, **Entonces** la vista previa circular se actualiza de inmediato con la nueva fotografía.
3. **Dado** que ya se cargó una fotografía de escudo en el formulario de registro, **Cuando** el usuario selecciona "Quitar escudo", **Entonces** se elimina la fotografía seleccionada y la vista previa vuelve automáticamente al emblema circular por defecto con el monograma y los colores distintivos del equipo.
4. **Dado** que el usuario cambia el color primario o secundario del equipo mientras tiene una foto de escudo cargada, **Cuando** selecciona un nuevo color, **Entonces** el borde circular que enmarca la fotografía del escudo se actualiza inmediatamente con los nuevos colores distintivos.

---

### Historia de Usuario 2 — Persistencia y Visualización Circular Uniforme en Toda la Aplicación (Prioridad: P1)

Como usuario de ViFutbol (entrenador, organizador, jugador, árbitro o aficionado), quiero que el escudo fotográfico de cada equipo se visualice siempre dentro de una circunferencia uniforme en todas las pantallas donde aparece el club (directorio de equipos, detalle del equipo, tabla de posiciones, tarjetas de partidos y panel del entrenador), para disfrutar una presentación visual limpia y consistente.

**Por qué esta prioridad**: Garantiza que la inversión de subir el escudo se refleje de forma consistente en toda la experiencia de la aplicación.

**Prueba Independiente**: Puede probarse registrando un equipo con fotografía de escudo y verificando su renderizado circular en el directorio de equipos, la pantalla de detalle del equipo, la tabla de posiciones, las tarjetas de partidos y el panel del entrenador.

**Escenarios de Aceptación**:

1. **Dado** un equipo registrado con una fotografía de escudo válida, **Cuando** se guarda con conexión a internet, **Entonces** la imagen se sube al almacenamiento en la nube y su referencia queda persistida tanto en la nube como en el almacenamiento local del equipo.
2. **Dado** un equipo que posee fotografía de escudo almacenada (remota o local), **Cuando** el equipo se muestra en el directorio de equipos, el detalle del equipo, la tabla de posiciones, las tarjetas de partidos o el panel del entrenador, **Entonces** la imagen del escudo se renderiza siempre recortada dentro de una circunferencia perfecta sin deformación y con borde acorde a los colores distintivos del equipo.

---

### Historia de Usuario 3 — Respaldo Circular Automático sin Escudo o ante Error de Carga (Prioridad: P1)

Como usuario visualizando equipos en ViFutbol, quiero que cualquier equipo sin fotografía de escudo (o cuya imagen remota falle al descargarse) muestre automáticamente el emblema circular con su monograma y colores distintivos, para evitar íconos rotos o espacios vacíos en la interfaz.

**Por qué esta prioridad**: Asegura continuidad visual para todos los equipos históricos y resiliencia ante fallas de red o enlaces rotos.

**Prueba Independiente**: Puede probarse renderizando el componente de escudo para un equipo sin foto y para un equipo cuya URL de escudo falle al cargar, comprobando que ambos muestran el monograma y colores distintivos dentro de una circunferencia perfecta sin excepciones ni errores visuales.

**Escenarios de Aceptación**:

1. **Dado** un equipo registrado sin fotografía de escudo (o un equipo histórico previo a esta funcionalidad), **Cuando** se renderiza su escudo en cualquier pantalla de la aplicación, **Entonces** se muestra el emblema circular por defecto con la sigla (monograma) y los colores distintivos del equipo.
2. **Dado** un equipo cuya fotografía de escudo remota no puede descargarse por falta de conectividad o error del servidor, **Cuando** falla la carga de la imagen, **Entonces** el sistema realiza una transición limpia al emblema circular con monograma y colores distintivos sin mostrar íconos de imagen rota ni errores visuales.

---

### Historia de Usuario 4 — Validación de Archivo, Continuidad Offline-First y Manejo Resiliente de Permisos (Prioridad: P2)

Como entrenador intentando subir el escudo de mi equipo desde un dispositivo móvil, quiero recibir mensajes claros en español si niego los permisos de cámara/galería o si selecciono un archivo no permitido, y poder guardar el equipo incluso sin conexión a internet conservando la vista local del escudo, para no perder mi avance en el formulario.

**Por qué esta prioridad**: Cumple las directrices móviles críticas de resiliencia, permisos y operación offline-first.

**Prueba Independiente**: Puede probarse simulando denegación de permisos de cámara/galería, seleccionando un archivo mayor a 5 MB o de formato no soportado, y registrando un equipo con escudo sin conexión a internet para comprobar preservación de datos y visualización local inmediata.

**Escenarios de Aceptación**:

1. **Dado** que el entrenador presiona "Subir escudo" sin permisos de cámara o galería concedidos, **Cuando** el sistema operativo deniega el permiso, **Entonces** se muestra un mensaje informativo claro en español y todos los demás campos diligenciados del formulario permanecen intactos.
2. **Dado** que el entrenador selecciona un archivo que supera el tamaño máximo permitido (5 MB) o tiene un formato no soportado (distinto de JPEG, PNG o WebP), **Cuando** el sistema valida el archivo, **Entonces** rechaza la imagen mostrando un mensaje claro en español indicando el límite o formatos permitidos, sin borrar los demás campos del formulario.
3. **Dado** que el entrenador diligenció el formulario con una fotografía de escudo válida estando sin conexión a internet, **Cuando** presiona "Registrar equipo", **Entonces** el equipo se guarda localmente conservando la ruta local de la imagen para mostrar el escudo circular inmediatamente en el dispositivo y queda listo para sincronizarse con la nube cuando se recupere la conectividad.

---

### Casos Borde y Comportamiento Móvil

- **Imágenes rectangulares o con relación de aspecto extrema**: Cualquier imagen seleccionada (vertical u horizontal) debe escalarse y recortarse centrada cubriendo completamente el área circular sin estirarse ni dejar bordes vacíos.
- **Límite de tamaño y formatos permitidos**: Solo se aceptan imágenes en formato JPEG, PNG o WebP con un tamaño máximo de 5 MB; archivos mayores o de otros formatos se rechazan antes de iniciar la subida.
- **Seguridad del almacenamiento**: El espacio de almacenamiento de escudos permite lectura pública (para que cualquier usuario autenticado o aficionado vea el escudo en tablas y partidos), pero restringe la subida/escritura exclusivamente a usuarios autenticados propietarios.
- **Prevención de doble envío**: Mientras se sube la fotografía del escudo y se registra el equipo, el botón de envío permanece bloqueado en estado de carga impidiendo subidas o registros duplicados.
- **Falla durante la subida en línea**: Si la subida de la imagen a la nube falla por red inestable o error temporal, el sistema aplica continuidad offline-first: guarda el equipo localmente conservando la ruta local de la imagen para mostrar el escudo circular de inmediato, programa la sincronización posterior del escudo e informa claramente al usuario en español.
- **Accesibilidad y escalado de texto**: Los botones de subir, cambiar y quitar escudo respetan áreas táctiles cómodas, incluyen descripciones semánticas claras en español y soportan tamaños de texto ampliados sin desbordamientos.

## Requisitos *(obligatorio)*

### Requisitos Funcionales

- **FR-001**: La página de registro de equipo DEBE incluir un control destacado que permita al usuario autorizado subir una fotografía del escudo desde la galería o capturarla con la cámara del dispositivo.
- **FR-002**: El formulario de registro DEBE permitir reemplazar o eliminar la fotografía del escudo seleccionada antes de guardar, manteniendo el escudo fotográfico como un campo opcional que no impide registrar el equipo si se omite.
- **FR-003**: El sistema DEBE validar que la imagen del escudo seleccionada corresponda a un formato permitido (`JPEG`, `PNG` o `WebP`) y no supere el límite máximo de **5 MB**, rechazando archivos inválidos con un mensaje claro en español sin alterar los demás campos del formulario.
- **FR-004**: El componente reutilizable de escudo de equipo DEBE aceptar una referencia de imagen (URL remota o ruta local) y renderizarla **siempre** recortada dentro de una circunferencia perfecta cubriendo el área circular completa, enmarcada con borde en los colores distintivos del equipo.
- **FR-005**: Cuando un equipo (nuevo o existente) no tenga foto de escudo asignada o cuando falle la carga de la imagen, el componente de escudo DEBE mostrar automáticamente el respaldo visual unificado en **formato circular** con el monograma (sigla) y los colores distintivos del equipo, sin errores visuales.
- **FR-006**: La visualización 100% circular del escudo (tanto fotográfico como respaldo de monograma para equipos nuevos y existentes) DEBE aplicarse de manera uniforme en toda la aplicación: vista previa del registro de equipo, directorio de equipos, pantalla de detalle del equipo, tabla de posiciones, tarjetas de partidos y panel del entrenador.
- **FR-007**: El sistema DEBE subir las fotografías de escudo válidas a un almacenamiento en la nube dedicado con política de acceso de **lectura pública** y **escritura restringida a usuarios autenticados propietarios**.
- **FR-008**: El sistema DEBE persistir la referencia de la fotografía del escudo junto con los datos del equipo tanto en la nube como en el almacenamiento local, preservando compatibilidad con equipos existentes que no tengan escudo fotográfico.
- **FR-009**: En modo sin conexión o ante fallas temporales de subida en línea (continuidad offline-first), el sistema DEBE guardar el equipo localmente conservando y mostrando inmediatamente la imagen local del escudo en formato circular, y reintentar automáticamente su subida y sincronización con la nube al restablecer conectividad.
- **FR-010**: El sistema DEBE manejar de forma resiliente la denegación de permisos de cámara o galería mostrando mensajes informativos claros en español y preservando intactos todos los datos ya ingresados en el formulario.
- **FR-011**: El sistema DEBE mantener protección de envío único (`single-flight`) durante la subida de la imagen del escudo y el guardado del equipo para evitar cargas duplicadas.
- **FR-012**: Todos los textos visibles relacionados con la carga, cambio, eliminación, validación y errores del escudo DEBEN estar redactados en español claro y consistente con el resto de la aplicación.

### Entidades Clave *(incluir si la funcionalidad maneja datos)*

- **Escudo de Equipo (Referencia de Imagen)**: URL pública remota (o ruta local temporal en modo sin conexión) asociada a un equipo que apunta a su fotografía oficial de escudo en formato JPEG, PNG o WebP (≤ 5 MB).
- **Equipo**: Entidad institucional del club ampliada con el atributo opcional de referencia al escudo fotográfico, propagado a listados del directorio, detalle del equipo, tabla de posiciones y partidos.

## Criterios de Éxito *(obligatorio)*

### Resultados Medibles

- **SC-001**: El 100% de las fotografías de escudo cargadas desde galería o cámara se previsualizan inmediatamente en formato circular en el formulario de registro y permiten ser reemplazadas o eliminadas antes de guardar.
- **SC-002**: El 100% de las vistas de equipo en la aplicación (directorio, detalle, tabla de posiciones, tarjetas de partidos y panel) renderizan el escudo dentro de una circunferencia perfecta, tanto cuando hay foto cargada como cuando aplica el respaldo por defecto.
- **SC-003**: El 100% de los intentos de seleccionar archivos mayores a 5 MB o en formatos no soportados son rechazados antes de subir con mensaje claro en español, preservando intactos los datos del formulario.
- **SC-004**: El 100% de los equipos sin fotografía de escudo o con fallas de descarga de imagen muestran el monograma circular con sus colores distintivos sin errores visuales ni excepciones.
- **SC-005**: El 100% de las denegaciones de permisos de cámara/galería se manejan con mensaje claro en español sin pérdida de datos del formulario, y los equipos creados con escudo sin conexión muestran inmediatamente su escudo local circular.

## Supuestos y Alcance

- **Alcance de esta especificación (HU 27.3)**: Cubre la carga/captura opcional de foto del escudo del equipo desde la página de registro de equipo, su almacenamiento en nube + continuidad offline-first, su persistencia en el modelo de equipos y su visualización circular obligatoria (con fallback circular) en toda la aplicación.
- **Fuera de alcance**: Recorte interactivo avanzado/filtros de edición de imagen antes de guardar, moderación automática de contenido de escudos, o pantalla dedicada de edición posterior de equipos existentes.
- **Supuestos**:
  - La página de registro detallado de equipo creada en HU 27.2 es el punto de integración principal para subir el escudo.
  - Los equipos creados previamente sin foto de escudo adoptan automáticamente el respaldo circular con su monograma y colores distintivos sin requerir migración manual de datos.
  - Toda la interfaz de usuario se presenta en español.
