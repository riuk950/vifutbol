# Tasks: Refactorización de Noticias (Filtros en Menú de 3 Puntos del AppBar y Creación de Noticia desde el Panel) (HU 15.1)

**Input**: Design documents from `/specs/024-news-filter-menu-panel/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/ui-news-filter-panel-contracts.md`, `quickstart.md`

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Exact file paths are included in every task description

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Spanish localization keys and code generation required across all stories.

- [X] T001 Define the 10 Spanish localization keys (`organizerActionPublishNews`, `organizerNoEditableTournamentsForNews`, `newsTournamentField`, `newsFilterMenuTooltip`, `newsFilterSheetTitle`, `newsFilterTournamentSectionTitle`, `newsFilterCategorySectionTitle`, `newsFilterResetButton`, `newsActiveFilterClearSemantics`, `newsFeedEmptyCategoryFilter`) in `lib/l10n/app_es.arb`
- [X] T002 Regenerate localization classes with `flutter gen-l10n` updating `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Reusable modal and dialog components that enable the panel creation flow and the AppBar filtering flow.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 Extend `CreateNewsDialog` and `CreateNewsDialog.show` in `lib/presentation/news/widgets/create_news_dialog.dart` to accept an optional `availableTournaments: List<ChampionshipTournament>?` parameter, rendering a `DropdownButtonFormField<String>` (`Key('create_news_tournament_dropdown')`) with label `l10n.newsTournamentField` preselecting `tournamentId`, and building `TournamentNewsItem` with the chosen tournament ID while preserving title ($3\text{–}120$ chars) and body ($5\text{–}3000$ chars) validations
- [X] T004 [P] Create `NewsFilterBottomSheet` (`Key('news_filter_bottom_sheet')`) in `lib/presentation/news/widgets/news_filter_bottom_sheet.dart` with title `l10n.newsFilterSheetTitle`, reset button (`Key('news_filter_reset_button')`), close button (`Key('news_filter_close_button')`), tournament `ChoiceChip` wrap (`Key('news_filter_tournament_chip_${tournament.id}')`) calling `tournamentsControllerProvider.notifier.selectTournament(tournament.id)`, and category `ChoiceChip` wrap (`Key('news_filter_category_chip_all')` and `Key('news_filter_category_chip_${category.name}')` for `general`, `disciplinary`, `rescheduling`) calling `tournamentNewsControllerProvider.notifier.setCategoryFilter` in real time without closing the sheet

**Checkpoint**: Foundation ready — `CreateNewsDialog` supports tournament selection and `NewsFilterBottomSheet` is ready to be wired.

---

## Phase 3: User Story 1 - Reubicación de la Publicación de Noticias al Panel Administrativo del Organizador (Priority: P1) 🎯 MVP

**Goal**: Remove the `"Nueva Noticia"` creation button from the public news feed (`TournamentNewsFeedView`) for all roles and add the `"Publicar Noticia"` quick action (`Key('organizer_action_publish_news')`) to `OrganizerPanelContent` (`/panel`) allowing the organizer to pick an editable tournament (`status != TournamentStatus.finished`) and publish an announcement in one step.

**Independent Test**: Render `TournamentNewsFeedView` as `UserRole.organizer` and verify `Key('create_news_button')` is absent; render `OrganizerPanelContent`, tap `Key('organizer_action_publish_news')`, select an active tournament in `Key('create_news_tournament_dropdown')`, submit the form, and verify the news item is saved and a confirmation `SnackBar` appears.

### Implementation for User Story 1

- [X] T005 [US1] Remove `create_news_button`, `_onCreateNews`, and the inline `TournamentNewsFilterBar` row from `TournamentNewsFeedView` in `lib/presentation/news/tournament_news_feed_view.dart`, and render a category-filtered empty state (`Key('news_feed_empty_filter')`) with `l10n.newsFeedEmptyCategoryFilter` and a reset button when `newsState.categoryFilter != null && filteredNews.isEmpty`
- [X] T006 [P] [US1] Add the `"Publicar Noticia"` quick action button (`Key('organizer_action_publish_news')`) and `_onPublishNews` handler in `lib/presentation/panel/widgets/organizer_panel_content.dart` filtering editable tournaments (`t.status != TournamentStatus.finished`), showing a `SnackBar` with `l10n.organizerNoEditableTournamentsForNews` when none exist, or opening `CreateNewsDialog.show` with `availableTournaments: editableTournaments` and publishing via `tournamentNewsControllerProvider.notifier.publishNews`
- [X] T007 [P] [US1] Add widget tests in `test/presentation/panel/organizer_panel_widget_test.dart` verifying `Key('organizer_action_publish_news')` visibility, non-finished tournament filtering in `Key('create_news_tournament_dropdown')`, announcement publication from `/panel`, and `SnackBar` feedback when no editable tournaments exist

**Checkpoint**: User Story 1 is functional and independently testable as an MVP increment.

---

## Phase 4: User Story 2 - Menú de Opciones de Tres Puntos en AppBar para Configuración de Filtros (Priority: P2)

**Goal**: Display a 3-dots (`Icons.more_vert`, `Key('app_bar_news_filter_action')`) action button in the `AppBar` of `AppShellScreen` exclusively when the active section is `"Noticias"` (`AppShellSection.news`), opening `NewsFilterBottomSheet` to filter news by tournament and category reactively.

**Independent Test**: Open `AppShellScreen`, switch to `"Noticias"`, verify `Key('app_bar_news_filter_action')` appears in the `AppBar` (and disappears on `"Partidos"` / `"Perfil"`), tap it to open `Key('news_filter_bottom_sheet')`, and select tournament/category chips to verify real-time feed updates.

### Implementation for User Story 2

- [X] T008 [US2] Add the contextual `IconButton` (`Key('app_bar_news_filter_action')`, `icon: const Icon(Icons.more_vert)`, `tooltip: l10n.newsFilterMenuTooltip`) to `AppBar.actions` in `lib/presentation/shell/app_shell_screen.dart` when `shellState.activeSection == AppShellSection.news`, invoking `NewsFilterBottomSheet.show(context)`
- [X] T009 [P] [US2] Add widget tests in `test/presentation/app_shell_widget_test.dart` verifying that `Key('app_bar_news_filter_action')` is rendered only when `AppShellSection.news` is active and opens `NewsFilterBottomSheet` (`Key('news_filter_bottom_sheet')`) when tapped

**Checkpoint**: User Stories 1 and 2 work independently and together.

---

## Phase 5: User Story 3 - Indicador Visual de Filtro Activo y Limpieza Rápida en el Feed (Priority: P3)

**Goal**: Remove the horizontal tournament chip bar from `NewsTabView`, permanently display the active tournament name as a subtitle (`Key('news_active_tournament_subtitle')`), and display a removable active category filter chip (`Key('news_active_filter_chip')`) with one-tap clear action (`Key('news_active_filter_clear_button')`) whenever `categoryFilter != null`.

**Independent Test**: Open `NewsTabView`, verify `Key('news_tournament_selector')` is absent and `Key('news_active_tournament_subtitle')` shows the active tournament name; apply a category filter (`disciplinary`), verify `Key('news_active_filter_chip')` appears, and tap its clear action to verify the filter resets to `"Todas"` (`null`) and the chip disappears.

### Implementation for User Story 3

- [X] T010 [US3] Refactor `NewsTabView` in `lib/presentation/shell/tabs/news_tab_view.dart` to remove `news_tournament_selector`, permanently render `Key('news_active_tournament_subtitle')` with the current tournament name, and conditionally render `Key('news_active_filter_chip')` with clear button (`Key('news_active_filter_clear_button')`) when `newsState.categoryFilter != null`
- [X] T011 [P] [US3] Update and expand widget tests in `test/widget/tournament_news_feed_widget_test.dart` verifying that `create_news_button` and `news_tournament_selector` are absent for all roles, `news_active_tournament_subtitle` is always displayed, `NewsFilterBottomSheet` updates tournament and category filters reactively in real time, and `news_active_filter_chip` clears the active category filter in one tap

**Checkpoint**: All user stories (US1, US2, US3) are complete and independently tested.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Compact viewport responsiveness ($320\times 640\text{ px}$ @ $130\%$ text scaling) and full quality gate verification.

- [X] T012 [P] Add a compact viewport ($320\times 640\text{ px}$) with $130\%$ text scaling widget test in `test/widget/tournament_news_feed_widget_test.dart` verifying zero `RenderFlex` overflows in `NewsTabView` (with `news_active_filter_chip` visible) and `NewsFilterBottomSheet`
- [X] T013 Execute `flutter analyze`, `dart format --output=none --set-exit-if-changed .`, and the full feature test suite per `specs/024-news-filter-menu-panel/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup (`T001`–`T002`)**: No dependencies — start immediately.
- **Phase 2: Foundational (`T003`–`T004`)**: Depends on Phase 1 completion — blocks all user stories.
- **Phase 3: User Story 1 (`T005`–`T007`)**: Depends on Phase 2 completion (MVP!).
- **Phase 4: User Story 2 (`T008`–`T009`)**: Depends on Phase 2 completion (`NewsFilterBottomSheet`).
- **Phase 5: User Story 3 (`T010`–`T011`)**: Depends on Phase 2 and Phase 3 (`TournamentNewsFeedView` cleanup).
- **Phase 6: Polish (`T012`–`T013`)**: Depends on completion of all user stories.

### User Story Dependencies

- **User Story 1 (P1)**: Independent after Foundational phase (`T003`).
- **User Story 2 (P2)**: Independent after Foundational phase (`T004`).
- **User Story 3 (P3)**: Integrates with `TournamentNewsFeedView` from US1 and `NewsFilterBottomSheet` from US2.

---

## Parallel Opportunities

- `T003` (`CreateNewsDialog` tournament selector) and `T004` (`NewsFilterBottomSheet`) modify different files and can be developed in parallel.
- `T005` (`TournamentNewsFeedView` cleanup) and `T006` (`OrganizerPanelContent` quick action) modify different files and can run in parallel.
- `T007` (organizer panel tests), `T009` (app shell tests), and `T011` (news feed tests) target separate test files and can run in parallel.

---

## Parallel Example: Foundational & User Story 1

```bash
# Parallel Foundational widgets:
Task T003: "Extend CreateNewsDialog in lib/presentation/news/widgets/create_news_dialog.dart"
Task T004: "Create NewsFilterBottomSheet in lib/presentation/news/widgets/news_filter_bottom_sheet.dart"

# Parallel User Story 1 implementation:
Task T005: "Clean up TournamentNewsFeedView in lib/presentation/news/tournament_news_feed_view.dart"
Task T006: "Add Publicar Noticia button in lib/presentation/panel/widgets/organizer_panel_content.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`T001`–`T002`).
2. Complete Phase 2: Foundational (`T003`–`T004`).
3. Complete Phase 3: User Story 1 (`T005`–`T007`).
4. **STOP and VALIDATE**: Confirm public news feed has no creation controls and organizer can publish news from `/panel`.

### Incremental Delivery

1. Setup + Foundational → Localization, `CreateNewsDialog` dropdown, and `NewsFilterBottomSheet` ready.
2. Add User Story 1 → Public feed cleaned up + `"Publicar Noticia"` in `/panel` operational (MVP!).
3. Add User Story 2 → 3-dots `more_vert` action in `AppShellScreen` `AppBar` wired to `NewsFilterBottomSheet`.
4. Add User Story 3 → Active tournament subtitle + removable `news_active_filter_chip` in `NewsTabView`.
5. Polish (`T012`–`T013`) → $320\times 640\text{ px}$ @ $130\%$ responsive verification and static analysis pass.
