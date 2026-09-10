import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

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
    final String dbPath;
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      dbPath = 'open_fantacalcio_manager.db';
    } else {
      // Check if running on desktop (Windows, macOS, Linux)
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      final docsDir = await getApplicationDocumentsDirectory();
      dbPath = p.join(docsDir.path, 'open_fantacalcio_manager.db');
    }

    return await openDatabase(
      dbPath,
      version: 2,
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
            target_percentages_json TEXT,
            tiers_json TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE settings ADD COLUMN target_percentages_json TEXT;');
          } catch (_) {
            // Column might already exist
          }
        }
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
