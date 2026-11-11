# Quickstart Validation Guide: Esquema `vifutboldev` en DEV (HU 17.2)

**Feature**: `036-supabase-vifutboldev-schema`  
**Branch**: `develop`  

---

## 1. Validación en Servidor Oracle Cloud DEV (PostgreSQL + PostgREST + Kong)

1. Aplicar los 4 scripts SQL de `supabase/migrations/` en orden contra `supabase-db` (vía SSH `ubuntu@157.137.227.250` con `sudo docker exec -i supabase-db psql -U supabase_admin -d postgres`).
2. Re-ejecutar los 4 scripts por segunda vez consecutiva verificando **0 errores** (idempotencia).
3. Verificar conteo de tablas, RLS e índices en `vifutboldev` y aislamiento de `public`:
   ```sql
   SELECT COUNT(*) AS table_count
   FROM information_schema.tables
   WHERE table_schema = 'vifutboldev';
   -- Esperado: 18

   SELECT COUNT(*) AS missing_rls
   FROM pg_tables
   WHERE schemaname = 'vifutboldev' AND rowsecurity = false;
   -- Esperado: 0
   ```
4. Verificar que `PGRST_DB_SCHEMAS` incluye `vifutboldev` y `supabase-rest` está saludable.
5. Verificar lectura pública vía REST con `Accept-Profile: vifutboldev` y la `anon key` de `.env.dev`:
   - `GET https://supabase.artbusinesstechnology.com/rest/v1/tournaments?select=id,name&limit=5` → **`HTTP 200 OK`**.
6. Verificar ciclo real de escritura + lectura + limpieza con sesión `authenticated` (GoTrue):
   - Crear/iniciar sesión con usuario de prueba en GoTrue -> insertar comunicado/registro de prueba en `vifutboldev` con `Content-Profile: vifutboldev` -> consultar por REST -> eliminar el registro de prueba y el usuario temporal tras validar.

---

## 2. Validación en Repositorio Flutter

```bash
dart format --output=none --set-exit-if-changed lib/ test/
flutter analyze
flutter test test/unit/application/supabase_providers_test.dart \
  test/unit/application/check_supabase_backend_health_use_case_test.dart \
  test/unit/application/supabase_bootstrap_resilience_test.dart
```

Resultado esperado: **0 errores de formato**, **0 issues en `flutter analyze`** y **100% de pruebas aprobadas**.
