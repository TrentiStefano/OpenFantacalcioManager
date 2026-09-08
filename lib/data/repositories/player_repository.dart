import 'dart:typed_data';
import '../models/player.dart';
import '../models/league_settings.dart';
import '../persistence/player_dao.dart';
import '../import/quotazioni_importer.dart';
import '../export/spreadsheet_exporter.dart';

class PlayerRepository {
  final PlayerDao _dao;

  PlayerRepository([PlayerDao? dao]) : _dao = dao ?? PlayerDao();

  Future<List<Player>> getPlayers() => _dao.getAllPlayers();

  Future<LeagueSettings> getSettings() => _dao.getSettings();

  Future<void> saveSettings(LeagueSettings settings) => _dao.saveSettings(settings);

  Future<void> savePlayers(List<Player> players) => _dao.savePlayers(players);

  Future<void> updatePlayer(Player player) => _dao.updatePlayer(player);

  Future<void> updatePlayerFields(int id, Map<String, dynamic> fields) =>
      _dao.updatePlayerFields(id, fields);

  Future<ImportResult> importSpreadsheetBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    final existing = await _dao.getAllPlayers();
    final existingMap = {for (final p in existing) p.id: p};

    final result = QuotazioniImporter.parseFileBytes(
      bytes,
      fileName,
      existingPlayersById: existingMap,
    );

    if (result.players.isNotEmpty) {
      await _dao.savePlayers(result.players);
    }
    return result;
  }

  Uint8List exportToExcel(List<Player> players, LeagueSettings settings) {
    return SpreadsheetExporter.exportToExcel(players: players, settings: settings);
  }

  String exportToCsv(List<Player> players, LeagueSettings settings) {
    return SpreadsheetExporter.exportToCsv(players: players, settings: settings);
  }

  Future<void> resetSeason() => _dao.resetAll();
}
