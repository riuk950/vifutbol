# Contracts: Navegación a Detalles de la Competición desde "Mis Competiciones" (HU 18.3)

**Feature**: `034-organizer-competition-navigation`  
**Date**: 2026-11-11  

---

## 1. Contrato de `OrganizerCompetitionsSection`

Ubicación: `lib/presentation/panel/widgets/organizer_competitions_section.dart`

```dart
/// Section in Organizer Panel listing the tournaments managed by the active organizer.
class OrganizerCompetitionsSection extends ConsumerStatefulWidget {
  const OrganizerCompetitionsSection({
    super.key,
    this.onCreateTournament,
    this.onEditTournament,
    this.onChangeStatus,
    this.onDeleteTournament,
    this.onTapTournament,
  });

  final VoidCallback? onCreateTournament;
  final ValueChanged<ChampionshipTournament>? onEditTournament;
  final ValueChanged<ChampionshipTournament>? onChangeStatus;
  final ValueChanged<ChampionshipTournament>? onDeleteTournament;
  final ValueChanged<ChampionshipTournament>? onTapTournament;
}
```

### Comportamiento de Toque en Tarjeta (`_handleTapTournament`)

1. Verifica ventana de debounce de 500 ms usando `_lastNavigationTap`:
   ```dart
   final now = DateTime.now();
   if (_lastNavigationTap != null &&
       now.difference(_lastNavigationTap!) < const Duration(milliseconds: 500)) {
     return;
   }
   _lastNavigationTap = now;
   ```
2. Sincroniza el estado global de torneo seleccionado:
   ```dart
   ref.read(tournamentsControllerProvider.notifier).selectTournament(tournament.id);
   ```
3. Ejecuta navegación:
   ```dart
   if (widget.onTapTournament != null) {
     widget.onTapTournament!(tournament);
   } else {
     Navigator.of(context).pushNamed('/competitions/${tournament.id}');
   }
   ```

---

## 2. Contrato de Tarjeta en `_buildTournamentCard`

```dart
return KickPulseCard(
  key: Key('organizer_competition_card_${tournament.id}'),
  onTap: () => _handleTapTournament(context, tournament),
  child: Padding(
    ...
  ),
);
```

- **Aislamiento de Menú**: `PopupMenuButton<String>(key: Key('organizer_competition_menu_button_${tournament.id}'), ...)` reside como hijo dentro de la tarjeta; su toque abre el menú emergente y NO propaga hacia `KickPulseCard.onTap`.
- **Retroalimentación Visual**: `KickPulseCard` usa `InkWell` con `borderRadius: KickPulseRadiiSpacing.cardBorderRadius` (16px).

---

## 3. Contrato de Ruta y Pantalla Destino

- **Ruta nominal**: `/competitions/:id` definida en `AppRouter` (`lib/presentation/navigation/app_router.dart`).
- **Pantalla destino**: `CompetitionDetailScreen(tournamentId: id)`.
- **Regreso**: `BackButton` en `AppBar` de `CompetitionDetailScreen` ejecuta `Navigator.pop()` regresando al Panel de Organización sin alterar el historial.
