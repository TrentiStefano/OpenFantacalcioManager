import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../models/player.dart';
import '../models/league_settings.dart';
import '../../domain/budget_calculator.dart';

class SpreadsheetExporter {
  /// Exports LISTONE and Squadra sheets to an Excel (.xlsx) file bytes
  static Uint8List exportToExcel({
    required List<Player> players,
    required LeagueSettings settings,
  }) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();

    // 1. LISTONE Sheet
    final listoneSheet = excel['LISTONE'];
    if (defaultSheet != null && defaultSheet != 'LISTONE') {
      excel.delete(defaultSheet);
    }

    // LISTONE Headers
    listoneSheet.appendRow([
      TextCellValue('Id'),
      TextCellValue('R'),
      TextCellValue('Nome'),
      TextCellValue('Squadra'),
      TextCellValue('FVM'),
      TextCellValue('% Budget'),
      TextCellValue('Valore Base Asta'),
      TextCellValue('Fascia'),
      TextCellValue('⭐ Preferito'),
      TextCellValue('Prezzo Obiettivo'),
      TextCellValue('Note'),
      TextCellValue('Stato'),
      TextCellValue('Val. Acquisto'),
    ]);

    for (final p in players) {
      final baseVal = p.calculateBaseValue(settings.initialBudget);
      listoneSheet.appendRow([
        IntCellValue(p.id),
        TextCellValue(p.role),
        TextCellValue(p.name),
        TextCellValue(p.team),
        DoubleCellValue(p.fvm),
        DoubleCellValue(p.budgetPercent),
        IntCellValue(baseVal),
        TextCellValue(p.tier),
        TextCellValue(p.isFavorite ? 'SI' : 'NO'),
        p.targetPrice != null ? IntCellValue(p.targetPrice!) : TextCellValue(''),
        TextCellValue(p.notes),
        TextCellValue(p.status.name),
        p.purchasePrice != null ? IntCellValue(p.purchasePrice!) : TextCellValue(''),
      ]);
    }

    // 2. Squadra Sheet
    final squadraSheet = excel['Squadra'];
    final summary = BudgetCalculator.computeSummary(
      players: players,
      settings: settings,
    );

    squadraSheet.appendRow([
      TextCellValue('GESTIONE ASTA & ROSA CLASSIC'),
    ]);
    squadraSheet.appendRow([TextCellValue('')]);

    // Top Summary Row
    squadraSheet.appendRow([
      TextCellValue('BUDGET INIZIALE'),
      TextCellValue('TOTALE SPESO'),
      TextCellValue('BUDGET RESIDUO'),
      TextCellValue('SLOT RIMANENTI'),
    ]);
    squadraSheet.appendRow([
      IntCellValue(summary.initialBudget),
      IntCellValue(summary.totalSpent),
      IntCellValue(summary.remainingBudget),
      IntCellValue(summary.remainingSlots),
    ]);
    squadraSheet.appendRow([TextCellValue('')]);

    // Per-Role Summary Table
    squadraSheet.appendRow([
      TextCellValue('Ruolo'),
      TextCellValue('Slot Totali'),
      TextCellValue('Acquistati'),
      TextCellValue('Rimanenti'),
      TextCellValue('Budget Allocato'),
      TextCellValue('Speso'),
      TextCellValue('Residuo'),
    ]);

    for (final role in ['P', 'D', 'C', 'A']) {
      final rSum = summary.roleSummaries[role];
      if (rSum != null) {
        squadraSheet.appendRow([
          TextCellValue(role),
          IntCellValue(rSum.totalSlots),
          IntCellValue(rSum.acquiredCount),
          IntCellValue(rSum.remainingSlots),
          IntCellValue(rSum.allocatedBudget),
          IntCellValue(rSum.spentBudget),
          IntCellValue(rSum.remainingBudget),
        ]);
      }
    }
    squadraSheet.appendRow([TextCellValue('')]);

    // Roster Purchases Table
    squadraSheet.appendRow([
      TextCellValue('TABELLA ACQUISTI ASTA (LA MIA ROSA)'),
    ]);
    squadraSheet.appendRow([
      TextCellValue('Ruolo'),
      TextCellValue('Calciatore'),
      TextCellValue('Squadra'),
      TextCellValue('Val. Acquisto'),
      TextCellValue('Note'),
    ]);

    final minePlayers = players.where((p) => p.status == PlayerStatus.mine).toList();
    for (final p in minePlayers) {
      squadraSheet.appendRow([
        TextCellValue(p.role),
        TextCellValue(p.name),
        TextCellValue(p.team),
        IntCellValue(p.purchasePrice ?? 0),
        TextCellValue(p.notes),
      ]);
    }

    final encoded = excel.encode();
    return Uint8List.fromList(encoded ?? []);
  }

  /// Exports current players and strategy board to CSV format
  static String exportToCsv({
    required List<Player> players,
    required LeagueSettings settings,
  }) {
    final rows = <List<dynamic>>[];
    rows.add([
      'Id',
      'R',
      'Nome',
      'Squadra',
      'FVM',
      '% Budget',
      'Valore Base Asta',
      'Fascia',
      '⭐ Preferito',
      'Prezzo Obiettivo',
      'Note',
      'Stato',
      'Val. Acquisto',
    ]);

    for (final p in players) {
      rows.add([
        p.id,
        p.role,
        p.name,
        p.team,
        p.fvm,
        p.budgetPercent,
        p.calculateBaseValue(settings.initialBudget),
        p.tier,
        p.isFavorite ? 'SI' : 'NO',
        p.targetPrice ?? '',
        p.notes,
        p.status.name,
        p.purchasePrice ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }
}
