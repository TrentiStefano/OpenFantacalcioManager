import 'package:flutter_test/flutter_test.dart';
import 'package:open_fantacalcio_manager/data/models/player.dart';
import 'package:open_fantacalcio_manager/domain/player_filter_sort.dart';

void main() {
  group('PlayerFilterSort Tests', () {
    test('default sorting sorts by Tier priority ASC then Role priority ASC then Value DESC', () {
      final players = [
        const Player(id: 1, role: 'D', name: 'Defender1', team: 'Inter', tier: 'SEMITOP', budgetPercent: 0.05),
        const Player(id: 2, role: 'P', name: 'Goalkeeper1', team: 'Roma', tier: 'TOP', budgetPercent: 0.10),
        const Player(id: 3, role: 'A', name: 'Forward1', team: 'Milan', tier: 'TOP', budgetPercent: 0.30),
        const Player(id: 4, role: 'P', name: 'Goalkeeper2', team: 'Juventus', tier: 'TOP', budgetPercent: 0.08),
      ];

      final sorted = PlayerFilterSort.apply(
        players: players,
        criteria: const PlayerFilterCriteria(sortColumn: SortColumn.defaultSort),
        initialBudget: 600,
      );

      // 1. TOP priority first:
      // Between TOP players: Role priority (P before A)
      // Among P in TOP: Goalkeeper1 (0.10 = 60 cr) before Goalkeeper2 (0.08 = 48 cr)
      expect(sorted[0].id, equals(2)); // P - Goalkeeper1 (TOP, val: 60)
      expect(sorted[1].id, equals(4)); // P - Goalkeeper2 (TOP, val: 48)
      expect(sorted[2].id, equals(3)); // A - Forward1 (TOP, val: 180)
      // 2. SEMITOP comes after TOP:
      expect(sorted[3].id, equals(1)); // D - Defender1 (SEMITOP)
    });

    test('filters by search query and role', () {
      final players = [
        const Player(id: 1, role: 'P', name: 'Svilar', team: 'Roma'),
        const Player(id: 2, role: 'D', name: 'Bastoni', team: 'Inter'),
        const Player(id: 3, role: 'D', name: 'Mancini', team: 'Roma'),
      ];

      // Filter by role 'D'
      final defenders = PlayerFilterSort.apply(
        players: players,
        criteria: const PlayerFilterCriteria(roleFilter: 'D'),
        initialBudget: 600,
      );
      expect(defenders.length, equals(2));

      // Filter by team 'Roma' via search
      final romaPlayers = PlayerFilterSort.apply(
        players: players,
        criteria: const PlayerFilterCriteria(searchQuery: 'Roma'),
        initialBudget: 600,
      );
      expect(romaPlayers.length, equals(2));
      expect(romaPlayers.map((p) => p.name), containsAll(['Svilar', 'Mancini']));
    });
  });
}
