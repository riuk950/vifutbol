import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/venues_providers.dart';
import 'package:vifutbol/application/use_cases/query_venues_geolocation_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/location_permission_state.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_state_view.dart';
import 'package:vifutbol/presentation/venues/venue_detail_sheet.dart';
import 'package:vifutbol/presentation/venues/venue_form_screen.dart';
import 'package:vifutbol/presentation/venues/widgets/kick_pulse_urban_map_canvas.dart';

/// Main screen for the "Sedes" tab in App Shell navigation.
class VenuesTabView extends ConsumerStatefulWidget {
  const VenuesTabView({super.key});

  @override
  ConsumerState<VenuesTabView> createState() => _VenuesTabViewState();
}

class _VenuesTabViewState extends ConsumerState<VenuesTabView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final envConfig = ref.watch(environmentConfigProvider);
    final userCapabilities = ref.watch(activeRoleCapabilitiesProvider);
    final canManage = userCapabilities.contains(RoleCapability.manageVenues);

    final venuesState = ref.watch(venuesControllerProvider);
    final venuesController = ref.read(venuesControllerProvider.notifier);
    final filteredVenues = ref.watch(filteredVenuesProvider);

    return Scaffold(
      backgroundColor: KickPulseColors.canvasBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await venuesController.loadCatalog();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Header Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    KickPulseRadiiSpacing.spaceMd,
                    KickPulseRadiiSpacing.spaceMd,
                    KickPulseRadiiSpacing.spaceMd,
                    KickPulseRadiiSpacing.spaceSm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.venuesTitle,
                              style: const TextStyle(
                                color: KickPulseColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(
                              height: KickPulseRadiiSpacing.spaceXs,
                            ),
                            Text(
                              l10n.venuesSubtitle,
                              style: const TextStyle(
                                color: KickPulseColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (canManage)
                        KickPulseButton(
                          label: l10n.venuesCreateAction,
                          variant: KickPulseButtonVariant.primary,
                          onPressed: () async {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const VenueFormScreen(),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // 2. Dev GPS Permission Simulator Bar (Dev Only)
              if (envConfig.environment == AppEnvironment.development)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: KickPulseRadiiSpacing.spaceMd,
                      vertical: KickPulseRadiiSpacing.spaceXs,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: KickPulseRadiiSpacing.spaceSm,
                      vertical: KickPulseRadiiSpacing.spaceXs,
                    ),
                    decoration: BoxDecoration(
                      color: KickPulseColors.surfaceElevated,
                      borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
                      border: Border.all(
                        color: KickPulseColors.accentElectric.withAlpha(80),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.developer_mode_rounded,
                          size: 16,
                          color: KickPulseColors.accentElectric,
                        ),
                        const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                        Text(
                          l10n.locationDevSimulatorTitle,
                          style: const TextStyle(
                            color: KickPulseColors.accentElectric,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        _buildDevSimChip(
                          label: l10n.locationDevStateGranted,
                          isSelected:
                              venuesState.locationState.status ==
                              LocationPermissionStatus.granted,
                          color: KickPulseColors.accentPrimary,
                          onTap: () =>
                              venuesController.simulateDevLocationStatus(
                                LocationPermissionStatus.granted,
                              ),
                        ),
                        const SizedBox(width: 4),
                        _buildDevSimChip(
                          label: l10n.locationDevStateDenied,
                          isSelected:
                              venuesState.locationState.status ==
                              LocationPermissionStatus.denied,
                          color: KickPulseColors.accentWarning,
                          onTap: () =>
                              venuesController.simulateDevLocationStatus(
                                LocationPermissionStatus.denied,
                              ),
                        ),
                        const SizedBox(width: 4),
                        _buildDevSimChip(
                          label: l10n.locationDevStatePermanentlyDenied,
                          isSelected:
                              venuesState.locationState.status ==
                              LocationPermissionStatus.permanentlyDenied,
                          color: KickPulseColors.accentLive,
                          onTap: () =>
                              venuesController.simulateDevLocationStatus(
                                LocationPermissionStatus.permanentlyDenied,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 3. Location Permission Fallback Banner (when denied or revoked)
              if (venuesState.locationState.status.isDenied)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(
                      KickPulseRadiiSpacing.spaceMd,
                      KickPulseRadiiSpacing.spaceXs,
                      KickPulseRadiiSpacing.spaceMd,
                      KickPulseRadiiSpacing.spaceSm,
                    ),
                    padding: const EdgeInsets.all(
                      KickPulseRadiiSpacing.spaceSm,
                    ),
                    decoration: BoxDecoration(
                      color: KickPulseColors.surfaceElevated,
                      borderRadius: KickPulseRadiiSpacing.cardBorderRadius,
                      border: Border.all(
                        color: KickPulseColors.accentWarning.withAlpha(80),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_off_outlined,
                          size: 20,
                          color: KickPulseColors.accentWarning,
                        ),
                        const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                        Expanded(
                          child: Text(
                            l10n.locationPermissionBanner,
                            style: const TextStyle(
                              color: KickPulseColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            venuesController.requestLocationPermission();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: KickPulseColors.accentElectric,
                            minimumSize: const Size(44, 44),
                          ),
                          child: Text(l10n.locationPermissionEnableAction),
                        ),
                      ],
                    ),
                  ),
                ),

              // 4. Search and Filters Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KickPulseRadiiSpacing.spaceMd,
                    vertical: KickPulseRadiiSpacing.spaceSm,
                  ),
                  child: Column(
                    children: [
                      // Search field
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: KickPulseColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.venuesSearchHint,
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: KickPulseColors.textMuted,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    venuesController.setSearchQuery('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: KickPulseColors.surfaceElevated,
                          border: OutlineInputBorder(
                            borderRadius:
                                KickPulseRadiiSpacing.chipBorderRadius,
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) {
                          venuesController.setSearchQuery(val);
                        },
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

                      // Filter chips row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Proximity filter chip
                            FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.near_me_rounded,
                                    size: 14,
                                    color: venuesState.sortByProximity
                                        ? KickPulseColors.canvasBackground
                                        : KickPulseColors.accentElectric,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    venuesState.sortByProximity
                                        ? l10n.venuesProximityActive
                                        : l10n.venuesProximityAction,
                                  ),
                                ],
                              ),
                              selected: venuesState.sortByProximity,
                              selectedColor: KickPulseColors.accentElectric,
                              backgroundColor: KickPulseColors.surfaceElevated,
                              onSelected: (_) {
                                venuesController.toggleProximitySort();
                              },
                            ),
                            const SizedBox(
                              width: KickPulseRadiiSpacing.spaceSm,
                            ),

                            // Surface filter chips
                            FilterChip(
                              label: Text(l10n.surfaceSyntheticGrass),
                              selected:
                                  venuesState.surfaceFilter ==
                                  PitchSurfaceType.syntheticGrass,
                              selectedColor: KickPulseColors.accentElectric,
                              backgroundColor: KickPulseColors.surfaceElevated,
                              onSelected: (_) =>
                                  venuesController.setSurfaceFilter(
                                    PitchSurfaceType.syntheticGrass,
                                  ),
                            ),
                            const SizedBox(
                              width: KickPulseRadiiSpacing.spaceSm,
                            ),
                            FilterChip(
                              label: Text(l10n.surfaceNaturalGrass),
                              selected:
                                  venuesState.surfaceFilter ==
                                  PitchSurfaceType.naturalGrass,
                              selectedColor: KickPulseColors.accentElectric,
                              backgroundColor: KickPulseColors.surfaceElevated,
                              onSelected: (_) =>
                                  venuesController.setSurfaceFilter(
                                    PitchSurfaceType.naturalGrass,
                                  ),
                            ),
                            const SizedBox(
                              width: KickPulseRadiiSpacing.spaceSm,
                            ),
                            FilterChip(
                              label: Text(l10n.surfaceHardCourt),
                              selected:
                                  venuesState.surfaceFilter ==
                                  PitchSurfaceType.hardCourt,
                              selectedColor: KickPulseColors.accentElectric,
                              backgroundColor: KickPulseColors.surfaceElevated,
                              onSelected: (_) => venuesController
                                  .setSurfaceFilter(PitchSurfaceType.hardCourt),
                            ),
                            const SizedBox(
                              width: KickPulseRadiiSpacing.spaceSm,
                            ),

                            // Lighting chip
                            FilterChip(
                              label: Text(l10n.venuesFilterLightingOnly),
                              selected: venuesState.onlyWithLighting,
                              selectedColor: KickPulseColors.accentElectric,
                              backgroundColor: KickPulseColors.surfaceElevated,
                              onSelected: (_) =>
                                  venuesController.toggleOnlyWithLighting(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Interactive Tactical Map Canvas
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KickPulseRadiiSpacing.spaceMd,
                    vertical: KickPulseRadiiSpacing.spaceSm,
                  ),
                  child: KickPulseUrbanMapCanvas(
                    centerCoordinate: _computeCenterCoordinate(venuesState),
                    venues: venuesState.venues,
                    selectedVenueId: venuesState.selectedVenueId,
                    userCoordinate: venuesState.locationState.userCoordinate,
                    height: 200,
                    onVenueSelected: (venue) {
                      venuesController.selectVenue(venue.id);
                      final withDistance = filteredVenues.firstWhere(
                        (item) => item.venue.id == venue.id,
                        orElse: () => VenueWithDistance(venue: venue),
                      );
                      VenueDetailSheet.show(
                        context,
                        venue: venue,
                        distanceInKm: withDistance.distanceInKm,
                      );
                    },
                  ),
                ),
              ),

              // 6. UI States & Venues List
              _buildStateContent(
                context: context,
                state: venuesState.viewState,
                filteredVenues: filteredVenues,
                l10n: l10n,
                canManage: canManage,
                onRetry: () => venuesController.loadCatalog(),
                onClearFilters: () {
                  _searchController.clear();
                  venuesController.clearFilters();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  GeoCoordinate _computeCenterCoordinate(dynamic state) {
    if (state.selectedVenue != null) {
      return state.selectedVenue!.coordinate;
    }
    if (state.venues.isNotEmpty) {
      return state.venues.first.coordinate;
    }
    return GeoCoordinate.defaultCityCenter;
  }

  Widget _buildDevSimChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? color : KickPulseColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : KickPulseColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStateContent({
    required BuildContext context,
    required UiViewState<List<SportsVenue>> state,
    required List<dynamic> filteredVenues,
    required AppLocalizations l10n,
    required bool canManage,
    required VoidCallback onRetry,
    required VoidCallback onClearFilters,
  }) {
    if (state is UiLoadingState<List<SportsVenue>>) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: KickPulseStateView(state: state),
      );
    }

    if (state is UiErrorState<List<SportsVenue>>) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: KickPulseStateView(state: state, onRetry: () async => onRetry()),
      );
    }

    if (state is UiEmptyState || filteredVenues.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceXl),
          child: KickPulseCard(
            backgroundColor: KickPulseColors.surfaceElevated,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sports_soccer_outlined,
                  size: 48,
                  color: KickPulseColors.textMuted,
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                Text(
                  l10n.venuesEmptyTitle,
                  style: const TextStyle(
                    color: KickPulseColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                Text(
                  l10n.venuesEmptySubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: KickPulseColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                TextButton(
                  onPressed: onClearFilters,
                  child: Text(l10n.venuesClearFilters),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Content: SliverList of Venue Cards
    return SliverPadding(
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = filteredVenues[index];
          final SportsVenue venue = item.venue;
          final double? distance = item.distanceInKm;

          return Padding(
            padding: const EdgeInsets.only(
              bottom: KickPulseRadiiSpacing.spaceSm,
            ),
            child: GestureDetector(
              onTap: () {
                VenueDetailSheet.show(
                  context,
                  venue: venue,
                  distanceInKm: distance,
                );
              },
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
                            venue.name,
                            style: const TextStyle(
                              color: KickPulseColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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
                    const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: KickPulseColors.textMuted,
                        ),
                        const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                        Expanded(
                          child: Text(
                            venue.address,
                            style: const TextStyle(
                              color: KickPulseColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (distance != null) ...[
                          const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                          Text(
                            l10n.venuesDistanceKm(distance.toStringAsFixed(1)),
                            style: const TextStyle(
                              color: KickPulseColors.accentElectric,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                    Wrap(
                      spacing: KickPulseRadiiSpacing.spaceSm,
                      runSpacing: KickPulseRadiiSpacing.spaceXs,
                      children: [
                        KickPulseBadge(
                          label: l10n.venuesPitchesCount(
                            venue.activePitchesCount,
                          ),
                          variant: KickPulseBadgeVariant.neutral,
                        ),
                        if (venue.hasNightLighting)
                          const KickPulseBadge(
                            label: 'Iluminación',
                            variant: KickPulseBadgeVariant.dev,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }, childCount: filteredVenues.length),
      ),
    );
  }
}
