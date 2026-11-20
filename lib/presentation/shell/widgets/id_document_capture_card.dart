// lib/presentation/shell/widgets/id_document_capture_card.dart

import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/document_scanner_providers.dart';
import 'package:vifutbol/domain/entities/colombian_id_scan_result.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';

/// Card widget for guided dual-side capture of Colombian identity documents (front and back).
class IdDocumentCaptureCard extends StatelessWidget {
  const IdDocumentCaptureCard({
    super.key,
    required this.capture,
    this.isScanning = false,
    this.isCapturing = false,
    this.permissionDenied = false,
    this.validationError,
    this.scanFeedback,
    this.onScanAll,
    this.onCaptureFront,
    this.onCaptureBack,
    this.onOpenSettings,
  });

  final PlayerDocumentCapture capture;
  final bool isScanning;
  final bool isCapturing;
  final bool permissionDenied;
  final String? validationError;
  final String? scanFeedback;
  final Future<void> Function()? onScanAll;
  final Future<void> Function()? onCaptureFront;
  final Future<void> Function()? onCaptureBack;
  final Future<void> Function()? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      key: const Key('player_form_id_capture_card'),
      decoration: BoxDecoration(
        color: KickPulseColors.surfaceElevated,
        borderRadius: KickPulseRadiiSpacing.cardBorderRadius,
        border: Border.all(
          color: validationError != null
              ? KickPulseColors.accentLive
              : KickPulseColors.borderSubtle,
        ),
      ),
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              const Icon(
                Icons.document_scanner_outlined,
                color: KickPulseColors.accentPrimary,
                size: 24,
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.playerDocumentCardTitle,
                      style: KickPulseTypography.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.playerDocumentCardSubtitle,
                      style: KickPulseTypography.captionMeta,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

          // Main Scan/Capture ID Button
          KickPulseButton(
            key: const Key('player_form_scan_id_button'),
            label: l10n.playerDocumentScanButton,
            icon: const Icon(Icons.camera_alt_outlined, color: Colors.black),
            isLoading: isCapturing,
            onPressed: (isScanning || isCapturing) ? null : onScanAll,
          ),

          // Permission Denied Banner
          if (permissionDenied) ...[
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
            Container(
              key: const Key('player_form_camera_permission_banner'),
              padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
              decoration: BoxDecoration(
                color: KickPulseColors.accentWarning.withAlpha(25),
                borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
                border: Border.all(
                  color: KickPulseColors.accentWarning.withAlpha(120),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: KickPulseColors.accentWarning,
                    size: 20,
                  ),
                  const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                  Expanded(
                    child: Text(
                      l10n.playerDocumentCameraPermissionDenied,
                      style: KickPulseTypography.captionMeta.copyWith(
                        color: KickPulseColors.accentWarning,
                      ),
                    ),
                  ),
                  const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                  TextButton(
                    key: const Key('player_form_open_settings_button'),
                    onPressed: onOpenSettings == null
                        ? null
                        : () async => onOpenSettings!(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.playerDocumentCameraPermissionOpenSettings,
                      style: KickPulseTypography.captionMeta.copyWith(
                        color: KickPulseColors.accentPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Scanning Indicator
          if (isScanning) ...[
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
            Row(
              key: const Key('player_form_id_scanning_indicator'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      KickPulseColors.accentPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                Text(
                  l10n.playerDocumentScanningIndicator,
                  style: KickPulseTypography.bodyPrimary.copyWith(
                    color: KickPulseColors.accentPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          // Scan Feedback Message
          if (scanFeedback != null && scanFeedback!.isNotEmpty) ...[
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
            Container(
              key: const Key('player_form_id_scan_feedback'),
              padding: const EdgeInsets.symmetric(
                horizontal: KickPulseRadiiSpacing.spaceSm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: KickPulseColors.accentPrimary.withAlpha(25),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: KickPulseColors.accentPrimary,
                    size: 16,
                  ),
                  const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                  Expanded(
                    child: Text(
                      scanFeedback!,
                      style: KickPulseTypography.captionMeta.copyWith(
                        color: KickPulseColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Validation Error
          if (validationError != null && validationError!.isNotEmpty) ...[
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
            Text(
              validationError!,
              key: const Key('player_form_id_images_error'),
              style: KickPulseTypography.bodyPrimary.copyWith(
                color: KickPulseColors.accentLive,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

          // Previews Row (Front and Back)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 280;
              final children = [
                Expanded(
                  flex: isNarrow ? 0 : 1,
                  child: _buildSidePreview(
                    context: context,
                    title: l10n.playerDocumentFrontSideLabel,
                    previewKey: const Key('player_form_id_front_preview'),
                    buttonKey: const Key('player_form_id_front_capture_btn'),
                    imagePath: capture.frontImagePath,
                    remoteUrl: capture.frontRemoteUrl,
                    hasImage: capture.hasFront,
                    onCapture: onCaptureFront,
                    captureLabel: l10n.playerDocumentCaptureFrontButton,
                    recaptureLabel: l10n.playerDocumentRecaptureButton,
                  ),
                ),
                SizedBox(
                  width: isNarrow ? 0 : KickPulseRadiiSpacing.spaceSm,
                  height: isNarrow ? KickPulseRadiiSpacing.spaceSm : 0,
                ),
                Expanded(
                  flex: isNarrow ? 0 : 1,
                  child: _buildSidePreview(
                    context: context,
                    title: l10n.playerDocumentBackSideLabel,
                    previewKey: const Key('player_form_id_back_preview'),
                    buttonKey: const Key('player_form_id_back_capture_btn'),
                    imagePath: capture.backImagePath,
                    remoteUrl: capture.backRemoteUrl,
                    hasImage: capture.hasBack,
                    onCapture: onCaptureBack,
                    captureLabel: l10n.playerDocumentCaptureBackButton,
                    recaptureLabel: l10n.playerDocumentRecaptureButton,
                  ),
                ),
              ];

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidePreview({
    required BuildContext context,
    required String title,
    required Key previewKey,
    required Key buttonKey,
    required String? imagePath,
    required String? remoteUrl,
    required bool hasImage,
    required Future<void> Function()? onCapture,
    required String captureLabel,
    required String recaptureLabel,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: KickPulseColors.surfaceBase,
        borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
        border: Border.all(
          color: hasImage
              ? KickPulseColors.accentPrimary.withAlpha(120)
              : KickPulseColors.borderSubtle,
        ),
      ),
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: KickPulseTypography.captionMeta.copyWith(
              color: KickPulseColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

          // Thumbnail Box
          Container(
            key: previewKey,
            height: 90,
            decoration: BoxDecoration(
              color: KickPulseColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: KickPulseColors.borderSubtle,
                style: hasImage ? BorderStyle.solid : BorderStyle.none,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildThumbnailImage(imagePath: imagePath, remoteUrl: remoteUrl),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

          // Individual Action Button
          OutlinedButton(
            key: buttonKey,
            onPressed: (isScanning || isCapturing || onCapture == null)
                ? null
                : () async => onCapture(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              side: const BorderSide(color: KickPulseColors.borderSubtle),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: Text(
              hasImage ? recaptureLabel : captureLabel,
              style: KickPulseTypography.captionMeta.copyWith(
                color: hasImage
                    ? KickPulseColors.textPrimary
                    : KickPulseColors.accentPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailImage({
    required String? imagePath,
    required String? remoteUrl,
  }) {
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
      );
    }

    if (remoteUrl != null && remoteUrl.isNotEmpty) {
      return Consumer(
        builder: (context, ref, _) {
          final resolvedAsync =
              ref.watch(resolveDocumentUrlProvider(remoteUrl));

          return resolvedAsync.when(
            data: (resolved) {
              if (resolved != null &&
                  (resolved.startsWith('http://') ||
                      resolved.startsWith('https://'))) {
                return Image.network(
                  resolved,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildSavedCloudPlaceholder(),
                );
              }
              if (resolved != null) {
                final file = File(resolved);
                if (file.existsSync()) {
                  return Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildSavedCloudPlaceholder(),
                  );
                }
              }
              return _buildSavedCloudPlaceholder();
            },
            loading: () => Container(
              color: KickPulseColors.surfaceElevated,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: KickPulseColors.accentPrimary,
                  ),
                ),
              ),
            ),
            error: (err, stack) => _buildSavedCloudPlaceholder(),
          );
        },
      );
    }

    return _buildPlaceholderIcon();
  }

  Widget _buildSavedCloudPlaceholder() {
    return Container(
      color: KickPulseColors.surfaceElevated,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_done_outlined,
              color: KickPulseColors.accentPrimary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              'Guardado',
              style: KickPulseTypography.captionMeta.copyWith(
                color: KickPulseColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(
        Icons.add_a_photo_outlined,
        color: KickPulseColors.textTertiary,
        size: 30,
      ),
    );
  }
}
