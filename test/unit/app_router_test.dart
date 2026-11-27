import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/presentation/navigation/app_router.dart';
import 'package:vifutbol/presentation/teams/create_team_screen.dart';
import 'package:vifutbol/presentation/teams/team_detail_screen.dart';

void main() {
  setUpAll(() {
    AppRouter.setupRouter();
  });

  group('AppRouter team routes', () {
    testWidgets('/teams/create resolves to CreateTeamScreen instead of /teams/:id', (
      tester,
    ) async {
      final match = AppRouter.router.match('/teams/create');
      expect(match, isNotNull);
      expect(match!.route.route, '/teams/create');

      final widget = match.route.handler!.handlerFunc(
        null,
        match.parameters,
      );
      expect(widget, isA<CreateTeamScreen>());
    });

    testWidgets('/teams/:id resolves to TeamDetailScreen with teamId', (
      tester,
    ) async {
      final match = AppRouter.router.match('/teams/team-123');
      expect(match, isNotNull);
      expect(match!.route.route, '/teams/:id');

      final widget = match.route.handler!.handlerFunc(
        null,
        match.parameters,
      );
      expect(widget, isA<TeamDetailScreen>());
      expect((widget! as TeamDetailScreen).teamId, 'team-123');
    });
  });
}
