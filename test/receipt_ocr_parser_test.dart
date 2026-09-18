import 'package:flutter_test/flutter_test.dart';
import 'package:uank/core/utils/currency_formatter.dart';
import 'package:uank/core/utils/receipt_ocr_parser.dart';

void main() {
  group('ReceiptOcrParser Text Parsing Tests', () {
    test('Correctly parses Indonesian Alfamart/Indomaret receipt with IDR and Total', () {
      const sampleReceipt = '''
      INDOMARET POINT
      JL. SUDIRMAN NO. 45
      08123456789
      
      2X ROTI TAWAR     30.000
      1X SUSU UHT       18.500
      SUBTOTAL          48.500
      PPN 11%            5.335
      TOTAL BAYAR       53.835
      TUNAI            100.000
      KEMBALI           46.165
      
      18/09/2026 14:30
      TERIMA KASIH
      ''';

      final result = ReceiptOcrParser.parseText(sampleReceipt);

      expect(result.currency, equals('IDR'));
      expect(result.amount, equals(53835.0));
      expect(result.merchant, equals('INDOMARET POINT'));
      expect(result.date, equals(DateTime(2026, 9, 18)));
    });

    test('Correctly parses Malaysian receipt with RM, decimals, and change', () {
      const sampleReceipt = '''
      FAMILYMART KLCC
      KUALA LUMPUR
      
      MATCHA LATTE       RM 9.90
      ODEN SET           RM 15.50
      SUBTOTAL           RM 25.40
      SST 6%             RM  1.52
      GRAND TOTAL        RM 26.92
      CASH               RM 50.00
      CHANGE             RM 23.08
      
      DATE: 2026-09-18 19:20
      THANK YOU COME AGAIN
      ''';

      final result = ReceiptOcrParser.parseText(sampleReceipt);

      expect(result.currency, equals('MYR'));
      expect(result.amount, equals(26.92));
      expect(result.merchant, equals('FAMILYMART KLCC'));
      expect(result.date, equals(DateTime(2026, 9, 18)));
    });

    test('Correctly parses Malaysian Touch n Go / e-Wallet RM 6.39 screenshot', () {
      const sampleTng = '''
      Touch 'n Go eWallet
      PAYMENT SUCCESSFUL
      
      RM 6.39
      
      RECIPIENT: 7-ELEVEN MALAYSIA
      DATE: 18 Sep 2026, 17:42
      REF NO: TNG202609181234
      TOTAL: RM 6.39
      ''';

      final result = ReceiptOcrParser.parseText(sampleTng);

      expect(result.currency, equals('MYR'));
      expect(result.amount, equals(6.39));
      expect(result.merchant, equals('7-ELEVEN MALAYSIA'));
      expect(result.date, equals(DateTime(2026, 9, 18)));
    });

    test('Correctly parses Bank Transfer proof slip', () {
      const sampleTransferProof = '''
      TRANSFER BERHASIL
      BANK MANDIRI
      
      TANGGAL: 18 Sep 2026
      NOMINAL TRANSFER
      Rp 1.500.000
      BIAYA ADMIN: Rp 0
      TOTAL: Rp 1.500.000
      
      DARI: TABUNGAN UTAMA
      KE: BANK BCA - JOHN DOE
      ''';

      final result = ReceiptOcrParser.parseText(sampleTransferProof);

      expect(result.currency, equals('IDR'));
      expect(result.amount, equals(1500000.0));
      expect(result.merchant, equals('BANK BCA - JOHN DOE'));
      expect(result.date, equals(DateTime(2026, 9, 18)));
    });

    test('Correctly parses DuitNow Malaysian Transfer Proof', () {
      const sampleDuitNow = '''
      DUITNOW TRANSFER SUCCESSFUL
      MAYBANK
      
      AMOUNT TRANSFERRED: RM 150.00
      DATE: 18/09/2026
      RECIPIENT: AHMAD BIN ALI
      REFERENCE: DINNER BILL
      ''';

      final result = ReceiptOcrParser.parseText(sampleDuitNow);

      expect(result.currency, equals('MYR'));
      expect(result.amount, equals(150.0));
      expect(result.merchant, equals('AHMAD BIN ALI'));
      expect(result.date, equals(DateTime(2026, 9, 18)));
    });

    test('Correctly parses BCA Mobile Transfer Screenshot', () {
      const sampleBcaScreenshot = '''
      M-TRANSFER BERHASIL
      18/09/2026 15:45:12
      
      DARI: 1234567890
      KE: 0987654321
      PENERIMA: SITI AMINAH
      JUMLAH: Rp 350.000,00
      BERITA: Uang Arisan
      ''';

      final result = ReceiptOcrParser.parseText(sampleBcaScreenshot);

      expect(result.currency, equals('IDR'));
      expect(result.amount, equals(350000.0));
      expect(result.merchant, equals('SITI AMINAH'));
      expect(result.date, equals(DateTime(2026, 9, 18)));
    });

    test('Correctly parses QRIS / GoPay Payment Screenshot', () {
      const sampleQrisScreenshot = '''
      PEMBAYARAN BERHASIL
      
      Rp 85.000
      
      MERCHANT: KOPI KENANGAN GRAND INDONESIA
      METODE PEMBAYARAN: GOPAY
      WAKTU: 18 September 2026 12:15
      TOTAL PEMBAYARAN: Rp 85.000
      ''';

      final result = ReceiptOcrParser.parseText(sampleQrisScreenshot);

      expect(result.currency, equals('IDR'));
      expect(result.amount, equals(85000.0));
      expect(result.merchant, equals('KOPI KENANGAN GRAND INDONESIA'));
      expect(result.date, equals(DateTime(2026, 9, 18)));
    });
  });

  group('CurrencyInputFormatter Unit Tests', () {
    test('Formats decimal MYR values correctly', () {
      expect(CurrencyInputFormatter.format(6.39, currency: 'MYR'), equals('6.39'));
      expect(CurrencyInputFormatter.format(1250.5, currency: 'MYR'), equals('1,250.50'));
      expect(CurrencyInputFormatter.format(100, currency: 'MYR'), equals('100'));
    });

    test('Formats integer IDR values correctly', () {
      expect(CurrencyInputFormatter.format(150000, currency: 'IDR'), equals('150.000'));
      expect(CurrencyInputFormatter.format(2500000, currency: 'IDR'), equals('2.500.000'));
    });

    test('Parses decimal and thousand-separated strings correctly', () {
      expect(CurrencyInputFormatter.parse('6.39', currency: 'MYR'), equals(6.39));
      expect(CurrencyInputFormatter.parse('1,250.50', currency: 'MYR'), equals(1250.50));
      expect(CurrencyInputFormatter.parse('150.000', currency: 'IDR'), equals(150000));
      expect(CurrencyInputFormatter.parse('350.000,00', currency: 'IDR'), equals(350000));
    });
  });
}
