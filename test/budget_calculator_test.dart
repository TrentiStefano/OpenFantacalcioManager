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

    test('Strategy feature computes base target percentages (P 6%, D 16%, C 26%, A 52%) correctly', () {
      const defaultPercentages = LeagueSettings.defaultTargetPercentages;
      expect(defaultPercentages['P'], equals(6.0));
      expect(defaultPercentages['D'], equals(16.0));
      expect(defaultPercentages['C'], equals(26.0));
      expect(defaultPercentages['A'], equals(52.0));

      final allocations600 = LeagueSettings.calculateAllocations(600, defaultPercentages);
      expect(allocations600['P'], equals(36));
      expect(allocations600['D'], equals(96));
      expect(allocations600['C'], equals(156));
      expect(allocations600['A'], equals(312));
      expect(allocations600.values.reduce((a, b) => a + b), equals(600));

      final allocations500 = LeagueSettings.calculateAllocations(500, defaultPercentages);
      expect(allocations500['P'], equals(30));
      expect(allocations500['D'], equals(80));
      expect(allocations500['C'], equals(130));
      expect(allocations500['A'], equals(260));
      expect(allocations500.values.reduce((a, b) => a + b), equals(500));
    });

    test('Underbudget delta of +25 cr when spending 25 credits less for defenders', () {
      final settings = const LeagueSettings(
        initialBudget: 600,
        slots: {'P': 3, 'D': 8, 'C': 8, 'A': 6},
      ); // Uses default target percentages: P 6% (36 cr), D 16% (96 cr), C 26% (156 cr), A 52% (312 cr)

      // 8 defenders bought for a total of 71 credits (96 - 25 = 71 credits spent)
      final defenders = List.generate(
        8,
        (i) => Player(
          id: 100 + i,
          role: 'D',
          name: 'Defender $i',
          team: 'Team $i',
          status: PlayerStatus.mine,
          purchasePrice: i == 0 ? 15 : 8, // 15 + 7*8 = 71 credits
        ),
      );

      final summary = BudgetCalculator.computeSummary(
        players: defenders,
        settings: settings,
      );

      final dSum = summary.roleSummaries['D']!;
      expect(dSum.allocatedBudget, equals(96));
      expect(dSum.spentBudget, equals(71));
      expect(dSum.remainingBudget, equals(25));
      expect(dSum.isCompleted, isTrue);
      expect(dSum.roleDelta, equals(25));
      expect(dSum.formattedDelta, equals('+25 cr'));

      // Total over/underbudget should show +25 cr savings available to buy other players
      expect(summary.totalOverUnderBudget, equals(25));
      expect(summary.formattedTotalOverUnder, equals('+25 cr'));
    });

    test('Overbudget and mixed delta across completed and active roles', () {
      final settings = const LeagueSettings(
        initialBudget: 600,
        slots: {'P': 3, 'D': 8, 'C': 8, 'A': 6},
      );

      // 8 defenders bought for 71 cr (target 96 cr -> +25 cr savings)
      final defenders = List.generate(
        8,
        (i) => Player(
          id: 100 + i,
          role: 'D',
          name: 'Defender $i',
          team: 'Team $i',
          status: PlayerStatus.mine,
          purchasePrice: i == 0 ? 15 : 8, // 71 cr
        ),
      );

      // 3 goalkeepers bought for 41 cr (target 36 cr -> -5 cr overrun)
      final goalkeepers = [
        const Player(id: 1, role: 'P', name: 'GK1', team: 'Team', status: PlayerStatus.mine, purchasePrice: 20),
        const Player(id: 2, role: 'P', name: 'GK2', team: 'Team', status: PlayerStatus.mine, purchasePrice: 11),
        const Player(id: 3, role: 'P', name: 'GK3', team: 'Team', status: PlayerStatus.mine, purchasePrice: 10),
      ];

      final summary = BudgetCalculator.computeSummary(
        players: [...defenders, ...goalkeepers],
        settings: settings,
      );

      final pSum = summary.roleSummaries['P']!;
      expect(pSum.allocatedBudget, equals(36));
      expect(pSum.spentBudget, equals(41));
      expect(pSum.remainingBudget, equals(-5));
      expect(pSum.isCompleted, isTrue);
      expect(pSum.roleDelta, equals(-5));
      expect(pSum.formattedDelta, equals('-5 cr'));

      // Net balance: +25 (from D) - 5 (from P) = +20 cr
      expect(summary.totalOverUnderBudget, equals(20));
      expect(summary.formattedTotalOverUnder, equals('+20 cr'));
    });
  });
}
