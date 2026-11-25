import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../design_system/kick_pulse_colors.dart';
import '../../design_system/kick_pulse_radii_spacing.dart';
import '../../design_system/kick_pulse_typography.dart';
import '../../design_system/widgets/kick_pulse_card.dart';

/// Legal document variants accessible offline from Profile.
enum ProfileLegalDocumentType { terms, privacyPolicy }

/// Immutable section model for legal document display.
class LegalDocumentSection {
  const LegalDocumentSection({required this.title, required this.body});

  final String title;
  final String body;
}

/// Dedicated offline reading screen for Terms & Conditions and Data Privacy Policy.
class ProfileLegalDocumentScreen extends StatelessWidget {
  const ProfileLegalDocumentScreen({super.key, required this.type});

  final ProfileLegalDocumentType type;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTerms = type == ProfileLegalDocumentType.terms;
    final title = isTerms
        ? l10n.profileTermsButton
        : l10n.profilePrivacyPolicyButton;
    final sections = isTerms
        ? <LegalDocumentSection>[
            LegalDocumentSection(
              title: l10n.termsSection1Title,
              body: l10n.termsSection1Body,
            ),
            LegalDocumentSection(
              title: l10n.termsSection2Title,
              body: l10n.termsSection2Body,
            ),
            LegalDocumentSection(
              title: l10n.termsSection3Title,
              body: l10n.termsSection3Body,
            ),
          ]
        : <LegalDocumentSection>[
            LegalDocumentSection(
              title: l10n.privacySection1Title,
              body: l10n.privacySection1Body,
            ),
            LegalDocumentSection(
              title: l10n.privacySection2Title,
              body: l10n.privacySection2Body,
            ),
            LegalDocumentSection(
              title: l10n.privacySection3Title,
              body: l10n.privacySection3Body,
            ),
          ];

    return Scaffold(
      backgroundColor: KickPulseColors.canvasBackground,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: KickPulseColors.surfaceBase,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.legalDocumentLastUpdated,
                style: const TextStyle(
                  color: KickPulseColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              for (var i = 0; i < sections.length; i++) ...[
                KickPulseCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sections[i].title,
                        style: KickPulseTypography.cardTitle,
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                      Text(
                        sections[i].body,
                        style: const TextStyle(
                          color: KickPulseColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < sections.length - 1)
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
