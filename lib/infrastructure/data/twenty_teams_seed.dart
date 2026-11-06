import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';

/// Generador de datos semilla con 20 equipos realistas
/// y 18 jugadores registrados por equipo (total 360 jugadores).
class TwentyTeamsSeedData {
  TwentyTeamsSeedData._();

  static const List<_TeamMetadata> _teamMetas = [
    _TeamMetadata(
      'atletico-norte',
      'atn',
      'Atlético Norte FC',
      'ATN',
      TeamCrestShape.shield,
      0xFF00E676,
      0xFF0A0E17,
    ),
    _TeamMetadata(
      'real-sabana',
      'rsc',
      'Real Sabana Club',
      'RSC',
      TeamCrestShape.hexagon,
      0xFF2979FF,
      0xFF1A237E,
    ),
    _TeamMetadata(
      'huracan-del-sur',
      'hds',
      'Huracán del Sur',
      'HDS',
      TeamCrestShape.diamond,
      0xFFEF4444,
      0xFF1E293B,
    ),
    _TeamMetadata(
      'deportivo-calixto',
      'dca',
      'Deportivo Calixto',
      'DCA',
      TeamCrestShape.hexagon,
      0xFFF59E0B,
      0xFF18181B,
    ),
    _TeamMetadata(
      'estudiantes-fc',
      'efc',
      'Estudiantes FC',
      'EFC',
      TeamCrestShape.shield,
      0xFF8B5CF6,
      0xFF0F172A,
    ),
    _TeamMetadata(
      'pumas-central',
      'pmc',
      'Pumas Central',
      'PMC',
      TeamCrestShape.circle,
      0xFFF97316,
      0xFF1C1917,
    ),
    _TeamMetadata(
      'inter-san-juan',
      'isj',
      'Inter San Juan',
      'ISJ',
      TeamCrestShape.diamond,
      0xFF06B6D4,
      0xFF022C22,
    ),
    _TeamMetadata(
      'deportivo-olimpo',
      'cdo',
      'Club Deportivo Olimpo',
      'CDO',
      TeamCrestShape.hexagon,
      0xFFEAB308,
      0xFF1E1B4B,
    ),
    _TeamMetadata(
      'tigres-del-prado',
      'tdp',
      'Tigres del Prado',
      'TDP',
      TeamCrestShape.shield,
      0xFFEC4899,
      0xFF18181B,
    ),
    _TeamMetadata(
      'alianza-andina',
      'ala',
      'Alianza Andina',
      'ALA',
      TeamCrestShape.circle,
      0xFF10B981,
      0xFF064E3B,
    ),
    _TeamMetadata(
      'boca-central',
      'boc',
      'Boca Central',
      'BOC',
      TeamCrestShape.diamond,
      0xFF3B82F6,
      0xFFFBBF24,
    ),
    _TeamMetadata(
      'racing-del-norte',
      'rcn',
      'Racing del Norte',
      'RCN',
      TeamCrestShape.hexagon,
      0xFF60A5FA,
      0xFF0F172A,
    ),
    _TeamMetadata(
      'union-deportiva',
      'ude',
      'Unión Deportiva',
      'UDE',
      TeamCrestShape.shield,
      0xFFA855F7,
      0xFF1E293B,
    ),
    _TeamMetadata(
      'independiente-capital',
      'idc',
      'Independiente Capital',
      'IDC',
      TeamCrestShape.circle,
      0xFFDC2626,
      0xFF111827,
    ),
    _TeamMetadata(
      'juventud-dorada',
      'jvd',
      'Juventud Dorada',
      'JVD',
      TeamCrestShape.diamond,
      0xFFCA8A04,
      0xFF000000,
    ),
    _TeamMetadata(
      'condor-real',
      'cdr',
      'Cóndor Real',
      'CDR',
      TeamCrestShape.hexagon,
      0xFF14B8A6,
      0xFF042F2E,
    ),
    _TeamMetadata(
      'titanes-soccer',
      'tts',
      'Titanes Soccer',
      'TTS',
      TeamCrestShape.shield,
      0xFF6366F1,
      0xFF1E1B4B,
    ),
    _TeamMetadata(
      'vanguardia-fc',
      'vgd',
      'Vanguardia FC',
      'VGD',
      TeamCrestShape.circle,
      0xFF84CC16,
      0xFF14532D,
    ),
    _TeamMetadata(
      'halcones-unidos',
      'hcu',
      'Halcones Unidos',
      'HCU',
      TeamCrestShape.diamond,
      0xFF0284C7,
      0xFF0F172A,
    ),
    _TeamMetadata(
      'leones-del-oriente',
      'ldo',
      'Leones del Oriente',
      'LDO',
      TeamCrestShape.hexagon,
      0xFFEA580C,
      0xFF27272A,
    ),
  ];

  static const List<String> _firstNames = [
    'Carlos',
    'Juan',
    'Andrés',
    'Mateo',
    'David',
    'Santiago',
    'Daniel',
    'Felipe',
    'Sebastián',
    'Nicolás',
    'Diego',
    'Alejandro',
    'Julián',
    'Lucas',
    'Gabriel',
    'Samuel',
    'Tomás',
    'Martín',
    'Camilo',
    'Joaquín',
    'Esteban',
    'Manuel',
    'Pablo',
    'Álvaro',
    'Rodrigo',
    'Cristian',
    'Ignacio',
    'Gonzalo',
    'Fernando',
    'Emilio',
    'Javier',
    'Hugo',
    'Oscar',
    'Leonardo',
    'Adrián',
    'Mauricio',
    'Guillermo',
    'Rafael',
    'Rubén',
    'Simón',
  ];

  static const List<String> _lastNames = [
    'Gómez',
    'Rodríguez',
    'Pérez',
    'Hernández',
    'Martínez',
    'García',
    'López',
    'González',
    'Sánchez',
    'Ramírez',
    'Torres',
    'Díaz',
    'Vargas',
    'Castillo',
    'Morales',
    'Rojas',
    'Mendoza',
    'Herrera',
    'Medina',
    'Castro',
    'Ortiz',
    'Silva',
    'Ríos',
    'Navarro',
    'Guerrero',
    'Montoya',
    'Cárdenas',
    'Peña',
    'Salazar',
    'Chávez',
    'Paredes',
    'Acosta',
    'Reyes',
    'Campos',
    'Delgado',
    'Vega',
    'Pacheco',
    'Barrios',
    'Miranda',
    'Bermúdez',
  ];

  /// Genera los 20 equipos con 18 jugadores cada uno asignados al [tournamentId].
  static List<TournamentTeam> generate({
    String tournamentId = 'tournament-seed-liga-clausura',
  }) {
    final List<TournamentTeam> teams = [];

    for (var tIdx = 0; tIdx < _teamMetas.length; tIdx++) {
      final meta = _teamMetas[tIdx];
      final teamId = 'team-seed-${meta.slug}';

      final List<RegisteredPlayer> players = [];

      if (meta.codeSlug == 'atn') {
        _buildAtnPlayers(players);
      } else if (meta.codeSlug == 'rsc') {
        _buildRscPlayers(players);
      } else {
        _buildGenericPlayers(tIdx, meta.codeSlug, players);
      }

      teams.add(
        TournamentTeam(
          id: teamId,
          tournamentId: tournamentId,
          name: meta.name,
          shortCode: meta.shortCode,
          crestShape: meta.crestShape,
          primaryColorHex: meta.primaryColorHex,
          secondaryColorHex: meta.secondaryColorHex,
          eligibilityStatus: TeamEligibilityStatus.eligible,
          players: players,
          updatedAt: DateTime(2026, 5, 1, 10, 0),
        ),
      );
    }

    return teams;
  }

  static void _buildAtnPlayers(List<RegisteredPlayer> players) {
    const atnBase = [
      (1, 'David Ospina', '10100001', 1, PlayerPosition.goalkeeper),
      (2, 'Yerry Mina', '10100002', 4, PlayerPosition.defender),
      (3, 'Dávinson Sánchez', '10100003', 5, PlayerPosition.defender),
      (4, 'Mateus Uribe', '10100004', 8, PlayerPosition.midfielder),
      (5, 'Radamel Falcao', '10100005', 9, PlayerPosition.forward),
      (6, 'James Rodríguez', '10100006', 10, PlayerPosition.midfielder),
      (7, 'Luis Díaz', '10100007', 11, PlayerPosition.forward),
      (8, 'Wilmar Barrios', '10100008', 6, PlayerPosition.midfielder),
      (9, 'Álvaro Montero', '10100009', 12, PlayerPosition.goalkeeper),
      (10, 'Jhon Durán', '10100010', 14, PlayerPosition.forward),
      (11, 'Johan Mojica', '10100011', 3, PlayerPosition.defender),
      (12, 'Santiago Arias', '10100012', 2, PlayerPosition.defender),
      (13, 'Carlos Cuesta', '10100013', 13, PlayerPosition.defender),
      (14, 'Daniel Muñoz', '10100014', 15, PlayerPosition.defender),
      (15, 'Jefferson Lerma', '10100015', 16, PlayerPosition.midfielder),
      (16, 'Richard Ríos', '10100016', 7, PlayerPosition.midfielder),
      (17, 'Jhon Arias', '10100017', 18, PlayerPosition.midfielder),
      (18, 'Rafael Santos Borré', '10100018', 17, PlayerPosition.forward),
    ];

    for (final p in atnBase) {
      players.add(
        RegisteredPlayer(
          id: 'p-seed-atn-${p.$1}',
          fullName: p.$2,
          documentId: p.$3,
          shirtNumber: p.$4,
          position: p.$5,
          isEligible: true,
        ),
      );
    }
  }

  static void _buildRscPlayers(List<RegisteredPlayer> players) {
    const rscBase = [
      (1, 'Camilo Vargas', '20200001', 1, PlayerPosition.goalkeeper),
      (2, 'Stefan Medina', '20200002', 2, PlayerPosition.defender),
      (3, 'William Tesillo', '20200003', 6, PlayerPosition.defender),
      (4, 'Luis Sinisterra', '20200004', 7, PlayerPosition.forward),
      (5, 'Juan Fernando Quintero', '20200005', 10, PlayerPosition.midfielder),
      (6, 'Aldair Quintana', '20200006', 12, PlayerPosition.goalkeeper),
      (7, 'Andrés Llinás', '20200007', 3, PlayerPosition.defender),
      (8, 'Jeison Murillo', '20200008', 4, PlayerPosition.defender),
      (9, 'Frank Fabra', '20200009', 5, PlayerPosition.defender),
      (10, 'Gabriel Fuentes', '20200010', 13, PlayerPosition.defender),
      (11, 'Víctor Cantillo', '20200011', 8, PlayerPosition.midfielder),
      (12, 'Baldomero Perlaza', '20200012', 14, PlayerPosition.midfielder),
      (13, 'Sebastián Gómez', '20200013', 15, PlayerPosition.midfielder),
      (14, 'Yeison Guzmán', '20200014', 16, PlayerPosition.midfielder),
      (15, 'Duvan Zapata', '20200015', 9, PlayerPosition.forward),
      (16, 'Miguel Borja', '20200016', 11, PlayerPosition.forward),
      (17, 'Harold Preciado', '20200017', 17, PlayerPosition.forward),
      (18, 'Macalister Silva', '20200018', 18, PlayerPosition.midfielder),
    ];

    for (final p in rscBase) {
      players.add(
        RegisteredPlayer(
          id: 'p-seed-rsc-${p.$1}',
          fullName: p.$2,
          documentId: p.$3,
          shirtNumber: p.$4,
          position: p.$5,
          isEligible: true,
        ),
      );
    }
  }

  static void _buildGenericPlayers(
    int tIdx,
    String codeSlug,
    List<RegisteredPlayer> players,
  ) {
    for (var pIdx = 1; pIdx <= 18; pIdx++) {
      final shirtNumber = pIdx;
      final position = _assignPosition(pIdx);
      final firstName = _firstNames[(tIdx * 7 + pIdx * 3) % _firstNames.length];
      final lastName = _lastNames[(tIdx * 5 + pIdx * 7) % _lastNames.length];
      final fullName = '$firstName $lastName';
      final docNum = 10000000 + (tIdx + 1) * 1000 + pIdx;

      players.add(
        RegisteredPlayer(
          id: 'p-seed-$codeSlug-$pIdx',
          fullName: fullName,
          documentId: '$docNum',
          shirtNumber: shirtNumber,
          position: position,
          isEligible: true,
        ),
      );
    }
  }

  static PlayerPosition _assignPosition(int shirtNumber) {
    if (shirtNumber == 1 || shirtNumber == 12) {
      return PlayerPosition.goalkeeper;
    } else if (shirtNumber >= 2 && shirtNumber <= 6 || shirtNumber == 13) {
      return PlayerPosition.defender;
    } else if ((shirtNumber >= 7 && shirtNumber <= 8) ||
        shirtNumber == 10 ||
        shirtNumber == 14 ||
        shirtNumber == 15 ||
        shirtNumber == 16) {
      return PlayerPosition.midfielder;
    } else {
      return PlayerPosition.forward;
    }
  }
}

class _TeamMetadata {
  final String slug;
  final String codeSlug;
  final String name;
  final String shortCode;
  final TeamCrestShape crestShape;
  final int primaryColorHex;
  final int secondaryColorHex;

  const _TeamMetadata(
    this.slug,
    this.codeSlug,
    this.name,
    this.shortCode,
    this.crestShape,
    this.primaryColorHex,
    this.secondaryColorHex,
  );
}
