import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_news_category.dart';
import 'package:vifutbol/domain/entities/tournament_news_item.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

class CreateNewsDialog extends StatefulWidget {
  const CreateNewsDialog({
    super.key,
    required this.tournamentId,
    required this.authorUserId,
    required this.authorName,
    this.availableTournaments,
  });

  final String tournamentId;
  final String authorUserId;
  final String authorName;
  final List<ChampionshipTournament>? availableTournaments;

  static Future<TournamentNewsItem?> show({
    required BuildContext context,
    required String tournamentId,
    required String authorUserId,
    required String authorName,
    List<ChampionshipTournament>? availableTournaments,
  }) {
    return showDialog<TournamentNewsItem>(
      context: context,
      builder: (context) => CreateNewsDialog(
        tournamentId: tournamentId,
        authorUserId: authorUserId,
        authorName: authorName,
        availableTournaments: availableTournaments,
      ),
    );
  }

  @override
  State<CreateNewsDialog> createState() => _CreateNewsDialogState();
}

class _CreateNewsDialogState extends State<CreateNewsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  late String _selectedTournamentId;
  TournamentNewsCategory _category = TournamentNewsCategory.general;
  bool _isPinned = false;

  @override
  void initState() {
    super.initState();
    final available = widget.availableTournaments;
    if (available != null && available.isNotEmpty) {
      final exists = available.any((t) => t.id == widget.tournamentId);
      _selectedTournamentId = exists ? widget.tournamentId : available.first.id;
    } else {
      _selectedTournamentId = widget.tournamentId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() != true) return;

    final item = TournamentNewsItem(
      id: const Uuid().v4(),
      tournamentId: _selectedTournamentId,
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      category: _category,
      publishedAt: DateTime.now(),
      authorUserId: widget.authorUserId,
      authorName: widget.authorName,
      isPinned: _isPinned,
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasTournaments =
        widget.availableTournaments != null &&
        widget.availableTournaments!.isNotEmpty;

    return AlertDialog(
      backgroundColor: KickPulseColors.surfaceElevated,
      title: Text(
        l10n.newsCreateDialogTitle,
        style: KickPulseTypography.cardTitle,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tournament Selector if availableTournaments provided
              if (hasTournaments) ...[
                DropdownButtonFormField<String>(
                  key: const Key('create_news_tournament_dropdown'),
                  initialValue: _selectedTournamentId.isNotEmpty
                      ? _selectedTournamentId
                      : widget.availableTournaments!.first.id,
                  decoration: InputDecoration(
                    labelText: l10n.newsTournamentField,
                    labelStyle: KickPulseTypography.captionMeta,
                    border: const OutlineInputBorder(),
                  ),
                  items: widget.availableTournaments!.map((t) {
                    return DropdownMenuItem<String>(
                      value: t.id,
                      child: Text(
                        t.name,
                        style: KickPulseTypography.bodyPrimary,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedTournamentId = val);
                    }
                  },
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              ],

              // Title Field
              TextFormField(
                key: const Key('create_news_title_field'),
                controller: _titleController,
                style: KickPulseTypography.bodyPrimary,
                decoration: InputDecoration(
                  labelText: l10n.newsTitleField,
                  labelStyle: KickPulseTypography.captionMeta,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.length < 3 || trimmed.length > 120) {
                    return l10n.newsTitleValidation;
                  }
                  return null;
                },
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

              // Category Selector
              DropdownButtonFormField<TournamentNewsCategory>(
                key: const Key('create_news_category_dropdown'),
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: l10n.newsCategoryField,
                  labelStyle: KickPulseTypography.captionMeta,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: TournamentNewsCategory.general,
                    child: Text(l10n.newsCategoryGeneral),
                  ),
                  DropdownMenuItem(
                    value: TournamentNewsCategory.disciplinary,
                    child: Text(l10n.newsCategoryDisciplinary),
                  ),
                  DropdownMenuItem(
                    value: TournamentNewsCategory.rescheduling,
                    child: Text(l10n.newsCategoryRescheduling),
                  ),
                ],
                onChanged: (cat) {
                  if (cat != null) {
                    setState(() => _category = cat);
                  }
                },
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

              // Body Field
              TextFormField(
                key: const Key('create_news_body_field'),
                controller: _bodyController,
                style: KickPulseTypography.bodyPrimary,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.newsBodyField,
                  labelStyle: KickPulseTypography.captionMeta,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.length < 5 || trimmed.length > 3000) {
                    return l10n.newsBodyValidation;
                  }
                  return null;
                },
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

              // Pinned Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.newsPinnedField,
                  style: KickPulseTypography.captionMeta,
                ),
                value: _isPinned,
                activeThumbColor: KickPulseColors.accentPrimary,
                onChanged: (val) => setState(() => _isPinned = val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: KickPulseTypography.captionMeta.copyWith(
              color: KickPulseColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          key: const Key('create_news_submit_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: KickPulseColors.accentPrimary,
            foregroundColor: KickPulseColors.surfaceBase,
          ),
          onPressed: _onSubmit,
          child: Text(l10n.newsPublishSubmit),
        ),
      ],
    );
  }
}
