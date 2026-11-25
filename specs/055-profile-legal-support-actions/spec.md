# Feature Specification: Botones de Quitar Anuncios, Términos, Políticas de Datos y Preguntas Frecuentes en Perfil

**Feature Branch**: `055-profile-legal-support-actions`

**Created**: 2026-11-25

**Status**: Draft

**Input**: User description: "HU 24.2 (Épica 24 - Notion): Botones de Quitar Anuncios, Términos, Políticas de Datos y Preguntas Frecuentes en Perfil — Como usuario de ViFutbol (autenticado o visitante), quiero encontrar debajo de la sección 'Permisos y capacidades del rol' los botones de Quitar anuncios, Términos y condiciones, Políticas de tratamiento de datos y Preguntas frecuentes, para gestionar mi experiencia sin publicidad y consultar fácilmente la información legal, de privacidad y de ayuda de la aplicación."

## Clarifications

### Session 2026-11-25

- Q: ¿Cómo deben abrirse los destinos al pulsar `Términos y condiciones`, `Políticas de tratamiento de datos`, `Preguntas frecuentes` y `Quitar anuncios`? → A: Pantallas dedicadas de lectura (con barra superior y botón atrás) para `Términos y condiciones`, `Políticas de tratamiento de datos` y `Preguntas frecuentes`, y un diálogo/hoja modal para `Quitar anuncios`.
- Q: ¿Qué comportamiento debe tener el modal de `Quitar anuncios` en esta entrega? → A: Mostrar un modal informativo en español explicando el beneficio de navegar sin publicidad e indicando claramente que la opción estará disponible próximamente (sin cobro ni persistencia).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Visualización Ordenada de Opciones de Suscripción, Legal y Soporte en Perfil (Priority: P1)

Como usuario de ViFutbol (autenticado con cualquiera de los cinco roles o en modo visitante), al desplazarme por la pantalla de Perfil debajo de la sección "Permisos y capacidades del rol" y antes de las acciones de cierre de sesión, quiero ver en orden claro los accesos a **Quitar anuncios**, **Términos y condiciones**, **Políticas de tratamiento de datos** y **Preguntas frecuentes**, cada uno con su ícono representativo, etiqueta en español e indicador visual de acción.

**Why this priority**: Es la superficie principal de descubrimiento exigida por HU 24.2 y cumple con requisitos de transparencia legal, privacidad y acceso a soporte/suscripción desde el Perfil para todos los usuarios.

**Independent Test**: Puede verificarse de forma independiente abriendo la pantalla de Perfil con usuarios autenticados (de cualquier rol) y en modo visitante, desplazando debajo de "Permisos y capacidades del rol" y comprobando que los cuatro botones aparecen exactamente en el orden definido, antes del botón de cierre de sesión/inicio de sesión, con íconos, etiquetas en español y áreas táctiles accesibles.

**Acceptance Scenarios**:

1. **Given** un usuario autenticado con cualquier rol (`Organizador`, `Entrenador`, `Árbitro`, `Jugador` o `Aficionado`) en la pantalla de Perfil, **When** desplaza la vista debajo de la sección "Permisos y capacidades del rol", **Then** visualiza en orden exacto los cuatro accesos: `Quitar anuncios`, `Términos y condiciones`, `Políticas de tratamiento de datos` y `Preguntas frecuentes`, ubicados antes del botón de cierre de sesión.
2. **Given** un usuario en modo visitante (`Aficionado` invitado) en la pantalla de Perfil, **When** desplaza la vista debajo de "Permisos y capacidades del rol", **Then** visualiza los mismos cuatro accesos en el mismo orden antes del botón de iniciar sesión/registrarse.
3. **Given** cualquier usuario visualizando la sección de accesos en pantallas pequeñas o con escalado de texto ampliado, **When** revisa los cuatro botones, **Then** cada botón muestra su ícono, etiqueta legible en español e indicador de navegación sin recortes ni desbordamientos horizontales y respetando áreas táctiles accesibles.

---

### User Story 2 - Consulta Offline de Términos, Políticas de Tratamiento de Datos y Preguntas Frecuentes (Priority: P2)

Como usuario de ViFutbol, al pulsar **Términos y condiciones**, **Políticas de tratamiento de datos** o **Preguntas frecuentes** desde el Perfil, quiero abrir el contenido correspondiente en español de forma inmediata e incluso sin conexión a internet, poder leerlo cómodamente con desplazamiento vertical y volver al Perfil conservando mi posición y estado.

**Why this priority**: Garantiza acceso real y útil a la información legal, de privacidad (tratamiento de datos personales) y de ayuda de la aplicación en cualquier condición de red móvil.

**Independent Test**: Puede verificarse de forma independiente pulsando cada una de las tres opciones legales/soporte con y sin conexión a internet, confirmando que se abre la vista o modal correspondiente con contenido estructurado en español, navegable y con retorno limpio al Perfil.

**Acceptance Scenarios**:

1. **Given** un usuario en la pantalla de Perfil, **When** presiona el botón `Términos y condiciones`, **Then** navega a la pantalla dedicada de lectura del documento de Términos y condiciones de ViFutbol en español (con barra superior y botón atrás), completamente legible sin requerir conexión a internet.
2. **Given** un usuario en la pantalla de Perfil, **When** presiona el botón `Políticas de tratamiento de datos`, **Then** navega a la pantalla dedicada de lectura de la Política de tratamiento de datos personales en español (con barra superior y botón atrás), legible sin conexión a internet.
3. **Given** un usuario en la pantalla de Perfil, **When** presiona el botón `Preguntas frecuentes`, **Then** navega a la pantalla dedicada de Preguntas frecuentes (FAQ) en español con preguntas y respuestas claras sobre el uso de ViFutbol, legible sin conexión a internet.
4. **Given** un usuario que abrió cualquiera de estas pantallas dedicadas, **When** presiona el botón atrás de la barra superior o del dispositivo, **Then** regresa a la pantalla de Perfil sin errores y conservando su sesión y estado intactos.

---

### User Story 3 - Modal Informativo de Quitar Anuncios y Protección contra Doble Tap (Priority: P3)

Como usuario de ViFutbol, al pulsar **Quitar anuncios** quiero ver un modal informativo claro en español explicando el beneficio de navegar sin publicidad e indicando que la opción estará disponible próximamente (sin cobro ni persistencia), y al pulsar rápidamente cualquiera de los cuatro botones no deben abrirse pantallas ni modales duplicados.

**Why this priority**: Completa las cuatro opciones de HU 24.2 ofreciendo claridad comercial al usuario sin simular cobros ni añadir dependencias de pago no integradas, y asegura resiliencia táctil frente a pulsaciones rápidas repetidas (`docs/MOBILE_GUIDELINES.md`).

**Independent Test**: Puede verificarse pulsando `Quitar anuncios` para comprobar la apertura del modal informativo "Próximamente" en español, y ejecutando múltiples toques rápidos consecutivos sobre cualquiera de los cuatro botones para confirmar que solo se abre una instancia a la vez.

**Acceptance Scenarios**:

1. **Given** un usuario en la pantalla de Perfil, **When** presiona el botón `Quitar anuncios`, **Then** se abre un diálogo/hoja modal informativo en español explicando el beneficio de navegar sin publicidad e indicando claramente que estará disponible próximamente (sin cobro ni persistencia), con una acción clara para cerrar.
2. **Given** un usuario en la pantalla de Perfil, **When** presiona dos o más veces de forma rápida y consecutiva cualquiera de los cuatro botones (`Quitar anuncios`, `Términos y condiciones`, `Políticas de tratamiento de datos` o `Preguntas frecuentes`), **Then** el sistema abre únicamente una instancia de la vista o modal destino, evitando pantallas o diálogos apilados duplicados.
3. **Given** un usuario con uno de los destinos abierto que envía la aplicación a segundo plano y luego regresa, **When** reanuda la aplicación, **Then** el contenido sigue visible de forma estable y puede cerrarse normalmente para regresar al Perfil.

---

### Edge Cases

- **Pulsaciones rápidas repetidas (doble tap)**: Tocar repetidamente un mismo botón o alternar rápidamente entre dos botones de la lista no debe apilar múltiples modales ni rutas duplicadas.
- **Uso completamente sin conexión (offline)**: Las cuatro opciones deben abrir su contenido o mensaje informativo localmente sin mostrar errores de red ni bloqueos por carga infinita.
- **Escalado de texto del sistema y pantallas compactas**: Las etiquetas largas como `Políticas de tratamiento de datos` deben ajustarse en múltiples líneas si es necesario sin desbordamiento horizontal ni recorte del ícono o chevron.
- **Navegación hacia atrás del sistema (gesto o botón físico atrás)**: Al retroceder desde cualquier vista o modal abierto por estos cuatro botones, el usuario regresa directamente a la pestaña de Perfil sin cerrar la aplicación ni perder su sesión.
- **Convivencia con roles y modo visitante**: La sección debe mostrarse por igual para todos los roles (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`) y para visitantes, sin alterar ni ocultar las secciones previas (identidad, datos de jugador, solicitudes de equipo, permisos) ni posteriores (cierre/inicio de sesión).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE mostrar una sección de opciones en la pantalla de Perfil inmediatamente debajo de la tarjeta "Permisos y capacidades del rol" y antes de las acciones de cierre de sesión o eliminación de cuenta.
- **FR-002**: La sección DEBE presentar exactamente cuatro botones/accesos en el siguiente orden fijo:
  1. `Quitar anuncios`
  2. `Términos y condiciones`
  3. `Políticas de tratamiento de datos`
  4. `Preguntas frecuentes`
- **FR-003**: Los cuatro botones DEBEN estar visibles y operativos tanto para usuarios autenticados de cualquiera de los cinco roles del sistema como para usuarios en modo visitante, en ambos entornos (`dev` y `prod`).
- **FR-004**: Cada botón DEBE incluir un ícono representativo, su etiqueta en español gestionada mediante el sistema centralizado de localización (`l10n`, sin textos incrustados directamente), un indicador visual de navegación/acción y un área táctil accesible (mínimo 44 px de altura).
- **FR-005**: Al presionar `Términos y condiciones`, el sistema DEBE navegar a una pantalla dedicada de lectura (con barra superior y botón atrás) que muestre el documento de Términos y condiciones de ViFutbol en español, disponible sin conexión a internet.
- **FR-006**: Al presionar `Políticas de tratamiento de datos`, el sistema DEBE navegar a una pantalla dedicada de lectura (con barra superior y botón atrás) que muestre la Política de tratamiento de datos personales de ViFutbol en español, disponible sin conexión a internet.
- **FR-007**: Al presionar `Preguntas frecuentes`, el sistema DEBE navegar a una pantalla dedicada de lectura (con barra superior y botón atrás) que muestre las Preguntas frecuentes (FAQ) en español con preguntas y respuestas relevantes sobre la aplicación, disponible sin conexión a internet.
- **FR-008**: Al presionar `Quitar anuncios`, el sistema DEBE abrir un diálogo o hoja modal informativo en español explicando el beneficio de navegar sin publicidad e indicando claramente que la opción estará disponible próximamente, sin cobro ni persistencia local/remota.
- **FR-009**: El sistema DEBE prevenir aperturas duplicadas de vistas o modales ante pulsaciones rápidas repetidas (protección contra doble tap) en los cuatro botones.
- **FR-010**: Todas las vistas o modales abiertos desde estos cuatro botones DEBEN soportar desplazamiento vertical del contenido, escalado de texto del sistema, lectores de pantalla y retorno limpio a la pantalla de Perfil mediante el control de cierre o el botón atrás del dispositivo.
- **FR-011**: La incorporación de esta sección NO DEBE introducir regresiones en las secciones existentes del Perfil (tarjeta de identidad, rol activo en solo lectura, completitud de perfil, datos personales de jugador, solicitudes de equipo, matriz de permisos y flujo de cierre/inicio de sesión).

### Key Entities *(include if feature involves data)*

- **Documento Informativo Legal / Soporte**: Contenido estático en español organizado por secciones (título, cuerpo o lista de preguntas y respuestas) para `Términos y condiciones`, `Políticas de tratamiento de datos` y `Preguntas frecuentes`, disponible localmente sin conexión.
- **Estado de Remoción de Anuncios (Ad-Free Offer Info)**: Información presentada al usuario sobre la opción de eliminar publicidad y su disponibilidad actual en la aplicación.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de los usuarios (los 5 roles autenticados y el modo visitante) visualizan los 4 botones en el orden exacto debajo de "Permisos y capacidades del rol" y antes del botón de cierre/inicio de sesión.
- **SC-002**: El 100% de los 4 botones abren su vista o diálogo correspondiente en español al ser pulsados, incluso en modo sin conexión (0 errores de carga o red).
- **SC-003**: Ante secuencias de pulsaciones rápidas repetidas sobre cualquiera de los 4 botones, se abre exactamente 1 instancia del destino (0 modales o pantallas duplicadas).
- **SC-004**: El 100% de las etiquetas y contenidos legales/informativos se renderizan sin desbordamiento visual en pantallas móviles estándar y bajo escalado de texto ampliado (`1.5x`), manteniendo intactas todas las acciones previas del Perfil.

## Assumptions

- La pasarela de pagos real (compras in-app / suscripciones de tiendas) aún no forma parte de esta historia; por defecto, `Quitar anuncios` presenta un modal o vista informativa clara en español explicando la futura experiencia sin anuncios y su estado "Próximamente" (sin cobrar ni requerir red).
- Los textos de `Términos y condiciones`, `Políticas de tratamiento de datos` y `Preguntas frecuentes` se sirven de forma local/offline dentro de la aplicación mediante localización en español, sin depender de enlaces externos ni navegador web.
- La opción de eliminación de cuenta con borrado en cascada pertenece a la historia separada **HU 24.3** y queda explícitamente fuera del alcance de esta especificación.
