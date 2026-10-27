import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyyyb/models/transaction.dart';
import 'package:honeyyyb/services/pdf_statement_parser.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  group('PdfStatementParserService Tests', () {
    test('Correctly extracts and categorizes transactions from PDF bytes', () async {
      // Create a test PDF document using syncfusion
      final document = PdfDocument();
      final page = document.pages.add();

      final font = PdfStandardFont(PdfFontFamily.helvetica, 11);
      final text = '''
HDFC Bank Account Statement
Account Ending: XX4921
15/08/2026 UPI/PRIYA SHARMA/940192 Flowers Date 1,500.00 DR
01/08/2026 ACH SALARY TECHCORP 48,000.00 CR
20/07/2026 POS STARBUCKS CAFE 450.00 DR
''';

      page.graphics.drawString(text, font, bounds: const Rect.fromLTWH(10, 10, 500, 400));
      final List<int> bytesList = document.saveSync();
      document.dispose();

      // Now parse the generated PDF with PdfStatementParserService
      final result = await PdfStatementParserService.parsePdfBytes(Uint8List.fromList(bytesList));

      expect(result.isSuccess, isTrue);
      expect(result.transactions.length, greaterThanOrEqualTo(2));

      final dateTx = result.transactions.firstWhere((t) => t.category.contains('Romance') || (t.personName ?? '').contains('Priya'));
      expect(dateTx.amount, 1500.00);
      expect(dateTx.type, TransactionType.expense);

      final salaryTx = result.transactions.firstWhere((t) => t.type == TransactionType.income);
      expect(salaryTx.amount, 48000.00);
    });
  });
}
