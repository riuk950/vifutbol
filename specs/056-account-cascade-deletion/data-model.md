# Data Model: Eliminación de Cuenta con Borrado en Cascada (HU 24.3)

**Feature**: `056-account-cascade-deletion`  
**Date**: 2026-11-25

## Cloud Cascade Matrix (`vifutboldev` + `storage` + `auth`)

| Tabla / Recurso | Relación con Usuario | Acción al Eliminar Cuenta | Justificación |
|---|---|---|---|
| `auth.users` | `id = auth.uid()` | **DELETE** | Elimina credenciales e identidad de autenticación. |
| `vifutboldev.user_accounts` | `auth_user_id = auth.uid()` | **DELETE** | Elimina la cuenta principal y dispara FKs en cascada. |
| `vifutboldev.coach_profiles` | `user_account_id` (`ON DELETE CASCADE`) | **DELETE** | Datos personales del rol Entrenador. |
| `vifutboldev.organizer_profiles` | `user_account_id` (`ON DELETE CASCADE`) | **DELETE** | Datos personales del rol Organizador. |
| `vifutboldev.fan_profiles` | `user_account_id` (`ON DELETE CASCADE`) | **DELETE** | Datos personales del rol Aficionado. |
| `vifutboldev.fan_favorite_teams` | `user_id` (`ON DELETE CASCADE`) | **DELETE** | Preferencias personales del usuario. |
| `vifutboldev.team_join_requests` | `coach_account_id` / `player_account_id` (`ON DELETE CASCADE`) | **DELETE** | Solicitudes pendientes o históricas del usuario. |
| `vifutboldev.players` (agente libre) | `user_account_id = id AND tournament_id IS NULL` | **DELETE** | Ficha de jugador sin vínculo a ningún torneo. |
| `vifutboldev.players` (en torneos) | `user_account_id = id AND tournament_id IS NOT NULL` | **UPDATE (`SET NULL` PII)** | Desvincula `user_account_id`, `phone`, `photo_url`, `document_front_url`, `document_back_url` conservando estadísticas/eventos del torneo. |
| `vifutboldev.match_referees` | `user_account_id = id` | **UPDATE (`SET NULL` PII)** | Desvincula `user_account_id` y `phone` conservando historial de arbitraje en actas. |
| `vifutboldev.sports_venues`, `tournaments`, `tournament_news`, `teams`, `digital_match_reports` | `organizer_id` / `author_user_id` / `coach_id` / `closed_by_user_id` (`ON DELETE SET NULL`) | **SET NULL** (automático) | Preserva campeonatos, equipos, sedes y actas oficiales compartidas. |
| `storage.objects` (`player-avatars`, `player-documents`) | `owner = auth.uid()` o `name LIKE auth.uid() || '/%'` | **DELETE** | Elimina fotos de perfil e imágenes de cédula en Storage. |

## Local Storage Cascade Matrix (Device)

| Recurso Local | Acción tras Éxito Remoto (o Modo Local) |
|---|---|
| `LocalStorageRepository.clearNamespace()` | Limpia completamente la caja Hive (o fallback en memoria) del entorno activo: `auth_session`, `auth_accounts`, `auth_passwords`, `sync_outbox_items_v1`, y todos los cachés de repositorios locales. |
| Archivos locales de imagen (`photoUrl`, `documentFrontUrl`, `documentBackUrl` cuando son rutas locales existentes) | Eliminación best-effort (`File.delete()`) si existen en disco. |
| `AuthFlowState` en memoria (`AuthController`) | Transición a `AuthFlowState(status: AuthStatus.unauthenticated, session: null, isSubmitting: false, lastFailure: null)`. |
