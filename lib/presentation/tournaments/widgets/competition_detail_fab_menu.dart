import 'package:material_ui/material_ui.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

/// Expandable speed-dial FAB menu for competition management actions
/// ("Generar Fixture" and "Agregar Equipos") adhering to KickPulse tokens.
class CompetitionDetailFabMenu extends StatefulWidget {
  final bool showGenerateFixture;
  final VoidCallback onGenerateFixture;
  final VoidCallback onAddTeams;

  const CompetitionDetailFabMenu({
    super.key,
    required this.showGenerateFixture,
    required this.onGenerateFixture,
    required this.onAddTeams,
  });

  @override
  State<CompetitionDetailFabMenu> createState() =>
      _CompetitionDetailFabMenuState();
}

class _CompetitionDetailFabMenuState extends State<CompetitionDetailFabMenu> {
  static const Duration _animationDuration = Duration(milliseconds: 120);

  bool _isExpanded = false;

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _handleAction(VoidCallback callback) {
    setState(() {
      _isExpanded = false;
    });
    callback();
  }

  Widget _buildMenuOption({
    required Key key,
    required String heroTag,
    required IconData icon,
    required String label,
    required Color accentColor,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Material(
            color: KickPulseColors.surfaceElevated,
            elevation: 4.0,
            borderRadius: BorderRadius.circular(
              KickPulseRadiiSpacing.chipRadius,
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(
                KickPulseRadiiSpacing.chipRadius,
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 220.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    KickPulseRadiiSpacing.chipRadius,
                  ),
                  border: Border.all(
                    color: KickPulseColors.borderStrong,
                    width: 1.0,
                  ),
                ),
                child: Text(
                  label,
                  style: KickPulseTypography.captionMeta.copyWith(
                    color: KickPulseColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10.0),
          FloatingActionButton.small(
            key: key,
            heroTag: heroTag,
            backgroundColor: accentColor,
            foregroundColor: KickPulseColors.surfaceBase,
            tooltip: label,
            onPressed: onPressed,
            child: Icon(icon, size: 20.0),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isExpanded)
          TweenAnimationBuilder<double>(
            key: const ValueKey('competition_fab_options_expanded'),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: _animationDuration,
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0.0, (1.0 - value) * 12.0),
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.showGenerateFixture)
                  _buildMenuOption(
                    key: const Key('competition_detail_fab_generate_fixture'),
                    heroTag: 'fab_action_generate_fixture',
                    icon: Icons.alt_route,
                    label: l10n.competitionFabGenerateFixtureLabel,
                    accentColor: KickPulseColors.accentElectric,
                    onPressed: () => _handleAction(widget.onGenerateFixture),
                  ),
                _buildMenuOption(
                  key: const Key('competition_detail_fab_add_team'),
                  heroTag: 'fab_action_add_team',
                  icon: Icons.group_add_outlined,
                  label: l10n.competitionFabAddTeamsLabel,
                  accentColor: KickPulseColors.accentPrimary,
                  onPressed: () => _handleAction(widget.onAddTeams),
                ),
              ],
            ),
          ),
        FloatingActionButton(
          key: const Key('competition_detail_fab_menu'),
          heroTag: 'fab_competition_detail_menu',
          backgroundColor: _isExpanded
              ? KickPulseColors.surfaceElevated
              : KickPulseColors.accentPrimary,
          foregroundColor: _isExpanded
              ? KickPulseColors.textPrimary
              : KickPulseColors.surfaceBase,
          tooltip: l10n.competitionFabMenuTooltip,
          onPressed: _toggleMenu,
          child: AnimatedRotation(
            duration: _animationDuration,
            turns: _isExpanded ? 0.125 : 0.0,
            child: const Icon(Icons.add, size: 24.0),
          ),
        ),
      ],
    );
  }
}
