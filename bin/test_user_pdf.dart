import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:honeyyyb/services/pdf_statement_parser.dart';

void main() async {
  final file = File('E:\\gpay_statement_20260601_20260831.pdf');
  if (!await file.exists()) {
    print('File does not exist at E:\\gpay_statement_20260601_20260831.pdf');
    return;
  }

  final bytes = await file.readAsBytes();
  print('File size: ${bytes.length} bytes');

  try {
    final document = PdfDocument(inputBytes: bytes);
    final textExtractor = PdfTextExtractor(document);
    final fullText = textExtractor.extractText();
    print('Extracted text length: ${fullText.length}');
    print('--- FIRST 500 CHARACTERS ---');
    print(fullText.length > 500 ? fullText.substring(0, 500) : fullText);
    print('--- END PREVIEW ---');
    document.dispose();

    final result = PdfStatementParserService.parseStatementText(fullText);
    print('Parsed success: ${result.isSuccess}');
    print('Transactions count: ${result.transactions.length}');
    print('Status message: ${result.statusMessage}');
    print('Total Debit: ${result.totalDebit}, Total Credit: ${result.totalCredit}');
    if (result.transactions.isNotEmpty) {
      print('First 3 transactions:');
      for (var i = 0; i < 3 && i < result.transactions.length; i++) {
        final t = result.transactions[i];
        print('  #${i + 1}: ${t.date} | ${t.title} | ${t.amount} | ${t.type} | ${t.category}');
      }
    }
  } catch (e) {
    print('Error opening or parsing PDF: $e');
  }
}
