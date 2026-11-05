# Feature Specification: Exportación e Importación de Respaldos (Backup/Restore) y Cierre Histórico de Temporada (HU 9.2)

**Feature Branch**: `012-backup-restore-season-closure`

**Created**: 2026-11-05

**Status**: Draft

**Input**: User description: "[Épica 9] HU 9.2: Exportación e Importación de Respaldos (Backup/Restore) y Cierre Histórico de Temporada"

## Clarifications

### Session 2026-11-05

- Q: ¿Qué alcance debe tener la restauración al importar un archivo de respaldo de un campeonato? → A: Restauración aislada por campeonato (`upsert` del torneo importado y sus entidades sin afectar otros campeonatos locales).
- Q: ¿Cómo debe funcionar el mecanismo de confirmación de seguridad de dos pasos antes de restaurar un respaldo o finalizar un campeonato? → A: Diálogo modal con resumen de impacto + casilla de verificación explícita que habilita el botón de confirmación final.
- Q: ¿Qué reglas deben aplicarse para determinar el "Máximo Goleador" y la "Valla Menos Vencida" al generar el Cuadro de Honor oficial? → A: Reglas deterministas: Valla Menos Vencida entre equipos con >=1 partido finalizado (menos goles en contra, más PJ, mejor DG); Máximo Goleador con desempate por asistencias y soporte para "Sin goles registrados".
- Q: ¿Dónde deben ubicarse visualmente el Cuadro de Honor y las acciones de Respaldo/Cierre de temporada dentro de la interfaz móvil? → A: Integración en Torneos y Clasificación: acciones de respaldo/cierre en la gestión del torneo (`Organizador`) y panel destacado del Cuadro de Honor para todos los roles cuando el torneo está `Finalizado`.
- Q: ¿Cómo debe el organizador exportar e importar el paquete de respaldo desde la aplicación móvil? → A: Modal de respaldo autónomo: genera el paquete exportable con resumen/copia/guardado local y permite cargar o pegar el archivo de respaldo con validación previa.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Exportación e Importación Validada de Respaldos del Campeonato (Priority: P1)

Como `Organizador` del campeonato, quiero exportar un respaldo completo del torneo e importar copias de respaldo verificadas para resguardar la información deportiva frente a contingencias o pérdida de dispositivo sin poner en riesgo los datos existentes.

**Why this priority**: La protección contra pérdida de datos y la capacidad de restaurar un torneo íntegro es crítica para la continuidad operativa de cualquier campeonato gestionado en campo.

**Independent Test**: Como `Organizador`, generar un respaldo completo de un campeonato activo, verificar que contiene toda la estructura del torneo (configuración, equipos, jugadores, partidos, actas, noticias y versión de esquema), luego simular la importación de un respaldo corrupto comprobando que se rechaza sin alterar el estado actual, y finalmente restaurar el respaldo válido tras confirmación de dos pasos verificando que el campeonato queda íntegro.

**Acceptance Scenarios**:

1. **Given** que un usuario con rol `Organizador` accede a la gestión o configuración avanzada del campeonato, **When** selecciona "Exportar respaldo del torneo", **Then** el sistema empaqueta la configuración del campeonato, equipos, jugadores, partidos, eventos de actas, noticias y estadísticas junto con la versión de esquema y fecha de creación, permitiendo guardar o compartir el respaldo y mostrando confirmación de éxito en español.
2. **Given** que el `Organizador` selecciona "Importar respaldo", **When** proporciona un archivo con formato inválido, versión incompatible o referencias huérfanas (por ejemplo, un partido cuyo equipo o jugador no existe en el paquete), **Then** el sistema aborta la operación antes de realizar cualquier cambio y muestra el mensaje exacto en español: `"El archivo de respaldo no es válido o está incompleto. No se realizaron cambios."`
3. **Given** que el `Organizador` selecciona un respaldo válido y compatible, **When** completa la confirmación explícita de seguridad de dos pasos advirtiendo que los datos actuales del campeonato serán reemplazados, **Then** el sistema restaura de forma atómica todas las entidades del torneo y actualiza las vistas de inmediato.
4. **Given** un usuario con rol distinto a `Organizador` (`Entrenador`, `Árbitro`, `Jugador` o `Aficionado`), **When** consulta el campeonato, **Then** las opciones de exportación e importación de respaldos no están visibles ni permitidas.

---

### User Story 2 - Cierre Oficial de Temporada y Publicación del Cuadro de Honor (Priority: P2)

Como `Organizador`, quiero cerrar oficialmente el campeonato una vez concluidos los partidos decisivos para coronar al campeón, publicar el cuadro de honor oficial y preservar la temporada como registro histórico.

**Why this priority**: El cierre formal de temporada otorga valor culminante al torneo al reconocer oficialmente a los ganadores y destacados ante toda la comunidad deportiva.

**Independent Test**: Configurar un campeonato cuyos partidos obligatorios (o gran final) estén en estado `Finalizado`, ejecutar la acción "Finalizar Campeonato" como `Organizador`, confirmar en el diálogo de seguridad de dos pasos y verificar que el estado cambia a `Finalizado` y que el Cuadro de Honor (Campeón, Subcampeón, Máximo Goleador y Valla Menos Vencida) se calcula y se muestra públicamente a todos los roles.

**Acceptance Scenarios**:

1. **Given** que todos los partidos programados de una liga o la gran final de un torneo eliminatorio se encuentran en estado `Finalizado`, **When** el `Organizador` ejecuta la acción "Finalizar Campeonato" y confirma en el diálogo de seguridad de dos pasos, **Then** el campeonato cambia su estado a `Finalizado` y genera el Cuadro de Honor oficial con Campeón, Subcampeón, Máximo Goleador y Valla Menos Vencida.
2. **Given** que un campeonato aún tiene partidos pendientes (`Programado`, `En Juego` o `Suspendido`) o no cuenta con partidos finalizados suficientes para determinar al ganador, **When** el `Organizador` intenta ejecutar "Finalizar Campeonato", **Then** el sistema impide el cierre y muestra un mensaje explicativo en español indicando que todos los partidos requeridos deben estar finalizados antes de cerrar la temporada.
3. **Given** que un campeonato ha sido cerrado oficialmente, **When** cualquier usuario (`Organizador`, `Entrenador`, `Árbitro`, `Jugador` o `Aficionado`) consulta el campeonato, **Then** visualiza de forma destacada el Cuadro de Honor de la temporada junto con los resultados y tablas finales.

---

### User Story 3 - Protección Histórica en Modo de Solo Lectura Permanente (Priority: P3)

Como `Organizador` y miembro de la comunidad del torneo, quiero que un campeonato cerrado permanezca bloqueado contra modificaciones operativas para garantizar que el historial oficial de la temporada sea inalterable.

**Why this priority**: Asegura la transparencia e integridad histórica del torneo una vez proclamados los campeones, evitando alteraciones accidentales o no autorizadas posteriores al cierre.

**Independent Test**: En un campeonato con estado `Finalizado`, intentar modificar reglas, inscribir/eliminar jugadores, reprogramar partidos o reabrir actas arbitrales y verificar que todas las operaciones de escritura están bloqueadas mientras la consulta y la exportación de respaldo histórico siguen disponibles.

**Acceptance Scenarios**:

1. **Given** un campeonato en estado `Finalizado`, **When** cualquier usuario (incluido el `Organizador` o `Árbitro`) intenta editar reglas del torneo, modificar plantillas de equipos, generar o reprogramar calendario, o alterar actas de partidos, **Then** el sistema rechaza la modificación e informa en español que la temporada se encuentra cerrada en modo de consulta histórica permanente.
2. **Given** un campeonato en estado `Finalizado`, **When** el `Organizador` desea conservar una copia de archivo del torneo cerrado, **Then** la función de "Exportar respaldo del torneo" continúa habilitada para resguardar el historial completo incluido su Cuadro de Honor.

---

### Edge Cases

- **Interrupción o cancelación durante la selección/importación de respaldo**: Si el usuario cancela el selector o la aplicación pasa a segundo plano antes de confirmar la restauración, no se altera ningún dato local y el estado previo permanece intacto.
- **Archivo de respaldo vacío, truncado o con estructura ajena al sistema**: El validador detecta la anomalía de inmediato sin lanzar errores no controlados y presenta el mensaje estándar `"El archivo de respaldo no es válido o está incompleto. No se realizaron cambios."`
- **Empate en distinciones individuales del Cuadro de Honor**: Si dos o más jugadores empatan en goles para "Máximo Goleador" o dos equipos empatan en goles recibidos para "Valla Menos Vencida", se aplica un criterio determinista (menor cantidad de partidos jugados y, de persistir, mejor diferencia de goles o orden alfabético) para garantizar un resultado único y reproducible.
- **Doble pulsación en acciones críticas ("Importar respaldo" o "Finalizar Campeonato")**: Los botones de confirmación se bloquean durante el procesamiento para evitar ejecuciones duplicadas.
- **Pantallas pequeñas (320 px) y texto escalado al 130%**: Las tarjetas del Cuadro de Honor y los diálogos de confirmación de dos pasos adaptan su contenido en múltiples líneas sin truncamiento crítico ni desbordamiento visual.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE permitir exclusivamente al rol `Organizador` exportar un paquete de respaldo completo de un campeonato mediante un modal autónomo (con nombre de archivo sugerido, resumen de entidades y acción de guardado/copia local) que incluya versión de esquema, metadatos de exportación, datos del torneo, equipos, jugadores, partidos, eventos de actas, comunicados oficiales y, si aplica, el cuadro de honor, así como cargar o pegar un archivo de respaldo con validación previa.
- **FR-002**: El sistema DEBE permitir exclusivamente al rol `Organizador` importar un paquete de respaldo aplicando una restauración aislada y atómica por campeonato (`upsert` del torneo importado y sus entidades asociadas), preservando intactos los demás campeonatos almacenados en el dispositivo.
- **FR-003**: Antes de aplicar cualquier restauración, el sistema DEBE ejecutar una validación integral de esquema, versión de compatibilidad e integridad referencial cruzada (todos los equipos referenciados en jugadores y partidos deben existir en el respaldo, y todos los eventos deben corresponder a partidos y jugadores válidos del mismo campeonato).
- **FR-004**: Si la validación del respaldo falla por cualquier motivo (formato corrupto, campos obligatorios faltantes, versión incompatible o referencias huérfanas), el sistema DEBE abortar la operación de forma atómica sin modificar los datos existentes y mostrar exactamente el mensaje en español: `"El archivo de respaldo no es válido o está incompleto. No se realizaron cambios."`
- **FR-005**: El sistema DEBE exigir una confirmación explícita de seguridad de dos pasos mediante un diálogo modal con resumen de impacto y una casilla de verificación obligatoria que habilita el botón de confirmación final antes de sobrescribir datos locales durante una importación de respaldo válida y antes de ejecutar el cierre definitivo de un campeonato.
- **FR-006**: El sistema DEBE permitir al `Organizador` ejecutar el cierre oficial de temporada ("Finalizar Campeonato") únicamente cuando el torneo tenga al menos un partido disputado y todos los partidos obligatorios (o el partido de la gran final en formato eliminatorio) se encuentren en estado `Finalizado`.
- **FR-007**: Al cerrar el campeonato, el sistema DEBE cambiar su estado a `Finalizado` y calcular/registrar automáticamente el Cuadro de Honor oficial compuesto por:
  - **Campeón**: Equipo ganador de la gran final (en formato eliminatorio o mixto con fase final) o primer lugar de la tabla de posiciones (en formato liga).
  - **Subcampeón**: Equipo finalista derrotado o segundo lugar de la tabla de posiciones.
  - **Máximo Goleador**: Jugador con mayor cantidad de goles oficiales registrados en el campeonato (con desempate determinista por mayor cantidad de asistencias y orden alfabético; si ningún jugador anotó goles en el campeonato, se registra como `"Sin goles registrados"`).
  - **Valla Menos Vencida**: Equipo con menor cantidad de goles recibidos entre aquellos con al menos 1 partido finalizado (con desempate determinista por mayor cantidad de partidos jugados, mejor diferencia de goles y orden alfabético).
- **FR-008**: Una vez que un campeonato alcanza el estado `Finalizado`, el sistema DEBE bloquear de forma permanente cualquier operación de creación, edición o eliminación sobre la configuración del torneo, equipos, jugadores, calendario, alineaciones, actas de partidos y comunicados, preservando todos sus registros en modo de solo lectura histórica.
- **FR-009**: El sistema DEBE mostrar las acciones de "Exportar respaldo", "Importar respaldo" y "Finalizar Campeonato" en la gestión del campeonato para el rol `Organizador`, y presentar el Cuadro de Honor oficial como un panel destacado en las vistas de Torneos y Clasificación para todos los roles (`Organizador`, `Entrenador`, `Árbitro`, `Jugador` y `Aficionado`) cuando el campeonato se encuentre en estado `Finalizado`.
- **FR-010**: Todos los textos visibles, etiquetas del Cuadro de Honor, advertencias de seguridad de dos pasos y mensajes de validación o error DEBEN presentarse 100% en español mediante el sistema de localización del proyecto (`l10n`).

### Key Entities *(include if feature involves data)*

- **`TournamentBackupPackage` (Paquete de Respaldo del Campeonato)**: Representa la instantánea estructurada y autónoma de un campeonato. Incluye versión del esquema (`schemaVersion`), fecha de exportación (`exportedAt`), datos del campeonato, lista de equipos, lista de jugadores, lista de partidos con sus eventos y actas, lista de noticias oficiales y cuadro de honor (si el torneo está finalizado).
- **`BackupValidationResult` (Resultado de Validación de Respaldo)**: Resultado determinista de la inspección previa a la importación. Indica si el paquete es válido (`isValid`), el mensaje de error localizado en caso de fallo y el resumen de entidades detectadas para presentar en la confirmación de dos pasos.
- **`SeasonHonorRoll` (Cuadro de Honor de Temporada)**: Registro histórico oficial generado al cerrar el campeonato. Contiene el identificador del torneo, fecha de clausura (`closedAt`), datos del equipo Campeón, equipo Subcampeón, distinción al Máximo Goleador (jugador, equipo y goles) y distinción a la Valla Menos Vencida (equipo y goles recibidos).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El `Organizador` puede exportar el respaldo completo de un campeonato o restaurar un respaldo válido en menos de 3 segundos sin bloqueo de la interfaz.
- **SC-002**: El 100% de los intentos de importación con archivos corruptos, incompletos o con referencias rotas son bloqueados antes de modificar el almacenamiento, mostrando el mensaje requerido en español y manteniendo el 100% de los datos previos intactos.
- **SC-003**: El 100% de las acciones destructivas o irreversibles (sobrescribir datos al restaurar un respaldo y cerrar definitivamente la temporada) requieren confirmación explícita de dos pasos.
- **SC-004**: Tras cerrar un campeonato, el 100% de los intentos de modificación operativa sobre el torneo cerrado son rechazados, mientras que el Cuadro de Honor y las estadísticas históricas permanecen accesibles en modo lectura para los 5 roles del sistema.
- **SC-005**: Cero desbordamientos visuales en las vistas del Cuadro de Honor y diálogos de respaldo/cierre en pantallas de 320 px de ancho con escalado tipográfico al 130%.

## Assumptions

- **Formato estándar portable y legible**: El paquete de respaldo utiliza una estructura de texto estándar autodescriptiva con versión de esquema explícita (`schemaVersion: 1`), lo que permite tanto guardarlo/importarlo desde archivos del dispositivo como inspeccionar o transferir su contenido sin depender de servicios en la nube.
- **Acceso desde la gestión de campeonatos**: Las acciones de "Exportar respaldo", "Importar respaldo" y "Finalizar Campeonato" se integran directamente en las vistas existentes de gestión y detalle del campeonato para el rol `Organizador`, respetando el límite máximo de 5 pestañas en la navegación principal.
- **Determinismo del Cuadro de Honor**: El cálculo de Campeón, Subcampeón, Máximo Goleador y Valla Menos Vencida reutiliza las reglas oficiales de clasificación y estadísticas ya vigentes en el campeonato, garantizando total consistencia con la tabla de posiciones y el ranking de goleadores.
