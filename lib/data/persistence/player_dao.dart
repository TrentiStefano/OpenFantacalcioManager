import 'package:sqflite/sqflite.dart';
import '../models/player.dart';
import '../models/league_settings.dart';
import 'db_provider.dart';

class PlayerDao {
  final DbProvider _dbProvider;

  PlayerDao([DbProvider? dbProvider]) : _dbProvider = dbProvider ?? DbProvider.instance;

  Future<List<Player>> getAllPlayers() async {
    final db = await _dbProvider.database;
    final maps = await db.query('players', orderBy: 'id ASC');
    return maps.map((m) => Player.fromMap(m)).toList();
  }

  Future<void> savePlayers(List<Player> players) async {
    final db = await _dbProvider.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final p in players) {
        batch.insert(
          'players',
          p.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> updatePlayer(Player player) async {
    final db = await _dbProvider.database;
    await db.update(
      'players',
      player.toMap(),
      where: 'id = ?',
      whereArgs: [player.id],
    );
  }

  Future<void> updatePlayerFields(int id, Map<String, dynamic> fields) async {
    final db = await _dbProvider.database;
    await db.update(
      'players',
      fields,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllPlayers() async {
    final db = await _dbProvider.database;
    await db.delete('players');
  }

  Future<LeagueSettings> getSettings() async {
    final db = await _dbProvider.database;
    final results = await db.query('settings', where: 'id = ?', whereArgs: [1]);
    if (results.isNotEmpty) {
      return LeagueSettings.fromMap(results.first);
    }
    const defaultSettings = LeagueSettings();
    await saveSettings(defaultSettings);
    return defaultSettings;
  }

  Future<void> saveSettings(LeagueSettings settings) async {
    final db = await _dbProvider.database;
    final map = settings.toMap()..['id'] = 1;
    await db.insert(
      'settings',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> resetAll() async {
    final db = await _dbProvider.database;
    await db.transaction((txn) async {
      await txn.delete('players');
      await txn.delete('settings');
    });
  }
}
