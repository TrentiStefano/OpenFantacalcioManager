import '../data/models/player.dart';
import '../data/models/league_settings.dart';
import '../data/models/auction_summary.dart';

class BudgetCalculator {
  /// Base price calculation: ROUND(% Budget * Budget Iniziale)
  static int calculateBaseValue(double budgetPercent, int initialBudget) {
    if (budgetPercent <= 0 || initialBudget <= 0) return 0;
    return (budgetPercent * initialBudget).round();
  }

  /// Calculates complete budget and roster summary across roles and totals
  static AuctionSummary computeSummary({
    required List<Player> players,
    required LeagueSettings settings,
  }) {
    final minePlayers = players.where((p) => p.status == PlayerStatus.mine).toList();

    int totalSpent = 0;
    final Map<String, int> spentByRole = {'P': 0, 'D': 0, 'C': 0, 'A': 0};
    final Map<String, int> countByRole = {'P': 0, 'D': 0, 'C': 0, 'A': 0};

    for (final p in minePlayers) {
      final roleKey = p.role.toUpperCase().trim();
      final price = p.purchasePrice ?? 0;
      totalSpent += price;

      if (spentByRole.containsKey(roleKey)) {
        spentByRole[roleKey] = (spentByRole[roleKey] ?? 0) + price;
        countByRole[roleKey] = (countByRole[roleKey] ?? 0) + 1;
      } else {
        spentByRole[roleKey] = price;
        countByRole[roleKey] = 1;
      }
    }

    final Map<String, RoleSummary> roleSummaries = {};
    for (final role in ['P', 'D', 'C', 'A']) {
      final totalSlots = settings.slots[role] ?? 0;
      final acquiredCount = countByRole[role] ?? 0;
      final targetPercentage = settings.targetPercentages[role] ?? 0.0;
      final allocatedBudget = settings.budgetAllocations[role] ?? 
          ((targetPercentage / 100.0) * settings.initialBudget).round();
      final spentBudget = spentByRole[role] ?? 0;

      roleSummaries[role] = RoleSummary(
        role: role,
        totalSlots: totalSlots,
        acquiredCount: acquiredCount,
        allocatedBudget: allocatedBudget,
        spentBudget: spentBudget,
        targetPercentage: targetPercentage,
      );
    }

    return AuctionSummary(
      initialBudget: settings.initialBudget,
      totalSpent: totalSpent,
      totalSlots: settings.totalSlots,
      totalAcquired: minePlayers.length,
      roleSummaries: roleSummaries,
    );
  }
}
