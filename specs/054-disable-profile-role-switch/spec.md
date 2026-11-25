# Feature Specification: Deshabilitar Cambio de Rol Activo en el Perfil para Todos los Roles

**Feature Branch**: `054-disable-profile-role-switch`

**Created**: 2026-11-25

**Status**: Draft

**Input**: User description: "HU 24.1 (Épica 24 - Notion): Deshabilitar Cambio de Rol Activo en el Perfil para Todos los Roles — Como administrador y usuario de ViFutbol (Organizador, Entrenador, Árbitro, Jugador o Aficionado), quiero que la opción de cambiar el rol activo desde la pantalla de Perfil esté deshabilitada para todos los roles, para mantener la integridad del control de acceso (RBAC) y evitar cambios de rol no autorizados o inconsistencias de estado desde el perfil, tanto en entorno dev como en prod."

## Clarifications

### Session 2026-11-25

- Q: ¿Cómo debe mostrarse la sección de rol en la pantalla de Perfil una vez que el cambio de rol esté deshabilitado? → A: Eliminar por completo la sección de cambio de rol del Perfil, dejando únicamente la insignia de rol activo en solo lectura dentro de la tarjeta de identidad superior.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Eliminación Universal del Selector de Cambio de Rol en el Perfil (Priority: P1)

Como usuario de ViFutbol con cualquiera de los cinco roles del sistema (`Organizador`, `Entrenador`, `Árbitro`, `Jugador` o `Aficionado`) o en modo visitante, al ingresar a la pantalla de Perfil no debe existir ninguna sección ni control para cambiar el rol activo, sin importar si utilizo el entorno de desarrollo (`dev`) o el entorno de producción (`prod`), de modo que ningún toque o interacción pueda alterar mi rol activo ni generar inconsistencias de sesión.

**Why this priority**: Es el núcleo de seguridad e integridad de control de acceso (RBAC) definido en la HU 24.1. Evita cambios de rol no autorizados y elimina el comportamiento diferencial que permitía alternar roles libremente en entorno de desarrollo.

**Independent Test**: Puede verificarse de forma independiente abriendo la pantalla de Perfil con sesiones de cada uno de los cinco roles (y modo visitante) tanto en entorno `dev` como en entorno `prod`, comprobando que la sección de cambio de rol no se muestra, no existen controles interactivos de selección de rol y el rol activo permanece intacto.

**Acceptance Scenarios**:

1. **Given** un usuario autenticado con el rol `Organizador` en entorno `dev`, **When** navega a la pantalla de Perfil, **Then** no se muestra la sección de cambio de rol ni controles seleccionables de rol, y la sesión mantiene `Organizador` como rol activo.
2. **Given** un usuario autenticado con el rol `Entrenador` en entorno `dev`, **When** navega a la pantalla de Perfil, **Then** no existe ningún selector para cambiar a otro rol y el rol activo continúa siendo `Entrenador`.
3. **Given** un usuario autenticado con el rol `Árbitro`, `Jugador` o `Aficionado` en entorno `prod`, **When** navega a la pantalla de Perfil, **Then** la sección de cambio de rol está ausente y el rol activo no sufre modificaciones.
4. **Given** un usuario autenticado con múltiples roles autorizados en su cuenta, **When** accede a la pantalla de Perfil en cualquier entorno (`dev` o `prod`), **Then** no se muestra ningún selector de cambio de rol y no es posible alternar a ninguno de los otros roles desde el perfil.
5. **Given** un usuario en modo visitante (`Aficionado` invitado), **When** accede a la pantalla de Perfil en `dev` o `prod`, **Then** no se muestra ningún selector de cambio de rol y conserva su estado de visitante.

---

### User Story 2 - Visualización del Rol Activo en Solo Lectura en la Tarjeta de Identidad (Priority: P2)

Como usuario de ViFutbol, al consultar mi pantalla de Perfil quiero seguir viendo claramente cuál es mi rol activo actual mediante la insignia de solo lectura en mi tarjeta de identidad superior, con una interfaz limpia, accesible y consistente en español, sin secciones redundantes ni mensajes de entorno de pruebas.

**Why this priority**: Preserva la transparencia para el usuario sobre el rol con el que está operando (especialmente relevante para el panel y permisos visibles en el perfil) mientras ofrece una pantalla de Perfil más limpia y sin elementos muertos.

**Independent Test**: Puede probarse de forma independiente inspeccionando la pantalla de Perfil para confirmar que la insignia de rol activo es visible y no interactiva en la tarjeta de identidad superior, que la sección anterior de cambio de rol fue removida por completo, y que las etiquetas están en español y son legibles bajo escalado de texto y lectores de pantalla.

**Acceptance Scenarios**:

1. **Given** cualquier usuario autenticado o visitante en la pantalla de Perfil, **When** observa su tarjeta de identidad superior, **Then** visualiza su rol activo actual mediante la insignia correspondiente en modo solo lectura.
2. **Given** cualquier usuario en la pantalla de Perfil en entorno `dev` o `prod`, **When** recorre la pantalla completa de Perfil, **Then** no aparece la sección de cambio de rol ni mensajes de entorno de desarrollo invitando a alternar roles.
3. **Given** un usuario que utiliza lector de pantalla o escalado de texto ampliado en su dispositivo móvil, **When** recorre la tarjeta de identidad en la pantalla de Perfil, **Then** la insignia de rol activo se lee claramente como información de solo lectura (no accionable), sin depender solo del color y sin recortes ni solapamientos de texto.

---

### User Story 3 - Conservación de Integridad de Sesión y Permisos al Reanudar o Operar Sin Conexión (Priority: P3)

Como usuario de ViFutbol operando en condiciones móviles reales (sin conexión a internet, tras enviar la aplicación a segundo plano o al reabrir la pantalla de Perfil), quiero que mi rol activo y las secciones asociadas de mi perfil (como estado de completitud, datos personales de jugador, matriz de permisos y cierre de sesión) permanezcan intactos y consistentes sin intentos de mutación de rol.

**Why this priority**: Garantiza el cumplimiento de resiliencia móvil (`docs/MOBILE_GUIDELINES.md`) y asegura que eliminar la sección de cambio de rol no introduzca regresiones en el resto de las capacidades de la pantalla de Perfil.

**Independent Test**: Puede verificarse alternando conectividad (offline/online), pausando y reanudando la aplicación o navegando fuera y de regreso a la pestaña de Perfil, comprobando que el rol activo no cambia y las demás funciones del perfil siguen respondiendo normalmente.

**Acceptance Scenarios**:

1. **Given** un usuario en la pantalla de Perfil sin conexión a internet, **When** consulta su perfil e intenta tocar repetidamente la insignia de rol en la tarjeta de identidad, **Then** el rol activo permanece estable en modo solo lectura, no se encolan ni disparan operaciones de sincronización o mutación, y no aparece ningún error.
2. **Given** un usuario en la pantalla de Perfil que envía la aplicación a segundo plano y luego regresa, **When** la pantalla se reanuda o recrea, **Then** el rol activo y la ausencia de la sección de cambio de rol se conservan exactamente igual que antes de la interrupción.
3. **Given** un usuario autenticado en la pantalla de Perfil, **When** utiliza otras acciones válidas del perfil (como completar perfil, consultar datos personales de jugador o cerrar sesión), **Then** dichas acciones siguen funcionando normalmente sin verse afectadas por la eliminación del cambio de rol.

---

### Edge Cases

- **Pulsaciones repetidas o rápidas sobre la insignia de rol**: Múltiples toques consecutivos sobre la insignia de rol activo en la tarjeta de identidad no deben disparar llamadas, errores ni cambios de estado en la sesión.
- **Usuario con múltiples roles autorizados en su cuenta**: Incluso si la cuenta tiene más de un rol autorizado registrado, desde la pantalla de Perfil la sección de cambio de rol permanece eliminada y únicamente se muestra el rol activo en la tarjeta de identidad.
- **Entorno de desarrollo (`dev`)**: No debe existir ninguna excepción ni bandera de entorno que vuelva a mostrar la sección de cambio de rol en `dev`.
- **Cambio de tamaño de texto del sistema y pantallas pequeñas**: La insignia de rol activo y los textos de la tarjeta de identidad deben ajustarse sin desbordamientos horizontales ni recortes dentro de las áreas seguras del dispositivo.
- **Ausencia de datos de sesión transitoria**: Si el perfil se renderiza sin sesión autenticada completa (por ejemplo, modo visitante por defecto), debe mostrar el rol por defecto (`Aficionado`) en solo lectura en la tarjeta de identidad y mantener ausente cualquier control de cambio de rol.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE eliminar por completo la sección de cambio de rol activo de la pantalla de Perfil para todos los roles del sistema (`Organizador`, `Entrenador`, `Árbitro`, `Jugador` y `Aficionado`) y para usuarios en modo visitante.
- **FR-002**: La eliminación de la sección de cambio de rol en la pantalla de Perfil DEBE aplicarse de manera uniforme tanto en entorno de desarrollo (`dev`) como en entorno de producción (`prod`), eliminando cualquier habilitación especial para pruebas en `dev`.
- **FR-003**: El sistema DEBE continuar mostrando únicamente el rol activo actual del usuario mediante su insignia de solo lectura dentro de la tarjeta de identidad superior de la pantalla de Perfil.
- **FR-004**: El sistema NO DEBE presentar controles interactivos (ni chips deshabilitados ni selectores) para cambiar de rol ni invocar la operación de cambio de rol activo desde la pantalla de Perfil.
- **FR-005**: Cualquier interacción del usuario (toque simple, toque prolongado o pulsaciones repetidas) sobre la insignia de rol en la tarjeta de identidad NO DEBE alterar el rol activo de la sesión ni disparar mutaciones de estado locales o remotas.
- **FR-006**: Todos los textos visibles en la pantalla de Perfil relacionados con la identidad y el rol activo DEBEN presentarse en español y gestionarse a través del sistema centralizado de localización de la aplicación, sin textos incrustados directamente.
- **FR-007**: La insignia de rol activo en la tarjeta de identidad DEBE presentarse como elemento informativo de solo lectura con contraste adecuado y semántica compatible con lectores de pantalla y escalado de texto del dispositivo, sin depender únicamente del color.
- **FR-008**: La eliminación de la sección de cambio de rol NO DEBE afectar el funcionamiento de las demás secciones y acciones existentes en la pantalla de Perfil (tarjeta de identidad, insignia y acción de completitud de perfil, acceso a datos personales de jugador, visualización de permisos del rol activo y flujo de cierre de sesión).
- **FR-009**: La visualización de solo lectura del rol activo y la ausencia del selector de cambio de rol DEBEN mantenerse consistentes ante cambios de conectividad (online/offline), paso de la aplicación a segundo plano, reanudación y navegación entre pestañas.

### Key Entities *(include if feature involves data)*

- **Perfil de Usuario (User Identity)**: Representación visual del usuario autenticado o visitante en la tarjeta de identidad superior de la pantalla de Perfil, que incluye nombre, correo o estado visitante, completitud del perfil y su rol activo actual en modo solo lectura.
- **Rol Activo (Active Role)**: Uno de los cinco roles oficiales del sistema (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`) asignado a la sesión vigente, inmutable desde la pantalla de Perfil.
- **Entorno Operativo (App Environment)**: Contexto de ejecución de la aplicación (`dev` o `prod`); bajo esta especificación ambos entornos aplican exactamente la misma restricción de eliminación del selector de cambio de rol en el perfil.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de los cinco roles del sistema (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`) y el modo visitante ven su pantalla de Perfil sin sección de cambio de rol y mantienen su rol activo sin cambios, tanto en entorno `dev` como en entorno `prod`.
- **SC-002**: Se registran 0 invocaciones a la operación de cambio de rol activo originadas desde la pantalla de Perfil en todos los escenarios de prueba automatizados y manuales.
- **SC-003**: El 100% de los usuarios autenticados y visitantes visualizan su rol activo actual de forma legible en la tarjeta de identidad superior del perfil al abrir la pantalla, sin errores de desbordamiento visual bajo tamaños de pantalla estándar y escalado de texto ampliado.
- **SC-004**: El 100% de las acciones existentes del perfil (completar perfil, datos personales de jugador, visualización de permisos y cierre de sesión) conservan su comportamiento esperado sin regresiones.

## Assumptions

- El rol inicial del usuario continúa asignándose durante el flujo de autenticación u onboarding existente; esta historia únicamente elimina la capacidad de cambiar el rol activo desde la pantalla de Perfil.
- La lógica de negocio subyacente de sesión/autenticación fuera de la pantalla de Perfil no se elimina si es requerida por otros flujos internos o pruebas unitarias de dominio, pero la vista de Perfil no expone ni invoca ningún mecanismo para cambiar de rol.
- La matriz de permisos visible en el perfil sigue mostrando los permisos correspondientes al rol activo actual en modo informativo.
- El cambio aplica exclusivamente a la pantalla de Perfil y no introduce nuevas opciones de menú, botones de soporte ni eliminación de cuenta (cubiertos por historias separadas de la Épica 24 como HU 24.2 y HU 24.3).
