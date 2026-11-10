# UI Contracts & Specifications: Gestión de Competiciones en Panel del Organizador (HU 16.1)

**Feature**: `028-organizer-competitions-crud`
**Date**: 2026-11-10

## 1. Widget Keys Contract

The following keys MUST be used in the UI widgets to enable automated component and integration testing:

| Component | Widget Key | Type / Purpose |
|---|---|---|
| Section Container | `const Key('organizer_competitions_section')` | Root container for the competitions list |
| Section Header Title | `const Key('organizer_competitions_header_title')` | Title of the section |
| Create Competition Button | `const Key('organizer_action_create_competition')` | Button to create new tournament |
| Empty State Container | `const Key('organizer_competitions_empty_state')` | Card shown when organizer has no tournaments |
| Empty State Create Button | `const Key('organizer_action_empty_create_competition')` | Button within empty state |
| Tournament Card | `Key('organizer_competition_card_${tournament.id}')` | Card representation for each tournament |
| Tournament Status Badge | `Key('organizer_competition_status_badge_${tournament.id}')` | Badge showing `openRegistration`, etc. |
| Tournament More Options | `Key('organizer_competition_menu_button_${tournament.id}')` | Context menu trigger on card |
| Menu Option: Edit | `Key('organizer_competition_menu_edit_${tournament.id}')` | Popup item / action to edit |
| Menu Option: Lifecycle | `Key('organizer_competition_menu_status_${tournament.id}')` | Popup item / action to change status |
| Menu Option: Delete | `Key('organizer_competition_menu_delete_${tournament.id}')` | Popup item / action to delete |
| Edit Dialog: Name Input | `const Key('competition_edit_name_input')` | Text field for tournament name |
| Edit Dialog: Category Input | `const Key('competition_edit_category_input')` | Text field for tournament category |
| Edit Dialog: Save Button | `const Key('competition_edit_save_button')` | Confirm save button |
| Edit Dialog: Cancel Button | `const Key('competition_edit_cancel_button')` | Cancel button |
| Lifecycle Dialog: Target Status Select | `const Key('competition_lifecycle_target_select')` | Dropdown or chips for target status |
| Lifecycle Dialog: Confirm Button | `const Key('competition_lifecycle_confirm_button')` | Confirm state transition button |
| Lifecycle Dialog: Action Enroll Teams | `const Key('competition_lifecycle_action_enroll_teams')` | Quick action button to enroll teams |
| Lifecycle Dialog: Action Generate Fixture | `const Key('competition_lifecycle_action_generate_fixture')` | Quick action button to generate fixture |
| Delete Dialog: Confirm Button | `const Key('competition_delete_confirm_button')` | Destructive confirm delete button |
| Delete Dialog: Cancel Button | `const Key('competition_delete_cancel_button')` | Cancel delete button |

---

## 2. Localization Keys (`lib/l10n/app_es.arb`)

All UI strings MUST be placed in `lib/l10n/app_es.arb`.

```json
{
  "organizerCompetitionsSectionTitle": "Mis Competiciones",
  "organizerCompetitionsCreateAction": "Nueva Competición",
  "organizerCompetitionsEmptyTitle": "No tienes competiciones activas",
  "organizerCompetitionsEmptySubtitle": "Crea y administra tus torneos, categorías y reglamentos desde este panel.",
  "organizerCompetitionsEmptyCreateButton": "Crear mi primera competición",
  "organizerCompetitionsTeamsCount": "{count, plural, =1{1 equipo inscrito} other{{count} equipos inscritos}}",
  "organizerCompetitionsMenuEdit": "Editar metadatos",
  "organizerCompetitionsMenuStatus": "Cambiar estado de competición",
  "organizerCompetitionsMenuDelete": "Eliminar competición",
  "competitionEditDialogTitle": "Editar Competición",
  "competitionEditNameLabel": "Nombre del torneo",
  "competitionEditCategoryLabel": "Categoría",
  "competitionEditFormatLabel": "Formato de competición",
  "competitionEditSaveButton": "Guardar cambios",
  "competitionEditSavedSuccess": "Competición actualizada exitosamente.",
  "competitionLifecycleDialogTitle": "Cambiar Estado del Torneo",
  "competitionLifecycleCurrentStatus": "Estado actual: {status}",
  "competitionLifecycleTargetStatus": "Nuevo estado:",
  "competitionLifecycleValidationMinTeams": "No se puede iniciar el torneo: requiere al menos 2 equipos inscritos (actuales: {count}).",
  "competitionLifecycleValidationNoFixture": "No se puede iniciar el torneo: debes generar el fixture de partidos previamente.",
  "competitionLifecycleActionEnrollTeams": "Inscribir Equipos",
  "competitionLifecycleActionGenerateFixture": "Generar Fixture",
  "competitionLifecycleConfirmButton": "Confirmar cambio de estado",
  "competitionLifecycleSuccess": "Estado del torneo actualizado a {status}.",
  "competitionDeleteDialogTitle": "Eliminar Competición",
  "competitionDeleteDialogMessage": "¿Estás seguro de que deseas eliminar permanentemente la competición \"{name}\"? Esta acción no se puede deshacer.",
  "competitionDeleteBlockedInProgress": "No se puede eliminar una competición en curso o finalizada.",
  "competitionDeleteBlockedHasMatches": "No se puede eliminar la competición porque ya cuenta con partidos disputados o en curso.",
  "competitionDeleteConfirmButton": "Eliminar definitivamente",
  "competitionDeleteSuccess": "La competición ha sido eliminada.",
  "competitionDeleteCancelButton": "Cancelar"
}
```

---

## 3. UI Component Signatures

### 3.1 `OrganizerCompetitionsSection`
```dart
class OrganizerCompetitionsSection extends ConsumerWidget {
  const OrganizerCompetitionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref);
}
```

### 3.2 `CompetitionEditDialog`
```dart
class CompetitionEditDialog extends ConsumerStatefulWidget {
  const CompetitionEditDialog({
    super.key,
    required this.tournament,
  });

  final ChampionshipTournament tournament;

  static Future<bool?> show({
    required BuildContext context,
    required ChampionshipTournament tournament,
  });
}
```

### 3.3 `CompetitionLifecycleDialog`
```dart
class CompetitionLifecycleDialog extends ConsumerStatefulWidget {
  const CompetitionLifecycleDialog({
    super.key,
    required this.tournament,
  });

  final ChampionshipTournament tournament;

  static Future<bool?> show({
    required BuildContext context,
    required ChampionshipTournament tournament,
  });
}
```

### 3.4 `CompetitionDeleteDialog`
```dart
class CompetitionDeleteDialog extends StatelessWidget {
  const CompetitionDeleteDialog({
    super.key,
    required this.tournament,
    required this.canDelete,
    this.blockReason,
  });

  final ChampionshipTournament tournament;
  final bool canDelete;
  final String? blockReason;

  static Future<bool?> show({
    required BuildContext context,
    required ChampionshipTournament tournament,
    required bool canDelete,
    String? blockReason,
  });
}
```
