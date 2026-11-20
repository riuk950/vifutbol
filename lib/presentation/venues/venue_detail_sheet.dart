import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/venues_providers.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/venues/venue_form_screen.dart';

/// Modal bottom sheet displaying detailed venue information, directions,
/// and internal pitches breakdown, with administrative controls for the Organizer.
class VenueDetailSheet extends ConsumerWidget {
  const VenueDetailSheet({super.key, required this.venue, this.distanceInKm});

  final SportsVenue venue;
  final double? distanceInKm;

  static Future<void> show(
    BuildContext context, {
    required SportsVenue venue,
    double? distanceInKm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KickPulseColors.surfaceBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(KickPulseRadiiSpacing.cardRadius),
        ),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollController) =>
            VenueDetailSheet(venue: venue, distanceInKm: distanceInKm),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final userCapabilities = ref.watch(activeRoleCapabilitiesProvider);
    final canManage = userCapabilities.contains(RoleCapability.manageVenues);

    return Column(
      children: [
        // Drag handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: KickPulseRadiiSpacing.spaceSm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: KickPulseColors.borderStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
            children: [
              // Header: Name and Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          venue.name,
                          style: const TextStyle(
                            color: KickPulseColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        if (distanceInKm != null) ...[
                          const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                          Row(
                            children: [
                              const Icon(
                                Icons.near_me_rounded,
                                size: 14,
                                color: KickPulseColors.accentElectric,
                              ),
                              const SizedBox(
                                width: KickPulseRadiiSpacing.spaceXs,
                              ),
                              Text(
                                l10n.venuesDistanceKm(
                                  distanceInKm!.toStringAsFixed(1),
                                ),
                                style: const TextStyle(
                                  color: KickPulseColors.accentElectric,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  KickPulseBadge(
                    label: venue.status == VenueOperationalStatus.active
                        ? l10n.venuesStatusActive
                        : l10n.venuesStatusMaintenance,
                    variant: venue.status == VenueOperationalStatus.active
                        ? KickPulseBadgeVariant.info
                        : KickPulseBadgeVariant.warning,
                  ),
                ],
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

              // Address and Directions Card
              KickPulseCard(
                backgroundColor: KickPulseColors.surfaceElevated,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: KickPulseColors.textTertiary,
                        ),
                        const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                        Expanded(
                          child: Text(
                            venue.address,
                            style: const TextStyle(
                              color: KickPulseColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (venue.urbanReference.isNotEmpty) ...[
                      const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: KickPulseColors.textTertiary,
                          ),
                          const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                          Expanded(
                            child: Text(
                              venue.urbanReference,
                              style: const TextStyle(
                                color: KickPulseColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                    Row(
                      children: [
                        const Icon(
                          Icons.map_outlined,
                          size: 18,
                          color: KickPulseColors.textTertiary,
                        ),
                        const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                        Text(
                          '${venue.coordinate.latitude.toStringAsFixed(4)}, ${venue.coordinate.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(
                            color: KickPulseColors.textMuted,
                            fontSize: 12,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: Text(l10n.venuesGetDirections),
                          style: TextButton.styleFrom(
                            foregroundColor: KickPulseColors.accentElectric,
                            minimumSize: const Size(44, 44),
                          ),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                text:
                                    '${venue.name}\n${venue.address}\n${venue.urbanReference}',
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.venuesDirectionsCopied),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

              // Internal Pitches Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.venuesPitchesSectionTitle,
                    style: const TextStyle(
                      color: KickPulseColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    l10n.venuesPitchesCount(venue.activePitchesCount),
                    style: const TextStyle(
                      color: KickPulseColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

              // Pitches List
              ...venue.pitches.map(
                (pitch) => _buildPitchCard(context, pitch, l10n),
              ),

              const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

              // Organizer Actions (Edit & Toggle Status)
              if (canManage) ...[
                Row(
                  children: [
                    Expanded(
                      child: KickPulseButton(
                        label: l10n.venuesEditAction,
                        variant: KickPulseButtonVariant.secondary,
                        onPressed: () async {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  VenueFormScreen(existingVenue: venue),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                    Expanded(
                      child: KickPulseButton(
                        label: venue.status == VenueOperationalStatus.active
                            ? l10n.venuesStatusMaintenance
                            : l10n.venuesStatusActive,
                        variant: venue.status == VenueOperationalStatus.active
                            ? KickPulseButtonVariant.outline
                            : KickPulseButtonVariant.primary,
                        onPressed: () async {
                          final newStatus =
                              venue.status == VenueOperationalStatus.active
                              ? VenueOperationalStatus.maintenance
                              : VenueOperationalStatus.active;
                          await ref
                              .read(venuesControllerProvider.notifier)
                              .setVenueStatus(venue.id, newStatus);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPitchCard(
    BuildContext context,
    VenuePitch pitch,
    AppLocalizations l10n,
  ) {
    String surfaceLabel;
    switch (pitch.surfaceType) {
      case PitchSurfaceType.syntheticGrass:
        surfaceLabel = l10n.surfaceSyntheticGrass;
      case PitchSurfaceType.naturalGrass:
        surfaceLabel = l10n.surfaceNaturalGrass;
      case PitchSurfaceType.dirtOrSand:
        surfaceLabel = l10n.surfaceDirtOrSand;
      case PitchSurfaceType.hardCourt:
        surfaceLabel = l10n.surfaceHardCourt;
    }

    String formatLabel;
    switch (pitch.format) {
      case PitchFormat.football5:
        formatLabel = l10n.formatFootball5;
      case PitchFormat.football7:
        formatLabel = l10n.formatFootball7;
      case PitchFormat.football8:
        formatLabel = l10n.formatFootball8;
      case PitchFormat.football11:
        formatLabel = l10n.formatFootball11;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: KickPulseRadiiSpacing.spaceSm),
      child: KickPulseCard(
        backgroundColor: KickPulseColors.surfaceElevated,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    pitch.name,
                    style: const TextStyle(
                      color: KickPulseColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                KickPulseBadge(
                  label: pitch.status == VenueOperationalStatus.active
                      ? l10n.venuesStatusActive
                      : l10n.venuesStatusMaintenance,
                  variant: pitch.status == VenueOperationalStatus.active
                      ? KickPulseBadgeVariant.info
                      : KickPulseBadgeVariant.warning,
                ),
              ],
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
            Wrap(
              spacing: KickPulseRadiiSpacing.spaceSm,
              runSpacing: KickPulseRadiiSpacing.spaceXs,
              children: [
                KickPulseBadge(
                  label: surfaceLabel,
                  variant: KickPulseBadgeVariant.neutral,
                ),
                KickPulseBadge(
                  label: formatLabel,
                  variant: KickPulseBadgeVariant.neutral,
                ),
                if (pitch.hasLighting)
                  const KickPulseBadge(
                    label: 'Iluminación',
                    variant: KickPulseBadgeVariant.dev,
                  ),
              ],
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
            Row(
              children: [
                const Icon(
                  Icons.people_alt_outlined,
                  size: 16,
                  color: KickPulseColors.textMuted,
                ),
                const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                Text(
                  l10n.venuesCapacityCount(pitch.capacity),
                  style: const TextStyle(
                    color: KickPulseColors.textMuted,
                    fontSize: 12,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
