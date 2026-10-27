import 'package:flutter_test/flutter_test.dart';
import 'package:honeyyyb/models/transaction.dart';
import 'package:honeyyyb/services/android_sms_service.dart';
import 'package:honeyyyb/services/sms_parser.dart';

void main() {
  group('SmsParserService Tests', () {
    test('Correctly parses UPI debit transaction with recipient and amount', () {
      const sms = 'Dear Customer, your A/C XX4921 has been debited by Rs 1,500.00 to Priya Sharma via GPay UPI. Ref 940192';
      final parsed = SmsParserService.parseSms(sms);

      expect(parsed.isTransaction, isTrue);
      expect(parsed.amount, 1500.00);
      expect(parsed.type, TransactionType.expense);
      expect(parsed.personOrMerchant, 'Priya Sharma');
      expect(parsed.accountNumber, 'XX4921');
      expect(parsed.referenceId, '940192');
    });

    test('Correctly parses salary credit notification', () {
      const sms = 'Your A/C XX4921 is credited with INR 48,000.00 towards Monthly Salary stipend from TechCorp. Ref SAL9901.';
      final parsed = SmsParserService.parseSms(sms);

      expect(parsed.isTransaction, isTrue);
      expect(parsed.amount, 48000.00);
      expect(parsed.type, TransactionType.income);
      expect(parsed.category, contains('Salary'));
    });

    test('Ignores OTP and non-financial SMS', () {
      const sms = 'Your OTP for verification is 492019. Do not share this with anyone.';
      final parsed = SmsParserService.parseSms(sms);

      expect(parsed.isTransaction, isFalse);
    });

    test('Correctly parses Truecaller Smart SMS & Truecaller Pay', () {
      const truecallerSms = '[Truecaller] Debited Rs 1,850.00 to Priya Sharma via Truecaller Pay. Ref TC902194';
      final parsed = SmsParserService.parseSms(truecallerSms, senderAddress: 'AD-TRUECL');

      expect(parsed.isTransaction, isTrue);
      expect(parsed.isTruecaller, isTrue);
      expect(parsed.amount, 1850.00);
      expect(parsed.type, TransactionType.expense);
      expect(parsed.personOrMerchant, 'Priya Sharma');
      expect(parsed.referenceId, 'TC902194');
      expect(parsed.bankName, contains('Truecaller'));
    });
  });

  group('4-Month SMS Date & Sync Tests', () {
    test('4-month cutoff date is approximately 120 days ago', () {
      final cutoff = AndroidSmsService.getFourMonthsAgoDate();
      final now = DateTime.now();
      final differenceInDays = now.difference(cutoff).inDays;

      expect(differenceInDays, inInclusiveRange(115, 125));
    });

    test('Simulated 4-month inbox returns valid transactions spanning 4 months', () async {
      final syncResult = await AndroidSmsService.scanLastFourMonthsInbox();

      expect(syncResult.isSuccess, isTrue);
      expect(syncResult.parsedTransactions.isNotEmpty, isTrue);
      expect(syncResult.newTransactionsAdded, greaterThan(0));

      // Test deduplication
      final secondSync = await AndroidSmsService.scanLastFourMonthsInbox(
        existingTransactions: syncResult.parsedTransactions,
      );

      expect(secondSync.newTransactionsAdded, equals(0));
      expect(secondSync.duplicatesSkipped, equals(syncResult.parsedTransactions.length));
    });
  });
}
