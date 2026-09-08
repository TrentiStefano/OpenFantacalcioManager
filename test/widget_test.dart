import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:open_fantacalcio_manager/main.dart';
import 'package:open_fantacalcio_manager/presentation/shared/editable_budget_cell.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('OpenFantacalcioApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: OpenFantacalcioApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Open Fantacalcio Manager'), findsWidgets);
    expect(find.text('OFM'), findsOneWidget);
  });

  testWidgets('EditableBudgetCell renders percentage and triggers callback', (WidgetTester tester) async {
    double updatedPct = 0.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditableBudgetCell(
            budgetPercent: 0.11,
            onPercentChanged: (val) => updatedPct = val,
          ),
        ),
      ),
    );

    expect(find.text('11.0%'), findsOneWidget);

    // Tap to edit
    await tester.tap(find.text('11.0%'));
    await tester.pumpAndSettle();

    // Enter new value
    await tester.enterText(find.byType(TextField), '12.5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(updatedPct, closeTo(0.125, 0.001));
  });
}
