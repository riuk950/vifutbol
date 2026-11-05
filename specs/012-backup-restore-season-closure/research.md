# Research & Architectural Decisions: Exportación e Importación de Respaldos y Cierre Histórico de Temporada (HU 9.2)

**Feature**: `012-backup-restore-season-closure`  
**Date**: 2026-11-05

---

## 1. Formato del Paquete de Respaldo y Compatibilidad de Esquema

- **Decision**: Definir un contrato JSON autónomo `TournamentBackupPackage` con versión de esquema explícita (`schemaVersion: 1`), identificador de formato (`formatSignature: "vifutbol.tournament_backup"`), marca de tiempo UTC (`exportedAt`) y colecciones completas de la raíz agregada del campeonato (`tournament`, `teams`, `matches`, `matchReports`, `newsItems`, `honorRoll`).
- **Rationale**: Garantiza portabilidad total offline sin requerir motores binarios propietarios ni servicios en la nube. La firma y `schemaVersion` permiten rechazar de forma determinista archivos ajenos o versiones futuras incompatibles antes de tocar el almacenamiento local.
- **Alternatives considered**:
  - *Respaldo binario SQLite / archivo ZIP*: Añade dependencias nativas de compresión y dificulta la inspección y las pruebas unitarias deterministas en memoria.
  - *Volcado crudo de claves de `SharedPreferences`*: Acopla el archivo exportado a las claves internas de almacenamiento y mezcla todos los torneos del dispositivo en lugar de aislar un campeonato específico.

---

## 2. Validación Previa e Integridad Referencial Cruzada Atómica

- **Decision**: Implementar un validador de dominio/caso de uso (`ValidateTournamentBackupUseCase`) que analiza el JSON en memoria y verifica:
  1. Estructura JSON válida, `formatSignature == "vifutbol.tournament_backup"` y `schemaVersion == 1`.
  2. Presencia y validez del campeonato (`tournament.id` no vacío, nombre válido, reglas válidas).
  3. Integridad referencial de equipos y jugadores (`team.tournamentId == tournament.id`, IDs de equipos y jugadores únicos y no vacíos).
  4. Integridad referencial de partidos (`match.tournamentId == tournament.id`, y cuando los equipos local/visitante no son placeholders de llaves por definir, sus IDs deben existir en `teams`).
  5. Integridad referencial de actas digitales y eventos (`report.tournamentId == tournament.id`, `report.matchId` existe en `matches`, y cada `MatchEvent` referencia un `teamId` válido del partido).
  6. Integridad referencial de noticias (`news.tournamentId == tournament.id`) y cuadro de honor (`honorRoll.tournamentId == tournament.id` si está presente).
  Si cualquier chequeo falla, retorna `BackupValidationResult.invalid("El archivo de respaldo no es válido o está incompleto. No se realizaron cambios.")` sin invocar ningún método de escritura en los repositorios.
- **Rationale**: Cumple estrictamente el criterio Gherkin de rechazo seguro y el Principio II de la Constitución (Integridad de Datos y Fuente de Verdad Transparente).
- **Alternatives considered**:
  - *Insertar entidad por entidad y hacer rollback en caso de error*: Riesgo de dejar estado parcial si ocurre una excepción a mitad de la escritura en almacenamiento clave-valor.

---

## 3. Restauración Aislada por Campeonato (`Upsert` Transaccional)

- **Decision**: Añadir soporte de reemplazo por campeonato (`restoreTournamentData`) o métodos equivalentes en los repositorios locales (`LocalTournamentsRepository`, `LocalTeamsRepository`, `LocalTournamentMatchesRepository`, `LocalMatchReportsRepository`, `LocalTournamentNewsRepository`, `LocalSeasonHonorRollRepository`) orquestados por `ImportTournamentBackupUseCase`. Todos los demás campeonatos con `id != package.tournament.id` se conservan intactos.
- **Rationale**: Responde a la clarificación Q1: evita que el organizador pierda otros torneos gestionados en el mismo dispositivo al restaurar una copia de seguridad de un campeonato específico.
- **Alternatives considered**:
  - *Sobrescritura global de todos los torneos*: Descartado en la sesión de clarificación por riesgo de pérdida de datos de otros campeonatos.

---

## 4. Cálculo Determinista del Cuadro de Honor (`SeasonHonorRoll`)

- **Decision**: Reutilizar los resultados deterministas de `CalculateTournamentStandingsAndRankingsUseCase` al cerrar el campeonato en `CloseTournamentSeasonUseCase`:
  - **Condición de cierre**: El campeonato debe estar en estado `inProgress`, contar con al menos un partido registrado, y:
    - En formato `league`: todos los partidos del campeonato deben estar en estado `MatchStatus.completed`.
    - En formato `knockoutCup` o `mixedGroupsAndKnockout`: el partido de la ronda `KnockoutRound.finalMatch` debe existir y estar en estado `MatchStatus.completed` (o todos los partidos del torneo deben estar en `MatchStatus.completed`).
  - **Campeón y Subcampeón**:
    - Si existe partido completado de `KnockoutRound.finalMatch`: el ganador del partido final (por marcador o penales) es el **Campeón** y el otro finalista es el **Subcampeón**.
    - En formato `league` (o si se define por tabla general): fila posición `1` de `mainStandingsTable` es **Campeón** y fila posición `2` es **Subcampeón**.
  - **Máximo Goleador**: Primer registro de `rankings.topScorers` con `goals > 0` (que ya desempata deterministamente por goles desc, asistencias desc, menos partidos jugados y nombre asc). Si ningún jugador anotó goles (`topScorers` vacío o `goals == 0`), se registra con indicador `hasTopScorer: false` y etiqueta localizada `"Sin goles registrados"`.
  - **Valla Menos Vencida**: Entre todos los equipos con `played >= 1` en los partidos finalizados del campeonato, se selecciona el equipo con menor `goalsAgainst`; en caso de empate: mayor `played`, mayor `goalDifference` y orden alfabético por `teamName`.
- **Rationale**: Garantiza 100% de consistencia matemática entre las tablas de posiciones, llaves eliminatorias, rankings y el Cuadro de Honor publicado al cerrar la temporada.
- **Alternatives considered**:
  - *Selección manual del cuadro de honor por el organizador*: Propenso a errores humanos e inconsistencias con las actas oficiales.

---

## 5. Protección Histórica de Solo Lectura Permanente (`TournamentStatus.finished`)

- **Decision**: Reforzar la guardia `tournament.status == TournamentStatus.finished` en los casos de uso de escritura (`ManageTournamentsUseCase`, `ManageTeamsEligibilityUseCase`, `FixtureSchedulingUseCase`, `ManageLineupsTrackingUseCase`, `ManageDigitalMatchReportUseCase`, `PublishTournamentNewsUseCase`, `DeleteTournamentNewsUseCase`) y ocultar/deshabilitar los controles de edición en la UI cuando el campeonato está finalizado, manteniendo activos los controles de consulta y "Exportar respaldo del torneo".
- **Rationale**: Cumple con US3 y FR-008 tanto en la capa de presentación como en la capa de casos de uso del dominio.
- **Alternatives considered**:
  - *Bloquear únicamente en la interfaz gráfica*: Insuficiente según el Principio IV y V de la Constitución; las reglas de inmutabilidad deben validarse en los casos de uso.
