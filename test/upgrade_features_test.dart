import 'package:flutter_test/flutter_test.dart';
import 'package:honeyyyb/models/transaction.dart';
import 'package:honeyyyb/services/ai_advisor_service.dart';
import 'package:honeyyyb/services/notification_parser_service.dart';
import 'package:honeyyyb/services/sms_parser.dart';

void main() {
  group('Credit vs Debit Direction & Parsing Accuracy Tests', () {
    test('Notification with incoming money is strictly parsed as Income (Credit)', () {
      final notif1 = NotificationParserService.parsePushNotification(
        title: 'Google Pay',
        body: 'Prasath JR sent you ₹500',
      );
      expect(notif1.isFinancial, isTrue);
      expect(notif1.transaction?.type, TransactionType.income);
      expect(notif1.transaction?.amount, 500.0);
      expect(notif1.transaction?.title, contains('Prasath'));

      final notif2 = NotificationParserService.parsePushNotification(
        title: 'PhonePe',
        body: 'Received ₹1,000 from SANGEETHA P via UPI',
      );
      expect(notif2.isFinancial, isTrue);
      expect(notif2.transaction?.type, TransactionType.income);
      expect(notif2.transaction?.amount, 1000.0);

      final notif3 = NotificationParserService.parsePushNotification(
        title: 'Bank Alert',
        body: 'Your A/C ending 1746 is credited with Rs 2,500 by transfer from Rahul',
      );
      expect(notif3.isFinancial, isTrue);
      expect(notif3.transaction?.type, TransactionType.income);
      expect(notif3.transaction?.amount, 2500.0);
    });

    test('Notification with outgoing money is strictly parsed as Expense (Debit)', () {
      final notif1 = NotificationParserService.parsePushNotification(
        title: 'Google Pay',
        body: 'Paid ₹190 to KARAIKUDI CHETTINADU MESS',
      );
      expect(notif1.isFinancial, isTrue);
      expect(notif1.transaction?.type, TransactionType.expense);
      expect(notif1.transaction?.amount, 190.0);

      final notif2 = NotificationParserService.parsePushNotification(
        title: 'PhonePe',
        body: 'You paid ₹47 to SANGEETHA P',
      );
      expect(notif2.isFinancial, isTrue);
      expect(notif2.transaction?.type, TransactionType.expense);
      expect(notif2.transaction?.amount, 47.0);
    });

    test('SMS Parser correctly extracts Credit vs Debit', () {
      final smsCredit = SmsParserService.parseSms(
        'Dear Customer, Rs 500.00 credited to A/C XX1746 on 02-JUN-26 by UPI/Prasath JR/Ref 615328053807',
      );
      expect(smsCredit.isTransaction, isTrue);
      expect(smsCredit.type, TransactionType.income);
      expect(smsCredit.amount, 500.0);

      final smsDebit = SmsParserService.parseSms(
        'Dear Customer, Rs 47.00 debited from A/C XX1746 on 01-JUN-26 to SANGEETHA P via UPI',
      );
      expect(smsDebit.isTransaction, isTrue);
      expect(smsDebit.type, TransactionType.expense);
      expect(smsDebit.amount, 47.0);
    });
  });

  group('Bilingual Tanglish & Tamil AI Conversation Tests', () {
    final transactions = [
      TransactionModel(
        id: 't1',
        title: 'Priya T',
        amount: 1500.0,
        type: TransactionType.expense,
        category: 'Romance & Dates 💖',
        date: DateTime.now(),
        personName: 'Priya',
      ),
      TransactionModel(
        id: 't2',
        title: 'Prasath JR',
        amount: 500.0,
        type: TransactionType.income,
        category: 'Friends & Transfers 👥',
        date: DateTime.now(),
        personName: 'Prasath JR',
      ),
    ];
    final budget = BudgetModel(monthlyLimit: 25000);

    test('AI responds sweetly to Tanglish greetings and food check-ins', () {
      final greeting = AiAdvisorService.processQuery(
        query: 'Vanakkam epdi iruka da?',
        transactions: transactions,
        budget: budget,
        currency: '₹',
      );
      expect(greeting.toLowerCase(), anyOf(contains('vanakkam'), contains('nalla iruken'), contains('happy')));

      final foodCheck = AiAdvisorService.processQuery(
        query: 'Saptya da?',
        transactions: transactions,
        budget: budget,
        currency: '₹',
      );
      expect(foodCheck.toLowerCase(), anyOf(contains('saap'), contains('food'), contains('battery')));
    });

    test('AI responds with comedy/joke in Tanglish', () {
      final joke = AiAdvisorService.processQuery(
        query: 'Oru joke sollu',
        transactions: transactions,
        budget: budget,
        currency: '₹',
      );
      expect(joke.toLowerCase(), anyOf(contains('joke'), contains('purse'), contains('shopping'), contains('rupee'), contains('macha'), contains('honeyyyb')));
    });

    test('AI responds to Tanglish balance and person queries', () {
      final balanceQuery = AiAdvisorService.processQuery(
        query: 'Kaasu evlo iruku?',
        transactions: transactions,
        budget: budget,
        currency: '₹',
      );
      expect(balanceQuery, contains('Balance'));

      final priyaQuery = AiAdvisorService.processQuery(
        query: 'Priya ku evlo aachu?',
        transactions: transactions,
        budget: budget,
        currency: '₹',
      );
      expect(priyaQuery, contains('Priya'));
      expect(priyaQuery, contains('1,500.00'));
    });
  });
}
