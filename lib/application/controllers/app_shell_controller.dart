import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/domain/entities/app_shell_section.dart';

/// StateNotifier controlling the active section and shell navigation state.
class AppShellController extends StateNotifier<AppShellState> {
  AppShellController() : super(const AppShellState());

  void setSection(AppShellSection section) {
    if (state.activeSection != section) {
      state = state.copyWith(activeSection: section);
    }
  }

  void setSectionByIndex(int index) {
    if (index >= 0 && index < AppShellSection.values.length) {
      setSection(AppShellSection.values[index]);
    }
  }
}

/// Global provider for App Shell state.
final appShellControllerProvider =
    StateNotifierProvider<AppShellController, AppShellState>((ref) {
      return AppShellController();
    });
