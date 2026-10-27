import 'package:flutter_test/flutter_test.dart';
import 'package:honeyyyb/models/transaction.dart';
import 'package:honeyyyb/services/ai_advisor_service.dart';
import 'package:honeyyyb/services/notification_parser_service.dart';
import 'package:honeyyyb/services/pdf_statement_parser.dart';
import 'package:honeyyyb/services/statement_generator_service.dart';

void main() {
  group('Comprehensive Honeyyyb Feature Tests', () {
    test('Enhanced PDF & Long Text Statement Parser correctly parses complex multi-line text', () {
      final longStatementText = '''
HDFC BANK ACCOUNT STATEMENT
Account Ending: XX4921
Customer Name: Surya Prakash

Date       Narration                               Debit (INR)   Credit (INR)
15/08/2026 UPI/PRIYA SHARMA/940192 Flowers Date     1,850.00      0.00
18/08/2026 POS STARBUCKS CAFE                       450.00        0.00
01/08/2026 ACH MONTHLY SALARY TECHCORP              0.00          52,000.00
05/08/2026 SWIGGY FOOD ORDER                        380.00        0.00
10/08/2026 UPI/RAHUL VERMA/990182 SPLIT EXPENSE     0.00          1,500.00
''';

      final result = PdfStatementParserService.parseStatementText(longStatementText);

      expect(result.isSuccess, isTrue);
      expect(result.transactions.length, greaterThanOrEqualTo(4));
      expect(result.totalDebit, greaterThan(2000.0));
      expect(result.totalCredit, greaterThan(50000.0));

      final priyaTx = result.transactions.firstWhere((t) => t.category.contains('Romance') || (t.personName ?? '').contains('Priya'));
      expect(priyaTx.amount, 1850.0);
      expect(priyaTx.type, TransactionType.expense);
    });

    test('Push Notification Parser correctly extracts GPay, PhonePe, and Paytm alerts', () {
      // 1. Google Pay
      final gpayRes = NotificationParserService.parsePushNotification(
        title: 'Google Pay',
        body: 'Paid ₹1,500 to Priya Sharma (Date Night)',
      );
      expect(gpayRes.isFinancial, isTrue);
      expect(gpayRes.transaction!.amount, 1500.0);
      expect(gpayRes.transaction!.type, TransactionType.expense);
      expect(gpayRes.transaction!.personName, 'Priya Sharma');
      expect(gpayRes.transaction!.category, contains('Romance'));

      // 2. PhonePe
      final phonePeRes = NotificationParserService.parsePushNotification(
        title: 'PhonePe',
        body: 'Payment of ₹850 to Zomato was successful.',
      );
      expect(phonePeRes.isFinancial, isTrue);
      expect(phonePeRes.transaction!.amount, 850.0);
      expect(phonePeRes.transaction!.type, TransactionType.expense);

      // 3. Security OTP ignored
      final otpRes = NotificationParserService.parsePushNotification(
        title: 'Google Pay',
        body: 'Your OTP is 492019 for login verification.',
      );
      expect(otpRes.isFinancial, isFalse);
    });

    test('AI Advisor Service computes Financial Health Score and answers queries', () {
      final sampleTxs = [
        TransactionModel(
          id: '1',
          title: 'TechCorp Salary',
          amount: 50000.0,
          type: TransactionType.income,
          category: 'Salary & Income 💰',
          date: DateTime.now(),
        ),
        TransactionModel(
          id: '2',
          title: 'Priya Flowers & Dinner',
          amount: 2500.0,
          type: TransactionType.expense,
          category: 'Romance & Dates 💖',
          personName: 'Priya Sharma',
          date: DateTime.now(),
        ),
        TransactionModel(
          id: '3',
          title: 'Starbucks Coffee',
          amount: 450.0,
          type: TransactionType.expense,
          category: 'Food & Dining 🍔',
          date: DateTime.now(),
        ),
      ];

      final budget = BudgetModel(monthlyLimit: 30000.0);

      // 1. Health Report
      final report = AiAdvisorService.generateReport(
        transactions: sampleTxs,
        budget: budget,
        currency: '₹',
      );
      expect(report.healthScore, greaterThanOrEqualTo(70));
      expect(report.savingsRate, greaterThan(50.0));
      expect(report.safeDailySpend, greaterThan(0));

      // 2. Person Query
      final priyaReply = AiAdvisorService.processQuery(
        query: 'How much did I spend on Priya?',
        transactions: sampleTxs,
        budget: budget,
        currency: '₹',
      );
      expect(priyaReply, contains('Priya'));
      expect(priyaReply, contains('2,500.00'));

      // 3. Affordability Query
      final affordReply = AiAdvisorService.processQuery(
        query: 'Can I afford a ₹1,200 dinner date?',
        transactions: sampleTxs,
        budget: budget,
        currency: '₹',
      );
      expect(affordReply, contains('Yes'));
    });

    test('Statement Generator Service creates valid CSV and PDF bytes', () {
      final sampleTxs = [
        TransactionModel(
          id: '1',
          title: 'Dinner Date',
          amount: 1500.0,
          type: TransactionType.expense,
          category: 'Romance & Dates 💖',
          personName: 'Priya Sharma',
          date: DateTime.now(),
        ),
      ];

      // CSV test
      final csv = StatementGeneratorService.generateCsv(
        transactions: sampleTxs,
        currency: '₹',
      );
      expect(csv, contains('Dinner Date'));
      expect(csv, contains('1500.00'));
      expect(csv, contains('Romance & Dates'));

      // PDF bytes test
      final pdfBytes = StatementGeneratorService.generatePdfStatementBytes(
        transactions: sampleTxs,
        currency: '₹',
        periodTitle: 'This Month',
      );
      expect(pdfBytes.lengthInBytes, greaterThan(100));
    });
  });
}
