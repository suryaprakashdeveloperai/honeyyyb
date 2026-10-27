import 'package:flutter_test/flutter_test.dart';
import 'package:honeyyyb/models/transaction.dart';
import 'package:honeyyyb/services/pdf_statement_parser.dart';
import 'package:honeyyyb/services/sms_parser.dart';

void main() {
  const userSampleText = '''
TRANSACTION STATEMENT
Statement Period: 01 June 2026 - 31 August 2026

SENT: ₹1,99,072.42
RECEIVED: ₹1,42,694


01 JUN 2026
11:37 AM | Paid to SANGEETHA P | ₹47 | UPI: 615282315505
02:22 PM | Paid to KARAIKUDI CHETTINADU MESS | ₹190 | UPI: 615277928456
08:26 PM | Paid to Arul Prabakaran Subramanian | ₹150 | UPI: 615293367924
08:36 PM | Paid to Murugan Store | ₹32 | UPI: 615227774493

02 JUN 2026
09:14 AM | Paid to Manimekalai Jayaraj | ₹60 | UPI: 651909601437
01:34 PM | Paid to KARAIKUDI CHETTINADU MESS | ₹190 | UPI: 651945803062
08:11 PM | Paid to KONGU ENGINEERING COLLEGE | ₹90,000 | UPI: 651930863995
08:15 PM | Received from Prasath JR | ₹500 | UPI: 615328053807

03 JUN 2026
07:28 PM | Paid to SRI SENTHIL MURUGAN PAZHAMUTHIR CHOLAI | ₹40 | UPI: 615468333459

04 JUN 2026
01:54 PM | Paid to HARINAKASH AGENCIES | ₹50 | UPI: 615583785558
08:08 PM | Paid to Kumaran Sathasivam | ₹21.82 | UPI: 652193118895

09 JUN 2026
08:28 AM | Paid to Prasath JR | ₹50 | UPI: 652640122196
09:34 AM | Received from Divya T | ₹400 | UPI: 616012936381
11:52 AM | Paid to Jio Prepaid | ₹350.90 | UPI: 652687851707

11 JUN 2026
07:55 PM | Paid to Divya T | ₹20,000 | UPI: 652858493503
''';

  group('User Exact Statement Parsing Tests', () {
    test('SmsParserService.parseMultiTextStatements correctly extracts all transactions and dates', () {
      final txs = SmsParserService.parseMultiTextStatements(userSampleText);

      expect(txs.length, 15);

      // Check first item on 01 JUN 2026
      expect(txs[0].title, 'SANGEETHA P');
      expect(txs[0].amount, 47.0);
      expect(txs[0].type, TransactionType.expense);
      expect(txs[0].date.day, 1);
      expect(txs[0].date.month, 6);
      expect(txs[0].date.year, 2026);

      // Check college payment on 02 JUN 2026
      final collegeTx = txs.firstWhere((t) => t.title.contains('KONGU'));
      expect(collegeTx.amount, 90000.0);
      expect(collegeTx.type, TransactionType.expense);
      expect(collegeTx.category, contains('Education'));

      // Check credit from Prasath JR on 02 JUN 2026
      final prasathTx = txs.firstWhere((t) => t.title.contains('Prasath') && t.type == TransactionType.income);
      expect(prasathTx.amount, 500.0);
      expect(prasathTx.type, TransactionType.income);

      // Check Divya T on 11 JUN 2026
      final divyaTx = txs.firstWhere((t) => t.title.contains('Divya') && t.amount == 20000.0);
      expect(divyaTx.amount, 20000.0);
      expect(divyaTx.date.day, 11);
      expect(divyaTx.date.month, 6);
    });

    test('PdfStatementParserService.parseStatementText correctly parses the full statement', () {
      final res = PdfStatementParserService.parseStatementText(userSampleText);

      expect(res.isSuccess, isTrue);
      expect(res.transactions.length, 15);
      expect(res.totalDebit, greaterThan(110000));
      expect(res.totalCredit, 900.0);
    });
  });
}
