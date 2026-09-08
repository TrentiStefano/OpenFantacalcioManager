import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../models/player.dart';

class ImportResult {
  final List<Player> players;
  final int totalImported;
  final int cedutiCount;
  final String sheetNameUsed;

  const ImportResult({
    required this.players,
    required this.totalImported,
    required this.cedutiCount,
    required this.sheetNameUsed,
  });
}

class QuotazioniImporter {
  /// Header canonical mapping rules:
  /// normalized header -> canonical field name
  static const Map<String, String> _canonicalHeaders = {
    'id': 'id',
    'codice': 'id',
    'r': 'role',
    'ruolo': 'role',
    'rm': 'role_mantra',
    'ruolo mantra': 'role_mantra',
    'ruolomantra': 'role_mantra',
    'nome': 'name',
    'calciatore': 'name',
    'giocatore': 'name',
    'squadra': 'team',
    'club': 'team',
    'qt.a': 'qt_a',
    'qta': 'qt_a',
    'qt. a': 'qt_a',
    'qt.i': 'qt_i',
    'qti': 'qt_i',
    'qt. i': 'qt_i',
    'diff.': 'diff',
    'diff': 'diff',
    'qt.a m': 'qt_a_m',
    'qta m': 'qt_a_m',
    'qta.m': 'qt_a_m',
    'qt.i m': 'qt_i_m',
    'qti m': 'qt_i_m',
    'qti.m': 'qt_i_m',
    'diff.m': 'diff_m',
    'diff. m': 'diff_m',
    'diffm': 'diff_m',
    'fvm': 'fvm',
    'fvm m': 'fvm_m',
    'fvm.m': 'fvm_m',
    'fvm mantra': 'fvm_m',
    '% budget': 'budget_percent',
    'budget %': 'budget_percent',
    'fascia': 'tier',
    'prezzo obiettivo': 'target_price',
    'note': 'notes',
  };

  static String _normalizeHeader(String raw) {
    return raw.toLowerCase().trim().replaceAll('⭐', '').trim();
  }

  /// Parses bytes from an .xlsx or .csv file
  static ImportResult parseFileBytes(
    Uint8List bytes,
    String fileName, {
    Map<int, Player>? existingPlayersById,
  }) {
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.csv')) {
      return _parseCsv(bytes, existingPlayersById: existingPlayersById);
    } else {
      return _parseExcel(bytes, existingPlayersById: existingPlayersById);
    }
  }

  static ImportResult _parseCsv(
    Uint8List bytes, {
    Map<int, Player>? existingPlayersById,
  }) {
    final content = utf8.decode(bytes, allowMalformed: true);
    final rows = const CsvToListConverter(shouldParseNumbers: true).convert(content);
    if (rows.isEmpty) {
      return const ImportResult(players: [], totalImported: 0, cedutiCount: 0, sheetNameUsed: 'CSV');
    }

    final headerRowIndex = _findHeaderRow(rows);
    if (headerRowIndex == -1) {
      throw Exception('Header row not found in CSV. Expected columns: Id, R, Nome, Squadra, etc.');
    }

    final columnMap = _buildColumnMap(rows[headerRowIndex]);
    final players = <Player>[];

    for (int i = headerRowIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;
      final player = _buildPlayerFromRow(row, columnMap, false, existingPlayersById);
      if (player != null) {
        players.add(player);
      }
    }

    return ImportResult(
      players: players,
      totalImported: players.length,
      cedutiCount: 0,
      sheetNameUsed: 'CSV',
    );
  }

  static ImportResult _parseExcel(
    Uint8List bytes, {
    Map<int, Player>? existingPlayersById,
  }) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      throw Exception('The Excel file is empty or corrupted.');
    }

    // Identify 'Ceduti' sheet if present to mark transferred players
    final Set<int> cedutiIds = {};
    for (final entry in excel.tables.entries) {
      final name = entry.key.toLowerCase().trim();
      if (name.contains('ceduti') || name.contains('trasferiti')) {
        final rows = _extractRows(entry.value);
        final headerIdx = _findHeaderRow(rows);
        if (headerIdx != -1) {
          final colMap = _buildColumnMap(rows[headerIdx]);
          final idCol = colMap['id'];
          if (idCol != null) {
            for (int r = headerIdx + 1; r < rows.length; r++) {
              final row = rows[r];
              if (idCol < row.length) {
                final id = _parseInt(row[idCol]);
                if (id != null) cedutiIds.add(id);
              }
            }
          }
        }
      }
    }

    // Auto-detect master 'all players' sheet (e.g. named 'Tutti', 'Listone', or table with max rows excluding Ceduti)
    String chosenSheetName = '';
    Sheet? chosenSheet;
    int maxRows = -1;

    for (final entry in excel.tables.entries) {
      final name = entry.key.toLowerCase().trim();
      if (name.contains('ceduti') || name.contains('trasferiti')) continue;
      if (name.contains('squadra') && !name.contains('tutti')) continue;

      final rowsCount = entry.value.maxRows;
      if (name == 'tutti' || name == 'listone' || name == 'tutti i calciatori') {
        chosenSheet = entry.value;
        chosenSheetName = entry.key;
        break;
      }

      if (rowsCount > maxRows) {
        maxRows = rowsCount;
        chosenSheet = entry.value;
        chosenSheetName = entry.key;
      }
    }

    if (chosenSheet == null) {
      chosenSheet = excel.tables.values.first;
      chosenSheetName = excel.tables.keys.first;
    }

    final rows = _extractRows(chosenSheet);
    final headerRowIndex = _findHeaderRow(rows);
    if (headerRowIndex == -1) {
      throw Exception('Header row not found in sheet "$chosenSheetName". Expected: Id, R, Nome, Squadra.');
    }

    final columnMap = _buildColumnMap(rows[headerRowIndex]);
    final players = <Player>[];
    final Set<int> addedIds = {};
    int cedutiCount = 0;

    for (int i = headerRowIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;
      final idCandidate = columnMap['id'] != null && columnMap['id']! < row.length
          ? _parseInt(row[columnMap['id']!])
          : null;
      final isCeduto = (idCandidate != null && cedutiIds.contains(idCandidate));

      final player = _buildPlayerFromRow(row, columnMap, isCeduto, existingPlayersById);
      if (player != null) {
        players.add(player);
        addedIds.add(player.id);
        if (player.isCeduto) cedutiCount++;
      }
    }

    // Also import rows from Ceduti sheet if they are not already in Tutti
    for (final entry in excel.tables.entries) {
      final name = entry.key.toLowerCase().trim();
      if (name.contains('ceduti') || name.contains('trasferiti')) {
        final cRows = _extractRows(entry.value);
        final cHeaderIdx = _findHeaderRow(cRows);
        if (cHeaderIdx != -1) {
          final cColMap = _buildColumnMap(cRows[cHeaderIdx]);
          for (int r = cHeaderIdx + 1; r < cRows.length; r++) {
            final row = cRows[r];
            if (row.isEmpty) continue;
            final player = _buildPlayerFromRow(row, cColMap, true, existingPlayersById);
            if (player != null && !addedIds.contains(player.id)) {
              players.add(player.copyWith(
                isCeduto: true,
                status: PlayerStatus.others,
              ));
              addedIds.add(player.id);
              cedutiCount++;
            }
          }
        }
      }
    }

    return ImportResult(
      players: players,
      totalImported: players.length,
      cedutiCount: cedutiCount,
      sheetNameUsed: chosenSheetName,
    );
  }

  static List<List<dynamic>> _extractRows(Sheet sheet) {
    final result = <List<dynamic>>[];
    for (int r = 0; r < sheet.maxRows; r++) {
      final row = <dynamic>[];
      final rawRow = sheet.row(r);
      for (final cell in rawRow) {
        if (cell == null || cell.value == null) {
          row.add('');
        } else {
          final val = cell.value;
          if (val is TextCellValue) {
            row.add(val.value);
          } else if (val is IntCellValue) {
            row.add(val.value);
          } else if (val is DoubleCellValue) {
            row.add(val.value);
          } else if (val is DateCellValue) {
            row.add(val.asDateTimeLocal().toString());
          } else if (val is BoolCellValue) {
            row.add(val.value);
          } else {
            row.add(val.toString());
          }
        }
      }
      result.add(row);
    }
    return result;
  }

  static int _findHeaderRow(List<List<dynamic>> rows) {
    for (int r = 0; r < rows.length && r < 10; r++) {
      final row = rows[r];
      int matches = 0;
      for (final cell in row) {
        final text = _normalizeHeader(cell.toString());
        if (_canonicalHeaders.containsKey(text)) {
          matches++;
        }
      }
      // If at least 3 canonical headers match (e.g. id, r, nome), this is the header row
      if (matches >= 3) {
        return r;
      }
    }
    return -1;
  }

  static Map<String, int> _buildColumnMap(List<dynamic> headerRow) {
    final map = <String, int>{};
    for (int col = 0; col < headerRow.length; col++) {
      final text = _normalizeHeader(headerRow[col].toString());
      final canonical = _canonicalHeaders[text];
      if (canonical != null && !map.containsKey(canonical)) {
        map[canonical] = col;
      }
    }
    return map;
  }

  static Player? _buildPlayerFromRow(
    List<dynamic> row,
    Map<String, int> colMap,
    bool isCedutoBySheet,
    Map<int, Player>? existingPlayersById,
  ) {
    dynamic getCol(String key) {
      final idx = colMap[key];
      if (idx == null || idx >= row.length) return null;
      return row[idx];
    }

    final id = _parseInt(getCol('id'));
    final name = getCol('name')?.toString().trim() ?? '';
    final role = getCol('role')?.toString().trim().toUpperCase() ?? '';

    // Must have at least a valid ID and non-empty name
    if (id == null || name.isEmpty) return null;

    final existing = existingPlayersById?[id];

    return Player(
      id: id,
      role: role.isNotEmpty ? role : (existing?.role ?? 'A'),
      roleMantra: getCol('role_mantra')?.toString().trim() ?? (existing?.roleMantra ?? ''),
      name: name,
      team: getCol('team')?.toString().trim() ?? (existing?.team ?? ''),
      qtA: _parseDouble(getCol('qt_a')) ?? (existing?.qtA ?? 0.0),
      qtI: _parseDouble(getCol('qt_i')) ?? (existing?.qtI ?? 0.0),
      diff: _parseDouble(getCol('diff')) ?? (existing?.diff ?? 0.0),
      qtAM: _parseDouble(getCol('qt_a_m')) ?? (existing?.qtAM ?? 0.0),
      qtIM: _parseDouble(getCol('qt_i_m')) ?? (existing?.qtIM ?? 0.0),
      diffM: _parseDouble(getCol('diff_m')) ?? (existing?.diffM ?? 0.0),
      fvm: _parseDouble(getCol('fvm')) ?? (existing?.fvm ?? 0.0),
      fvmM: _parseDouble(getCol('fvm_m')) ?? (existing?.fvmM ?? 0.0),
      isCeduto: isCedutoBySheet || (existing?.isCeduto ?? false),
      // Preserve existing user strategy fields if re-importing
      budgetPercent: _parseDouble(getCol('budget_percent')) ?? (existing?.budgetPercent ?? 0.0),
      tier: getCol('tier')?.toString().trim().isNotEmpty == true
          ? getCol('tier')!.toString().trim()
          : (existing?.tier ?? 'ALTRI'),
      isFavorite: existing?.isFavorite ?? false,
      targetPrice: _parseInt(getCol('target_price')) ?? existing?.targetPrice,
      notes: getCol('notes')?.toString().trim() ?? (existing?.notes ?? ''),
      status: existing?.status ?? PlayerStatus.available,
      purchasePrice: existing?.purchasePrice,
    );
  }

  static int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is double) return val.toInt();
    final s = val.toString().replaceAll(',', '.').trim();
    return int.tryParse(s) ?? double.tryParse(s)?.toInt();
  }

  static double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    final s = val.toString().replaceAll(',', '.').trim();
    return double.tryParse(s);
  }
}
