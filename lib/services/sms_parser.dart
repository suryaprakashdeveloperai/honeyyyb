import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';

class ParsedSmsResult {
  final bool isTransaction;
  final double? amount;
  final TransactionType? type;
  final String? personOrMerchant;
  final String? bankName;
  final String? accountNumber;
  final String category;
  final String rawText;
  final String? note;
  final DateTime? messageDate;
  final String? referenceId;
  final String? senderAddress;
  final bool isTruecaller;

  ParsedSmsResult({
    required this.isTransaction,
    this.amount,
    this.type,
    this.personOrMerchant,
    this.bankName,
    this.accountNumber,
    this.category = 'General',
    required this.rawText,
    this.note,
    this.messageDate,
    this.referenceId,
    this.senderAddress,
    this.isTruecaller = false,
  });
}

class SmsParserService {
  static const _uuid = Uuid();

  /// Parse a single SMS message or single log line
  static ParsedSmsResult parseSms(
    String body, {
    DateTime? messageDate,
    String? senderAddress,
  }) {
    String text = body.replaceAll('\n', ' ').trim();
    final lowerRaw = text.toLowerCase();
    final lowerSender = (senderAddress ?? '').toLowerCase();

    // Detect Truecaller indicators in sender header or text body
    final bool isTruecaller = lowerRaw.contains('truecaller') ||
        lowerRaw.contains('tc-smart') ||
        lowerSender.contains('truecl') ||
        lowerSender.contains('truecaller');

    // Clean Truecaller prefix if present
    text = text.replaceAll(RegExp(r'^\[Truecaller\]\s*', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'^Truecaller\s*(?:Pay|Smart)?:\s*', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'^TC-(?:Smart|Pay):\s*', caseSensitive: false), '');

    final lowerText = text.toLowerCase();

    final type = _determineDirection(lowerText);
    if (type == null) {
      return ParsedSmsResult(
        isTransaction: false,
        rawText: text,
        messageDate: messageDate,
        senderAddress: senderAddress,
        isTruecaller: isTruecaller,
      );
    }
    final isDebit = type == TransactionType.expense;

    // 1. Extract Amount (including ₹, Rs, INR, USD, and clean numbers)
    final amount = _extractAmount(text);
    if (amount == null || amount <= 0) {
      return ParsedSmsResult(
        isTransaction: false,
        rawText: text,
        messageDate: messageDate,
        senderAddress: senderAddress,
        isTruecaller: isTruecaller,
      );
    }

    // 2. Extract Person or Merchant Name
    String? personOrMerchant = _extractPersonOrMerchant(text, isDebit: isDebit);

    // If person not found in body, check senderAddress resolution
    if (personOrMerchant == null && senderAddress != null) {
      personOrMerchant = _resolveSenderToName(senderAddress);
    }

    // 3. Extract Bank or Wallet Name (from text body or sender address header)
    final bankName = _extractBank(text, senderAddress: senderAddress);

    // 4. Extract Account / Card snippet
    final accountNumber = _extractAccount(text);

    // 5. Extract Reference / UTR Number
    final refId = _extractRefId(text);

    // 6. Categorize based on person/merchant or text keywords
    final category = _determineCategory(text, personOrMerchant);

    final noteString = isTruecaller
        ? '[Truecaller Verified] ${refId != null ? 'Ref: $refId | ' : ''}$text'
        : (refId != null ? 'Ref: $refId | $text' : text);

    return ParsedSmsResult(
      isTransaction: true,
      amount: amount,
      type: type,
      personOrMerchant: personOrMerchant,
      bankName: bankName,
      accountNumber: accountNumber,
      category: category,
      rawText: text,
      note: noteString,
      messageDate: messageDate ?? DateTime.now(),
      referenceId: refId,
      senderAddress: senderAddress,
      isTruecaller: isTruecaller,
    );
  }

  /// Parses entire multi-line statement text blocks with date section headers
  static List<TransactionModel> parseMultiTextStatements(String rawText) {
    final List<TransactionModel> results = [];
    final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    DateTime currentSectionDate = DateTime.now();

    final dateHeaderRegex = RegExp(
      r'^\s*(\d{1,2}\s+[A-Za-z]{3,9}\s+\d{2,4}|\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{4}-\d{2}-\d{2})\s*$',
      caseSensitive: false,
    );

    // Matches line format: 11:37 AM | Paid to SANGEETHA P | ₹47 | UPI: 615282315505
    final pipeRegex = RegExp(
      r'(?:(\d{1,2}:\d{2}(?:\s*[AP]M)?)\s*\|\s*)?(Paid to|Received from|Sent to|Transfer to)\s*([^|]+)\|\s*(?:₹|INR|Rs\.?)?\s*([\d,]+(?:\.\d{1,2})?)\s*(?:\|\s*UPI:\s*([0-9]+))?',
      caseSensitive: false,
    );

    for (final line in lines) {
      final upper = line.toUpperCase();
      if (upper.startsWith('SENT:') ||
          upper.startsWith('RECEIVED:') ||
          upper.startsWith('TOTAL SPENT') ||
          upper.startsWith('TOTAL RECEIVED') ||
          upper.startsWith('STATEMENT PERIOD') ||
          upper.startsWith('TRANSACTION STATEMENT') ||
          upper.startsWith('ACCOUNT SUMMARY') ||
          upper.startsWith('OPENING BALANCE') ||
          upper.startsWith('CLOSING BALANCE')) {
        continue;
      }

      // 1. Check if line is a Date Header (e.g. "01 JUN 2026")
      final dateMatch = dateHeaderRegex.firstMatch(line);
      if (dateMatch != null) {
        final parsedDate = _parseDateString(dateMatch.group(1)!);
        if (parsedDate != null) {
          currentSectionDate = parsedDate;
          continue;
        }
      }

      // 2. Check for pipe format: "11:37 AM | Paid to SANGEETHA P | ₹47 | UPI: 615282315505"
      final pMatch = pipeRegex.firstMatch(line);
      if (pMatch != null) {
        final timeStr = pMatch.group(1);
        final action = pMatch.group(2)!.toLowerCase();
        final payee = pMatch.group(3)!.trim();
        final rawAmt = pMatch.group(4)!.replaceAll(',', '').trim();
        final upiRef = pMatch.group(5);

        final amount = double.tryParse(rawAmt);
        if (amount != null && amount > 0) {
          final isCredit = action.contains('received');
          final txDate = _applyTimeToDate(currentSectionDate, timeStr);
          final category = determineCategory(payee, payee);

          results.add(
            TransactionModel(
              id: 'stmt_${_uuid.v4().substring(0, 8)}',
              title: payee,
              amount: amount,
              type: isCredit ? TransactionType.income : TransactionType.expense,
              category: category,
              date: txDate,
              personName: payee,
              note: 'UPI: ${upiRef ?? ''} | $line',
              bankName: 'Google Pay / PhonePe',
              source: 'statement_export',
            ),
          );
          continue;
        }
      }

      // 3. Fallback to standard SMS single-line parser
      final smsRes = parseSms(line, messageDate: currentSectionDate);
      if (smsRes.isTransaction && smsRes.amount != null) {
        results.add(
          TransactionModel(
            id: 'sms_${_uuid.v4().substring(0, 8)}',
            title: smsRes.personOrMerchant ?? 'Transaction',
            amount: smsRes.amount!,
            type: smsRes.type ?? TransactionType.expense,
            category: smsRes.category,
            date: currentSectionDate,
            personName: smsRes.personOrMerchant,
            note: smsRes.note,
            bankName: smsRes.bankName,
            accountNumber: smsRes.accountNumber,
            source: 'sms_import',
          ),
        );
      }
    }

    return results;
  }

  static TransactionType? _determineDirection(String lowerText) {
    // Ignore OTP, balance inquiries, promotional without actual debits/credits
    if (lowerText.contains('otp') ||
        lowerText.contains('is your secret code') ||
        lowerText.contains('verification code') ||
        lowerText.contains('passcode')) {
      return null;
    }

    // 1. High-confidence explicit Credit indicators (Money coming in)
    if (lowerText.contains('credited') ||
        lowerText.contains('credit of') ||
        lowerText.contains('sent you') ||
        lowerText.contains('has sent you') ||
        lowerText.contains('paid you') ||
        lowerText.contains('received from') ||
        lowerText.contains('received rs') ||
        lowerText.contains('received ₹') ||
        lowerText.contains('received inr') ||
        lowerText.contains('money received') ||
        lowerText.contains('refund') ||
        lowerText.contains('cashback') ||
        lowerText.contains('salary') ||
        lowerText.contains('deposited') ||
        lowerText.contains('cr to a/c') ||
        lowerText.contains('added to your') ||
        lowerText.contains('inward rem')) {
      return TransactionType.income;
    }

    // 2. High-confidence explicit Debit indicators (Money going out)
    if (lowerText.contains('debited') ||
        lowerText.contains('debit of') ||
        lowerText.contains('you paid') ||
        lowerText.contains('paid to') ||
        lowerText.contains('you sent') ||
        lowerText.contains('sent to') ||
        lowerText.contains('transferred to') ||
        lowerText.contains('spent on') ||
        lowerText.contains('spent at') ||
        lowerText.contains('purchase of') ||
        lowerText.contains('payment of') ||
        lowerText.contains('payment to') ||
        lowerText.contains('withdrawn') ||
        lowerText.contains('dr to a/c')) {
      return TransactionType.expense;
    }

    // 3. Fallback checks
    if (lowerText.contains('cr') || lowerText.contains('received')) {
      return TransactionType.income;
    }
    if (lowerText.contains('dr') || lowerText.contains('paid') || lowerText.contains('sent') || lowerText.contains('spent')) {
      return TransactionType.expense;
    }

    return null;
  }



  static double? _extractAmount(String text) {
    final regexes = [
      RegExp(r'(?:₹|rs\.?|inr|usd|\$)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'([\d,]+(?:\.\d{1,2})?)\s*(?:₹|rs\.?|inr)', caseSensitive: false),
      RegExp(r'amount\s*(?:of)?\s*(?:₹|rs\.?|inr|\$)?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'debited\s*(?:by|with)?\s*(?:₹|rs\.?|inr|\$)?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'credited\s*(?:by|with)?\s*(?:₹|rs\.?|inr|\$)?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'\|\s*(?:₹|rs\.?|inr|\$)?\s*([\d,]+(?:\.\d{1,2})?)\s*\|', caseSensitive: false),
    ];

    for (final regex in regexes) {
      final match = regex.firstMatch(text);
      if (match != null && match.group(1) != null) {
        final rawNum = match.group(1)!.replaceAll(',', '');
        final parsed = double.tryParse(rawNum);
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    return null;
  }

  static String? _extractPersonOrMerchant(String text, {required bool isDebit}) {
    // Check pipe pattern first (e.g. "Paid to SANGEETHA P | ₹47")
    final pipeMatch = RegExp(r'(?:Paid to|Received from|Sent to|Transfer to)\s+([^|]+?)(?:\s*\||$)', caseSensitive: false).firstMatch(text);
    if (pipeMatch != null) {
      final name = pipeMatch.group(1)!.trim();
      if (name.isNotEmpty) return _capitalizeWords(name);
    }

    final patterns = isDebit
        ? [
            RegExp(r'(?:sent to|paid to|to VPA|transferred to|towards)\s+([A-Za-z0-9\.\_\-\s]{2,25})', caseSensitive: false),
            RegExp(r'at\s+([A-Za-z0-9\s]{2,20})\s+on', caseSensitive: false),
            RegExp(r'to\s+([A-Za-z0-9\s]{2,20})\s+via', caseSensitive: false),
            RegExp(r'info:\s*UPI/P2P/[^/]+/([A-Za-z0-9\s]{2,20})', caseSensitive: false),
            RegExp(r'spent on\s+([A-Za-z0-9\s]{2,20})', caseSensitive: false),
          ]
        : [
            RegExp(r'(?:received from|from VPA|by|from)\s+([A-Za-z0-9\.\_\-\s]{2,25})', caseSensitive: false),
            RegExp(r'info:\s*UPI/P2A/[^/]+/([A-Za-z0-9\s]{2,20})', caseSensitive: false),
            RegExp(r'credited by\s+([A-Za-z0-9\s]{2,20})', caseSensitive: false),
          ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        String name = match.group(1)!.trim();
        name = name.replaceAll(RegExp(r'\s+(on|via|ref|txn|val|bal|a/c|using|date).*', caseSensitive: false), '').trim();
        if (name.isNotEmpty && name.length > 1) {
          return _capitalizeWords(name);
        }
      }
    }
    return null;
  }

  static String? _extractBank(String text, {String? senderAddress}) {
    final lowerText = text.toLowerCase();
    final lowerSender = (senderAddress ?? '').toLowerCase();

    if (lowerText.contains('hdfc') || lowerSender.contains('hdfc')) return 'HDFC Bank';
    if (lowerText.contains('sbi') || lowerSender.contains('sbi')) return 'State Bank of India';
    if (lowerText.contains('icici') || lowerSender.contains('icici')) return 'ICICI Bank';
    if (lowerText.contains('axis') || lowerSender.contains('axis')) return 'Axis Bank';
    if (lowerText.contains('kotak') || lowerSender.contains('kotak')) return 'Kotak Mahindra';
    if (lowerText.contains('paytm') || lowerSender.contains('paytm')) return 'Paytm Payments';
    if (lowerText.contains('truecaller') || lowerSender.contains('truecl') || lowerSender.contains('tc-')) return 'Truecaller Pay';
    if (lowerText.contains('gpay') || lowerText.contains('google pay')) return 'Google Pay';
    if (lowerText.contains('phonepe')) return 'PhonePe';
    if (lowerText.contains('cred')) return 'CRED';
    if (lowerText.contains('airtel')) return 'Airtel Payments';

    return 'Bank / UPI';
  }

  static String? _extractAccount(String text) {
    final regex = RegExp(r'(?:a/c|account|acct|card)\s*(?:no\.?)?\s*(?:ending)?\s*[:#-]?\s*x*(\d{3,6})', caseSensitive: false);
    final match = regex.firstMatch(text);
    if (match != null && match.group(1) != null) {
      return 'XX${match.group(1)}';
    }
    return null;
  }

  static String? _extractRefId(String text) {
    final regex = RegExp(r'(?:ref(?:\s*no\.?)?|txn(?:\s*id)?|upi(?:\s*ref)?|utr)\s*[:#-]?\s*([A-Za-z0-9]{6,16})', caseSensitive: false);
    final match = regex.firstMatch(text);
    return match?.group(1);
  }

  static String _determineCategory(String text, String? personOrMerchant) {
    return determineCategory(text, personOrMerchant);
  }

  static String determineCategory(String text, String? personOrMerchant) {
    final combined = '${text.toLowerCase()} ${(personOrMerchant ?? '').toLowerCase()}';

    // Salary & Incomes
    if (combined.contains('salary') || combined.contains('stipend') || combined.contains('bonus') || combined.contains('payroll')) {
      return 'Salary & Income 💰';
    }

    // Romance & Partner Spends
    if (combined.contains('priya') ||
        combined.contains('divya') ||
        combined.contains('love') ||
        combined.contains('date') ||
        combined.contains('flowers') ||
        combined.contains('gift') ||
        combined.contains('girlfriend') ||
        combined.contains('partner') ||
        combined.contains('beauty') ||
        combined.contains('ramdev')) {
      return 'Romance & Dates 💖';
    }

    // College & Education
    if (combined.contains('college') || combined.contains('school') || combined.contains('engineering') || combined.contains('fees') || combined.contains('kongu')) {
      return 'Education / College 🎓';
    }

    // Food & Dining
    if (combined.contains('mess') ||
        combined.contains('swiggy') ||
        combined.contains('zomato') ||
        combined.contains('starbucks') ||
        combined.contains('cafe') ||
        combined.contains('restaurant') ||
        combined.contains('bakery') ||
        combined.contains('hotel') ||
        combined.contains('food') ||
        combined.contains('chettinadu') ||
        combined.contains('meenachi') ||
        combined.contains('chicken') ||
        combined.contains('vilas')) {
      return 'Food & Dining 🍔';
    }

    // Bills & Utilities & Mobile
    if (combined.contains('jio') ||
        combined.contains('airtel') ||
        combined.contains('recharge') ||
        combined.contains('prepaid') ||
        combined.contains('electricity') ||
        combined.contains('bescom') ||
        combined.contains('bill') ||
        combined.contains('wifi') ||
        combined.contains('broadband')) {
      return 'Bills & Utilities ⚡';
    }

    // Grocery & Stores
    if (combined.contains('store') ||
        combined.contains('blinkit') ||
        combined.contains('zepto') ||
        combined.contains('instamart') ||
        combined.contains('malligai') ||
        combined.contains('pazhamuthir') ||
        combined.contains('oil') ||
        combined.contains('grocery') ||
        combined.contains('market')) {
      return 'Groceries & Stores 🛒';
    }

    // Shopping
    if (combined.contains('amazon') ||
        combined.contains('flipkart') ||
        combined.contains('myntra') ||
        combined.contains('shopping') ||
        combined.contains('google play')) {
      return 'Shopping & Gear 🛍️';
    }

    // Travel & Transport
    if (combined.contains('uber') ||
        combined.contains('ola') ||
        combined.contains('rapido') ||
        combined.contains('petrol') ||
        combined.contains('fuel') ||
        combined.contains('irctc') ||
        combined.contains('metro')) {
      return 'Travel & Fuel 🚗';
    }

    // Default Person / Friends
    if (personOrMerchant != null && personOrMerchant.isNotEmpty) {
      return 'Friends & Transfers 👥';
    }

    return 'General Miscellaneous 💡';
  }

  static String? _resolveSenderToName(String sender) {
    final lower = sender.toLowerCase();
    if (lower.contains('swiggy')) return 'Swiggy';
    if (lower.contains('zomato')) return 'Zomato';
    if (lower.contains('amazon')) return 'Amazon';
    if (lower.contains('flipkart')) return 'Flipkart';
    if (lower.contains('uber')) return 'Uber';
    if (lower.contains('jio')) return 'Jio';
    if (lower.contains('airtel')) return 'Airtel';
    return null;
  }

  static String _capitalizeWords(String input) {
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  static DateTime? _parseDateString(String raw) {
    final cleaned = raw.replaceAll(',', '').trim();
    final patterns = [
      'dd MMM yyyy',
      'd MMM yyyy',
      'dd MMMM yyyy',
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'yyyy-MM-dd',
      'dd/MM/yy',
      'dd-MM-yy',
    ];

    for (final p in patterns) {
      try {
        final f = DateFormat(p, 'en_US');
        final dt = f.parseLoose(cleaned);
        if (dt.year > 2000 && dt.year < 2050) return dt;
      } catch (_) {}
    }
    return null;
  }

  static DateTime _applyTimeToDate(DateTime baseDate, String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return baseDate;
    try {
      final cleaned = timeStr.trim().toUpperCase();
      final timeFormat = DateFormat('hh:mm a', 'en_US');
      final parsedTime = timeFormat.parseLoose(cleaned);
      return DateTime(baseDate.year, baseDate.month, baseDate.day, parsedTime.hour, parsedTime.minute);
    } catch (_) {
      return baseDate;
    }
  }

  static String categorizeTransaction(String text, String merchant) {
    return determineCategory(text, merchant);
  }

  static String? extractMerchant(String text) {
    return _extractPersonOrMerchant(text, isDebit: true) ?? _extractPersonOrMerchant(text, isDebit: false);
  }
}
