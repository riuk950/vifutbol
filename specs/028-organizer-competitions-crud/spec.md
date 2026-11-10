# Feature Specification: Gestión Integral (CRUD) y Ciclo de Vida de Competiciones en Panel del Organizador (HU 16.1)

**Feature Branch**: `028-organizer-competitions-crud`

**Created**: 2026-11-10

**Status**: Draft

**Input**: User description: "[Épica 16] HU 16.1: Gestión Integral (CRUD) y Ciclo de Vida de Competiciones en Panel del Organizador"

## Clarifications

### Session 2026-11-10

- Q: ¿Se debe bloquear la edición del formato de competición y del sistema de puntuación una vez que el torneo pasa a estado inProgress o finished? → A: Permitir editar todos los campos en cualquier estado, recalculando tablas y fixture automáticamente (Opción B).
- Q: ¿Qué debe ocurrir con los partidos programados (fixture generado sin ningún partido disputado aún) cuando el organizador elimina una competición en estado openRegistration? → A: Eliminar en cascada todos los partidos programados asociados al torneo eliminado para no dejar registros huérfanos (Opción A).
- Q: ¿Se debe bloquear la inscripción o registro de nuevos equipos una vez que la competición pasa a estado inProgress? → A: Permitir inscripciones en cualquier momento, exigiendo regenerar el fixture para incluirlos (Opción B).
- Q: ¿Qué debe ocurrir con el torneo activo (selectedTournamentProvider) si el organizador elimina la competición que actualmente tiene seleccionada? → A: Seleccionar automáticamente el primer torneo restante del organizador, o null si no quedan más (Opción A).
- Q: Cuando el organizador intente pasar un torneo a estado inProgress y el sistema detecte que faltan equipos o que no se ha generado el fixture, ¿qué tipo de asistencia debe proporcionar la interfaz? → A: Mensaje explicativo con botón de acción rápida para completar el requisito faltante ("Inscribir Equipos" o "Generar Fixture") (Opción A).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Visualización y Filtrado de Competiciones del Organizador (Priority: P1)

Como organizador que inicia sesión en la plataforma,
quiero ver en mi panel de control una sección dedicada con la lista exclusiva de las competiciones que he creado,
para tener visibilidad inmediata de su estado, categoría y cantidad de equipos inscritos, o ver un estado vacío con invitación a crear si aún no tengo torneos.

**Why this priority**: Es el punto de entrada esencial de la gestión de competiciones en el panel del organizador; sin listar las competiciones propias, ninguna otra acción CRUD o de ciclo de vida puede ser descubierta o ejecutada.

**Independent Test**: Iniciar sesión como organizador, acceder a la pestaña de gestión de competiciones en el panel del organizador y verificar que se listan solo sus competiciones con badge de estado, categoría y conteo de equipos, o el estado vacío descriptivo si no tiene ninguna.

**Acceptance Scenarios**:

1. **Given** un organizador autenticado con torneos creados asociados a su identificador, **When** accede a la sección de competiciones del panel del organizador, **Then** visualiza tarjetas de sus torneos con nombre, categoría, cantidad de equipos inscritos y badge de estado (`openRegistration`, `inProgress`, `finished`).
2. **Given** un organizador autenticado que no ha creado ninguna competición, **When** accede a la sección de competiciones, **Then** visualiza un estado vacío ilustrativo indicando que no tiene torneos y un botón destacado para crear su primera competición.
3. **Given** un organizador en la sección de competiciones, **When** presiona el botón "Crear Competición", **Then** se abre el diálogo/formulario de creación de torneo y al guardarse aparece reflejado de inmediato en su lista.

---

### User Story 2 - Edición de Metadatos de la Competición (Priority: P2)

Como organizador de un torneo,
quiero poder editar los metadatos de una competición (nombre, categoría, formato, sistema de puntuación y reglamento),
para mantener la información actualizada ante cambios de patrocinador, ajustes reglamentarios o correcciones ortográficas.

**Why this priority**: Permite corregir o actualizar información crítica del torneo sin tener que recrearlo ni alterar su historial de equipos.

**Independent Test**: Desde la tarjeta de un torneo propio, seleccionar "Editar" en el menú contextual, modificar el nombre o reglamento en el formulario pre-llenado, guardar los cambios y verificar que la tarjeta y el repositorio se actualizan de inmediato.

**Acceptance Scenarios**:

1. **Given** una tarjeta de torneo propio en el panel del organizador, **When** el organizador selecciona la opción "Editar", **Then** se presenta un formulario modal pre-diligenciado con el nombre, categoría, formato, sistema de puntos y reglas de la competición.
2. **Given** el formulario de edición abierto, **When** el organizador modifica los campos con valores válidos (incluyendo formato o puntuación en torneos en curso) y confirma el guardado, **Then** los cambios se persisten en el repositorio, la tarjeta en el panel se actualiza de inmediato con los nuevos valores y las tablas de posiciones se recalculan automáticamente según las nuevas reglas.
3. **Given** el formulario de edición abierto, **When** el organizador deja el nombre vacío o con menos de 3 caracteres, **Then** el formulario muestra un error de validación y bloquea el guardado.

---

### User Story 3 - Transición Controlada del Ciclo de Vida del Campeonato (Priority: P3)

Como organizador de un torneo,
quiero cambiar el estado de la competición siguiendo el ciclo de vida oficial (`openRegistration` → `inProgress` → `finished`),
con validaciones automáticas que impidan transiciones inválidas, para garantizar que un torneo no inicie sin equipos suficientes o sin fixture generado.

**Why this priority**: Garantiza la integridad operativa y lógica del torneo, previniendo incoherencias como torneos en curso vacíos o vueltas atrás accidentales.

**Independent Test**: Intentar cambiar un torneo de `openRegistration` a `inProgress` sin fixture o con menos de 2 equipos y verificar el bloqueo informativo; luego con fixture y equipos válidos verificar la transición exitosa, y constatar que no se permite regresar a `openRegistration`.

**Acceptance Scenarios**:

1. **Given** un torneo en estado `openRegistration` con menos de 2 equipos inscritos o sin fixture generado, **When** el organizador intenta cambiar el estado a `inProgress`, **Then** el sistema muestra un mensaje informativo de bloqueo explicando los requisitos faltantes (mínimo 2 equipos y fixture generado) y proporciona un botón de acción rápida para dirigirse directamente al flujo faltante ("Inscribir Equipos" o "Generar Fixture").
2. **Given** un torneo en estado `openRegistration` con al menos 2 equipos habilitados y fixture generado, **When** el organizador confirma el cambio a `inProgress`, **Then** el estado del torneo se actualiza a `inProgress` y el badge visual refleja el cambio.
3. **Given** un torneo en estado `inProgress`, **When** el organizador decide finalizar el campeonato, **Then** el sistema solicita confirmación y actualiza el estado a `finished`.
4. **Given** un torneo en estado `inProgress` o `finished`, **When** el organizador inspecciona las opciones de estado, **Then** el sistema no permite revertir el torneo a estados previos (`openRegistration`).

---

### User Story 4 - Eliminación Restringida y Segura de Competición (Priority: P4)

Como organizador de un torneo,
quiero poder eliminar una competición creada por error o cancelada,
siempre y cuando aún se encuentre en fase de inscripciones y no tenga partidos disputados, con una confirmación destructiva explícita.

**Why this priority**: Evita la acumulación de torneos de prueba o cancelados tempranamente, al tiempo que blinda la integridad histórica de partidos y estadísticas disputadas.

**Independent Test**: Verificar que un torneo en curso o con partidos jugados bloquee la acción de eliminación, mientras que un torneo en `openRegistration` sin partidos disputados permita la eliminación tras confirmar en el diálogo destructivo.

**Acceptance Scenarios**:

1. **Given** un torneo en estado `openRegistration` sin partidos iniciados ni completados, **When** el organizador selecciona la opción "Eliminar", **Then** el sistema presenta un diálogo de confirmación destructiva advirtiendo las consecuencias.
2. **Given** el diálogo de confirmación destructiva para un torneo elegible, **When** el organizador confirma la eliminación, **Then** el torneo y todos sus partidos programados asociados se eliminan en cascada del repositorio y desaparecen del panel y los feeds de forma inmediata.
3. **Given** un torneo en estado `inProgress`, `finished`, o que cuenta con partidos jugados/en curso o actas arbitrales registradas, **When** el organizador intenta eliminarlo, **Then** la acción está deshabilitada o el sistema notifica que la competición no puede eliminarse por contar con historial activo.

---

### Edge Cases

- **Organizador sin ID explícito o sesión anónima**: Si la sesión de usuario no tiene un `organizerId` específico, se asocia por defecto al `userId` de la sesión actual o un fallback `'org-seed-1'` para no dejar huérfana la competición.
- **Torneo con partidos generados pero ninguno jugado**: Si el fixture fue generado pero ningún partido ha iniciado ni finalizado (`MatchStatus.scheduled`), la eliminación es permitida y elimina en cascada todos los partidos programados asociados para evitar registros huérfanos.
- **Inscripción de equipos con torneo en curso**: Si se inscribe un nuevo equipo a un torneo ya en estado `inProgress`, el sistema lo permite y notifica al organizador que debe regenerar el fixture para incluir al nuevo equipo en el calendario de partidos.
- **Navegación reactiva en tiempo real**: Si el organizador edita o elimina un torneo seleccionado como actual en otro proveedor (`selectedTournamentProvider`), el sistema selecciona automáticamente el primer torneo restante del organizador o establece `null` si no quedan más torneos, actualizando todos los observadores reactivos.
- **Pantalla pequeña con texto grande**: Las tarjetas y menús deben ser completamente navegables y libres de desbordamiento en pantallas de 320px de ancho con 130% de escalado de texto.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El modelo `ChampionshipTournament` DEBE poseer un atributo opcional o requerido `organizerId` (con valor por defecto en serialización) para asociar el torneo al usuario organizador.
- **FR-002**: El sistema DEBE exponer un proveedor `organizerTournamentsProvider` que filtre la lista de torneos retornando únicamente aquellos cuyo `organizerId` coincida con el usuario organizador autenticado.
- **FR-003**: La sección `OrganizerCompetitionsSection` DEBE renderizar la lista de torneos del organizador con: nombre, categoría, formato, cantidad de equipos inscritos y badge de estado KickPulse.
- **FR-004**: La sección DEBE incluir un botón de acción principal para crear una nueva competición.
- **FR-005**: Si la lista de torneos del organizador está vacía, el sistema DEBE mostrar un estado vacío informativo con llamado a la acción para crear la primera competición.
- **FR-006**: Cada tarjeta de competición DEBE contar con un menú contextual o botones de acción para: "Editar", "Cambiar Estado" y "Eliminar".
- **FR-007**: El diálogo/formulario de edición DEBE permitir modificar nombre, categoría, formato, puntos por victoria/empate/derrota y reglamento en cualquier estado del torneo, recalculando automáticamente tablas y fixture si el torneo ya está en curso.
- **FR-008**: La transición de estado DEBE seguir el flujo unidireccional `openRegistration` → `inProgress` → `finished`.
- **FR-009**: Para pasar de `openRegistration` a `inProgress`, el sistema DEBE validar que el torneo cuente con al menos 2 equipos y fixture generado; si no se cumple, debe informar el motivo del bloqueo y ofrecer botones de acción rápida para inscribir equipos o generar fixture.
- **FR-010**: El sistema DEBE prohibir y bloquear la eliminación de cualquier torneo que esté en `inProgress`, `finished` o que tenga partidos disputados/en curso o actas registradas.
- **FR-011**: La eliminación de un torneo en `openRegistration` sin partidos disputados DEBE requerir confirmación explícita mediante diálogo destructivo KickPulse.
- **FR-012**: Todos los textos de la interfaz de usuario DEBEN estar localizados en español (`lib/l10n/app_es.arb`).

### Key Entities

- **ChampionshipTournament**: Entidad de dominio que representa una competición o torneo. Atributos: `id`, `name`, `category`, `format`, `status` (`TournamentStatus`), `teams`, `rules`, `scoringSystem`, `organizerId`.
- **TournamentStatus**: Enumeración del ciclo de vida: `openRegistration`, `inProgress`, `finished`.
- **TournamentMatchesRepository**: Repositorio consultado para validar la existencia de fixture y partidos disputados antes de autorizar transiciones o eliminaciones.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El organizador puede visualizar sus torneos en menos de 1 segundo tras abrir el panel del organizador.
- **SC-002**: El flujo completo de edición de metadatos se completa y persiste en menos de 3 pasos (abrir menú -> editar campos -> guardar).
- **SC-003**: El 100% de los intentos de eliminar un torneo con partidos disputados o en curso son bloqueados con mensaje claro explicativo.
- **SC-004**: El 100% de los intentos de iniciar un torneo sin mínimo 2 equipos o sin fixture son bloqueados con mensaje guiado.
- **SC-005**: La interfaz se adapta responsive sin errores de RenderFlex en resolución mínima de 320x640 con 130% text scaling.

## Assumptions

- El usuario autenticado en el rol de Organizador tiene un identificador accesible vía `authControllerProvider` o un identificador predeterminado de pruebas (`org-seed-1`).
- Los torneos semilla existentes en `LocalTournamentsRepository` se vincularán al organizador por defecto para permitir pruebas inmediatas en desarrollo.
- El formato y sistema de puntuación se mantienen compatibles con la estructura ya existente de `ChampionshipTournament`.
