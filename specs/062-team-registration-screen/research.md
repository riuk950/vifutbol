# Investigación Técnica (Phase 0): Nueva Página de Registro Detallado de Equipo (HU 27.2)

**Funcionalidad**: `specs/062-team-registration-screen`  
**Fecha**: 2026-11-26

## Decisiones Técnicas Consolidadas

### 1. Reutilización de Columnas Existentes en `vifutboldev.teams`
- **Decisión**: Conservar las columnas existentes `primary_color_hex bigint`, `secondary_color_hex bigint`, `normalized_name text UNIQUE` y `short_code text CHECK (2..4)` en `vifutboldev.teams`, y agregar únicamente `delegate_name text` y `founded_date date` (ambas nulables) mediante una migración SQL idempotente (`202611260002_teams_delegate_and_founded_date.sql`).
- **Justificación**: `primary_color_hex` y `secondary_color_hex` ya existen en BD y en el repositorio híbrido; añadir solo las dos columnas nuevas mantiene 100% compatibilidad con equipos existentes sin migraciones destructivas.
- **Alternativas consideradas**:
  - Hacer `delegate_name` y `founded_date` `NOT NULL` en BD: descartado porque rompería los registros históricos de equipos ya creados antes de HU 27.2.

### 2. Reemplazo del Diálogo Modal por Página Dedicada (`/teams/create`)
- **Decisión**: Crear `CreateTeamScreen` en `lib/presentation/teams/create_team_screen.dart`, registrar la ruta `/teams/create` en `AppRouter` y actualizar los puntos de entrada (`CoachPanelContent` y `TeamsDirectoryScreen`) para navegar mediante `Navigator.of(context).pushNamed('/teams/create')`.
- **Justificación**: Cumple directamente el objetivo principal de la HU 27.2 (scroll cómodo, teclado sin desbordamientos, vista previa en vivo, confirmación `PopScope` de cambios sin guardar) y evita saturar un `AlertDialog`.
- **Alternativas consideradas**:
  - Mantener `CreateTeamDialog` ampliado con scroll: rechazado explícitamente por la HU 27.2.

### 3. Selector de Colores Distintivos (Paleta Curada con Primario ≠ Secundario)
- **Decisión**: Proveer una paleta curada de 12 colores deportivos contrastados (representados como enteros ARGB `0xFFRRGGBB` compatibles con `primaryColorHex`/`secondaryColorHex` existentes), con valores iniciales contrastados (`0xFF00E676` verde eléctrico y `0xFF0A0E17` azul medianoche), validando que `primaryColorHex != secondaryColorHex` tanto en la UI como en `ManageTeamsEligibilityUseCase`.
- **Justificación**: Cumple la clarificación Q1 (paleta curada, primario ≠ secundario), se integra sin conversiones con `KickPulseTeamCrest` y `TeamInfoTabView`, y actualiza la tarjeta de vista previa en vivo instantáneamente.
- **Alternativas consideradas**:
  - Picker libre HSV / texto hexadecimal manual: descartado en Q1 por complejidad innecesaria en móvil.

### 4. Auto-Sugerencia de Código Corto y Campo Delegado
- **Decisión**:
  - `shortCode`: al escribir el nombre del equipo, si el usuario no ha editado manualmente el campo de sigla, se auto-sugiere una sigla de 2–4 letras en mayúsculas (p. ej., iniciales de palabras o primeras 3 letras alfanuméricas), manteniéndola siempre editable.
  - `delegateName`: inicia siempre vacío (per Q2) y exige al menos 1 carácter no vacío tras `trim()`.
  - `foundedDate`: obligatorio, seleccionado con `showDatePicker` localizado en español (`locale: const Locale('es')`, `lastDate: DateTime.now()`), validado también en dominio contra fechas futuras.
- **Justificación**: Cumple literalmente `FR-003`, `FR-004` (Q2) y `FR-005`, minimizando fricción de captura.

### 5. Persistencia Offline-First y Compatibilidad con `TeamsController`
- **Decisión**: Extender `TournamentTeam` y `TeamDirectoryItem` con `String? delegateName` y `DateTime? foundedDate`, extender `TeamsController.createTeam(...)` con parámetros opcionales `delegateName`, `foundedDate`, `primaryColorHex` y `secondaryColorHex`, y propagar los campos a través de `LocalTeamsRepository` (Hive) y `HybridTeamsRepository` (Supabase + cola de sincronización).
- **Justificación**: Preserva compatibilidad total con las pruebas y llamadores existentes mientras habilita persistencia local inmediata y sincronización automática con Supabase.

### 6. Visualización en Ficha del Equipo (`TeamInfoTabView`)
- **Decisión**: Agregar filas de **Delegado** y **Fecha de creación** (formateada en español `dd/MM/yyyy` o texto legible) en `_buildClubProfileCard` de `TeamInfoTabView`, mostrando `"No registrado"` / `"No registrada"` para equipos heredados sin esos datos, junto a las muestras de colores primario y secundario ya existentes.
- **Justificación**: Reutiliza la estructura visual existente de `TeamInfoTabView` sin romper ninguna prueba ni diseño previo.
