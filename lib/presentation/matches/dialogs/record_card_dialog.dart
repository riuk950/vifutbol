import 'package:material_ui/material_ui.dart';
import '../../../domain/entities/digital_match_report.dart';
import '../../../domain/entities/registered_player.dart';
import '../../design_system/kick_pulse_colors.dart';
import '../../design_system/kick_pulse_radii_spacing.dart';
import '../../design_system/kick_pulse_typography.dart';

class RecordCardDialog extends StatefulWidget {
  const RecordCardDialog({
    super.key,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.awayTeamId,
    required this.awayTeamName,
    required this.homePlayers,
    required this.awayPlayers,
    required this.report,
    required this.initialMinute,
    this.initialIsDirectRed = false,
    required this.onConfirm,
  });

  final String homeTeamId;
  final String homeTeamName;
  final String awayTeamId;
  final String awayTeamName;
  final List<RegisteredPlayer> homePlayers;
  final List<RegisteredPlayer> awayPlayers;
  final DigitalMatchReport report;
  final int initialMinute;
  final bool initialIsDirectRed;
  final void Function(
    String teamId,
    RegisteredPlayer player,
    bool isDirectRed,
    int minute,
    String? notes,
  )
  onConfirm;

  @override
  State<RecordCardDialog> createState() => _RecordCardDialogState();
}

class _RecordCardDialogState extends State<RecordCardDialog> {
  late String _selectedTeamId;
  late int _minute;
  late bool _isDirectRed;
  RegisteredPlayer? _selectedPlayer;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTeamId = widget.homeTeamId;
    _minute = widget.initialMinute.clamp(1, 130);
    _isDirectRed = widget.initialIsDirectRed;
    _initDefaultPlayer();
  }

  void _initDefaultPlayer() {
    final available = _currentAvailablePlayers;
    _selectedPlayer = available.isNotEmpty ? available.first : null;
  }

  List<RegisteredPlayer> get _currentAvailablePlayers {
    final list = _selectedTeamId == widget.homeTeamId
        ? widget.homePlayers
        : widget.awayPlayers;
    return list.where((p) => !widget.report.isPlayerExpelled(p.id)).toList();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availablePlayers = _currentAvailablePlayers;
    final int currentYellows = _selectedPlayer != null
        ? widget.report.yellowCardCountForPlayer(_selectedPlayer!.id)
        : 0;
    final bool willTriggerSecondYellowExpulsion =
        !_isDirectRed && currentYellows == 1;

    return AlertDialog(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isDirectRed ? Icons.dangerous : Icons.style,
            color: _isDirectRed ? KickPulseColors.accentLive : Colors.amber,
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'Tarjeta Disciplinaria',
              overflow: TextOverflow.ellipsis,
            ),
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
              // Card type selection
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Amarilla'),
                    icon: Icon(Icons.style, color: Colors.amber),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Roja Directa'),
                    icon: Icon(
                      Icons.dangerous,
                      color: KickPulseColors.accentLive,
                    ),
                  ),
                ],
                selected: {_isDirectRed},
                onSelectionChanged: (val) {
                  setState(() => _isDirectRed = val.first);
                },
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

              // Team Selection
              const Text('Equipo', style: KickPulseTypography.captionMeta),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                key: const Key('record_card_team_dropdown'),
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
                      _initDefaultPlayer();
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

              // Player Selection
              const Text(
                'Jugador sancionado',
                style: KickPulseTypography.captionMeta,
              ),
              const SizedBox(height: 6),
              if (availablePlayers.isEmpty)
                const Text(
                  'No hay jugadores disponibles para sancionar en este equipo.',
                  style: TextStyle(color: Colors.redAccent, fontSize: 13),
                )
              else
                DropdownButtonFormField<RegisteredPlayer>(
                  key: const Key('record_card_player_dropdown'),
                  initialValue: _selectedPlayer,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: availablePlayers.map((player) {
                    final yellows = widget.report.yellowCardCountForPlayer(
                      player.id,
                    );
                    final yellowBadge = yellows > 0 ? ' [1🟨]' : '';
                    return DropdownMenuItem(
                      value: player,
                      child: Text(
                        '#${player.shirtNumber} - ${player.fullName}$yellowBadge',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedPlayer = val);
                  },
                ),

              // Double Yellow Warning
              if (willTriggerSecondYellowExpulsion) ...[
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                Container(
                  padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
                  decoration: BoxDecoration(
                    color: KickPulseColors.accentLive.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(
                      KickPulseRadiiSpacing.chipRadius,
                    ),
                    border: Border.all(color: KickPulseColors.accentLive),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: KickPulseColors.accentLive,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '¡Segunda amarilla! Se generará la expulsión automática por tarjeta roja.',
                          style: TextStyle(
                            color: KickPulseColors.accentLive,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
          label: Text(
            willTriggerSecondYellowExpulsion
                ? 'Confirmar Expulsión'
                : 'Confirmar Tarjeta',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _isDirectRed || willTriggerSecondYellowExpulsion
                ? KickPulseColors.accentLive
                : Colors.amber.shade800,
            minimumSize: const Size(120, 48),
          ),
          onPressed: _selectedPlayer != null
              ? () {
                  Navigator.of(context).pop();
                  widget.onConfirm(
                    _selectedTeamId,
                    _selectedPlayer!,
                    _isDirectRed,
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
