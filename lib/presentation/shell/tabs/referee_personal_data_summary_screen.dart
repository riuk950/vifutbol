import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/providers/auth_providers.dart';
import '../../../application/providers/document_scanner_providers.dart';
import '../../../domain/entities/player_personal_enums.dart';
import '../../../domain/entities/role_profile_data.dart';
import '../../../domain/entities/user_account.dart';
import '../../../domain/services/player_personal_data_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../design_system/kick_pulse_colors.dart';
import '../../design_system/kick_pulse_radii_spacing.dart';
import '../../design_system/kick_pulse_typography.dart';
import '../../design_system/widgets/kick_pulse_card.dart';

/// Read-only summary screen displaying the referee's dossier:
/// avatar photo, identity header with age, demographic/location details,
/// certification level and document preview, and dual-side ID previews with zoom.
class RefereePersonalDataSummaryScreen extends ConsumerWidget {
  const RefereePersonalDataSummaryScreen({super.key});

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
          l10n.refereePersonalDataSummaryTitle,
          style: KickPulseTypography.screenTitle,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: KickPulseRadiiSpacing.spaceSm),
            child: Semantics(
              button: true,
              label: l10n.playerPersonalDataEditAction,
              child: TextButton.icon(
                key: const ValueKey('referee_summary_edit_action'),
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed('/profile/referee-personal-data'),
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
                  _buildCertificationCard(context, profile),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceLg),
                  _buildDocumentationCard(context, profile),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceXl),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, UserAccount user) {
    final l10n = AppLocalizations.of(context);
    final photo = user.photoUrl;
    final birthDate = user.roleProfile?.birthDate;

    final ageText = birthDate != null
        ? l10n.playerSummaryAgeFormat(
            PlayerPersonalDataUtils.calculateAge(birthDate),
          )
        : l10n.playerSummaryAgeUnknown;

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
      key: const ValueKey('referee_summary_header_card'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Semantics(
            label: l10n.refereeAvatarSectionTitle,
            image: true,
            child: CircleAvatar(
              key: const ValueKey('referee_summary_avatar'),
              radius: 36,
              backgroundColor: KickPulseColors.surfaceSubtle,
              backgroundImage: imageProvider,
              onBackgroundImageError:
                  imageProvider != null ? (_, _) {} : null,
              child: imageProvider == null
                  ? const Icon(
                      Icons.person_outline,
                      color: KickPulseColors.accentPrimary,
                      size: 40,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: KickPulseRadiiSpacing.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isNotEmpty ? user.fullName : l10n.roleReferee,
                  key: const ValueKey('referee_summary_full_name'),
                  style: KickPulseTypography.cardTitle,
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                Text(
                  user.documentId != null && user.documentId!.isNotEmpty
                      ? 'CC: ${user.documentId}'
                      : 'CC: -',
                  key: const ValueKey('referee_summary_document_id'),
                  style: const TextStyle(
                    color: KickPulseColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                Text(
                  ageText,
                  key: const ValueKey('referee_summary_age'),
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

  Widget _buildDemographicsCard(
    BuildContext context,
    UserAccount user,
    RoleProfileData? profile,
  ) {
    final l10n = AppLocalizations.of(context);
    final birthDate = profile?.birthDate;
    final formattedBirthDate = birthDate != null
        ? '${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}'
        : '-';

    return KickPulseCard(
      key: const ValueKey('referee_summary_demographics_card'),
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
            value: _formatSex(context, profile?.sex),
            key: const ValueKey('referee_summary_sex_row'),
          ),
          _buildDetailRow(
            label: l10n.playerSummaryBirthDateLabel,
            value: formattedBirthDate,
            key: const ValueKey('referee_summary_birth_date_row'),
          ),
          _buildDetailRow(
            label: l10n.playerSummaryBloodTypeLabel,
            value: profile?.bloodType ?? '-',
            key: const ValueKey('referee_summary_blood_type_row'),
          ),
          _buildDetailRow(
            label: l10n.refereeSummaryPhoneLabel,
            value: (user.phone != null && user.phone!.isNotEmpty)
                ? user.phone!
                : '-',
            key: const ValueKey('referee_summary_phone_row'),
          ),
          _buildDetailRow(
            label: l10n.playerSummaryDepartmentLabel,
            value: profile?.department ?? '-',
            key: const ValueKey('referee_summary_department_row'),
          ),
          _buildDetailRow(
            label: l10n.playerSummaryMunicipalityLabel,
            value: profile?.municipality ?? '-',
            key: const ValueKey('referee_summary_municipality_row'),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationCard(
    BuildContext context,
    RoleProfileData? profile,
  ) {
    final l10n = AppLocalizations.of(context);
    final level = profile?.certificationLevel;
    final certDocUrl = profile?.certificationDocumentUrl;

    return KickPulseCard(
      key: const ValueKey('referee_summary_certification_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.refereeSummaryCertificationTitle,
            style: KickPulseTypography.sectionHeader,
          ),
          const SizedBox(height: 2),
          Text(
            l10n.refereeSummaryCertificationSubtitle,
            style: const TextStyle(
              color: KickPulseColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          const Divider(height: 1, color: KickPulseColors.borderSubtle),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          _buildDetailRow(
            label: l10n.refereeCertificationLevelLabel,
            value: (level != null && level.trim().isNotEmpty) ? level : '-',
            key: const ValueKey('referee_summary_certification_level_row'),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          _buildDocPreviewTile(
            context: context,
            title: l10n.refereeSummaryCertificationDocLabel,
            imageUrl: certDocUrl,
            thumbnailKey:
                const ValueKey('referee_summary_certification_doc_preview'),
            emptyKey: const ValueKey('referee_summary_certification_doc_empty'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentationCard(
    BuildContext context,
    RoleProfileData? profile,
  ) {
    final l10n = AppLocalizations.of(context);
    final frontUrl = profile?.documentFrontUrl;
    final backUrl = profile?.documentBackUrl;

    return KickPulseCard(
      key: const ValueKey('referee_summary_documentation_card'),
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
                  thumbnailKey:
                      const ValueKey('referee_summary_doc_front_preview'),
                  emptyKey: const ValueKey('referee_summary_doc_front_empty'),
                ),
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceMd),
              Expanded(
                child: _buildDocPreviewTile(
                  context: context,
                  title: l10n.playerSummaryBackDocLabel,
                  imageUrl: backUrl,
                  thumbnailKey:
                      const ValueKey('referee_summary_doc_back_preview'),
                  emptyKey: const ValueKey('referee_summary_doc_back_empty'),
                ),
              ),
            ],
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
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: KickPulseColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: KickPulseTypography.bodyPrimary.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
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
                return Semantics(
                  button: true,
                  label: title,
                  child: InkWell(
                    key: thumbnailKey,
                    onTap: () => _openZoomDialog(context, effectiveUrl, title),
                    borderRadius:
                        BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        KickPulseRadiiSpacing.cardRadius,
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: _buildImageWidget(
                          context,
                          effectiveUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
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
              error: (_, _) => Semantics(
                button: true,
                label: title,
                child: InkWell(
                  key: thumbnailKey,
                  onTap: () => _openZoomDialog(context, imageUrl, title),
                  borderRadius:
                      BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: _buildImageWidget(
                        context,
                        imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _openZoomDialog(BuildContext context, String imageUrl, String title) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
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
                    Text(title, style: KickPulseTypography.cardTitle),
                    IconButton(
                      key: const ValueKey('referee_summary_viewer_close_button'),
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
                          child: _buildImageWidget(
                            context,
                            url ?? imageUrl,
                            fit: BoxFit.contain,
                          ),
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
                        error: (_, _) => InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4.0,
                          child: _buildImageWidget(
                            context,
                            imageUrl,
                            fit: BoxFit.contain,
                          ),
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

  Widget _buildImageWidget(
    BuildContext context,
    String pathOrUrl, {
    BoxFit fit = BoxFit.contain,
  }) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return Image.network(
        pathOrUrl,
        fit: fit,
        errorBuilder: (_, _, _) => _imageErrorPlaceholder(context),
      );
    }
    final file = File(pathOrUrl);
    if (!file.existsSync()) {
      return _imageErrorPlaceholder(context);
    }
    return Image.file(
      file,
      fit: fit,
      errorBuilder: (_, _, _) => _imageErrorPlaceholder(context),
    );
  }

  Widget _imageErrorPlaceholder(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: KickPulseColors.surfaceSubtle,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.broken_image_outlined,
              color: KickPulseColors.textMuted,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.refereeSummaryDocLoadFallback,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: KickPulseColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSex(BuildContext context, String? raw) {
    final l10n = AppLocalizations.of(context);
    final sex = PlayerSex.fromRaw(raw);
    if (sex == null) return '-';
    return switch (sex) {
      PlayerSex.male => l10n.playerPersonalDataSexMale,
      PlayerSex.female => l10n.playerPersonalDataSexFemale,
      PlayerSex.other => l10n.playerPersonalDataSexOther,
    };
  }
}
