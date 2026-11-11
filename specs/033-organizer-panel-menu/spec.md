# Feature Specification: Reorganización del Panel de Organización: Menú en Barra Superior y Depuración de Acciones Rápidas (HU 18.2)

**Feature Branch**: `033-organizer-panel-menu`  
**Created**: 2026-11-11  
**Status**: Draft  
**Input**: User description: "de notion HU 18.2 en curso ([Épica 18] HU 18.2: Reorganización del Panel de Organización: Menú en AppBar y Depuración de Acciones Rápidas)"  

## Clarifications

### Session 2026-11-11

- Q: ¿Cómo deben presentarse visualmente las opciones dentro del menú contextual de la barra superior del Organizador? → A: Ícono alusivo junto con el texto descriptivo (ej. megáfono para "Publicar Noticia" y respaldo/disco para "Copia de Seguridad").
- Q: ¿Cómo debe responder el sistema si el Organizador selecciona "Publicar Noticia" cuando aún no existen competiciones registradas en la plataforma? → A: Permitir abrir el formulario para publicar la noticia como un comunicado general no vinculado a ningún torneo específico (asignando un identificador de ámbito general).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Retiro de Acciones Rápidas del Cuerpo del Panel (Priority: P1) 🎯 MVP

Como Organizador de la plataforma, quiero que la sección de tarjetas de "Acciones Rápidas" se retire del cuerpo principal de mi panel administrativo, para disfrutar de un espacio limpio, ordenado y sin elementos redundantes que compitan visualmente con mis métricas y el listado de mis competiciones.

**Why this priority**: Es la necesidad visual y funcional primaria expresada en la historia. Despeja inmediatamente la pantalla del organizador, eliminando accesos obsoletos que ya pertenecen al contexto de cada competición específica.

**Independent Test**: Iniciar sesión como organizador, acceder al Panel Administrativo y verificar que el cuerpo de la pantalla muestra únicamente el resumen de métricas clave y a continuación la sección de competiciones, sin renderizar el bloque de "Acciones Rápidas" ni los botones de generación de fixture o programación de partidos.

**Acceptance Scenarios**:

1. **Given** que el usuario con rol de Organizador navega a la pantalla del Panel Administrativo, **When** observa el contenido principal de la pantalla, **Then** no se visualiza el título de sección ni el contenedor de "Acciones Rápidas", y el espacio queda directamente asignado a las métricas y al listado de "Mis Competiciones".
2. **Given** que el panel carga las métricas operativas del organizador, **When** el usuario se desplaza verticalmente, **Then** la transición visual hacia la lista de competiciones es continua y sin espacios vacíos o huecos residuales.

---

### User Story 2 - Menú Contextual en la Barra Superior con Acciones Depuradas (Priority: P2)

Como Organizador de la plataforma, quiero acceder a un menú contextual (icono de opciones de tres puntos verticales) en la barra superior de mi panel que contenga de forma exclusiva las opciones globales de "Publicar Noticia" y "Copia de Seguridad", para ejecutar operaciones transversales sin recargar la vista principal.

**Why this priority**: Asegura que las dos funciones administrativas globales indispensables ("Publicar Noticia" y "Copia de Seguridad") sigan estando disponibles de manera rápida y accesible desde la cabecera, mientras se suprimen definitivamente las acciones redundantes ("Generar Fixture" y "Programar Partido").

**Independent Test**: Abrir el Panel Administrativo como Organizador, pulsar el botón de opciones en la barra superior, y verificar que se despliega un menú con exactamente dos opciones: "Publicar Noticia" y "Copia de Seguridad", confirmando la ausencia total de opciones de calendario o fixture.

**Acceptance Scenarios**:

1. **Given** que el usuario está en el Panel Administrativo con rol de Organizador, **When** pulsa el icono de tres puntos en la barra superior, **Then** se despliega un menú contextual con exactamente dos opciones compuestas por ícono alusivo y texto descriptivo: "Publicar Noticia" (ícono de megáfono/campaña) y "Copia de Seguridad" (ícono de respaldo/disco).
2. **Given** que el usuario inspecciona las opciones del menú contextual, **When** busca opciones de partidos o fixture, **Then** confirma que "Generar Fixture" y "Programar Partido" no están presentes.
3. **Given** que un usuario con un rol diferente (ej. Entrenador, Árbitro o Jugador) accede a su respectivo Panel, **When** observa la barra superior, **Then** no se visualiza el menú de opciones del organizador.

---

### User Story 3 - Ejecución de Acciones Globales desde el Menú Contextual (Priority: P3)

Como Organizador de la plataforma, quiero que al pulsar "Publicar Noticia" o "Copia de Seguridad" desde el menú contextual de la barra superior se abra el flujo correspondiente, para completar la publicación o el respaldo de datos sin fricción.

**Why this priority**: Conecta las opciones del nuevo menú contextual con las pantallas y diálogos operativos existentes, garantizando la continuidad de las capacidades administrativas del organizador.

**Independent Test**: Pulsar "Publicar Noticia" desde el menú contextual y verificar la apertura del formulario de creación de noticias; luego pulsar "Copia de Seguridad" y verificar la apertura de la ventana de respaldos y cierre de temporada.

**Acceptance Scenarios**:

1. **Given** que el organizador abre el menú de opciones de la barra superior, **When** pulsa "Publicar Noticia", **Then** el sistema presenta el formulario para redactar y publicar una noticia vinculada a una competición disponible.
2. **Given** que no existen competiciones registradas en la plataforma, **When** el organizador pulsa "Publicar Noticia", **Then** el sistema abre el formulario de redacción permitiendo publicar la noticia como un comunicado general del organizador.
3. **Given** que el organizador abre el menú de opciones de la barra superior, **When** pulsa "Copia de Seguridad", **Then** el sistema presenta la interfaz de exportación, importación y cierre histórico de temporada.

---

### Edge Cases

- **Usuario cambia de rol dinámicamente**: Si el usuario conmuta su rol activo en sesión (por ejemplo, de Organizador a Entrenador o Árbitro), el menú contextual en la barra superior debe desaparecer inmediatamente para reflejar las facultades del nuevo rol.
- **Sin competiciones registradas**: Si el catálogo de competiciones está completamente vacío, seleccionar "Publicar Noticia" abre el formulario asociando la noticia a un identificador general/global sin requerir selección forzada de torneo.
- **Cierre del menú sin selección**: Si el usuario despliega el menú contextual y pulsa fuera de él o retrocede, el menú se cierra sin alterar el estado del panel ni disparar acciones secundarias.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE retirar de forma definitiva el bloque visual de "Acciones Rápidas" del cuerpo del Panel Administrativo del Organizador.
- **FR-002**: El sistema DEBE presentar un botón de menú de opciones (icono de tres puntos verticales) en la barra superior exclusivamente cuando el rol activo sea Organizador.
- **FR-003**: El menú contextual de la barra superior DEBE contener única y exclusivamente dos opciones visibles, cada una compuesta por su respectivo ícono alusivo y etiqueta de texto: "Publicar Noticia" (ícono de megáfono/comunicado) y "Copia de Seguridad" (ícono de respaldo/disco).
- **FR-004**: El sistema NO DEBE incluir las acciones "Generar Fixture" ni "Programar Partido" en el menú contextual del panel, ya que su ámbito operativo reside en el detalle de cada competición.
- **FR-005**: Al seleccionar la opción "Publicar Noticia", el sistema DEBE invocar el diálogo o pantalla de redacción de noticias administrativas; en caso de no existir competiciones disponibles, DEBE permitir redactar la noticia como un comunicado general del organizador.
- **FR-006**: Al seleccionar la opción "Copia de Seguridad", el sistema DEBE desplegar la interfaz de gestión de respaldos y cierre de temporada.
- **FR-007**: El sistema DEBE mantener sin alteraciones la sección de resumen de métricas operativas y el listado de competiciones del organizador en el cuerpo del panel.
- **FR-008**: Los paneles asociados a otros roles (Entrenador, Árbitro, Jugador y Aficionado) NO DEBEN mostrar este menú contextual de acciones del organizador en su barra superior.

---

### Key Entities *(include if feature involves data)*

- **Panel Administrativo del Organizador**: Vista central de control para el usuario con rol de Organizador, que consolida métricas clave, acceso a competiciones propias y comandos globales de administración.
- **Acción Administrativa Global**: Operación que aplica al ámbito general de la plataforma y no a un partido o torneo particular (ej. publicación de comunicados y respaldo general de base de datos).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de los accesos redundantes a generación de fixture y programación de partidos en el cuerpo del panel quedan eliminados, reduciendo la sobrecarga cognitiva del usuario.
- **SC-002**: El tiempo necesario para acceder a "Publicar Noticia" o "Copia de Seguridad" desde el panel principal no supera los 2 toques (1 toque para abrir el menú + 1 toque para elegir la acción).
- **SC-003**: El espacio vertical liberado en el cuerpo del panel permite visualizar las competiciones del organizador inmediatamente después del bloque de métricas sin requerir scroll excesivo.
- **SC-004**: Cero regresiones en la navegación y funcionalidad de los paneles de otros roles (Entrenador, Árbitro, Jugador, Aficionado).

---

## Assumptions

- La funcionalidad de generación de fixture permanece plenamente accesible a través del menú de acción flotante (FAB Menu) dentro del detalle de cada competición habilitada.
- La programación de partidos permanece accesible desde la vista de jornadas y partidos de la competición.
- Los diálogos de publicación de noticias y copias de seguridad existentes conservan su comportamiento y contratos funcionales vigentes.
- La terminología mostrada en el menú contextual está traducida y respeta las pautas de localización del sistema en español.
