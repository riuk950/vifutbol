import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/connectivity_banner_controller.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';

/// Top banner that dynamically displays offline warnings and 3-second restoration alerts (FR-007).
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannerState = ref.watch(connectivityBannerControllerProvider);
    final l10n = AppLocalizations.of(context);

    if (bannerState.visibility == ConnectivityBannerVisibility.hidden) {
      return const SizedBox.shrink();
    }

    final isOffline =
        bannerState.visibility == ConnectivityBannerVisibility.offline;
    final bgColor = isOffline
        ? KickPulseColors.accentWarning
        : KickPulseColors.accentPrimary;
    final message = isOffline
        ? l10n.connectivityOfflineMessage
        : l10n.connectivityRestoredMessage;
    final icon = isOffline ? Icons.wifi_off : Icons.wifi;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(icon, size: 18.0, color: Colors.black),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
