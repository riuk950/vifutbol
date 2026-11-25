import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../design_system/kick_pulse_colors.dart';
import '../../../design_system/kick_pulse_radii_spacing.dart';
import '../../../design_system/kick_pulse_typography.dart';
import '../../../design_system/widgets/kick_pulse_card.dart';
import '../profile_faq_screen.dart';
import '../profile_legal_document_screen.dart';
import 'remove_ads_dialog.dart';

/// Ordered section in Profile providing access to Remove Ads, Terms,
/// Data Privacy Policy, and FAQ with double-tap protection.
class ProfileLegalSupportSection extends StatefulWidget {
  const ProfileLegalSupportSection({super.key});

  @override
  State<ProfileLegalSupportSection> createState() =>
      _ProfileLegalSupportSectionState();
}

class _ProfileLegalSupportSectionState
    extends State<ProfileLegalSupportSection> {
  bool _isActionInProgress = false;

  Future<void> _runGuardedAction(Future<void> Function() action) async {
    if (_isActionInProgress) return;
    _isActionInProgress = true;
    try {
      await action();
    } finally {
      if (mounted) {
        _isActionInProgress = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.profileLegalSupportSectionTitle,
          style: KickPulseTypography.sectionHeader,
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
        KickPulseCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ProfileActionTile(
                key: const Key('profile_remove_ads_tile'),
                icon: Icons.workspace_premium_outlined,
                iconColor: KickPulseColors.accentWarning,
                label: l10n.profileRemoveAdsButton,
                onTap: () => _runGuardedAction(
                  () => RemoveAdsDialog.show(context),
                ),
              ),
              const Divider(
                height: 1,
                color: KickPulseColors.borderSubtle,
              ),
              _ProfileActionTile(
                key: const Key('profile_terms_tile'),
                icon: Icons.description_outlined,
                iconColor: KickPulseColors.accentElectric,
                label: l10n.profileTermsButton,
                onTap: () => _runGuardedAction(
                  () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileLegalDocumentScreen(
                        type: ProfileLegalDocumentType.terms,
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(
                height: 1,
                color: KickPulseColors.borderSubtle,
              ),
              _ProfileActionTile(
                key: const Key('profile_privacy_policy_tile'),
                icon: Icons.privacy_tip_outlined,
                iconColor: KickPulseColors.accentElectric,
                label: l10n.profilePrivacyPolicyButton,
                onTap: () => _runGuardedAction(
                  () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileLegalDocumentScreen(
                        type: ProfileLegalDocumentType.privacyPolicy,
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(
                height: 1,
                color: KickPulseColors.borderSubtle,
              ),
              _ProfileActionTile(
                key: const Key('profile_faq_tile'),
                icon: Icons.help_outline_rounded,
                iconColor: KickPulseColors.accentPrimary,
                label: l10n.profileFaqButton,
                onTap: () => _runGuardedAction(
                  () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileFaqScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KickPulseRadiiSpacing.spaceMd,
            vertical: KickPulseRadiiSpacing.spaceSm,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: KickPulseColors.surfaceElevated,
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceMd),
              Expanded(
                child: Text(
                  label,
                  style: KickPulseTypography.cardTitle,
                ),
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
              const Icon(
                Icons.chevron_right,
                color: KickPulseColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
