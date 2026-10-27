import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:honeyyyb/models/transaction.dart';
import 'package:honeyyyb/services/sms_parser.dart';

void main() {
  test('Parse Google Pay PDF directly using regex', () async {
    final file = File(r'E:\gpay_statement_20260601_20260831.pdf');
    if (!file.existsSync()) {
      print('Skipping test: sample file not present at E:\\gpay_statement_20260601_20260831.pdf');
      return;
    }
    final bytes = await file.readAsBytes();

    final document = PdfDocument(inputBytes: bytes);
    final textExtractor = PdfTextExtractor(document);
    final text = textExtractor.extractText();
    document.dispose();

    final gpayTxRegex = RegExp(
      r'(\d{1,2})\s+([A-Za-z]{3}),?\s+(\d{4})\s+(\d{1,2}:\d{2})\s+([AP]M)\s+(Paid\s+to|Received\s+from|Transfer\s+to|Money\s+sent\s+to)\s+([\s\S]+?)\s+(?:UPI\s+Transaction\s+ID:|Google\s+transaction\s+ID:|Transaction\s+ID:)\s*([0-9A-Za-z]+)\s+[\s\S]+?(?:₹|INR|Rs\.?)\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    );

    final matches = gpayTxRegex.allMatches(text).toList();
    print('Found GPay Matches count: ${matches.length}');

    final List<TransactionModel> txs = [];
    double totalDebit = 0.0;
    double totalCredit = 0.0;

    for (final m in matches) {
      final day = m.group(1)!;
      final month = m.group(2)!;
      final year = m.group(3)!;
      final time = m.group(4)!;
      final ampm = m.group(5)!;
      final action = m.group(6)!.toLowerCase();
      var payee = m.group(7)!.replaceAll('\n', ' ').trim();
      final upiId = m.group(8)!;
      final rawAmt = m.group(9)!.replaceAll(',', '');
      final amount = double.tryParse(rawAmt) ?? 0.0;

      // Clean payee
      payee = payee.replaceAll(RegExp(r'\s+'), ' ').trim();

      final isCredit = action.contains('received');
      final dateStr = '$day $month $year $time $ampm';
      final dt = DateFormat('dd MMM yyyy hh:mm a').parseLoose(dateStr) ?? DateTime.now();

      final category = SmsParserService.determineCategory(payee, payee);

      txs.add(
        TransactionModel(
          id: 'gpay_pdf_${upiId.substring(0, 8 < upiId.length ? 8 : upiId.length)}_${txs.length}',
          title: payee,
          amount: amount,
          type: isCredit ? TransactionType.income : TransactionType.expense,
          category: category,
          date: dt,
          personName: payee,
          note: 'UPI: $upiId | $payee',
          bankName: 'Google Pay',
          source: 'gpay_pdf',
        ),
      );

      if (isCredit) {
        totalCredit += amount;
      } else {
        totalDebit += amount;
      }
    }

    print('Successfully extracted: ${txs.length} transactions');
    print('Total Debit: ₹$totalDebit (expected ₹1,99,072.42)');
    print('Total Credit: ₹$totalCredit (expected ₹1,42,694)');

    for (var i = 0; i < 5 && i < txs.length; i++) {
      final t = txs[i];
      print('Tx #${i + 1}: ${DateFormat('dd MMM yyyy hh:mm a').format(t.date)} | ${t.type == TransactionType.expense ? 'DR' : 'CR'} | ${t.title} | ₹${t.amount} | ${t.category}');
    }

    expect(txs.length, greaterThan(100));
  });
}
