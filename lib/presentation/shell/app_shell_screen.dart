import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/app_shell_controller.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/sync_bootstrap_provider.dart';
import 'package:vifutbol/domain/entities/app_shell_section.dart';
import 'package:vifutbol/domain/services/colombia_time_utils.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/alerts/widgets/fan_alerts_bell_action.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/news/widgets/news_filter_bottom_sheet.dart';
import 'package:vifutbol/presentation/shell/tabs/matchday_tab_view.dart';
import 'package:vifutbol/presentation/shell/tabs/news_tab_view.dart';
import 'package:vifutbol/presentation/shell/tabs/profile_tab_view.dart';
import 'package:vifutbol/presentation/shell/widgets/app_navigation_drawer.dart';
import 'package:vifutbol/presentation/shell/widgets/connectivity_banner.dart';
import 'package:vifutbol/presentation/sync/sync_status_app_bar_action.dart';

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

  Future<void> _onPickCalendarDate(BuildContext context) async {
    final feedState = ref.read(dailyMatchesFeedControllerProvider);
    final initialDate = feedState.dateState.selectedDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: ColombiaTimeUtils.minCalendarDate,
      lastDate: ColombiaTimeUtils.maxCalendarDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: KickPulseColors.accentPrimary,
              onPrimary: KickPulseColors.surfaceBase,
              surface: KickPulseColors.surfaceElevated,
              onSurface: KickPulseColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: KickPulseColors.surfaceBase,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref
          .read(dailyMatchesFeedControllerProvider.notifier)
          .selectCustomDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      ref.watch(cloudSyncBootstrapProvider);
    } catch (_) {
      // Safe fallback in minimal widget tests without Supabase overrides.
    }
    final shellState = ref.watch(appShellControllerProvider);
    final envConfig = ref.watch(environmentConfigProvider);
    final l10n = AppLocalizations.of(context);
    final isCalendarVisible =
        shellState.activeSection == AppShellSection.matchday;

    final visualIndex = switch (shellState.activeSection) {
      AppShellSection.matches => 0,
      AppShellSection.news => 1,
      AppShellSection.profile => 2,
      AppShellSection.explore => 0,
    };

    return Scaffold(
      drawer: const AppNavigationDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            key: const Key('app_bar_drawer_button'),
            icon: const Icon(Icons.menu),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                l10n.appTitle,
                style: KickPulseTypography.screenTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (envConfig.showEnvironmentBanner) ...[
              const SizedBox(width: 6.0),
              KickPulseBadge(
                label: l10n.envDevBadge,
                variant: KickPulseBadgeVariant.dev,
              ),
            ],
          ],
        ),
        actions: [
          if (isCalendarVisible)
            IconButton(
              key: const Key('app_bar_calendar_action'),
              icon: const Icon(Icons.calendar_month_outlined),
              tooltip: l10n.calendarPickerTooltip,
              onPressed: () => _onPickCalendarDate(context),
            ),
          if (shellState.activeSection == AppShellSection.news)
            IconButton(
              key: const Key('app_bar_news_filter_action'),
              icon: const Icon(Icons.more_vert),
              tooltip: l10n.newsFilterMenuTooltip,
              onPressed: () => NewsFilterBottomSheet.show(context),
            ),
          const SyncStatusAppBarAction(),
          const FanAlertsBellAction(userId: 'user-active-current'),
        ],
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: IndexedStack(
              index: visualIndex,
              children: const [
                MatchdayTabView(),
                NewsTabView(),
                ProfileTabView(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: visualIndex,
        onDestinationSelected: (index) {
          final targetSection = switch (index) {
            0 => AppShellSection.matches,
            1 => AppShellSection.news,
            2 => AppShellSection.profile,
            _ => AppShellSection.matches,
          };
          ref
              .read(appShellControllerProvider.notifier)
              .setSection(targetSection);
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
            icon: const Icon(Icons.newspaper_outlined),
            selectedIcon: const Icon(
              Icons.newspaper,
              color: KickPulseColors.accentPrimary,
            ),
            label: l10n.tabNews,
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
