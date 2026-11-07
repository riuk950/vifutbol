# Implementation Plan: Pestaña de Información y Reglas Oficiales de la Competición (HU 13.3)

**Branch**: `020-competition-detail-rules` | **Date**: 2026-11-06 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/020-competition-detail-rules/spec.md`

---

## Summary

Implementar la experiencia completa de la 3ª pestaña "Información" dentro de `CompetitionDetailScreen` (`/competitions/:id`):
1. **Reglamento y Normativa Oficial**: Integrar `TournamentRulesSummaryCard` en modo estrictamente de solo lectura, presentando el sistema de puntuación oficial (Pts por Victoria, Empate y Derrota), parámetros de partido (duración de mitades), límites de plantilla deportiva y umbral disciplinario de tarjetas amarillas.
2. **Criterios de Desempate y Periodo Oficial**: Detallar la jerarquía ordenada de criterios de desempate (`tiebreakerOrder`) y el rango de vigencia oficial del campeonato (`startDate` — `endDate`).
3. **Auditoría de Reglas Segregada por Rol**: Condicionar la visibilidad del historial de auditoría de reglas críticas (`auditTrail`) para que sea visible exclusivamente para usuarios con rol `UserRole.organizer` cuando existan registros (`auditTrail.isNotEmpty`), manteniéndola oculta para el resto de los roles.
4. **Sede Principal de la Competición**: Desplegar una tarjeta informativa (`KickPulseCard`) con el nombre, dirección y cantidad de canchas de la sede deportiva principal del torneo, resuelta a partir de `venuesControllerProvider` y los partidos asignados.
5. **Resiliencia & Accesibilidad**: Estados de carga y no encontrado amigables con `KickPulseStateView`, garantizando cero desbordamientos visuales (`RenderFlex` overflow) en pantallas compactas de $320 \times 640\text{ px}$ con $130\%$ de escalado tipográfico.

---

## Technical Context

**Language/Version**: Dart 3.7+ / Flutter 3.29+  
**Primary Dependencies**: `flutter_riverpod`, `flutter_localizations`, `intl`  
**Storage**: Offline-first con `LocalStorageRepository` (memoria/persistencia desacoplada)  
**Testing**: `flutter_test` (unit and widget testing)  
**Target Platform**: Mobile-first (iOS / Android)  
**Project Type**: Mobile Application (`vifutbol`)  
**Performance Goals**: Renderizado inmediato de la pestaña en $<200\text{ ms}$; cero llamadas de red redundantes.  
**Constraints**: Zero `RenderFlex` overflow en $320 \times 640\text{ px}$ con $130\%$ de escalado de texto; textos exclusivamente en español mediante `app_es.arb`; consulta exclusivamente de solo lectura en esta vista.  
**Scale/Scope**: 1 componente de pestaña actualizado (`CompetitionInfoTabView`), 1 componente de reglas ajustado (`TournamentRulesSummaryCard`), 1 archivo de localización (`app_es.arb`), 2 suites de pruebas de widgets.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| **I. La Spec Manda** | Basado estrictamente en especificación aprobada sin cambios no documentados | **PASS** | `spec.md` detallado y clarificado (3 decisiones formalizadas). |
| **II. Integridad de Datos** | Normativa, scoring y trazabilidad resueltos desde el agregado de dominio | **PASS** | `ChampionshipTournament.rules` y `auditTrail` inmutables. |
| **III. Pruebas Automatizadas** | Suite de tests aislados de widgets para cada sección y rol | **PASS** | Planificada suite dedicada `competition_info_tab_view_test.dart` y validaciones en pantalla completa. |
| **IV. Arquitectura Limpia** | Separación estricta entre presentación, aplicación y dominio | **PASS** | `CompetitionInfoTabView` como `ConsumerWidget` consumiendo providers sin lógica de negocio directa. |
| **V. Segregación de Roles & UI** | Fidelidad a tokens KickPulse (`DESIGN.md`) y control de acceso | **PASS** | `activeUserRoleProvider` controla la visibilidad de la auditoría. |
| **VI. Idioma y Nomenclatura** | Código en inglés, interfaz de usuario en español vía `l10n` | **PASS** | Nuevas claves agregadas a `app_es.arb`. |
| **VII. Resiliencia Móvil** | Cero desbordamientos a $320 \times 640\text{ px}$ @ $130\%$ font scale | **PASS** | `SingleChildScrollView` vertical con padding KickPulse para resiliencia en pantallas pequeñas. |

---

## Project Structure

### Documentation (this feature)

```text
specs/020-competition-detail-rules/
├── plan.md                                       # This file
├── research.md                                   # Phase 0 output
├── data-model.md                                 # Phase 1 output
├── quickstart.md                                 # Phase 1 output
├── contracts/                                    # Phase 1 output
│   └── ui-competition-rules-contracts.md
├── checklists/
│   └── requirements.md
└── tasks.md                                      # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── l10n/
│   ├── app_es.arb                                # Spanish localization keys
│   └── app_localizations.dart                    # Generated localizations
└── presentation/
    └── tournaments/
        ├── competition_detail_screen.dart        # Host screen with 3 tabs
        └── widgets/
            ├── competition_info_tab_view.dart    # Target implementation widget
            └── tournament_rules_summary_card.dart# Existing rules summary card (role guard)

test/
└── presentation/
    ├── directories_responsive_widget_test.dart   # Viewport and text scaling test
    └── tournaments/
        ├── competition_detail_screen_test.dart   # Full screen integration test
        └── competition_info_tab_view_test.dart   # Dedicated info tab widget tests
```

**Structure Decision**: Single Flutter mobile application architecture. The feature enhances `lib/presentation/tournaments/widgets/competition_info_tab_view.dart` into a `ConsumerWidget` embedding `TournamentRulesSummaryCard` and a primary venue card, while ensuring `TournamentRulesSummaryCard` enforces the role guard on `auditTrail`.

---

## Complexity Tracking

> No constitution violations detected. Standard layered architecture preserved without introducing new external packages or bypasses.
