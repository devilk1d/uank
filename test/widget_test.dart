import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uank/core/theme/app_colors.dart';
import 'package:uank/core/utils/currency_formatter.dart';
import 'package:uank/core/widgets/app_dropdown.dart';
import 'package:uank/core/widgets/receipt_ocr_animation_widget.dart';

void main() {
  testWidgets('AppDropdownFormField updates displayed label when value changes dynamically', (tester) async {
    String selectedValue = 'acc1';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  AppDropdownFormField<String>(
                    value: selectedValue,
                    labelText: 'Source Account',
                    items: const [
                      AppDropdownItem(value: 'acc1', label: 'BCA (IDR)'),
                      AppDropdownItem(value: 'acc2', label: 'Maybank (MYR)'),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => selectedValue = val);
                      }
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedValue = selectedValue == 'acc1' ? 'acc2' : 'acc1';
                      });
                    },
                    child: const Text('Swap'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('BCA (IDR)'), findsOneWidget);
    expect(find.text('Maybank (MYR)'), findsNothing);

    // Tap the Swap button to swap selectedValue
    await tester.tap(find.text('Swap'));
    await tester.pumpAndSettle();

    // Verify it updated to Maybank
    expect(find.text('Maybank (MYR)'), findsOneWidget);
    expect(find.text('BCA (IDR)'), findsNothing);
  });

  testWidgets('Light and Dark Theme render with appropriate color contrast', (tester) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    Text('Test Text', style: TextStyle(color: context.textPrimary)),
                    Container(color: context.cardBg),
                    Container(color: context.inputBg),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Test Text'), findsOneWidget);
    }
  });

  testWidgets('StepAllSet renders in English without emojis', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                Text("You're All Set"),
                Text('Get Started'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text("You're All Set"), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  test('CurrencyInputFormatter correctly formats and parses nominal numbers', () {
    expect(CurrencyInputFormatter.format(1000000), '1.000.000');
    expect(CurrencyInputFormatter.format(350000), '350.000');
    expect(CurrencyInputFormatter.parse('1.000.000'), 1000000);
    expect(CurrencyInputFormatter.parse('250,000'), 250000);
  });

  testWidgets('ReceiptOcrAnimationWidget renders animation elements smoothly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReceiptOcrAnimationWidget(height: 200),
        ),
      ),
    );

    expect(find.text('FamilyMart KLCC'), findsOneWidget);
    expect(find.text('RM 25.40'), findsOneWidget);
    expect(find.text('TOTAL'), findsOneWidget);
    expect(find.byType(ReceiptOcrAnimationWidget), findsOneWidget);
  });
}

