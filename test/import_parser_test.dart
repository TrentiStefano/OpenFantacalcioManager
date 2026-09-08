import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_fantacalcio_manager/data/import/quotazioni_importer.dart';

void main() {
  group('QuotazioniImporter Tests', () {
    test('Imports Quotazioni_Fantacalcio_Stagione_2026_27.xlsx correctly', () async {
      final file = File('spreadsheets/Quotazioni_Fantacalcio_Stagione_2026_27.xlsx');
      expect(file.existsSync(), isTrue);

      final bytes = await file.readAsBytes();
      final result = QuotazioniImporter.parseFileBytes(
        bytes,
        'Quotazioni_Fantacalcio_Stagione_2026_27.xlsx',
      );

      // Verify row counts and sheet detection
      expect(result.totalImported, greaterThan(500));
      expect(result.cedutiCount, greaterThan(0));
      expect(result.sheetNameUsed.toLowerCase(), contains('tutti'));

      // Verify specific player mapping: Svilar (Id: 5841, Role: P, Team: Roma)
      final svilar = result.players.firstWhere((p) => p.id == 5841);
      expect(svilar.name, equals('Svilar'));
      expect(svilar.role, equals('P'));
      expect(svilar.team, equals('Roma'));
      expect(svilar.qtA, equals(18.0));
      expect(svilar.fvm, greaterThan(50));
      expect(svilar.isCeduto, isFalse);

      // Verify ceduti player detection: Di Gregorio (Id: 5876, present in Ceduti sheet)
      final diGregorio = result.players.firstWhere((p) => p.id == 5876);
      expect(diGregorio.name, equals('Di Gregorio'));
      expect(diGregorio.isCeduto, isTrue);
    });

    test('Imports Asta Fantacalcio 26_27.xlsx LISTONE correctly', () async {
      final file = File('spreadsheets/Asta Fantacalcio 26_27.xlsx');
      expect(file.existsSync(), isTrue);

      final bytes = await file.readAsBytes();
      final result = QuotazioniImporter.parseFileBytes(
        bytes,
        'Asta Fantacalcio 26_27.xlsx',
      );

      expect(result.totalImported, greaterThan(500));

      final svilar = result.players.firstWhere((p) => p.id == 5841);
      expect(svilar.name, equals('Svilar'));
      expect(svilar.budgetPercent, closeTo(0.11, 0.001));
      expect(svilar.tier, equals('TOP'));
    });
  });
}
