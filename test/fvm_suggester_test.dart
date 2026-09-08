import 'package:flutter_test/flutter_test.dart';
import 'package:open_fantacalcio_manager/data/models/player.dart';
import 'package:open_fantacalcio_manager/data/models/league_settings.dart';
import 'package:open_fantacalcio_manager/domain/fvm_suggester.dart';

void main() {
  group('FvmSuggester Tests', () {
    test('normalizes FVM proportionally to role budget', () {
      const settings = LeagueSettings(
        initialBudget: 500,
        budgetAllocations: {'P': 50, 'D': 100, 'C': 150, 'A': 200},
      );

      final players = [
        const Player(id: 1, role: 'P', name: 'Gk1', team: 'Roma', fvm: 60),
        const Player(id: 2, role: 'P', name: 'Gk2', team: 'Lazio', fvm: 40),
      ];

      final suggested = FvmSuggester.suggestPercentages(
        players: players,
        settings: settings,
      );

      // Total role FVM = 100.
      // Gk1: 60/100 * 50 cr = 30 cr -> 30/500 = 0.06 (6%)
      // Gk2: 40/100 * 50 cr = 20 cr -> 20/500 = 0.04 (4%)
      expect(suggested[0].budgetPercent, closeTo(0.06, 0.001));
      expect(suggested[1].budgetPercent, closeTo(0.04, 0.001));
    });
  });
}
