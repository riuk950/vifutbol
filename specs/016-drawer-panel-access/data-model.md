# Data Model: Acceso a "Panel" en Navigation Drawer y Ocultación Temporal de "Explorar"

**Feature**: `016-drawer-panel-access`
**Date**: 2026-11-06

---

## 1. Entidades de Presentación y Navegación

### `AppShellSection` (Existente, Conservada)
```
┌──────────────────────────────────────────────┐
│ enum AppShellSection                         │
├──────────────────────────────────────────────┤
│ - matches   (Partidos por fecha)             │
│ - explore   (Standings / Llaves - OCULTO)    │
│ - news      (Feed de noticias)               │
│ - profile   (Perfil de usuario y roles)      │
└──────────────────────────────────────────────┘
```

### Mapeo de Pestañas Visuales en `AppShellScreen`
```
Índice Visual (NavigationBar)          Sección de Dominio (AppShellSection)
┌───────────────────────────┐          ┌──────────────────────────────────┐
│ 0: "Partidos"             │ ◄──────► │ AppShellSection.matches          │
├───────────────────────────┤          ├──────────────────────────────────┤
│ 1: "Noticias"             │ ◄──────► │ AppShellSection.news             │
├───────────────────────────┤          ├──────────────────────────────────┤
│ 2: "Perfil"               │ ◄──────► │ AppShellSection.profile          │
└───────────────────────────┘          └──────────────────────────────────┘
                                       (AppShellSection.explore: fallback → 0)
```

---

## 2. Matriz de Visibilidad de Destinos en `AppNavigationDrawer`

| Destino de Navegación | Clave de Test (`Key`) | Ruta | Ícono | Visibilidad por Rol |
| :--- | :--- | :--- | :--- | :--- |
| **Panel** *(Nuevo)* | `drawer_destination_panel` | `/panel` | `Icons.dashboard_outlined` | `Organizador`, `Entrenador`, `Árbitro`, `Jugador` (**Oculto para `Aficionado`**) |
| **Competiciones** | `drawer_destination_competitions` | `/competitions` | `Icons.emoji_events_outlined` | Todos los 5 roles |
| **Equipos** | `drawer_destination_teams` | `/teams` | `Icons.shield_outlined` | Todos los 5 roles |
| **Jugadores** | `drawer_destination_players` | `/players` | `Icons.groups_outlined` | Todos los 5 roles |
| **Sedes** | `drawer_destination_venues` | `/venues` | `Icons.stadium_outlined` | Todos los 5 roles |

---

## 3. Matriz de Autorización por Rol para Acceso a "Panel"

```
┌──────────────────────┬────────────────────────┬──────────────────────┐
│ UserRole             │ ¿Muestra Ítem Panel?   │ Acceso a Ruta /panel │
├──────────────────────┼────────────────────────┼──────────────────────┤
│ UserRole.organizer   │ SÍ                     │ AUTORIZADO           │
│ UserRole.coach       │ SÍ                     │ AUTORIZADO           │
│ UserRole.referee     │ SÍ                     │ AUTORIZADO           │
│ UserRole.player      │ SÍ                     │ AUTORIZADO           │
│ UserRole.fan         │ NO                     │ NO AUTORIZADO        │
└──────────────────────┴────────────────────────┴──────────────────────┘
```
