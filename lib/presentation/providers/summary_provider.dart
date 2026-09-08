import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/auction_summary.dart';
import '../../data/models/league_settings.dart';
import '../../domain/budget_calculator.dart';
import 'players_provider.dart';
import 'settings_provider.dart';

final auctionSummaryProvider = Provider<AuctionSummary>((ref) {
  final playersAsync = ref.watch(playersProvider);
  final settingsAsync = ref.watch(settingsProvider);

  final players = playersAsync.value ?? [];
  final settings = settingsAsync.value ?? const LeagueSettings();

  return BudgetCalculator.computeSummary(
    players: players,
    settings: settings,
  );
});
