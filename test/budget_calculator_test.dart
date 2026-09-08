import 'package:flutter_test/flutter_test.dart';
import 'package:open_fantacalcio_manager/data/models/player.dart';
import 'package:open_fantacalcio_manager/data/models/league_settings.dart';
import 'package:open_fantacalcio_manager/domain/budget_calculator.dart';

void main() {
  group('BudgetCalculator Tests', () {
    test('calculateBaseValue computes round(% * budget) correctly', () {
      // Svilar: 11% of 600 = 66
      expect(BudgetCalculator.calculateBaseValue(0.11, 600), equals(66));

      // Martinez: 9% of 600 = 54
      expect(BudgetCalculator.calculateBaseValue(0.09, 600), equals(54));

      // Boundary values
      expect(BudgetCalculator.calculateBaseValue(0.0, 600), equals(0));
      expect(BudgetCalculator.calculateBaseValue(0.005, 500), equals(3)); // 2.5 rounds to 3
    });

    test('computeSummary aggregates Allocato, Speso, Residuo, and slots correctly', () {
      const settings = LeagueSettings(
        initialBudget: 600,
        slots: {'P': 3, 'D': 8, 'C': 8, 'A': 6},
        budgetAllocations: {'P': 12, 'D': 100, 'C': 200, 'A': 288},
      );

      final players = [
        const Player(id: 1, role: 'P', name: 'De Gea', team: 'Fiorentina', status: PlayerStatus.mine, purchasePrice: 5),
        const Player(id: 2, role: 'P', name: 'Okoye', team: 'Udinese', status: PlayerStatus.mine, purchasePrice: 5),
        const Player(id: 3, role: 'D', name: 'Bastoni', team: 'Inter', status: PlayerStatus.mine, purchasePrice: 18),
        const Player(id: 4, role: 'A', name: 'Lautaro', team: 'Inter', status: PlayerStatus.mine, purchasePrice: 180),
        const Player(id: 5, role: 'A', name: 'Vlahovic', team: 'Juventus', status: PlayerStatus.others), // Not mine
        const Player(id: 6, role: 'C', name: 'Barella', team: 'Inter', status: PlayerStatus.available), // Available
      ];

      final summary = BudgetCalculator.computeSummary(
        players: players,
        settings: settings,
      );

      // Total spent = 5 + 5 + 18 + 180 = 208
      expect(summary.totalSpent, equals(208));
      // Remaining budget = 600 - 208 = 392
      expect(summary.remainingBudget, equals(392));
      // Total acquired = 4
      expect(summary.totalAcquired, equals(4));
      // Total slots = 25
      expect(summary.totalSlots, equals(25));
      // Remaining slots = 25 - 4 = 21
      expect(summary.remainingSlots, equals(21));

      // Check Portieri summary
      final pSum = summary.roleSummaries['P']!;
      expect(pSum.totalSlots, equals(3));
      expect(pSum.acquiredCount, equals(2));
      expect(pSum.remainingSlots, equals(1));
      expect(pSum.allocatedBudget, equals(12));
      expect(pSum.spentBudget, equals(10));
      expect(pSum.remainingBudget, equals(2)); // Allocato - Speso = 12 - 10 = 2

      // Check Difensori summary
      final dSum = summary.roleSummaries['D']!;
      expect(dSum.totalSlots, equals(8));
      expect(dSum.acquiredCount, equals(1));
      expect(dSum.remainingSlots, equals(7));
      expect(dSum.allocatedBudget, equals(100));
      expect(dSum.spentBudget, equals(18));
      expect(dSum.remainingBudget, equals(82));

      // Check Centrocampisti summary (none acquired yet)
      final cSum = summary.roleSummaries['C']!;
      expect(cSum.acquiredCount, equals(0));
      expect(cSum.spentBudget, equals(0));
      expect(cSum.remainingBudget, equals(200));

      // Check Attaccanti summary
      final aSum = summary.roleSummaries['A']!;
      expect(aSum.acquiredCount, equals(1));
      expect(aSum.spentBudget, equals(180));
      expect(aSum.remainingBudget, equals(108)); // 288 - 180 = 108
    });
  });
}
