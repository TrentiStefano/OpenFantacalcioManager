import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/player.dart';
import '../../domain/player_filter_sort.dart';
import 'players_provider.dart';
import 'settings_provider.dart';

final filterCriteriaProvider = StateNotifierProvider<FilterCriteriaNotifier, PlayerFilterCriteria>((ref) {
  return FilterCriteriaNotifier();
});

class FilterCriteriaNotifier extends StateNotifier<PlayerFilterCriteria> {
  FilterCriteriaNotifier() : super(const PlayerFilterCriteria());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setRoleFilter(String? role) {
    state = state.copyWith(roleFilter: role, clearRoleFilter: role == null);
  }

  void setTierFilter(String? tier) {
    state = state.copyWith(tierFilter: tier, clearTierFilter: tier == null);
  }

  void toggleFavoritesOnly() {
    state = state.copyWith(favoritesOnly: !state.favoritesOnly);
  }

  void setStatusFilter(PlayerStatus? status) {
    state = state.copyWith(statusFilter: status, clearStatusFilter: status == null);
  }

  void toggleExcludeCeduti() {
    state = state.copyWith(excludeCeduti: !state.excludeCeduti);
  }

  void setSort(SortColumn column, {SortDirection? direction}) {
    if (state.sortColumn == column && direction == null) {
      // Toggle direction
      final newDir = state.sortDirection == SortDirection.ascending
          ? SortDirection.descending
          : SortDirection.ascending;
      state = state.copyWith(sortDirection: newDir);
    } else {
      state = state.copyWith(
        sortColumn: column,
        sortDirection: direction ?? SortDirection.ascending,
      );
    }
  }

  void resetFilters() {
    state = const PlayerFilterCriteria();
  }
}

final filteredPlayersProvider = Provider<List<Player>>((ref) {
  final playersAsync = ref.watch(playersProvider);
  final criteria = ref.watch(filterCriteriaProvider);
  final settingsAsync = ref.watch(settingsProvider);

  final players = playersAsync.value ?? [];
  final initialBudget = settingsAsync.value?.initialBudget ?? 600;

  return PlayerFilterSort.apply(
    players: players,
    criteria: criteria,
    initialBudget: initialBudget,
  );
});
