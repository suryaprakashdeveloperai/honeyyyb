import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import 'sms_parser.dart';

class NotificationParseResult {
  final bool isFinancial;
  final TransactionModel? transaction;
  final String appName; // "Google Pay", "PhonePe", "Paytm", "Bank", etc.
  final String summary;

  NotificationParseResult({
    required this.isFinancial,
    this.transaction,
    required this.appName,
    required this.summary,
  });
}

class NotificationParserService {
  static const _uuid = Uuid();

  /// Parses Android Push Notification Title and Body (from GPay, PhonePe, Paytm, etc.)
  static NotificationParseResult parsePushNotification({
    required String title,
    required String body,
    String? packageName,
  }) {
    final fullText = '$title $body'.trim();
    final lower = fullText.toLowerCase();

    // 1. Identify Source App
    String appName = 'Payment App';
    if (lower.contains('google pay') || lower.contains('gpay') || (packageName ?? '').contains('com.google.android.apps.nbu.paisa.user')) {
      appName = 'Google Pay';
    } else if (lower.contains('phonepe') || (packageName ?? '').contains('com.phonepe.app')) {
      appName = 'PhonePe';
    } else if (lower.contains('paytm') || (packageName ?? '').contains('net.one97.paytm')) {
      appName = 'Paytm';
    } else if (lower.contains('cred') || (packageName ?? '').contains('com.dreamplug.androidapp')) {
      appName = 'CRED';
    } else if (lower.contains('bhim')) {
      appName = 'BHIM UPI';
    } else if (lower.contains('bank') || lower.contains('hdfc') || lower.contains('sbi') || lower.contains('icici') || lower.contains('axis') || lower.contains('kotak')) {
      appName = 'Bank Alert';
    }

    // 2. Check if notification is an OTP or non-financial alert (ignore OTPs)
    if (lower.contains('otp') || lower.contains('verification code') || lower.contains('login') || lower.contains('security code')) {
      return NotificationParseResult(
        isFinancial: false,
        appName: appName,
        summary: 'Ignored non-transaction security notification / OTP',
      );
    }

    // 3. Extract Amount
    final amountRegex = RegExp(r'(?:₹|INR|Rs\.?|\$)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false);
    final amtMatch = amountRegex.firstMatch(fullText);

    if (amtMatch == null) {
      return NotificationParseResult(
        isFinancial: false,
        appName: appName,
        summary: 'No financial transaction amount detected in notification',
      );
    }

    final rawAmt = amtMatch.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(rawAmt);
    if (amount == null || amount <= 0) {
      return NotificationParseResult(
        isFinancial: false,
        appName: appName,
        summary: 'Invalid amount found in notification',
      );
    }

    // 4. Determine Debit vs Credit (Precise Direction Logic)
    bool isCredit = false;

    // Explicit Credit patterns (Money coming IN)
    if (lower.contains('sent you') ||
        lower.contains('has sent you') ||
        lower.contains('sent to your') ||
        lower.contains('paid you') ||
        lower.contains('received') ||
        lower.contains('credited') ||
        lower.contains('credit of') ||
        lower.contains('refund') ||
        lower.contains('cashback') ||
        lower.contains('salary') ||
        lower.contains('money received') ||
        lower.contains('deposited')) {
      isCredit = true;
    }

    // Explicit Debit patterns (Money going OUT)
    if (lower.contains('you paid') ||
        lower.contains('paid to') ||
        lower.contains('you sent') ||
        lower.contains('sent to') ||
        lower.contains('debited') ||
        lower.contains('debit of') ||
        lower.contains('spent') ||
        lower.contains('payment of') ||
        lower.contains('purchase of') ||
        lower.contains('transferred to') ||
        lower.contains('transfer to')) {
      isCredit = false;
    }

    // 5. Extract Payee / Merchant / Person
    String? merchant;

    // Pattern A: "Prasath JR sent you ₹500" or "Priya paid you ₹1000"
    final sentYouMatch = RegExp(r'([A-Za-z0-9\s&]+?)\s+(?:sent you|paid you|has sent you)', caseSensitive: false).firstMatch(body.isNotEmpty ? body : fullText);
    if (sentYouMatch != null) {
      merchant = sentYouMatch.group(1)!.trim();
    }

    // Pattern B: "Paid ₹190 to KARAIKUDI CHETTINADU MESS" or "Paid to SANGEETHA P"
    if (merchant == null || merchant.isEmpty) {
      final paidToMatch = RegExp(r'(?:paid\s*(?:₹|INR|Rs\.?|\$)?\s*[\d,]+(?:\.\d{1,2})?\s*to|paid to|sent to|payment of\s*(?:₹|INR|Rs\.?|\$)?\s*[\d,]+(?:\.\d{1,2})?\s*to|payment to|transferred to|transfer to)\s+([A-Za-z0-9\s&]+?)(?:\s+successful|\s+was successful|\s+using|\s+from|\s+via|\(|\.|$)', caseSensitive: false).firstMatch(fullText);
      if (paidToMatch != null) {
        merchant = paidToMatch.group(1)!.trim();
      }
    }

    // Pattern C: "Received ₹1000 from SANGEETHA P" or "Received from Priya"
    if (merchant == null || merchant.isEmpty) {
      final receivedFromMatch = RegExp(r'(?:received\s*(?:₹|INR|Rs\.?|\$)?\s*[\d,]+(?:\.\d{1,2})?\s*from|received from|sent from|received payment from)\s+([A-Za-z0-9\s&]+?)(?:\s+via|\s+in|\(|\.|$)', caseSensitive: false).firstMatch(fullText);
      if (receivedFromMatch != null) {
        merchant = receivedFromMatch.group(1)!.trim();
      }
    }

    // Pattern D: "by transfer from Rahul"
    if (merchant == null || merchant.isEmpty) {
      final transferFromMatch = RegExp(r'(?:transfer from|from)\s+([A-Za-z0-9\s&]+?)(?:\s+via|\s+in|\(|\.|$)', caseSensitive: false).firstMatch(body);
      if (transferFromMatch != null) {
        merchant = transferFromMatch.group(1)!.trim();
      }
    }

    if (merchant == null || merchant.isEmpty) {
      merchant = SmsParserService.extractMerchant(fullText) ?? appName;
    }

    // Strip app names or keywords if prefixed
    merchant = merchant.replaceAll(RegExp(r'^(?:Google Pay|PhonePe|Paytm|BHIM|Bank Alert)\s*', caseSensitive: false), '').trim();
    merchant = merchant.replaceAll(RegExp(r'\b(?:₹|INR|Rs\.?|\$)\s*[\d,]+(?:\.\d{1,2})?\b', caseSensitive: false), '').trim();
    if (merchant.isEmpty) merchant = appName;

    // 6. Categorize (Multi-Category Engine)
    final category = SmsParserService.categorizeTransaction(fullText, merchant);

    final transaction = TransactionModel(
      id: 'notif_${_uuid.v4().substring(0, 8)}',
      title: merchant,
      amount: amount,
      type: isCredit ? TransactionType.income : TransactionType.expense,
      category: category,
      date: DateTime.now(),
      personName: merchant != appName && merchant != 'Unknown Merchant' ? merchant : null,
      note: fullText,
      bankName: appName,
      source: 'push_notification',
    );

    return NotificationParseResult(
      isFinancial: true,
      transaction: transaction,
      appName: appName,
      summary: 'Parsed $appName ${isCredit ? 'Credit' : 'Debit'} of ₹$rawAmt for $merchant ($category)',
    );
  }
}
