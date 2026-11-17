# Quickstart & Validation Guide: Formulario de Datos Personales del Jugador (HU 21.1)

**Feature**: `046-player-personal-data-form`  
**References**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/046-player-personal-data-form/spec.md) | [data-model.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/046-player-personal-data-form/data-model.md) | [player_personal_data_contract.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/046-player-personal-data-form/contracts/player_personal_data_contract.md)

## 1. Regeneración de Localizaciones

```bash
flutter gen-l10n
```

## 2. Verificación Estática

```bash
flutter analyze
```

**Expected outcome**: `No issues found!`

## 3. Suite de Pruebas Automatizadas

### Pruebas Unitarias (Dominio, Edad, Nombres, Catálogo Colombia y Posiciones)
```bash
flutter test \
  test/unit/domain/player_personal_data_utils_test.dart \
  test/unit/domain/colombia_location_catalog_test.dart \
  test/unit/domain/detailed_football_position_test.dart \
  test/unit/domain/user_account_role_profile_test.dart
```

### Pruebas de Infraestructura (Local & Supabase Auth Repository)
```bash
flutter test \
  test/unit/infrastructure/local_auth_repository_test.dart \
  test/unit/infrastructure/supabase_auth_repository_test.dart
```

### Pruebas de Widget y Responsividad (Formulario, Cascada, Multi-Selección, Perfil)
```bash
flutter test \
  test/presentation/shell/player_personal_data_screen_test.dart \
  test/presentation/shell/profile_tab_completeness_test.dart
```

## 4. Validación Manual / En Dispositivo

1. Iniciar sesión con una cuenta con rol `player` cuyo perfil esté incompleto.
2. En la pestaña **Perfil**, verificar que aparecen el badge `"Perfil incompleto"`, el botón `"Completar mi perfil"` y la tarjeta `"Datos Personales"`.
3. Pulsar cualquiera de los dos accesos -> se abre la pantalla completa **Datos Personales**.
4. Probar:
   - Seleccionar **Fecha de nacimiento** (ej. una fecha futura en el mes actual de hace 25 años) -> verificar que **Edad** muestra el valor exacto en solo lectura sin permitir edición.
   - Abrir **Departamento**, buscar `"Antioquia"` -> abrir **Municipio**, buscar `"Medellin"` -> seleccionar `"Medellín"` -> cambiar **Departamento** a `"Cundinamarca"` -> verificar que **Municipio** se limpia automáticamente.
   - Intentar guardar sin posiciones -> verificar mensaje de error exigiendo al menos una posición.
   - Seleccionar múltiples posiciones (ej. `LD` y `CAD`), completar todos los campos obligatorios y guardar -> verificar retorno a **Perfil**, cambio inmediato del badge a `"Perfil completo"` y actualización del nombre completo concatenado sin espacios dobles.
   - Volver a abrir `"Datos Personales"` -> verificar que todos los valores guardados aparecen precargados.
5. Verificar en Supabase DEV (`vifutboldev.players`) que las nuevas columnas (`first_name`, `second_name`, `first_surname`, `second_surname`, `sex`, `birth_date`, `blood_type`, `department`, `municipality`, `secondary_positions`, `position`) contienen los valores persistidos y que la vinculación por `document_id` funciona sin duplicar registros.
