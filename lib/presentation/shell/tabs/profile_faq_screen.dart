import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../design_system/kick_pulse_colors.dart';
import '../../design_system/kick_pulse_radii_spacing.dart';
import '../../design_system/kick_pulse_typography.dart';
import '../../design_system/widgets/kick_pulse_card.dart';

/// Immutable FAQ entry displayed on [ProfileFaqScreen].
class FaqItem {
  const FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

/// Dedicated offline Frequently Asked Questions screen accessible from Profile.
class ProfileFaqScreen extends StatelessWidget {
  const ProfileFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <FaqItem>[
      FaqItem(question: l10n.faqItem1Question, answer: l10n.faqItem1Answer),
      FaqItem(question: l10n.faqItem2Question, answer: l10n.faqItem2Answer),
      FaqItem(question: l10n.faqItem3Question, answer: l10n.faqItem3Answer),
      FaqItem(question: l10n.faqItem4Question, answer: l10n.faqItem4Answer),
    ];

    return Scaffold(
      backgroundColor: KickPulseColors.canvasBackground,
      appBar: AppBar(
        title: Text(l10n.profileFaqButton),
        backgroundColor: KickPulseColors.surfaceBase,
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
          itemCount: items.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          itemBuilder: (context, index) {
            final item = items[index];
            return KickPulseCard(
              padding: EdgeInsets.zero,
              child: Material(
                color: Colors.transparent,
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: index == 0,
                    iconColor: KickPulseColors.accentPrimary,
                    collapsedIconColor: KickPulseColors.textSecondary,
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: KickPulseRadiiSpacing.spaceMd,
                      vertical: KickPulseRadiiSpacing.spaceXs,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(
                      KickPulseRadiiSpacing.spaceMd,
                      0,
                      KickPulseRadiiSpacing.spaceMd,
                      KickPulseRadiiSpacing.spaceMd,
                    ),
                    title: Text(
                      item.question,
                      style: KickPulseTypography.cardTitle,
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.answer,
                          style: const TextStyle(
                            color: KickPulseColors.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
