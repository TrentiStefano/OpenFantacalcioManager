import '../data/models/player.dart';
import '../data/models/league_settings.dart';

class FvmSuggester {
  /// Normalizes FVM into a starting percentage per role based on the role budget allocation.
  /// For each player: % Budget = (playerFVM / sumRoleFVM) * (roleAllocatedBudget / initialBudget)
  /// Returns a new list of players with updated budgetPercent and recalculated base value.
  static List<Player> suggestPercentages({
    required List<Player> players,
    required LeagueSettings settings,
  }) {
    if (settings.initialBudget <= 0) return players;

    // Calculate sum of FVM per role
    final Map<String, double> roleFvmSum = {};
    for (final p in players) {
      if (p.isCeduto) continue;
      final role = p.role.toUpperCase().trim();
      final fvmVal = settings.isMantra && p.fvmM > 0 ? p.fvmM : p.fvm;
      if (fvmVal > 0) {
        roleFvmSum[role] = (roleFvmSum[role] ?? 0.0) + fvmVal;
      }
    }

    return players.map((player) {
      if (player.isCeduto) return player;
      final role = player.role.toUpperCase().trim();
      final totalRoleFvm = roleFvmSum[role] ?? 0.0;
      final roleAllocated = (settings.budgetAllocations[role] ?? 0).toDouble();
      final fvmVal = settings.isMantra && player.fvmM > 0 ? player.fvmM : player.fvm;

      if (totalRoleFvm > 0 && roleAllocated > 0 && fvmVal > 0) {
        // Proportional share of the role budget in % of total budget
        final shareOfRoleBudget = (fvmVal / totalRoleFvm) * roleAllocated;
        final rawPct = shareOfRoleBudget / settings.initialBudget;
        // Round to 3 decimal places (e.g. 0.095 = 9.5%)
        final roundedPct = (rawPct * 1000).round() / 1000.0;
        return player.copyWith(budgetPercent: roundedPct);
      } else {
        return player.copyWith(budgetPercent: 0.0);
      }
    }).toList();
  }
}
