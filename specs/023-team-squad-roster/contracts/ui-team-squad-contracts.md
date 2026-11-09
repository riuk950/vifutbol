# UI & Localization Contracts: Pestaña de Plantilla y Jugadores del Equipo (HU 14.3)

**Feature**: `023-team-squad-roster`  
**Date**: 2026-11-09

---

## 1. Widget Key Contracts (`Key`)

Para garantizar trazabilidad y pruebas deterministas de widgets, los componentes de la pestaña **"Plantilla"** (`TeamSquadTabView`) DEBEN exponer las siguientes claves (`Key`):

| Componente / Elemento | Key | Descripción |
|-----------------------|-----|-------------|
| Vista de Pestaña "Plantilla" | `PageStorageKey('team_squad_tab_view')` | Raíz con preservación de scroll dentro del `TabBarView` de `TeamDetailScreen`. |
| Estado Vacío Global de Plantilla | `Key('team_squad_empty_state')` | `KickPulseStateView` cuando el equipo no tiene ningún jugador inscrito (`team.players.isEmpty`). |
| Encabezado Bloque "Porteros" | `Key('team_squad_header_goalkeeper')` | Encabezado de la sección de porteros. |
| Encabezado Bloque "Defensas" | `Key('team_squad_header_defender')` | Encabezado de la sección de defensas. |
| Encabezado Bloque "Centrocampistas" | `Key('team_squad_header_midfielder')` | Encabezado de la sección de centrocampistas. |
| Encabezado Bloque "Delanteros" | `Key('team_squad_header_forward')` | Encabezado de la sección de delanteros. |
| Estado Vacío por Posición | `Key('team_squad_empty_${position.name}')` | Mensaje contextual cuando un bloque táctico específico no tiene jugadores inscritos. |
| Tarjeta de Jugador | `Key('team_squad_player_item_${player.id}')` | Tarjeta interactiva (`KickPulseCard`) de cada jugador inscrito ($\ge 48 \times 48\text{ dp}$). |
| Dorsal del Jugador | `Key('team_squad_player_shirt_${player.id}')` | Insignia tabular con el número de camiseta (`#${player.shirtNumber}`). |
| Badge de Posición del Jugador | `Key('team_squad_player_position_badge_${player.id}')` | `KickPulseBadge` con la posición táctica en español (*Portero*, *Defensa*, *Centrocampista*, *Delantero*). |
| Badge de Elegibilidad del Jugador | `Key('team_squad_player_eligibility_badge_${player.id}')` | `KickPulseBadge` que muestra **"Habilitado"** (`success`) o **"Suspendido"** (`live`). |

---

## 2. Contratos de Localización (`lib/l10n/app_es.arb`)

Todas las etiquetas visibles nuevas para la pestaña **"Plantilla"** DEBEN declararse en `lib/l10n/app_es.arb`:

| Clave `l10n` | Valor en Español (`app_es.arb`) | Uso |
|--------------|---------------------------------|-----|
| `teamSquadGoalkeepersSectionTitle` | `"Porteros"` | Encabezado del primer bloque táctico |
| `teamSquadDefendersSectionTitle` | `"Defensas"` | Encabezado del segundo bloque táctico |
| `teamSquadMidfieldersSectionTitle` | `"Centrocampistas"` | Encabezado del tercer bloque táctico |
| `teamSquadForwardsSectionTitle` | `"Delanteros"` | Encabezado del cuarto bloque táctico |
| `teamSquadPositionGoalkeeper` | `"Portero"` | Etiqueta de badge de posición para `PlayerPosition.goalkeeper` |
| `teamSquadPositionDefender` | `"Defensa"` | Etiqueta de badge de posición para `PlayerPosition.defender` |
| `teamSquadPositionMidfielder` | `"Centrocampista"` | Etiqueta de badge de posición para `PlayerPosition.midfielder` |
| `teamSquadPositionForward` | `"Delantero"` | Etiqueta de badge de posición para `PlayerPosition.forward` |
| `teamSquadPlayerStatusEligible` | `"Habilitado"` | Etiqueta del badge semántico para jugador habilitado (`KickPulseBadgeVariant.success`) |
| `teamSquadPlayerStatusSuspended` | `"Suspendido"` | Etiqueta del badge semántico para jugador suspendido (`KickPulseBadgeVariant.live`) |
| `teamSquadEmptyGlobalTitle` | `"Plantilla sin jugadores inscritos"` | Título del estado vacío global cuando `team.players` está vacío |
| `teamSquadEmptyGlobalMessage` | `"Este equipo aún no registra jugadores inscritos en su nómina oficial."` | Descripción del estado vacío global |
| `teamSquadEmptyPositionMessage` | `"Sin jugadores registrados en esta posición"` | Mensaje contextual cuando uno de los 4 bloques tácticos no tiene efectivos |

---

## 3. Contrato de Interacción y Accesibilidad

1. **Toque sobre Tarjeta de Jugador (`team_squad_player_item_${player.id}`)**:
   - Abre la hoja modal de perfil de rendimiento del jugador exhibiendo `PlayerPerformanceProfileCard` (`Key('player_performance_profile_card')`) con las métricas del jugador seleccionado y la lista completa de compañeros de plantilla (`allTournamentPlayers: roster.allProfiles`) para permitir alternar rápidamente entre futbolistas del equipo.
2. **Accesibilidad (`Semantics` y `Touch Target`)**:
   - Cada tarjeta garantiza una altura mínima de `48 dp` (`ConstrainedBox(constraints: BoxConstraints(minHeight: 48))`).
   - El nodo semántico anuncia: `"Dorsal {shirtNumber}, {fullName}, {positionLabel}, {eligibilityLabel}"`.
   - El dorsal se formatea con `FontFeature.tabularFigures()` para alineación numérica uniforme.
