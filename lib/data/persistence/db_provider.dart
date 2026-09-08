import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DbProvider {
  static final DbProvider instance = DbProvider._();
  DbProvider._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Check if running on desktop (Windows, macOS, Linux)
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'open_fantacalcio_manager.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE players (
            id INTEGER PRIMARY KEY,
            role TEXT NOT NULL,
            role_mantra TEXT,
            name TEXT NOT NULL,
            team TEXT NOT NULL,
            qt_a REAL,
            qt_i REAL,
            diff REAL,
            qt_a_m REAL,
            qt_i_m REAL,
            diff_m REAL,
            fvm REAL,
            fvm_m REAL,
            is_ceduto INTEGER DEFAULT 0,
            budget_percent REAL DEFAULT 0.0,
            tier TEXT DEFAULT 'ALTRI',
            is_favorite INTEGER DEFAULT 0,
            target_price INTEGER,
            notes TEXT DEFAULT '',
            status TEXT DEFAULT 'available',
            purchase_price INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE settings (
            id INTEGER PRIMARY KEY DEFAULT 1,
            initial_budget INTEGER DEFAULT 600,
            is_mantra INTEGER DEFAULT 0,
            slots_json TEXT,
            allocations_json TEXT,
            tiers_json TEXT
          )
        ''');
      },
    );
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
