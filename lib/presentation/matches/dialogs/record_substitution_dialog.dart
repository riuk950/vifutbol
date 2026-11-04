import 'package:flutter/material.dart';
import '../../../domain/entities/registered_player.dart';
import '../../design_system/kick_pulse_colors.dart';
import '../../design_system/kick_pulse_radii_spacing.dart';
import '../../design_system/kick_pulse_typography.dart';

class RecordSubstitutionDialog extends StatefulWidget {
  const RecordSubstitutionDialog({
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
    RegisteredPlayer playerOut,
    RegisteredPlayer playerIn,
    int minute,
    String? notes,
  )
  onConfirm;

  @override
  State<RecordSubstitutionDialog> createState() =>
      _RecordSubstitutionDialogState();
}

class _RecordSubstitutionDialogState extends State<RecordSubstitutionDialog> {
  late String _selectedTeamId;
  late int _minute;
  RegisteredPlayer? _selectedPlayerOut;
  RegisteredPlayer? _selectedPlayerIn;
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
    _selectedPlayerOut = available.isNotEmpty ? available.first : null;
    _selectedPlayerIn = available.length > 1 ? available[1] : null;
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
    final availablePlayersIn = availablePlayers
        .where((p) => p.id != _selectedPlayerOut?.id)
        .toList();

    final bool canSubmit =
        _selectedPlayerOut != null &&
        _selectedPlayerIn != null &&
        _selectedPlayerOut!.id != _selectedPlayerIn!.id;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.swap_horiz, color: KickPulseColors.accentElectric),
          SizedBox(width: 8),
          Text('Registrar Sustitución'),
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
              const Text('Equipo', style: KickPulseTypography.captionMeta),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
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

              // Player Out Selection
              const Text(
                'Jugador que sale',
                style: KickPulseTypography.captionMeta,
              ),
              const SizedBox(height: 6),
              if (availablePlayers.isEmpty)
                const Text(
                  'No hay jugadores disponibles para sustitución.',
                  style: TextStyle(color: Colors.redAccent, fontSize: 13),
                )
              else
                DropdownButtonFormField<RegisteredPlayer>(
                  initialValue: _selectedPlayerOut,
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
                      _selectedPlayerOut = val;
                      if (_selectedPlayerIn?.id == val?.id) {
                        _selectedPlayerIn = null;
                      }
                    });
                  },
                ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

              // Player In Selection
              const Text(
                'Jugador que entra',
                style: KickPulseTypography.captionMeta,
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<RegisteredPlayer>(
                initialValue: _selectedPlayerIn,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: availablePlayersIn.map((player) {
                  return DropdownMenuItem(
                    value: player,
                    child: Text(
                      '#${player.shirtNumber} - ${player.fullName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedPlayerIn = val);
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
          label: const Text('Confirmar Sustitución'),
          style: FilledButton.styleFrom(
            backgroundColor: KickPulseColors.accentElectric,
            minimumSize: const Size(120, 48),
          ),
          onPressed: canSubmit
              ? () {
                  Navigator.of(context).pop();
                  widget.onConfirm(
                    _selectedTeamId,
                    _selectedPlayerOut!,
                    _selectedPlayerIn!,
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
