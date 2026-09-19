import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uank/core/theme/app_theme.dart';
import 'package:uank/core/utils/spreadsheet_helper.dart';
import 'package:uank/core/widgets/app_pagination.dart';
import 'package:uank/domain/entities/transaction.dart';

void main() {
  group('AppPagination Widget Tests', () {
    testWidgets('Renders pagination info and buttons correctly', (tester) async {
      int activePage = 1;
      int pageSize = 25;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: AppPagination(
              currentPage: activePage,
              totalItems: 120,
              itemsPerPage: pageSize,
              onPageChanged: (p) => activePage = p,
              onItemsPerPageChanged: (s) => pageSize = s,
            ),
          ),
        ),
      );

      // Verify "Showing 1-25 of 120 entries"
      expect(find.text('Showing '), findsOneWidget);
      expect(find.text('1-25'), findsOneWidget);
      expect(find.text(' of '), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
      expect(find.text(' entries'), findsOneWidget);

      // Verify page number pills
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Tap on page 2
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(activePage, equals(2));
    });

    testWidgets('Prev and Next navigation triggers callbacks', (tester) async {
      int activePage = 2;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AppPagination(
                  currentPage: activePage,
                  totalItems: 50,
                  itemsPerPage: 10,
                  onPageChanged: (p) {
                    setState(() => activePage = p);
                  },
                );
              },
            ),
          ),
        ),
      );

      // Tap Next
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(activePage, equals(3));

      // Tap Prev
      await tester.tap(find.text('Prev'));
      await tester.pumpAndSettle();
      expect(activePage, equals(2));
    });
  });

  group('SpreadsheetHelper Unit Tests', () {
    test('Correctly parses CSV formatted text with IDR and MYR', () {
      const csvData = '''Tanggal,Keterangan,Masuk ke,Mata Uang,Nominal,Kategori,Setara IDR
01/09/2026,Transfer dari Mba Una,Tabungan Pribadi,IDR,1000000.00,Transfer,1000000
11/09/2026,Topup TNG,Touch 'n Go Wallet,RM,231.39,Kebutuhan,998911
18/09/2026,Card Holder,Touch 'n Go Wallet,RM,6.39,Belanja,27586''';

      final rows = SpreadsheetHelper.parseSpreadsheetContent(csvData);
      expect(rows.length, equals(3));

      expect(rows[0].description, equals('Transfer dari Mba Una'));
      expect(rows[0].currency, equals('IDR'));
      expect(rows[0].amount, equals(1000000.0));
      expect(rows[0].categoryName, equals('Transfer'));

      expect(rows[1].description, equals('Topup TNG'));
      expect(rows[1].currency, equals('MYR'));
      expect(rows[1].amount, equals(231.39));

      expect(rows[2].description, equals('Card Holder'));
      expect(rows[2].currency, equals('MYR'));
      expect(rows[2].amount, equals(6.39));
      expect(rows[2].categoryName, equals('Belanja'));
    });

    test('Generates valid CSV export string from transaction list', () {
      final transactions = [
        Transaction(
          id: 'tx-1',
          accountId: 'acc-1',
          categoryId: 'cat-1',
          type: 'income',
          amount: 500000,
          amountIdr: 500000,
          description: 'Gaji Bulanan',
          transactionDate: DateTime(2026, 9, 1),
        ),
        Transaction(
          id: 'tx-2',
          accountId: 'acc-2',
          categoryId: 'cat-2',
          type: 'expense',
          amount: 25.50,
          amountIdr: 90000,
          description: 'Makan Siang',
          transactionDate: DateTime(2026, 9, 2),
        ),
      ];

      final csv = SpreadsheetHelper.generateCsv(
        transactions: transactions,
        accountNames: {'acc-1': 'BCA', 'acc-2': 'Maybank'},
        categoryNames: {'cat-1': 'Gaji', 'cat-2': 'Makanan'},
      );

      expect(csv, contains('Tanggal,Tipe,Kategori,Keterangan,Akun / Sumber,Mata Uang,Nominal,Setara IDR'));
      expect(csv, contains('2026-09-01,Pemasukan (Income),Gaji,Gaji Bulanan,BCA,IDR,500000.00,500000.00'));
      expect(csv, contains('2026-09-02,Pengeluaran (Expense),Makanan,Makan Siang,Maybank,MYR,25.50,90000.00'));
    });
  });
}
