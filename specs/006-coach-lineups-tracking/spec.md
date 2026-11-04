# Feature Specification: Gestión de Convocatorias, Alineaciones y Seguimiento Interno por el Entrenador (HU 5.2)

**Feature Branch**: `006-coach-lineups-tracking`  
**Created**: 2026-11-04  
**Status**: Draft  
**Input**: User description: "Notion [Épica 5] HU 5.2: Gestión de Convocatorias, Alineaciones y Seguimiento Interno por el Entrenador (Page ID: 4078442e-3f49-8119-b539-f119f3baaece)"

## Clarifications

### Session 2026-11-04

- Q: ¿Cómo deben integrarse en la navegación móvil la gestión de convocatoria, el seguimiento interno del plantel y la vista de nómina sincronizada para el árbitro? → A: Option A — Abrir desde el detalle del equipo (`/tournaments/teams/detail`) una vista dedicada (`/tournaments/teams/lineup`) con secciones para armar la `"Convocatoria del Partido"`, consultar el `"Seguimiento Interno"` y previsualizar la `"Nómina Sincronizada en Acta Arbitral"` según el rol activo.
- Q: ¿Cómo debe validarse la cantidad de titulares, suplentes y capitán al confirmar una convocatoria oficial según las reglas del campeonato? → A: Option A — Exigir exactamente `requiredStarters` titulares en cancha (`min(minPlayersPerTeam, 11)`), `1` capitán obligatorio entre los titulares y de `0` al resto de jugadores no suspendidos como suplentes habilitados.
- Q: ¿Qué debe ocurrir si el entrenador necesita ajustar una convocatoria ya confirmada antes de que el árbitro cierre el acta del partido? → A: Option A — Permitir al `Entrenador` modificar la selección y reconfirmar la convocatoria para el próximo partido, actualizando de inmediato la nómina oficial sincronizada en la vista del `Árbitro`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Convocatoria y Publicación de Alineación Oficial para un Partido (Priority: P1)

Como `Entrenador` de un equipo inscrito y habilitado en un campeonato, quiero acceder al próximo partido programado de mi equipo, seleccionar a los jugadores titulares respetando la modalidad del torneo (por ejemplo, Fútbol 11, Fútbol 8 o Fútbol 5), designar obligatoriamente al capitán dentro de los titulares, marcar a los suplentes habilitados y confirmar la convocatoria, para dejar registrada la alineación oficial del equipo y que el `Árbitro` del encuentro visualice inmediatamente los titulares y suplentes habilitados en su vista de acta arbitral.

**Why this priority**: Representa el flujo operativo principal de la HU 5.2 (Fase 1 Gherkin) y conecta las plantillas oficiales de equipos (HU 5.1) con la operación del día del partido y el acta arbitral.

**Independent Test**: Se puede probar iniciando sesión como `Entrenador`, abriendo la gestión de convocatoria de un equipo habilitado para su próximo partido, seleccionando la cantidad reglamentaria de titulares según la modalidad del torneo, designando un capitán, seleccionando suplentes y confirmando la convocatoria, verificando que la alineación queda guardada como oficial y visible para el rol `Árbitro`.

**Acceptance Scenarios**:

1. **Given** que el `Entrenador` accede al próximo partido programado de su equipo habilitado, **When** selecciona la cantidad exacta de jugadores titulares exigida por la modalidad del campeonato, designa al capitán entre los titulares, marca a los suplentes habilitados y confirma la convocatoria, **Then** el sistema guarda la alineación oficial del equipo para ese partido y sincroniza la nómina con la vista de acta digital del `Árbitro`.
2. **Given** que un campeonato tiene definida una modalidad de juego (por ejemplo, 7 titulares en cancha), **When** el `Entrenador` intenta confirmar la convocatoria con menos o más titulares de los requeridos o sin haber designado un capitán titular, **Then** el sistema impide confirmar la alineación oficial y muestra en español el mensaje reglamentario indicando el requisito faltante.
3. **Given** que el `Entrenador` ha confirmado la convocatoria oficial del partido, **When** el `Árbitro` o el `Organizador` consulta la nómina del encuentro, **Then** visualiza inmediatamente la lista de titulares (con insignia de capitán) y suplentes habilitados del equipo.

---

### User Story 2 - Bloqueo Automático de Sancionados y Seguimiento Interno del Plantel (Priority: P2)

Como `Entrenador`, quiero consultar el seguimiento interno de rendimiento y disciplina de mi plantel (partidos jugados, goles, asistencias, tarjetas amarillas acumuladas, tarjetas rojas y fechas de suspensión pendientes) y que el sistema marque automáticamente como `"Suspendido"` a cualquier jugador con sanción activa (por tarjeta roja previa o por alcanzar el umbral de acumulación de amarillas definido en las reglas del campeonato), bloqueando su selección tanto de titular como de suplente en la convocatoria del partido.

**Why this priority**: Garantiza el cumplimiento estricto de las reglas disciplinarias del torneo (Fase 2 Gherkin) y provee al `Entrenador` los datos reales de rendimiento y disciplina para tomar decisiones tácticas sin incurrir en alineaciones indebidas.

**Independent Test**: Se puede probar visualizando un equipo que contenga un jugador con una fecha de suspensión pendiente o con tarjetas amarillas acumuladas iguales al umbral de suspensión del campeonato, verificando que aparece con la insignia semántica `"Suspendido (1 fecha)"` acompañada de ícono e indicador de advertencia/error, y que su control de selección está deshabilitado impidiendo incluirlo en la convocatoria.

**Acceptance Scenarios**:

1. **Given** que un jugador de la plantilla tiene una fecha de suspensión pendiente en el campeonato (por tarjeta roja o por alcanzar el límite de tarjetas amarillas acumuladas configurado en las reglas del torneo), **When** el `Entrenador` abre el listado de jugadores para armar la convocatoria, **Then** el jugador aparece con la insignia semántica de advertencia/error `"Suspendido (1 fecha)"` y el control de selección se encuentra deshabilitado impidiendo incluirlo en la lista del partido.
2. **Given** que un jugador se encuentra a una tarjeta amarilla de alcanzar el límite de suspensión del torneo, **When** el `Entrenador` consulta el seguimiento interno de su plantel o arma la convocatoria, **Then** el sistema muestra una señal semántica de advertencia (`"En capilla"` / alerta de amarillas acumuladas) con etiqueta de texto explícita sin bloquear su convocatoria mientras no esté suspendido.
3. **Given** que el `Entrenador` consulta el panel de seguimiento interno de su equipo, **When** revisa las métricas de cada jugador inscrito, **Then** visualiza de forma clara sus estadísticas acumuladas en el campeonato (partidos, goles, asistencias, tarjetas amarillas, tarjetas rojas y estado disciplinario).

---

### User Story 3 - Conservación del Estado de Selección ante Interrupciones Móviles (Priority: P3)

Como `Entrenador` que arma una convocatoria desde su teléfono móvil en cancha, quiero que el sistema preserve automáticamente el borrador en curso de mi selección de titulares, suplentes y capitán si recibo una llamada, bloqueo la pantalla, cambio temporalmente de aplicación o navego hacia atrás accidentalmente, para no perder el trabajo táctico realizado antes de confirmar la alineación oficial.

**Why this priority**: Cumple con el escenario Gherkin de Fase 3 y las directrices móviles del proyecto para operaciones deportivas en campo.

**Independent Test**: Se puede probar seleccionando parcialmente jugadores titulares y un capitán sin confirmar aún la convocatoria, enviando la aplicación a segundo plano (o reabriendo la pantalla de convocatoria del equipo) y comprobando que la selección parcial permanece intacta.

**Acceptance Scenarios**:

1. **Given** que el `Entrenador` ha seleccionado parcialmente a sus jugadores titulares, suplentes o capitán sin haber confirmado aún la convocatoria oficial, **When** recibe una llamada o cambia temporalmente de aplicación y regresa a `vifutbol`, **Then** la pantalla conserva intacta la selección de jugadores realizada hasta ese momento.
2. **Given** que existe un borrador de convocatoria guardado localmente para el partido, **When** el `Entrenador` vuelve a entrar a la pantalla de convocatoria de su equipo, **Then** el sistema restaura automáticamente la selección previa y le permite continuar hasta confirmar la alineación oficial.

### Edge Cases

- **Jugador suspendido que había sido incluido previamente en un borrador**: Si un jugador pasa a estado `"Suspendido"` antes de confirmarse la convocatoria, el sistema debe removerlo automáticamente de cualquier selección de titular/suplente/capitán en el borrador e impedir la confirmación hasta reemplazarlo por un jugador habilitado.
- **Un jugador no puede ser titular y suplente simultáneamente**: Al marcar un jugador como titular, no puede figurar como suplente al mismo tiempo (y viceversa); el capitán debe pertenecer obligatoriamente al grupo de titulares seleccionados.
- **Equipo aún no `"Habilitado"` por el Organizador**: Si un equipo aún está en estado `"Pendiente de Cupo"` o `"Listo para Habilitar"` (sin habilitación oficial en HU 5.1), el sistema informa que el equipo debe estar oficialmente `"Habilitado"` antes de publicar una alineación oficial para un partido, permitiendo aún consultar el seguimiento interno de la plantilla.
- **Accesibilidad sin dependencia exclusiva del color**: Todas las insignias disciplinarias (`"Habilitado"`, `"En capilla"`, `"Suspendido (1 fecha)"`, `"Titular"`, `"Suplente"`, `"Capitán"`) deben combinar color semántico (`#10B981`, `#F59E0B`, `#EF4444`), ícono y etiqueta de texto explícita en español.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE permitir acceder desde el detalle del equipo (`/tournaments/teams/detail`) a una vista dedicada (`/tournaments/teams/lineup`) donde el `Entrenador` (y el `Organizador` con permisos de gestión) pueda gestionar la convocatoria y alineación para el próximo partido del campeonato, clasificando a los jugadores habilitados de la plantilla en `"Titular"`, `"Suplente"` o `"No convocado"`, designando a un `"Capitán"` dentro de los titulares y alternando hacia la sección de `"Seguimiento Interno"`.
- **FR-002**: El sistema DEBE determinar la cantidad reglamentaria de jugadores titulares en cancha para el partido según la modalidad o configuración del campeonato (`requiredStarters = min(minPlayersPerTeam, 11)`, por ejemplo: Fútbol 5 = 5 titulares, Fútbol 7 = 7 titulares, Fútbol 8 = 8 titulares, Fútbol 11 = 11 titulares) y validar al confirmar la convocatoria que:
  - El número de titulares seleccionados coincida exactamente con `requiredStarters`.
  - Exista exactamente un jugador titular designado como capitán.
  - Se permita incluir desde `0` hasta el total restante de jugadores habilitados (no suspendidos) de la plantilla como suplentes (`"Suplente"`), dejando al resto como `"No convocado"`.
  - Ningún jugador convocado (titular o suplente) tenga una sanción disciplinaria activa.
- **FR-003**: El sistema DEBE evaluar automáticamente el estado disciplinario de cada jugador en el campeonato considerando las reglas del torneo (`yellowCardsSuspensionThreshold`):
  - Si el jugador tiene fechas de suspensión pendientes (por tarjeta roja previa o por alcanzar el umbral de tarjetas amarillas acumuladas del campeonato), DEBE mostrarse con la insignia semántica de error `"Suspendido ({count} fecha)"` / `"Suspendido ({count} fechas)"` (en color semántico `#EF4444` e ícono de bloqueo) y su control de selección DEBE estar deshabilitado.
  - Si el jugador está a `1` tarjeta amarilla de alcanzar `yellowCardsSuspensionThreshold` y no está suspendido, DEBE mostrarse con una insignia preventiva de advertencia (`#F59E0B`) indicando riesgo por acumulación de amarillas.
- **FR-004**: El sistema DEBE ofrecer al `Entrenador` una vista o sección de seguimiento interno del plantel donde pueda consultar las métricas individuales de cada jugador en el campeonato (partidos jugados, goles, asistencias, tarjetas amarillas acumuladas, tarjetas rojas y fechas de suspensión pendientes) para fundamentar sus decisiones tácticas.
- **FR-005**: Al confirmar la convocatoria oficial del equipo para el partido, el sistema DEBE persistir la alineación confirmada y dejarla inmediatamente disponible en modo de consulta/sincronización para el `Árbitro` del encuentro (vista de nómina habilitada para el acta arbitral) y demás roles autorizados; asimismo, DEBE permitir al `Entrenador` (u `Organizador`) ajustar la selección y reconfirmar la convocatoria antes del cierre del encuentro, actualizando la nómina oficial sincronizada.
- **FR-006**: El sistema DEBE conservar automáticamente en almacenamiento local el progreso parcial (borrador) de la selección de titulares, suplentes y capitán ante cambios de ciclo de vida de la aplicación móvil (paso a segundo plano, llamadas entrantes o reingreso a la pantalla) antes de su confirmación definitiva.
- **FR-007**: En entorno de desarrollo (`dev`), el sistema DEBE precargar datos semilla realistas de seguimiento interno y sanciones (incluyendo al menos un jugador con suspensión activa de `1 fecha` y jugadores con métricas de goles, asistencias y tarjetas amarillas) sobre los equipos semilla del campeonato para permitir verificar de inmediato todos los escenarios Gherkin.
- **FR-008**: Todos los textos visibles al usuario, etiquetas tácticas, insignias disciplinarias y mensajes de validación DEBEN estar 100% en español, manteniendo todos los identificadores técnicos en inglés.

### Key Entities *(include if feature involves data)*

- **`PlayerInternalTracking`**: Registro de seguimiento interno de rendimiento y disciplina de un jugador dentro de un campeonato (identificador de jugador, partidos jugados, goles, asistencias, tarjetas amarillas acumuladas, tarjetas rojas y fechas de suspensión pendientes).
- **`PlayerDisciplinaryStatus`**: Estado disciplinario calculado de un jugador para el próximo partido (`eligible` / `"Habilitado"`, `warningAccumulation` / `"Riesgo de Amarillas"`, `suspended` / `"Suspendido"`, junto con el número de fechas pendientes).
- **`MatchLineupConvocation`**: Convocatoria y alineación de un equipo para un partido específico del campeonato (identificador de partido/encuentro, campeonato, equipo, lista de identificadores de titulares, lista de identificadores de suplentes, identificador del capitán, estado de borrador o confirmada oficialmente para el acta arbitral, y marca de tiempo de actualización).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un `Entrenador` puede armar y confirmar la convocatoria oficial de su equipo (titulares, suplentes y capitán) en menos de 60 segundos desde el detalle del equipo.
- **SC-002**: El 100% de los jugadores con sanción activa aparecen identificados visualmente con la etiqueta `"Suspendido (1 fecha)"` (o el número de fechas correspondiente) y tienen bloqueada su inclusión en la convocatoria tanto en la interfaz como en las validaciones de negocio.
- **SC-003**: El 100% de las selecciones parciales de convocatoria en curso se conservan intactas tras pasar la aplicación a segundo plano y regresar a la pantalla.
- **SC-004**: El 100% de las convocatorias confirmadas por el `Entrenador` quedan inmediatamente visibles como nómina oficial de titulares y suplentes habilitados para el `Árbitro` del encuentro.

## Assumptions

- Dado que la generación completa del calendario de partidos (Fixture, Épica 6 / HU 6.1) y el acta digital en vivo (Épica 7 / HU 7.1) pertenecen a historias posteriores, cada equipo inscrito en un campeonato dispone de un contexto de "Próximo Partido Programado" del campeonato sobre el cual el `Entrenador` gestiona y publica la convocatoria oficial y el `Árbitro` puede previsualizar la nómina sincronizada para su acta digital.
- La cantidad de titulares requeridos en cancha se deriva determinísticamente de la configuración del campeonato (`minPlayersPerTeam` de las reglas personalizadas del torneo, que representa el mínimo reglamentario de jugadores para presentarse en cancha según la modalidad, p. ej. 5, 7, 8 u 11 titulares, con tope a `11` cuando `minPlayersPerTeam > 11`).
- Solo los roles autorizados (`Entrenador` con capacidad de gestionar alineaciones y `Organizador`) pueden modificar y confirmar la convocatoria o actualizar el seguimiento interno, mientras que el `Árbitro` visualiza la nómina oficial sincronizada para el acta arbitral.
