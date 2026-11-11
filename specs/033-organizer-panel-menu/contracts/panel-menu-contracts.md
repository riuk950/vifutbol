# Contracts: Reorganización del Panel de Organización: Menú en AppBar y Depuración de Acciones Rápidas (HU 18.2)

**Feature**: `033-organizer-panel-menu`  
**Date**: 2026-11-11  

---

## 1. Contratos de Componentes Visuales

### `OrganizerPanelAppBarMenu`

Componente de menú desplegable que encapsula las opciones administrativas globales en el `AppBar` de `PanelScreen`.

```dart
/// AppBar action menu displaying global administrative options for organizers.
class OrganizerPanelAppBarMenu extends ConsumerWidget {
  const OrganizerPanelAppBarMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref);
}
```

#### Identificadores de Widget (`Key`):
- Botón del menú en AppBar: `Key('organizer_panel_appbar_menu')`
- Ítem "Publicar Noticia": `Key('organizer_menu_publish_news')`
- Ítem "Copia de Seguridad": `Key('organizer_menu_backup')`

---

## 2. Contrato de Integración en `PanelScreen`

```dart
class PanelScreen extends ConsumerWidget {
  ...
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final activeRole = ref.watch(activeUserRoleProvider);

    return Scaffold(
      key: const Key('panel_screen'),
      backgroundColor: KickPulseColors.canvasBackground,
      appBar: AppBar(
        leading: const BackButton(key: Key('panel_back_button')),
        title: Text(
          _appBarTitle(l10n, activeRole),
          key: const Key('panel_screen_title'),
        ),
        actions: [
          if (activeRole == UserRole.organizer)
            const OrganizerPanelAppBarMenu(),
        ],
      ),
      body: SafeArea(child: _buildRoleContent(activeRole)),
    );
  }
}
```

---

## 3. Contrato de Limpieza en `OrganizerPanelContent`

En `OrganizerPanelContent` (`lib/presentation/panel/widgets/organizer_panel_content.dart`):

1. **Eliminar**:
   - `_isGeneratingFixture`
   - `_onGenerateFixture(...)`
   - `_onScheduleMatches(...)`
   - `_onPublishNews(...)` (se traslada a `OrganizerPanelAppBarMenu`)
   - `_onBackup(...)` (se traslada a `OrganizerPanelAppBarMenu`)
   - Texto de cabecera `l10n.organizerQuickActionsTitle`
   - Tarjeta `KickPulseCard` que alojaba los 4 botones:
     - `organizer_action_generate_fixture`
     - `organizer_action_schedule_matches`
     - `organizer_action_publish_news`
     - `organizer_action_backup`
2. **Estructura resultante**:
   ```dart
   Column(
     crossAxisAlignment: CrossAxisAlignment.stretch,
     children: [
       // Resumen de Métricas
       Text(l10n.organizerSummaryTitle, style: KickPulseTypography.sectionHeader),
       const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
       Row(children: [ ... ]), // 3 tarjetas de métricas
       const SizedBox(height: KickPulseRadiiSpacing.spaceLg),
       // Sección Mis Competiciones
       OrganizerCompetitionsSection( ... ),
     ],
   )
   ```

---

## 4. Claves de Localización (`l10n`)

Se reutilizan las cadenas existentes en `app_es.arb` para garantizar coherencia sin alterar textos aprobados:

| Clave | Texto en Español | Uso |
|---|---|---|
| `organizerActionPublishNews` | "Publicar Noticia" | Etiqueta del ítem de menú de noticias |
| `organizerActionBackup` | "Copia de Seguridad" | Etiqueta del ítem de menú de respaldo |
| `newsPublishedSuccess` | "Noticia publicada correctamente" | SnackBar de confirmación de noticia |
