import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/league_settings.dart';
import '../../data/repositories/player_repository.dart';

final repositoryProvider = Provider<PlayerRepository>((ref) {
  return PlayerRepository();
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<LeagueSettings>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return SettingsNotifier(repo);
});

class SettingsNotifier extends StateNotifier<AsyncValue<LeagueSettings>> {
  final PlayerRepository _repository;

  SettingsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final settings = await _repository.getSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSettings(LeagueSettings settings) async {
    try {
      await _repository.saveSettings(settings);
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateInitialBudget(int budget) async {
    final current = state.value ?? const LeagueSettings();
    final updated = current.copyWith(initialBudget: budget);
    await updateSettings(updated);
  }

  Future<void> toggleMantra(bool isMantra) async {
    final current = state.value ?? const LeagueSettings();
    final updated = current.copyWith(isMantra: isMantra);
    await updateSettings(updated);
  }

  Future<void> updateRoleSlots(Map<String, int> slots) async {
    final current = state.value ?? const LeagueSettings();
    final updated = current.copyWith(slots: slots);
    await updateSettings(updated);
  }

  Future<void> updateRoleAllocations(Map<String, int> allocations) async {
    final current = state.value ?? const LeagueSettings();
    final updated = current.copyWith(budgetAllocations: allocations);
    await updateSettings(updated);
  }

  Future<void> updateTargetPercentages(Map<String, double> percentages) async {
    final current = state.value ?? const LeagueSettings();
    final allocations = LeagueSettings.calculateAllocations(current.initialBudget, percentages);
    final updated = current.copyWith(
      targetPercentages: percentages,
      budgetAllocations: allocations,
    );
    await updateSettings(updated);
  }

  Future<void> resetStrategyToDefault() async {
    await updateTargetPercentages(LeagueSettings.defaultTargetPercentages);
  }
}
