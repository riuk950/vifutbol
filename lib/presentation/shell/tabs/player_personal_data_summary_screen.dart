import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/auth_providers.dart';
import '../../../application/providers/document_scanner_providers.dart';
import '../../../domain/entities/detailed_football_position.dart';
import '../../../domain/entities/player_personal_enums.dart';
import '../../../domain/entities/team_enums.dart';
import '../../../domain/entities/user_account.dart';
import '../../../domain/services/player_personal_data_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../design_system/kick_pulse_colors.dart';
import '../../design_system/kick_pulse_radii_spacing.dart';
import '../../design_system/kick_pulse_typography.dart';
import '../../design_system/widgets/kick_pulse_card.dart';

/// Read-only summary screen displaying the player's full dossier:
/// profile photograph avatar, identity header with calculated age,
/// demographic data, tactical position chips, and dual-side ID previews with zoom dialog.
class PlayerPersonalDataSummaryScreen extends ConsumerWidget {
  const PlayerPersonalDataSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).session?.user;
    final profile = user?.roleProfile;

    return Scaffold(
      backgroundColor: KickPulseColors.canvasBackground,
      appBar: AppBar(
        backgroundColor: KickPulseColors.canvasBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: KickPulseColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          l10n.playerPersonalDataSummaryTitle,
          style: KickPulseTypography.screenTitle,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: KickPulseRadiiSpacing.spaceSm),
            child: TextButton.icon(
              key: const ValueKey('player_summary_edit_action'),
              onPressed: () =>
                  Navigator.of(context).pushNamed('/profile/personal-data'),
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: KickPulseColors.accentElectric,
              ),
              label: Text(
                l10n.playerPersonalDataEditAction,
                style: const TextStyle(
                  color: KickPulseColors.accentElectric,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: user == null
          ? const Center(
              child: CircularProgressIndicator(
                color: KickPulseColors.accentPrimary,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderCard(context, user),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceLg),
                  _buildDemographicsCard(context, user, profile),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceLg),
                  _buildTacticalCard(context, profile),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceLg),
                  _buildDocumentationCard(context, profile),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceXl),
                ],
              ),
            ),
    );
  }

  // --- Section 1: Header / Identity ---

  Widget _buildHeaderCard(BuildContext context, UserAccount user) {
    final l10n = AppLocalizations.of(context);
    final photo = user.photoUrl;
    final birthDate = user.roleProfile?.birthDate;

    String ageText;
    if (birthDate != null) {
      final age = PlayerPersonalDataUtils.calculateAge(birthDate);
      ageText = l10n.playerSummaryAgeFormat(age);
    } else {
      ageText = l10n.playerSummaryAgeUnknown;
    }

    ImageProvider? imageProvider;
    if (photo != null && photo.trim().isNotEmpty) {
      if (photo.startsWith('http://') || photo.startsWith('https://')) {
        imageProvider = NetworkImage(photo);
      } else {
        final localFile = File(photo);
        if (localFile.existsSync()) {
          imageProvider = FileImage(localFile);
        }
      }
    }

    return KickPulseCard(
      key: const ValueKey('player_summary_header_card'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            key: const ValueKey('player_summary_avatar'),
            radius: 36,
            backgroundColor: KickPulseColors.surfaceSubtle,
            backgroundImage: imageProvider,
            onBackgroundImageError:
                imageProvider != null ? (exception, stackTrace) {} : null,
            child: imageProvider == null
                ? const Icon(
                    Icons.person_outline,
                    color: KickPulseColors.accentPrimary,
                    size: 40,
                  )
                : null,
          ),
          const SizedBox(width: KickPulseRadiiSpacing.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isNotEmpty
                      ? user.fullName
                      : 'Jugador',
                  key: const ValueKey('player_summary_full_name'),
                  style: KickPulseTypography.cardTitle,
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                Text(
                  user.documentId != null && user.documentId!.isNotEmpty
                      ? 'CC: ${user.documentId}'
                      : 'CC: -',
                  key: const ValueKey('player_summary_document_id'),
                  style: const TextStyle(
                    color: KickPulseColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                Text(
                  ageText,
                  key: const ValueKey('player_summary_age'),
                  style: const TextStyle(
                    color: KickPulseColors.accentPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Section 2: Demographics ---

  Widget _buildDemographicsCard(
    BuildContext context,
    UserAccount user,
    dynamic profile,
  ) {
    final l10n = AppLocalizations.of(context);
    final birthDate = profile?.birthDate as DateTime?;
    final formattedBirthDate = birthDate != null
        ? '${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}'
        : '-';

    return KickPulseCard(
      key: const ValueKey('player_summary_demographics_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.playerSummaryDemographicsTitle,
            style: KickPulseTypography.sectionHeader,
          ),
          const SizedBox(height: 2),
          Text(
            l10n.playerSummaryDemographicsSubtitle,
            style: const TextStyle(
              color: KickPulseColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          const Divider(height: 1, color: KickPulseColors.borderSubtle),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          _buildDetailRow(
            label: l10n.playerSummarySexLabel,
            value: _formatSex(context, profile?.sex as String?),
            key: const ValueKey('player_summary_sex_row'),
          ),
          _buildDetailRow(
            label: l10n.playerSummaryBirthDateLabel,
            value: formattedBirthDate,
            key: const ValueKey('player_summary_birth_date_row'),
          ),
          _buildDetailRow(
            label: l10n.playerSummaryBloodTypeLabel,
            value: (profile?.bloodType as String?) ?? '-',
            key: const ValueKey('player_summary_blood_type_row'),
          ),
          _buildDetailRow(
            label: l10n.playerSummaryDepartmentLabel,
            value: (profile?.department as String?) ?? '-',
            key: const ValueKey('player_summary_department_row'),
          ),
          _buildDetailRow(
            label: l10n.playerSummaryMunicipalityLabel,
            value: (profile?.municipality as String?) ?? '-',
            key: const ValueKey('player_summary_municipality_row'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required Key key,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: KickPulseColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: KickPulseTypography.bodyPrimary.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --- Section 3: Tactical Profile ---

  Widget _buildTacticalCard(BuildContext context, dynamic profile) {
    final l10n = AppLocalizations.of(context);
    final primaryPos = profile?.primaryPosition as PlayerPosition?;
    final secondaryPositions =
        (profile?.secondaryPositions as List<String>?) ?? const <String>[];

    return KickPulseCard(
      key: const ValueKey('player_summary_tactical_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.playerSummaryTacticalTitle,
            style: KickPulseTypography.sectionHeader,
          ),
          const SizedBox(height: 2),
          Text(
            l10n.playerSummaryTacticalSubtitle,
            style: const TextStyle(
              color: KickPulseColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          const Divider(height: 1, color: KickPulseColors.borderSubtle),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

          // Primary Position
          Text(
            l10n.playerSummaryPrimaryPositionLabel,
            style: const TextStyle(
              color: KickPulseColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
          if (primaryPos != null)
            Chip(
              key: const ValueKey('player_summary_primary_position_chip'),
              label: Text(
                _primaryPositionLabel(l10n, primaryPos),
                style: const TextStyle(
                  color: KickPulseColors.accentPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: KickPulseColors.accentPrimary.withAlpha(40),
              side: const BorderSide(color: KickPulseColors.accentPrimary),
            )
          else
            const Text('-', style: TextStyle(color: KickPulseColors.textMuted)),

          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

          // Secondary Positions
          Text(
            l10n.playerSummarySecondaryPositionsLabel,
            style: const TextStyle(
              color: KickPulseColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
          if (secondaryPositions.isEmpty)
            Text(
              l10n.playerSummaryNoSecondaryPositions,
              key: const ValueKey('player_summary_no_secondary_positions'),
              style: const TextStyle(
                color: KickPulseColors.textMuted,
                fontSize: 12,
              ),
            )
          else
            Wrap(
              spacing: KickPulseRadiiSpacing.spaceSm,
              runSpacing: KickPulseRadiiSpacing.spaceSm,
              children: secondaryPositions.map((code) {
                return Chip(
                  key: ValueKey('player_summary_secondary_chip_$code'),
                  label: Text(
                    _formatPositionCode(context, code),
                    style: const TextStyle(
                      color: KickPulseColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: KickPulseColors.surfaceSubtle,
                  side: const BorderSide(color: KickPulseColors.borderSubtle),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // --- Section 4: Documentation (Dual-side ID) ---

  Widget _buildDocumentationCard(BuildContext context, dynamic profile) {
    final l10n = AppLocalizations.of(context);
    final frontUrl = profile?.documentFrontUrl as String?;
    final backUrl = profile?.documentBackUrl as String?;

    return KickPulseCard(
      key: const ValueKey('player_summary_documentation_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.playerSummaryDocumentationTitle,
            style: KickPulseTypography.sectionHeader,
          ),
          const SizedBox(height: 2),
          Text(
            l10n.playerSummaryDocumentationSubtitle,
            style: const TextStyle(
              color: KickPulseColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          const Divider(height: 1, color: KickPulseColors.borderSubtle),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          Row(
            children: [
              Expanded(
                child: _buildDocPreviewTile(
                  context: context,
                  title: l10n.playerSummaryFrontDocLabel,
                  imageUrl: frontUrl,
                  thumbnailKey: const ValueKey('player_summary_front_doc_thumbnail'),
                  emptyKey: const ValueKey('player_summary_front_doc_empty'),
                ),
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceMd),
              Expanded(
                child: _buildDocPreviewTile(
                  context: context,
                  title: l10n.playerSummaryBackDocLabel,
                  imageUrl: backUrl,
                  thumbnailKey: const ValueKey('player_summary_back_doc_thumbnail'),
                  emptyKey: const ValueKey('player_summary_back_doc_empty'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocPreviewTile({
    required BuildContext context,
    required String title,
    required String? imageUrl,
    required Key thumbnailKey,
    required Key emptyKey,
  }) {
    final l10n = AppLocalizations.of(context);
    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;

    if (!hasImage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: KickPulseColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
          Container(
            key: emptyKey,
            height: 90,
            decoration: BoxDecoration(
              color: KickPulseColors.surfaceSubtle,
              borderRadius:
                  BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
              border: Border.all(color: KickPulseColors.borderSubtle),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.credit_card_outlined,
                    color: KickPulseColors.textMuted,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.playerSummaryDocNotCaptured,
                    style: const TextStyle(
                      color: KickPulseColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: KickPulseColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
        Consumer(
          builder: (context, ref, _) {
            final resolvedAsync =
                ref.watch(resolveDocumentUrlProvider(imageUrl));

            return resolvedAsync.when(
              data: (resolvedUrl) {
                final effectiveUrl = resolvedUrl ?? imageUrl;
                return InkWell(
                  key: thumbnailKey,
                  onTap: () => _openZoomDialog(context, effectiveUrl, title),
                  borderRadius:
                      BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: _buildImageWidget(effectiveUrl, fit: BoxFit.cover),
                    ),
                  ),
                );
              },
              loading: () => Container(
                height: 90,
                decoration: BoxDecoration(
                  color: KickPulseColors.surfaceSubtle,
                  borderRadius:
                      BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
                  border: Border.all(color: KickPulseColors.borderSubtle),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: KickPulseColors.accentPrimary,
                    ),
                  ),
                ),
              ),
              error: (err, stack) => InkWell(
                key: thumbnailKey,
                onTap: () => _openZoomDialog(context, imageUrl, title),
                borderRadius:
                    BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: _buildImageWidget(imageUrl, fit: BoxFit.cover),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- Zoom Viewer Dialog ---

  void _openZoomDialog(BuildContext context, String imageUrl, String title) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: KickPulseColors.surfaceElevated,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KickPulseRadiiSpacing.spaceMd,
                  vertical: KickPulseRadiiSpacing.spaceSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: KickPulseTypography.cardTitle,
                    ),
                    IconButton(
                      key: const ValueKey('player_summary_viewer_close_button'),
                      icon: const Icon(
                        Icons.close,
                        color: KickPulseColors.textPrimary,
                      ),
                      tooltip: l10n.playerSummaryViewerCloseAction,
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: KickPulseColors.borderSubtle),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final resolvedAsync =
                          ref.watch(resolveDocumentUrlProvider(imageUrl));

                      return resolvedAsync.when(
                        data: (url) => InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4.0,
                          child: _buildImageWidget(url ?? imageUrl,
                              fit: BoxFit.contain),
                        ),
                        loading: () => const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: KickPulseColors.accentPrimary,
                            ),
                          ),
                        ),
                        error: (err, stack) => InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4.0,
                          child: _buildImageWidget(imageUrl,
                              fit: BoxFit.contain),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Helpers ---

  Widget _buildImageWidget(String pathOrUrl, {BoxFit fit = BoxFit.contain}) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return Image.network(
        pathOrUrl,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _imageErrorPlaceholder(),
      );
    }
    final file = File(pathOrUrl);
    return Image.file(
      file,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _imageErrorPlaceholder(),
    );
  }

  Widget _imageErrorPlaceholder() {
    return Container(
      color: KickPulseColors.surfaceSubtle,
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: KickPulseColors.textMuted,
          size: 32,
        ),
      ),
    );
  }

  String _formatSex(BuildContext context, String? raw) {
    final l10n = AppLocalizations.of(context);
    final sex = PlayerSex.fromRaw(raw);
    return switch (sex) {
      PlayerSex.male => l10n.playerPersonalDataSexMale,
      PlayerSex.female => l10n.playerPersonalDataSexFemale,
      PlayerSex.other => l10n.playerPersonalDataSexOther,
      null => raw ?? '-',
    };
  }

  String _primaryPositionLabel(AppLocalizations l10n, PlayerPosition pos) {
    return switch (pos) {
      PlayerPosition.goalkeeper => l10n.playerTacticalLineGoalkeeper,
      PlayerPosition.defender => l10n.playerTacticalLineDefender,
      PlayerPosition.midfielder => l10n.playerTacticalLineMidfielder,
      PlayerPosition.forward => l10n.playerTacticalLineForward,
    };
  }

  String _formatPositionCode(BuildContext context, String code) {
    final detailed = DetailedFootballPosition.fromCode(code);
    if (detailed == null) return code;
    final l10n = AppLocalizations.of(context);
    return switch (detailed) {
      DetailedFootballPosition.goalkeeper => l10n.playerPositionPOR,
      DetailedFootballPosition.centerBack => l10n.playerPositionDFC,
      DetailedFootballPosition.rightBack => l10n.playerPositionLD,
      DetailedFootballPosition.leftBack => l10n.playerPositionLI,
      DetailedFootballPosition.rightWingBack => l10n.playerPositionCAD,
      DetailedFootballPosition.leftWingBack => l10n.playerPositionCAI,
      DetailedFootballPosition.defensiveMidfielder => l10n.playerPositionMCD,
      DetailedFootballPosition.centralMidfielder => l10n.playerPositionMC,
      DetailedFootballPosition.attackingMidfielder => l10n.playerPositionMCO,
      DetailedFootballPosition.rightMidfielder => l10n.playerPositionMD,
      DetailedFootballPosition.leftMidfielder => l10n.playerPositionMI,
      DetailedFootballPosition.rightWinger => l10n.playerPositionED,
      DetailedFootballPosition.leftWinger => l10n.playerPositionEI,
      DetailedFootballPosition.secondStriker => l10n.playerPositionMP,
      DetailedFootballPosition.centerForward => l10n.playerPositionDC,
    };
  }
}
