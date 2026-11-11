# Contracts: Menú Flotante Expandible y Modal de Búsqueda de Equipos (HU 18.4)

**Feature**: `035-competition-fab-team-search`  
**Date**: 2026-11-11  

---

## 1. Contrato de Caso de Uso y Controlador (`ManageTeamsEligibilityUseCase` / `TeamsController`)

### 1.1 `EnrollExistingTeamResult`
Ubicación: `lib/application/use_cases/manage_teams_eligibility_use_case.dart`

```dart
class EnrollExistingTeamResult {
  final TournamentTeam enrolledTeam;
  final int copiedPlayersCount;
  final int skippedConflictingPlayersCount;
  final String? assignedGroupName;

  const EnrollExistingTeamResult({
    required this.enrolledTeam,
    required this.copiedPlayersCount,
    required this.skippedConflictingPlayersCount,
    this.assignedGroupName,
  });
}
```

### 1.2 `ManageTeamsEligibilityUseCase.enrollExistingTeamFromCatalog`
```dart
Future<EnrollExistingTeamResult> enrollExistingTeamFromCatalog({
  required TournamentTeam sourceTeam,
  required ChampionshipTournament tournament,
  required UserRole actorRole,
  String? generatedTeamId,
})
```
**Precondiciones y Reglas**:
1. Verifica `RoleCapability.manageTournaments` para `actorRole` (`UnauthorizedRoleFailure` si falla).
2. Verifica `tournament.status.isEditable` (`TeamEligibilityValidationFailure` si está finalizada).
3. Valida longitud de `name` (>= 3) y `shortCode` (2..4).
4. Verifica no duplicidad contra `tournamentTeams` usando tanto `normalizedName` como `normalizeSearchText(name)` (insensible a mayúsculas y tildes). Lanza `TeamEligibilityValidationFailure(TeamEligibilityErrorCode.duplicateTeamNameInTournament)` si ya está inscrito.
5. Si `tournament.format == TournamentFormat.mixedGroupsAndKnockout`, calcula el grupo menos poblado (`StandingsCalculatorService.buildValidGroupNames` + `resolveEffectiveGroupName`).
6. Filtra `sourceTeam.players` omitiendo documentos ya presentes en `tournamentTeams` (`normalizedDocumentId`) o excedentes de `tournament.rules.maxPlayersPerTeam`, asignando `isEligible: false` y nuevos `id`.
7. Crea e inserta `TournamentTeam` con `eligibilityStatus: TeamEligibilityStatus.pendingVerification`.

### 1.3 `TeamsController.enrollExistingTeamFromCatalog`
Ubicación: `lib/application/controllers/teams_controller.dart`

```dart
Future<EnrollExistingTeamResult?> enrollExistingTeamFromCatalog({
  required TournamentTeam sourceTeam,
  required ChampionshipTournament tournament,
  required UserRole actorRole,
})
```
- Protegido con single-flight guard (`if (state.isSaving) return null;`).
- Actualiza `state = state.copyWith(teams: updatedTeams, selectedTeamId: result.enrolledTeam.id, isSaving: false)` tras guardar.
- Ante fallo captura `AppFailure` en `state.lastFailure` y retorna `null`.

---

## 2. Contrato de `CompetitionDetailFabMenu`

Ubicación: `lib/presentation/tournaments/widgets/competition_detail_fab_menu.dart`

```dart
class CompetitionDetailFabMenu extends StatefulWidget {
  final bool showGenerateFixture;
  final VoidCallback onGenerateFixture;
  final VoidCallback onAddTeams;

  const CompetitionDetailFabMenu({
    super.key,
    required this.showGenerateFixture,
    required this.onGenerateFixture,
    required this.onAddTeams,
  });
}
```

### Keys Estables y Comportamiento
- Botón principal toggle: `Key('competition_detail_fab_menu')` (`FloatingActionButton`, tooltip `l10n.competitionFabMenuTooltip`).
- Al pulsar `competition_detail_fab_menu`, alterna `_isExpanded` con animación de `120ms` (`< 150ms` requerido por `SC-001`).
- Cuando `_isExpanded == true`:
  - Opción `"Agregar Equipos"`: `Key('competition_detail_fab_add_team')`, etiqueta `l10n.competitionFabAddTeamsLabel` (`"Agregar Equipos"`), ícono `Icons.group_add_outlined`. Al pulsar: colapsa el menú e invoca `onAddTeams`.
  - Opción `"Generar Fixture"` (visible solo si `showGenerateFixture == true`): `Key('competition_detail_fab_generate_fixture')`, etiqueta `l10n.competitionFabGenerateFixtureLabel` (`"Generar Fixture"`), ícono `Icons.alt_route`. Al pulsar: colapsa el menú e invoca `onGenerateFixture`.
- En `CompetitionDetailScreen`:
  - No se renderiza si `!RolePermissionMatrix.hasCapability(userRole, RoleCapability.manageTournaments)` o `tournament == null` o `!tournament.status.isEditable`.
  - `showGenerateFixture` es `!hasFixture`.

---

## 3. Contrato de `AddTeamsToCompetitionModal`

Ubicación: `lib/presentation/tournaments/widgets/add_teams_to_competition_modal.dart`

```dart
class AddTeamsToCompetitionModal extends ConsumerStatefulWidget {
  final ChampionshipTournament tournament;

  const AddTeamsToCompetitionModal({
    super.key,
    required this.tournament,
  });

  static Future<void> show(
    BuildContext context, {
    required ChampionshipTournament tournament,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: KickPulseColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(KickPulseRadiiSpacing.cardRadius),
        ),
      ),
      builder: (_) => AddTeamsToCompetitionModal(tournament: tournament),
    );
  }
}
```

### Keys Estables y Comportamiento Visual
- Contenedor raíz: `Key('add_teams_modal')`
- Botón de cierre: `Key('add_teams_modal_close_button')`
- Campo de búsqueda (`KickPulseSearchBar`): `Key('add_teams_search_field')`
- Lista de catálogo: `Key('add_teams_catalog_list')`
- Tarjeta de cada equipo del catálogo: `Key('add_teams_catalog_item_${entry.sourceTeam.id}')`
- Estado / Acción por fila:
  - Si `entry.isEnrolledInCurrentTournament == true`:
    - Muestra distintivo `KickPulseBadge` con etiqueta `l10n.addTeamsStatusEnrolledBadge` (`"Inscrito"`, variante `success`) con `Key('add_teams_enrolled_badge_${entry.sourceTeam.id}')`.
    - Botón de acción deshabilitado (`onPressed: null`, con `Key('add_teams_action_button_${entry.sourceTeam.id}')`) mostrando `"Inscrito"`.
  - Si `entry.isEnrolledInCurrentTournament == false`:
    - Botón habilitado (`Key('add_teams_action_button_${entry.sourceTeam.id}')`) con etiqueta `l10n.addTeamsActionAdd` (`"Agregar"`), bloqueado temporalmente mientras esa fila o `teamsState.isSaving` está en curso.
- Estados vacíos:
  - Catálogo global sin equipos: `Key('add_teams_empty_catalog_state')`.
  - Búsqueda sin coincidencias: `Key('add_teams_empty_search_state')` con botón `Key('add_teams_clear_filter_button')` (`"Limpiar búsqueda"`).
- Al completar inscripción:
  - El modal **permanece abierto** y **conserva `_searchQuery`**.
  - Al recibir el siguiente snapshot de `teamsControllerProvider`, la fila pasa automáticamente a `"Inscrito"` y `CompetitionTeamsTabView` refleja el nuevo equipo en estado `pendingVerification`.
  - Muestra aviso feedback en pantalla (`SnackBar` / banner de resultado) indicando éxito o el número de jugadores omitidos por conflicto de documento.
