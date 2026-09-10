import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/player.dart';
import '../../data/models/league_settings.dart';
import '../../data/import/quotazioni_importer.dart';
import '../../domain/fvm_suggester.dart';
import 'settings_provider.dart';

final playersProvider = StateNotifierProvider<PlayersNotifier, AsyncValue<List<Player>>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return PlayersNotifier(repo);
});

class PlayersNotifier extends StateNotifier<AsyncValue<List<Player>>> {
  final dynamic _repository;

  PlayersNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPlayers();
  }

  Future<void> loadPlayers() async {
    try {
      final players = await _repository.getPlayers();
      state = AsyncValue.data(players);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<ImportResult> importFile(Uint8List bytes, String fileName) async {
    final result = await _repository.importSpreadsheetBytes(bytes, fileName);
    final fresh = await _repository.getPlayers();
    state = AsyncValue.data(fresh);
    return result;
  }

  Future<ImportResult> loadFixtureFromAsset(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final bytes = byteData.buffer.asUint8List();
    final fileName = assetPath.split('/').last;
    return await importFile(bytes, fileName);
  }

  Future<void> updatePlayer(Player player) async {
    final currentList = state.value ?? [];
    final updatedList = currentList.map((p) => p.id == player.id ? player : p).toList();
    state = AsyncValue.data(updatedList);
    await _repository.updatePlayer(player);
  }

  Future<void> updateBudgetPercent(int playerId, double percent) async {
    final currentList = state.value ?? [];
    final updatedList = currentList.map((p) {
      if (p.id == playerId) {
        return p.copyWith(budgetPercent: percent);
      }
      return p;
    }).toList();
    state = AsyncValue.data(updatedList);
    await _repository.updatePlayerFields(playerId, {'budget_percent': percent});
  }

  Future<void> updateTier(int playerId, String tier) async {
    final currentList = state.value ?? [];
    final updatedList = currentList.map((p) {
      if (p.id == playerId) {
        return p.copyWith(tier: tier);
      }
      return p;
    }).toList();
    state = AsyncValue.data(updatedList);
    await _repository.updatePlayerFields(playerId, {'tier': tier});
  }

  Future<void> toggleFavorite(int playerId) async {
    final currentList = state.value ?? [];
    Player? updatedPlayer;
    final updatedList = currentList.map((p) {
      if (p.id == playerId) {
        final newVal = !p.isFavorite;
        updatedPlayer = p.copyWith(isFavorite: newVal);
        return updatedPlayer!;
      }
      return p;
    }).toList();
    state = AsyncValue.data(updatedList);
    if (updatedPlayer != null) {
      await _repository.updatePlayerFields(playerId, {'is_favorite': updatedPlayer!.isFavorite ? 1 : 0});
    }
  }

  Future<void> updateTargetPrice(int playerId, int? targetPrice) async {
    final currentList = state.value ?? [];
    final updatedList = currentList.map((p) {
      if (p.id == playerId) {
        return p.copyWith(
          targetPrice: targetPrice,
          clearTargetPrice: targetPrice == null,
        );
      }
      return p;
    }).toList();
    state = AsyncValue.data(updatedList);
    await _repository.updatePlayerFields(playerId, {'target_price': targetPrice});
  }

  Future<void> updateNotes(int playerId, String notes) async {
    final currentList = state.value ?? [];
    final updatedList = currentList.map((p) {
      if (p.id == playerId) {
        return p.copyWith(notes: notes);
      }
      return p;
    }).toList();
    state = AsyncValue.data(updatedList);
    await _repository.updatePlayerFields(playerId, {'notes': notes});
  }

  Future<void> assignToMe(int playerId, int hammerPrice) async {
    final currentList = state.value ?? [];
    final updatedList = currentList.map((p) {
      if (p.id == playerId) {
        return p.copyWith(
          status: PlayerStatus.mine,
          purchasePrice: hammerPrice,
        );
      }
      return p;
    }).toList();
    state = AsyncValue.data(updatedList);
    await _repository.updatePlayerFields(playerId, {
      'status': PlayerStatus.mine.toDbString(),
      'purchase_price': hammerPrice,
    });
  }

  Future<void> soldToOthers(int playerId) async {
    final currentList = state.value ?? [];
    final updatedList = currentList.map((p) {
      if (p.id == playerId) {
        return p.copyWith(
          status: PlayerStatus.others,
          clearPurchasePrice: true,
        );
      }
      return p;
    }).toList();
    state = AsyncValue.data(updatedList);
    await _repository.updatePlayerFields(playerId, {
      'status': PlayerStatus.others.toDbString(),
      'purchase_price': null,
    });
  }

  Future<void> makeAvailable(int playerId) async {
    final currentList = state.value ?? [];
    final updatedList = currentList.map((p) {
      if (p.id == playerId) {
        return p.copyWith(
          status: PlayerStatus.available,
          clearPurchasePrice: true,
        );
      }
      return p;
    }).toList();
    state = AsyncValue.data(updatedList);
    await _repository.updatePlayerFields(playerId, {
      'status': PlayerStatus.available.toDbString(),
      'purchase_price': null,
    });
  }

  Future<void> suggestFromFvm(LeagueSettings settings) async {
    final currentList = state.value ?? [];
    final updated = FvmSuggester.suggestPercentages(players: currentList, settings: settings);
    state = AsyncValue.data(updated);
    await _repository.savePlayers(updated);
  }

  Future<void> resetSeason() async {
    await _repository.resetSeason();
    state = const AsyncValue.data([]);
  }
}
