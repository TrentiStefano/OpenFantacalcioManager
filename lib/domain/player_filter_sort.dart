import '../core/constants/app_tiers.dart';
import '../data/models/player.dart';

enum SortColumn {
  defaultSort,
  name,
  team,
  role,
  fvm,
  budgetPercent,
  baseValue,
  tier,
  targetPrice,
}

enum SortDirection {
  ascending,
  descending,
}

class PlayerFilterCriteria {
  final String searchQuery;
  final String? roleFilter; // null = all, 'P', 'D', 'C', 'A'
  final String? tierFilter; // null = all
  final bool favoritesOnly;
  final PlayerStatus? statusFilter; // null = all
  final bool excludeCeduti;
  final SortColumn sortColumn;
  final SortDirection sortDirection;

  const PlayerFilterCriteria({
    this.searchQuery = '',
    this.roleFilter,
    this.tierFilter,
    this.favoritesOnly = false,
    this.statusFilter,
    this.excludeCeduti = true,
    this.sortColumn = SortColumn.defaultSort,
    this.sortDirection = SortDirection.ascending,
  });

  PlayerFilterCriteria copyWith({
    String? searchQuery,
    String? roleFilter,
    bool clearRoleFilter = false,
    String? tierFilter,
    bool clearTierFilter = false,
    bool? favoritesOnly,
    PlayerStatus? statusFilter,
    bool clearStatusFilter = false,
    bool? excludeCeduti,
    SortColumn? sortColumn,
    SortDirection? sortDirection,
  }) {
    return PlayerFilterCriteria(
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: clearRoleFilter ? null : (roleFilter ?? this.roleFilter),
      tierFilter: clearTierFilter ? null : (tierFilter ?? this.tierFilter),
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      excludeCeduti: excludeCeduti ?? this.excludeCeduti,
      sortColumn: sortColumn ?? this.sortColumn,
      sortDirection: sortDirection ?? this.sortDirection,
    );
  }
}

class PlayerFilterSort {
  static int getRolePriority(String role) {
    final r = role.toUpperCase().trim();
    if (r.startsWith('P')) return 1;
    if (r.startsWith('D')) return 2;
    if (r.startsWith('C')) return 3;
    if (r.startsWith('A')) return 4;
    return 5;
  }

  static List<Player> apply({
    required List<Player> players,
    required PlayerFilterCriteria criteria,
    required int initialBudget,
  }) {
    final filtered = players.where((p) {
      if (criteria.excludeCeduti && p.isCeduto) return false;
      if (criteria.favoritesOnly && !p.isFavorite) return false;
      if (criteria.roleFilter != null && criteria.roleFilter!.isNotEmpty) {
        if (p.role.toUpperCase() != criteria.roleFilter!.toUpperCase()) {
          return false;
        }
      }
      if (criteria.tierFilter != null && criteria.tierFilter!.isNotEmpty) {
        if (p.tier.toUpperCase() != criteria.tierFilter!.toUpperCase()) {
          return false;
        }
      }
      if (criteria.statusFilter != null) {
        if (p.status != criteria.statusFilter) return false;
      }
      if (criteria.searchQuery.isNotEmpty) {
        final query = criteria.searchQuery.toLowerCase().trim();
        final matchName = p.name.toLowerCase().contains(query);
        final matchTeam = p.team.toLowerCase().contains(query);
        if (!matchName && !matchTeam) return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      if (criteria.sortColumn == SortColumn.defaultSort) {
        // 1. Tier priority ASC (TOP = 1, ALTRI = 7)
        final tierComp = AppTiers.getPriority(a.tier).compareTo(AppTiers.getPriority(b.tier));
        if (tierComp != 0) return tierComp;

        // 2. Role priority ASC (P=1, D=2, C=3, A=4)
        final roleComp = getRolePriority(a.role).compareTo(getRolePriority(b.role));
        if (roleComp != 0) return roleComp;

        // 3. Valore Base Asta DESC
        final valA = a.calculateBaseValue(initialBudget);
        final valB = b.calculateBaseValue(initialBudget);
        final valComp = valB.compareTo(valA);
        if (valComp != 0) return valComp;

        // 4. Fallback FVM DESC
        return b.fvm.compareTo(a.fvm);
      }

      int comp = 0;
      switch (criteria.sortColumn) {
        case SortColumn.name:
          comp = a.name.compareTo(b.name);
          break;
        case SortColumn.team:
          comp = a.team.compareTo(b.team);
          break;
        case SortColumn.role:
          comp = getRolePriority(a.role).compareTo(getRolePriority(b.role));
          break;
        case SortColumn.fvm:
          comp = a.fvm.compareTo(b.fvm);
          break;
        case SortColumn.budgetPercent:
          comp = a.budgetPercent.compareTo(b.budgetPercent);
          break;
        case SortColumn.baseValue:
          comp = a.calculateBaseValue(initialBudget).compareTo(b.calculateBaseValue(initialBudget));
          break;
        case SortColumn.tier:
          comp = AppTiers.getPriority(a.tier).compareTo(AppTiers.getPriority(b.tier));
          break;
        case SortColumn.targetPrice:
          comp = (a.targetPrice ?? 0).compareTo(b.targetPrice ?? 0);
          break;
        case SortColumn.defaultSort:
          break;
      }

      return criteria.sortDirection == SortDirection.ascending ? comp : -comp;
    });

    return filtered;
  }
}
