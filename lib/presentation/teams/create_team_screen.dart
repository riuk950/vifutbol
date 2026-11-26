import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/teams/widgets/kick_pulse_team_crest.dart';

/// Curated athletic color palette for distinctive team registration.
const List<int> kTeamDistinctiveColorPalette = <int>[
  0xFF00E676, // Emerald
  0xFF0A0E17, // Midnight
  0xFF2979FF, // Electric Blue
  0xFFFF1744, // Crimson Red
  0xFFFFD600, // Gold Yellow
  0xFFFF6D00, // Vibrant Orange
  0xFF00B0FF, // Sky Cyan
  0xFF7C4DFF, // Royal Purple
  0xFFFFFFFF, // Pure White
  0xFF1B5E20, // Forest Green
  0xFFAD1457, // Burgundy
  0xFF37474F, // Slate Steel
];

/// Dedicated full-screen page for registering a detailed team with
/// name, auto-suggested short code, delegate, founded date, distinctive colors,
/// live club preview, and optional tournament enrollment.
class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => CreateTeamScreenState();
}

class CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _shortCodeController;
  late final TextEditingController _delegateController;

  bool _shortCodeEditedManually = false;
  bool _isDirty = false;
  bool _submittedOnce = false;
  bool _isSubmitting = false;

  DateTime? _foundedDate;
  String? _selectedTournamentId;
  int _primaryColorHex = kTeamDistinctiveColorPalette[0];
  int _secondaryColorHex = kTeamDistinctiveColorPalette[1];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _shortCodeController = TextEditingController();
    _delegateController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortCodeController.dispose();
    _delegateController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  String _suggestShortCode(String rawName) {
    final words = rawName
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    if (words.length >= 2) {
      final initials = words.map((w) => w[0]).take(4).join();
      if (initials.length >= 2) return initials;
    }
    final compact = words.join();
    if (compact.length <= 3) return compact;
    return compact.substring(0, 3);
  }

  void _onTeamNameChanged(String value) {
    if (!_shortCodeEditedManually) {
      final suggested = _suggestShortCode(value);
      _shortCodeController.value = TextEditingValue(
        text: suggested,
        selection: TextSelection.collapsed(offset: suggested.length),
      );
    }
    setState(() {
      _isDirty = true;
      _errorMessage = null;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty || _isSubmitting) return true;
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KickPulseColors.surfaceElevated,
        title: Text(
          l10n.createTeamUnsavedChangesTitle,
          style: KickPulseTypography.cardTitle,
        ),
        content: Text(
          l10n.createTeamUnsavedChangesMessage,
          style: KickPulseTypography.bodyPrimary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.createTeamUnsavedChangesKeep,
              style: const TextStyle(color: KickPulseColors.textSecondary),
            ),
          ),
          KickPulseButton(
            label: l10n.createTeamUnsavedChangesDiscard,
            variant: KickPulseButtonVariant.secondary,
            onPressed: () async => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _pickFoundedDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = _foundedDate ?? today;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(today) ? today : initialDate,
      firstDate: DateTime(1900, 1, 1),
      lastDate: today,
      locale: const Locale('es'),
    );

    if (picked != null && mounted) {
      setState(() {
        _foundedDate = picked;
        _isDirty = true;
        _errorMessage = null;
      });
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String? _foundedDateErrorText(AppLocalizations l10n) {
    if (_foundedDate == null) {
      return _submittedOnce ? l10n.createTeamFoundedDateRequired : null;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalized = DateTime(
      _foundedDate!.year,
      _foundedDate!.month,
      _foundedDate!.day,
    );
    if (normalized.isAfter(today)) {
      return l10n.createTeamFoundedDateFutureError;
    }
    return null;
  }

  bool get _hasDistinctColors => _primaryColorHex != _secondaryColorHex;

  void _selectPrimaryColor(int colorHex, AppLocalizations l10n) {
    if (colorHex == _secondaryColorHex) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.createTeamDistinctColorsError),
            backgroundColor: KickPulseColors.accentWarning,
          ),
        );
      return;
    }
    setState(() {
      _primaryColorHex = colorHex;
      _isDirty = true;
      _errorMessage = null;
    });
  }

  void _selectSecondaryColor(int colorHex, AppLocalizations l10n) {
    if (colorHex == _primaryColorHex) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.createTeamDistinctColorsError),
            backgroundColor: KickPulseColors.accentWarning,
          ),
        );
      return;
    }
    setState(() {
      _secondaryColorHex = colorHex;
      _isDirty = true;
      _errorMessage = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    final l10n = AppLocalizations.of(context);
    final authState = ref.read(authControllerProvider);
    final actorRole = authState.session?.user.activeRole ?? UserRole.fan;

    if (actorRole != UserRole.coach && actorRole != UserRole.organizer) {
      setState(() => _errorMessage = l10n.unauthorizedTeamCreationMessage);
      return;
    }

    setState(() {
      _submittedOnce = true;
      _errorMessage = null;
    });

    final formValid = _formKey.currentState?.validate() ?? false;
    final foundedError = _foundedDateErrorText(l10n);
    if (!formValid || foundedError != null || !_hasDistinctColors) {
      if (!_hasDistinctColors) {
        setState(() => _errorMessage = l10n.createTeamDistinctColorsError);
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final tournamentsState = ref.read(tournamentsControllerProvider);
      final selectedTournament = _selectedTournamentId != null
          ? tournamentsState.tournaments
              .where((t) => t.id == _selectedTournamentId)
              .firstOrNull
          : null;

      final coachId = authState.session?.user.id ?? 'coach-seed-1';
      final teamName = _nameController.text.trim();
      final shortCode = _shortCodeController.text.trim().toUpperCase();
      final delegateName = _delegateController.text.trim();

      final success = await ref
          .read(teamsControllerProvider.notifier)
          .createTeam(
            name: teamName,
            shortCode: shortCode,
            delegateName: delegateName,
            foundedDate: _foundedDate,
            primaryColorHex: _primaryColorHex,
            secondaryColorHex: _secondaryColorHex,
            tournament: selectedTournament,
            coachId: coachId,
            actorRole: actorRole,
          );

      if (!mounted) return;

      if (success) {
        _isDirty = false;
        _isSubmitting = false;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.createTeamSuccessMessage(teamName)),
              backgroundColor: KickPulseColors.accentPrimary,
            ),
          );
        Navigator.of(context).pop(true);
      } else {
        final teamsState = ref.read(teamsControllerProvider);
        setState(() {
          _isSubmitting = false;
          _errorMessage =
              teamsState.lastFailure?.message ??
              l10n.unauthorizedTeamCreationMessage;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = l10n.unauthorizedTeamCreationMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);
    final actorRole = authState.session?.user.activeRole ?? UserRole.fan;
    final isAuthorized =
        actorRole == UserRole.coach || actorRole == UserRole.organizer;

    final tournamentsState = ref.watch(tournamentsControllerProvider);
    final openTournaments = tournamentsState.tournaments
        .where((t) => t.status == TournamentStatus.openRegistration)
        .toList();
    final isSaving =
        _isSubmitting || ref.watch(teamsControllerProvider).isSaving;

    final previewName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : l10n.createTeamNameLabel;
    final previewShortCode = _shortCodeController.text.trim().isNotEmpty
        ? _shortCodeController.text.trim().toUpperCase()
        : 'EQ';

    return PopScope(
      canPop: !_isDirty || isSaving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: KickPulseColors.canvasBackground,
        appBar: AppBar(
          title: Text(
            l10n.createTeamScreenTitle,
            style: KickPulseTypography.screenTitle,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: !isAuthorized
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
                    child: KickPulseCard(
                      key: const Key('create_team_unauthorized_banner'),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 40,
                            color: KickPulseColors.accentWarning,
                          ),
                          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                          Text(
                            l10n.unauthorizedTeamCreationMessage,
                            textAlign: TextAlign.center,
                            style: KickPulseTypography.bodyPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    key: const Key('create_team_screen'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: KickPulseRadiiSpacing.spaceMd,
                      vertical: KickPulseRadiiSpacing.spaceSm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.createTeamScreenSubtitle,
                          style: const TextStyle(
                            color: KickPulseColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

                        if (_errorMessage != null) ...[
                          Container(
                            key: const Key('create_team_error_banner'),
                            padding: const EdgeInsets.all(
                              KickPulseRadiiSpacing.spaceMd,
                            ),
                            decoration: BoxDecoration(
                              color: KickPulseColors.accentLive.withAlpha(25),
                              border: Border.all(
                                color: KickPulseColors.accentLive.withAlpha(120),
                              ),
                              borderRadius: BorderRadius.circular(
                                KickPulseRadiiSpacing.cardRadius,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: KickPulseColors.accentLive,
                                ),
                                const SizedBox(
                                  width: KickPulseRadiiSpacing.spaceSm,
                                ),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: KickPulseTypography.bodyPrimary
                                        .copyWith(
                                      color: KickPulseColors.accentLive,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                        ],

                        // 1. Live Identity Preview Card
                        KickPulseCard(
                          key: const Key('create_team_identity_preview'),
                          child: Row(
                            children: [
                              KickPulseTeamCrest(
                                shortCode: previewShortCode,
                                primaryColorHex: _primaryColorHex,
                                secondaryColorHex: _secondaryColorHex,
                                size: 60,
                              ),
                              const SizedBox(
                                width: KickPulseRadiiSpacing.spaceMd,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.createTeamIdentityPreviewTitle,
                                      style: const TextStyle(
                                        color: KickPulseColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      previewName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: KickPulseTypography.cardTitle,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: Color(_primaryColorHex),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  KickPulseColors.borderStrong,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: Color(_secondaryColorHex),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  KickPulseColors.borderStrong,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          previewShortCode,
                                          style: const TextStyle(
                                            color: KickPulseColors.textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

                        // 2. Team Identity & Institutional Fields
                        KickPulseCard(
                          child: Column(
                            children: [
                              TextFormField(
                                key: const Key('create_team_name_input'),
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                onChanged: _onTeamNameChanged,
                                style: KickPulseTypography.bodyPrimary,
                                decoration: InputDecoration(
                                  labelText: l10n.createTeamNameLabel,
                                  prefixIcon: const Icon(Icons.shield_outlined),
                                ),
                                validator: (value) {
                                  final trimmed = value?.trim() ?? '';
                                  if (trimmed.length < 3) {
                                    return 'El nombre del equipo debe tener al menos 3 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(
                                height: KickPulseRadiiSpacing.spaceMd,
                              ),
                              TextFormField(
                                key: const Key('create_team_short_code_input'),
                                controller: _shortCodeController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                maxLength: 4,
                                onChanged: (_) {
                                  _shortCodeEditedManually = true;
                                  setState(() {
                                    _isDirty = true;
                                    _errorMessage = null;
                                  });
                                },
                                style: KickPulseTypography.bodyPrimary,
                                decoration: InputDecoration(
                                  labelText: l10n.createTeamShortCodeLabel,
                                  helperText: l10n.createTeamShortCodeHelper,
                                  prefixIcon: const Icon(Icons.tag),
                                ),
                                validator: (value) {
                                  final trimmed = value?.trim() ?? '';
                                  if (trimmed.length < 2 ||
                                      trimmed.length > 4) {
                                    return 'La sigla debe tener entre 2 y 4 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(
                                height: KickPulseRadiiSpacing.spaceMd,
                              ),
                              TextFormField(
                                key: const Key('create_team_delegate_input'),
                                controller: _delegateController,
                                textCapitalization: TextCapitalization.words,
                                onChanged: (_) => _markDirty(),
                                style: KickPulseTypography.bodyPrimary,
                                decoration: InputDecoration(
                                  labelText: l10n.createTeamDelegateLabel,
                                  hintText: l10n.createTeamDelegateHint,
                                  prefixIcon: const Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return l10n.createTeamDelegateRequired;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(
                                height: KickPulseRadiiSpacing.spaceMd,
                              ),
                              InkWell(
                                key: const Key('create_team_founded_date_field'),
                                onTap: () => _pickFoundedDate(context),
                                borderRadius: BorderRadius.circular(
                                  KickPulseRadiiSpacing.chipRadius,
                                ),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: l10n.createTeamFoundedDateLabel,
                                    prefixIcon: const Icon(
                                      Icons.calendar_today_outlined,
                                    ),
                                    errorText: _foundedDateErrorText(l10n),
                                  ),
                                  child: Text(
                                    _foundedDate != null
                                        ? _formatDate(_foundedDate!)
                                        : l10n.createTeamFoundedDateHint,
                                    style: KickPulseTypography.bodyPrimary
                                        .copyWith(
                                      color: _foundedDate != null
                                          ? KickPulseColors.textPrimary
                                          : KickPulseColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

                        // 3. Distinctive Colors Selector
                        KickPulseCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.createTeamColorsSectionTitle,
                                style: KickPulseTypography.sectionHeader,
                              ),
                              const SizedBox(
                                height: KickPulseRadiiSpacing.spaceMd,
                              ),
                              Text(
                                l10n.createTeamPrimaryColorLabel,
                                style: KickPulseTypography.captionMeta.copyWith(
                                  color: KickPulseColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(
                                height: KickPulseRadiiSpacing.spaceSm,
                              ),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: kTeamDistinctiveColorPalette
                                    .map(
                                      (hex) => _ColorSwatchTile(
                                        key: Key(
                                          'create_team_primary_color_${hex.toRadixString(16)}',
                                        ),
                                        colorHex: hex,
                                        isSelected: _primaryColorHex == hex,
                                        isDisabled: _secondaryColorHex == hex,
                                        onTap: () =>
                                            _selectPrimaryColor(hex, l10n),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                              const SizedBox(
                                height: KickPulseRadiiSpacing.spaceMd,
                              ),
                              Text(
                                l10n.createTeamSecondaryColorLabel,
                                style: KickPulseTypography.captionMeta.copyWith(
                                  color: KickPulseColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(
                                height: KickPulseRadiiSpacing.spaceSm,
                              ),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: kTeamDistinctiveColorPalette
                                    .map(
                                      (hex) => _ColorSwatchTile(
                                        key: Key(
                                          'create_team_secondary_color_${hex.toRadixString(16)}',
                                        ),
                                        colorHex: hex,
                                        isSelected: _secondaryColorHex == hex,
                                        isDisabled: _primaryColorHex == hex,
                                        onTap: () =>
                                            _selectSecondaryColor(hex, l10n),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

                        // 4. Optional Tournament Enrollment
                        KickPulseCard(
                          child: DropdownButtonFormField<String?>(
                            key: const Key('create_team_tournament_dropdown'),
                            isExpanded: true,
                            initialValue: _selectedTournamentId,
                            dropdownColor: KickPulseColors.surfaceElevated,
                            style: KickPulseTypography.bodyPrimary,
                            decoration: InputDecoration(
                              labelText: l10n.createTeamTournamentLabel,
                              prefixIcon: const Icon(
                                Icons.emoji_events_outlined,
                              ),
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(l10n.createTeamNoTournamentOption),
                              ),
                              ...openTournaments.map(
                                (tourn) => DropdownMenuItem<String?>(
                                  value: tourn.id,
                                  child: Text(
                                    tourn.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedTournamentId = val;
                                _isDirty = true;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

                        KickPulseButton(
                          key: const Key('create_team_submit_button'),
                          label: l10n.createTeamSubmitButton,
                          icon: const Icon(Icons.check, size: 18),
                          isLoading: isSaving,
                          isFullWidth: true,
                          onPressed: isSaving ? null : _handleSubmit,
                        ),
                        const SizedBox(height: KickPulseRadiiSpacing.spaceXl),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _ColorSwatchTile extends StatelessWidget {
  const _ColorSwatchTile({
    super.key,
    required this.colorHex,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  final int colorHex;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(colorHex);
    final checkColor = color.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: !isDisabled,
      label: 'Color ${colorHex.toRadixString(16)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Opacity(
          opacity: isDisabled ? 0.3 : 1.0,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? KickPulseColors.accentPrimary
                    : KickPulseColors.borderStrong,
                width: isSelected ? 3 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: KickPulseColors.accentPrimary.withAlpha(110),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(Icons.check, size: 18, color: checkColor)
                : (isDisabled
                    ? Icon(Icons.block, size: 14, color: checkColor)
                    : null),
          ),
        ),
      ),
    );
  }
}
