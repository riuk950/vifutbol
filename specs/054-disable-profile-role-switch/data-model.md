# Data Model: Deshabilitar Cambio de Rol Activo en el Perfil (HU 24.1)

**Feature**: `054-disable-profile-role-switch`  
**Date**: 2026-11-25

Esta funcionalidad **no introduce nuevas entidades ni modifica esquemas de persistencia local (Hive) o remota (Supabase)**. Opera exclusivamente como una proyección de solo lectura de las entidades de autenticación y entorno existentes en la pantalla de Perfil.

## Existing Entities Referenced (Read-Only in Profile)

### 1. `UserAccount` (`lib/domain/entities/user_account.dart`)
- `id` (`String`): Identificador único inmutable del usuario.
- `fullName` (`String`): Nombre visible en la tarjeta de identidad.
- `email` (`String`): Correo electrónico visible (oculto cuando `isGuestFan == true`).
- `activeRole` (`UserRole`): Rol activo vigente de la sesión. **Regla de validación en Perfil**: solo lectura; nunca se muta desde `ProfileTabView`.
- `authorizedRoles` (`Set<UserRole>`): Conjunto de roles autorizados de la cuenta. **Regla en Perfil**: no se expone como selector ni lista interactiva en `ProfileTabView` (solo se usa para visibilidad condicional existente de secciones como datos personales de jugador si corresponde).
- `isGuestFan` (`bool`): Indica si opera en modo visitante (`Aficionado`).
- `isProfileCompleteForActiveRole` (`bool`): Determina la insignia de completitud del perfil y el banner/botón de completar perfil.

### 2. `UserRole` (`lib/domain/entities/user_role.dart`)
Enumeración de los cinco roles oficiales del sistema:
- `organizer` (`Organizador`)
- `coach` (`Entrenador`)
- `referee` (`Árbitro`)
- `player` (`Jugador`)
- `fan` (`Aficionado`)

### 3. `AppEnvironment` (`lib/domain/entities/app_environment.dart`)
- `development` (`dev`)
- `production` (`prod`)
- **Regla de negocio (FR-002)**: `ProfileTabView` no debe ramificar ni habilitar capacidades de cambio de rol en función de `AppEnvironment`.

## State Transitions

- **Desde `ProfileTabView`**: Ninguna transición permitida sobre `UserAccount.activeRole`. El estado de rol activo es estrictamente inmutable ante cualquier evento de UI en Perfil (toques, reanudación de app, cambios de conectividad).
