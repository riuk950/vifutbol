import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/app_shell_controller.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/domain/entities/app_shell_section.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/alerts/widgets/fan_alerts_bell_action.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/shell/tabs/matchday_tab_view.dart';
import 'package:vifutbol/presentation/shell/tabs/profile_tab_view.dart';
import 'package:vifutbol/presentation/shell/tabs/standings_tab_view.dart';
import 'package:vifutbol/presentation/shell/tabs/venues_tab_view.dart';
import 'package:vifutbol/presentation/shell/widgets/connectivity_banner.dart';

/// Root App Shell container with 4-tab bottom navigation, environment badge,
/// and reactive connectivity banner.
class AppShellScreen extends ConsumerStatefulWidget {
  final AppShellSection? initialSection;

  const AppShellScreen({super.key, this.initialSection});

  @override
  ConsumerState<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends ConsumerState<AppShellScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initialSection != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(appShellControllerProvider.notifier)
            .setSection(widget.initialSection!);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Preserves current shell navigation and screen context across background/foreground transitions
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    final shellState = ref.watch(appShellControllerProvider);
    final envConfig = ref.watch(environmentConfigProvider);
    final l10n = AppLocalizations.of(context);

    final currentIndex = AppShellSection.values.indexOf(
      shellState.activeSection,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              child: Text(
                l10n.appTitle,
                style: KickPulseTypography.screenTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (envConfig.showEnvironmentBanner) ...[
              const SizedBox(width: 8.0),
              KickPulseBadge(
                label: l10n.envDevBadge,
                variant: KickPulseBadgeVariant.dev,
              ),
            ],
          ],
        ),
        actions: const [FanAlertsBellAction(userId: 'user-active-current')],
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: const [
                MatchdayTabView(),
                StandingsTabView(),
                VenuesTabView(),
                ProfileTabView(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref
              .read(appShellControllerProvider.notifier)
              .setSectionByIndex(index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.sports_soccer_outlined),
            selectedIcon: const Icon(
              Icons.sports_soccer,
              color: KickPulseColors.accentPrimary,
            ),
            label: l10n.tabMatchday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.format_list_numbered_outlined),
            selectedIcon: const Icon(
              Icons.format_list_numbered,
              color: KickPulseColors.accentPrimary,
            ),
            label: l10n.tabStandings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.location_on_outlined),
            selectedIcon: const Icon(
              Icons.location_on,
              color: KickPulseColors.accentPrimary,
            ),
            label: l10n.tabVenues,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(
              Icons.person,
              color: KickPulseColors.accentPrimary,
            ),
            label: l10n.tabProfile,
          ),
        ],
      ),
    );
  }
}
