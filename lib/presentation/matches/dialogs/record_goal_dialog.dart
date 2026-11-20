import 'package:material_ui/material_ui.dart';
import '../../../domain/entities/registered_player.dart';
import '../../design_system/kick_pulse_colors.dart';
import '../../design_system/kick_pulse_radii_spacing.dart';
import '../../design_system/kick_pulse_typography.dart';

class RecordGoalDialog extends StatefulWidget {
  const RecordGoalDialog({
    super.key,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.awayTeamId,
    required this.awayTeamName,
    required this.homePlayers,
    required this.awayPlayers,
    required this.expelledPlayerIds,
    required this.initialMinute,
    required this.onConfirm,
  });

  final String homeTeamId;
  final String homeTeamName;
  final String awayTeamId;
  final String awayTeamName;
  final List<RegisteredPlayer> homePlayers;
  final List<RegisteredPlayer> awayPlayers;
  final Set<String> expelledPlayerIds;
  final int initialMinute;
  final void Function(
    String teamId,
    RegisteredPlayer scorer,
    RegisteredPlayer? assistant,
    int minute,
    String? notes,
  )
  onConfirm;

  @override
  State<RecordGoalDialog> createState() => _RecordGoalDialogState();
}

class _RecordGoalDialogState extends State<RecordGoalDialog> {
  late String _selectedTeamId;
  late int _minute;
  RegisteredPlayer? _selectedScorer;
  RegisteredPlayer? _selectedAssistant;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTeamId = widget.homeTeamId;
    _minute = widget.initialMinute.clamp(1, 130);
    _initDefaultPlayers();
  }

  void _initDefaultPlayers() {
    final available = _currentAvailablePlayers;
    _selectedScorer = available.isNotEmpty ? available.first : null;
    _selectedAssistant = null;
  }

  List<RegisteredPlayer> get _currentAvailablePlayers {
    final list = _selectedTeamId == widget.homeTeamId
        ? widget.homePlayers
        : widget.awayPlayers;
    return list.where((p) => !widget.expelledPlayerIds.contains(p.id)).toList();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availablePlayers = _currentAvailablePlayers;
    final availableAssistants = availablePlayers
        .where((p) => p.id != _selectedScorer?.id)
        .toList();

    return AlertDialog(
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_soccer, color: KickPulseColors.accentLive),
          SizedBox(width: 8),
          Flexible(
            child: Text('Registrar Gol', overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Team Selection
              const Text(
                'Equipo Anotador',
                style: KickPulseTypography.captionMeta,
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                key: const Key('record_goal_team_dropdown'),
                initialValue: _selectedTeamId,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: widget.homeTeamId,
                    child: Text(
                      widget.homeTeamName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: widget.awayTeamId,
                    child: Text(
                      widget.awayTeamName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null && val != _selectedTeamId) {
                    setState(() {
                      _selectedTeamId = val;
                      _initDefaultPlayers();
                    });
                  }
                },
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

              // Minute selection
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Minuto de juego',
                      style: KickPulseTypography.bodyPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    onPressed: _minute > 1
                        ? () => setState(() => _minute--)
                        : null,
                  ),
                  Text(
                    '$_minute\'',
                    style: KickPulseTypography.cardTitle.copyWith(fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    onPressed: _minute < 130
                        ? () => setState(() => _minute++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

              // Scorer Selection
              const Text(
                'Jugador Anotador',
                style: KickPulseTypography.captionMeta,
              ),
              const SizedBox(height: 6),
              if (availablePlayers.isEmpty)
                const Text(
                  'No hay jugadores disponibles para anotar en este equipo.',
                  style: TextStyle(color: Colors.redAccent, fontSize: 13),
                )
              else
                DropdownButtonFormField<RegisteredPlayer>(
                  key: const Key('record_goal_scorer_dropdown'),
                  initialValue: _selectedScorer,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: availablePlayers.map((player) {
                    return DropdownMenuItem(
                      value: player,
                      child: Text(
                        '#${player.shirtNumber} - ${player.fullName}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedScorer = val;
                      if (_selectedAssistant?.id == val?.id) {
                        _selectedAssistant = null;
                      }
                    });
                  },
                ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

              // Assistant Selection (Optional)
              const Text(
                'Asistente (opcional)',
                style: KickPulseTypography.captionMeta,
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<RegisteredPlayer?>(
                key: const Key('record_goal_assistant_dropdown'),
                initialValue: _selectedAssistant,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: [
                  const DropdownMenuItem<RegisteredPlayer?>(
                    value: null,
                    child: Text('Sin asistencia'),
                  ),
                  ...availableAssistants.map((player) {
                    return DropdownMenuItem<RegisteredPlayer?>(
                      value: player,
                      child: Text(
                        '#${player.shirtNumber} - ${player.fullName}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: (val) {
                  setState(() => _selectedAssistant = val);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('Confirmar Gol'),
          style: FilledButton.styleFrom(
            backgroundColor: KickPulseColors.accentLive,
            minimumSize: const Size(120, 48),
          ),
          onPressed: _selectedScorer != null
              ? () {
                  Navigator.of(context).pop();
                  widget.onConfirm(
                    _selectedTeamId,
                    _selectedScorer!,
                    _selectedAssistant,
                    _minute,
                    _notesController.text.trim().isNotEmpty
                        ? _notesController.text.trim()
                        : null,
                  );
                }
              : null,
        ),
      ],
    );
  }
}
