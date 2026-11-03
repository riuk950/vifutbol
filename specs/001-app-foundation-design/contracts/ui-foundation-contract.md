# UI & Architecture Contracts: HU 1.1 — Fundación, Entornos, Localización y Sistema de Diseño

**Feature**: `001-app-foundation-design`  
**Date**: 2026-11-03

---

## 1. Entrypoints & Environment Contract (`FR-001`)

| Entrypoint File | Flavor / Mode | `AppEnvironment` | Storage Namespace | Environment Badge |
|-----------------|---------------|------------------|-------------------|-------------------|
| `lib/env/main.dev.dart` | `dev` | `AppEnvironment.development` | `vifutbol_dev` | Visible (`DEV`) |
| `lib/env/main.prod.dart` | `prod` | `AppEnvironment.production` | `vifutbol_prod` | Hidden |
| `lib/main.dart` | default (dev fallback) | `AppEnvironment.development` | `vifutbol_dev` | Visible (`DEV`) |

---

## 2. Design System Token Contract (`DESIGN.md` — `FR-003`, `FR-004`, `FR-005`)

### 2.1 Color Tokens (`KickPulseColors`)
| Token Identifier | Hex Value | Usage |
|------------------|-----------|-------|
| `canvasBackground` | `#080B11` | Scaffold / root background |
| `surfaceBase` | `#0E1422` | Cards, AppBar, BottomNavigationBar, Lists |
| `surfaceElevated` | `#161F33` | Chips, Popovers, Modals |
| `surfaceSubtle` | `#1D2840` | Badge backgrounds, active hover/selection |
| `borderSubtle` | `#1F2C44` | 1px card and list borders |
| `borderStrong` | `#2D3F60` | Emphasized or focused container borders |
| `accentPrimary` | `#22C55E` | Pitch Green primary CTA, active indicators |
| `accentLive` | `#EF4444` | Live match pulse, danger, error states |
| `accentWarning` | `#F59E0B` | Offline warning, yellow cards |
| `accentElectric` | `#38BDF8` | Analytics, informational highlights |
| `textPrimary` | `#F8FAFC` | Primary headings and body text |
| `textSecondary` | `#94A3B8` | Subtitles and supporting metadata |
| `textTertiary` | `#64748B` | Captions, disabled or muted labels |

### 2.2 Component Geometry & Ergonomics
- **Card Border Radius**: `16.0` (`16px`)
- **Chip Border Radius**: `12.0` (`12px`)
- **Badge Border Radius**: `9999.0` (Full pill)
- **Spacing Scale**: `spaceXs: 4.0`, `spaceSm: 8.0`, `spaceMd: 16.0`, `spaceLg: 24.0`, `spaceXl: 32.0`
- **Minimum Touch Target**: `44.0 x 44.0` logical pixels on all interactive widgets (`KickPulseButton`, `KickPulseChip`, navigation items, retry buttons).
- **Tabular Numerals**: All typography styles (`statMetric`, scores, timers, standings counters) MUST include `FontFeature.tabularFigures()` and `FontFeature.liningFigures()`.

---

## 3. App Shell & Reactive Connectivity Banner Contract (`FR-006`, `FR-007`, `FR-008`)

1. **Orientation Lock**: Portrait-only (`DeviceOrientation.portraitUp`).
2. **Top Connectivity Banner**:
   - **Connected (Steady)**: Height `0`, not rendered in accessibility tree.
   - **Offline (`ConnectivityBannerVisibility.offline`)**: Persistent banner at top of shell body with semantic warning/error styling (`#F59E0B` / `#EF4444`) and Spanish localized text (`"Modo sin conexión: mostrando datos guardados en el dispositivo"`).
   - **Restored (`ConnectivityBannerVisibility.restored`)**: Green banner (`#22C55E`) with Spanish localized text (`"Conexión restaurada"`) displayed for 3 seconds, then automatically dismissed.
3. **Bottom Navigation Bar**:
   - 4 destinations with localized Spanish labels:
     1. `Jornada` (`AppShellSection.matchday`)
     2. `Posiciones` (`AppShellSection.standings`)
     3. `Sedes` (`AppShellSection.venues`)
     4. `Perfil` (`AppShellSection.profile`)
   - Preserves active tab index and child scroll/state across tab switches and app background/foreground lifecycle transitions.
4. **Standardized 5 UI State Views (`KickPulseStateView`)**:
   - Supports rendering and interactive verification of `Loading`, `Content`, `Empty`, `Error` (with single-flight retry button), and `Success` states in Spanish.
