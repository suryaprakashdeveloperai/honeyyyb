import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import 'sms_parser.dart';

class PdfParseResult {
  final bool isSuccess;
  final String statusMessage;
  final String? bankName;
  final String? accountNumber;
  final List<TransactionModel> transactions;
  final double totalDebit;
  final double totalCredit;
  final String rawTextSnippet;

  PdfParseResult({
    required this.isSuccess,
    required this.statusMessage,
    this.bankName,
    this.accountNumber,
    required this.transactions,
    this.totalDebit = 0.0,
    this.totalCredit = 0.0,
    this.rawTextSnippet = '',
  });
}

class PdfStatementParserService {
  static const _uuid = Uuid();

  /// Parses bank, GPay, or PhonePe PDF statement bytes into structured transactions
  static Future<PdfParseResult> parsePdfBytes(
    Uint8List bytes, {
    String? password,
  }) async {
    try {
      PdfDocument document;
      try {
        document = PdfDocument(
          inputBytes: bytes,
          password: password != null && password.isNotEmpty ? password : null,
        );
      } catch (e) {
        return PdfParseResult(
          isSuccess: false,
          statusMessage: 'Failed to open PDF. If it is password protected, please enter the password: $e',
          transactions: [],
        );
      }

      final textExtractor = PdfTextExtractor(document);
      final String fullText = textExtractor.extractText();
      document.dispose();

      if (fullText.trim().isEmpty) {
        return PdfParseResult(
          isSuccess: false,
          statusMessage: 'No extractable text found in PDF. If this is a scanned photo, please use the "PASTE TEXT" tab.',
          transactions: [],
        );
      }

      return parseStatementText(fullText);
    } catch (e) {
      return PdfParseResult(
        isSuccess: false,
        statusMessage: 'An error occurred while parsing PDF statement: $e',
        transactions: [],
      );
    }
  }

  /// Parses raw statement text (from PDF or user paste)
  static PdfParseResult parseStatementText(String fullText) {
    try {
      if (fullText.trim().isEmpty) {
        return PdfParseResult(
          isSuccess: false,
          statusMessage: 'Statement text is empty.',
          transactions: [],
        );
      }

      // Normalize unicode spaces, currency symbols, and delimiters
      String normalizedText = fullText
          .replaceAll('\u00A0', ' ')
          .replaceAll('\u200B', ' ')
          .replaceAll('\t', ' ')
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n');

      // Detect Bank or Source
      String bankName = 'Transaction Statement';
      final upperText = normalizedText.toUpperCase();
      if (upperText.contains('GOOGLE PAY') || upperText.contains('GPAY') || upperText.contains('GOOGLE ACCOUNT')) {
        bankName = 'Google Pay Statement';
      } else if (upperText.contains('PHONEPE')) {
        bankName = 'PhonePe Statement';
      } else if (upperText.contains('PAYTM')) {
        bankName = 'Paytm Statement';
      } else if (upperText.contains('HDFC')) {
        bankName = 'HDFC Bank';
      } else if (upperText.contains('STATE BANK OF INDIA') || upperText.contains('SBI')) {
        bankName = 'State Bank of India';
      } else if (upperText.contains('ICICI')) {
        bankName = 'ICICI Bank';
      } else if (upperText.contains('AXIS')) {
        bankName = 'Axis Bank';
      } else if (upperText.contains('KOTAK')) {
        bankName = 'Kotak Mahindra Bank';
      }

      // Extract Account / User snippet
      final accMatch = RegExp(r'(?:A/c\s*(?:No)?|Account\s*(?:Number)?|Ending|UPI ID|statement\s*)\s*[:#-]?\s*x*([A-Za-z0-9@._-]{3,25})', caseSensitive: false).firstMatch(normalizedText);
      final accountNumber = accMatch?.group(1);

      // 1. Official Google Pay PDF Statement Parser (extracts multi-column text token streams)
      final gpayOfficialList = _parseOfficialGooglePayPdf(normalizedText);
      if (gpayOfficialList.isNotEmpty) {
        double debit = 0.0;
        double credit = 0.0;
        for (final tx in gpayOfficialList) {
          if (tx.type == TransactionType.expense) {
            debit += tx.amount;
          } else {
            credit += tx.amount;
          }
        }

        return PdfParseResult(
          isSuccess: true,
          statusMessage: 'Successfully parsed ${gpayOfficialList.length} transactions from $bankName!',
          bankName: bankName,
          accountNumber: accountNumber,
          transactions: gpayOfficialList,
          totalDebit: debit,
          totalCredit: credit,
          rawTextSnippet: normalizedText.length > 300 ? normalizedText.substring(0, 300) : normalizedText,
        );
      }

      // 2. Structured Multi-Text Statement Parser (Date section headers + pipes)
      final structuredList = SmsParserService.parseMultiTextStatements(normalizedText);
      if (structuredList.isNotEmpty) {
        double debit = 0.0;
        double credit = 0.0;
        for (final tx in structuredList) {
          if (tx.type == TransactionType.expense) {
            debit += tx.amount;
          } else {
            credit += tx.amount;
          }
        }

        return PdfParseResult(
          isSuccess: true,
          statusMessage: 'Successfully parsed ${structuredList.length} transactions from $bankName!',
          bankName: bankName,
          accountNumber: accountNumber,
          transactions: structuredList,
          totalDebit: debit,
          totalCredit: credit,
          rawTextSnippet: normalizedText.length > 300 ? normalizedText.substring(0, 300) : normalizedText,
        );
      }

      final List<TransactionModel> parsedList = [];
      double totalDebit = 0.0;
      double totalCredit = 0.0;

      final lines = normalizedText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

      // Date Regex supporting Indian/Global and GPay/PhonePe formats
      final dateRegex = RegExp(
        r'(\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b|\b\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{2,4}\b|\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2},?\s+\d{2,4}\b|\b\d{4}-\d{2}-\d{2}\b)',
        caseSensitive: false,
      );

      // Amount Regex supporting ₹, Rs, INR, decimals or integers with commas
      final amountRegex = RegExp(r'(?:₹|INR|Rs\.?|\$)?\s*([+\-]?\d{1,3}(?:,\d{2,3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)');

      // 3. Sliding Window Parser (1 to 4 lines window)
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];

        final matchDate = dateRegex.firstMatch(line);
        if (matchDate != null) {
          final rawDateStr = matchDate.group(1)!;
          final txDate = _parseStatementDate(rawDateStr) ?? DateTime.now();

          final lineWithoutDate = line.replaceFirst(rawDateStr, ' ');
          List<double> lineAmtMatches = _extractAmountsFromLine(lineWithoutDate, amountRegex);

          if (lineAmtMatches.isNotEmpty) {
            final tx = _buildTransactionFromLine(
              line: line,
              dateStr: rawDateStr,
              date: txDate,
              amounts: lineAmtMatches,
              bankName: bankName,
              accountNumber: accountNumber,
            );

            if (tx != null) {
              parsedList.add(tx);
              if (tx.type == TransactionType.expense) {
                totalDebit += tx.amount;
              } else {
                totalCredit += tx.amount;
              }
              continue;
            }
          }

          // Check window of next 1 to 3 lines
          bool matchedInWindow = false;
          for (int windowSize = 1; windowSize <= 3 && (i + windowSize) < lines.length; windowSize++) {
            final combinedLines = [line, for (int k = 1; k <= windowSize; k++) lines[i + k]].join(' ');
            final windowAmounts = _extractAmountsFromLine(combinedLines.replaceFirst(rawDateStr, ' '), amountRegex);

            if (windowAmounts.isNotEmpty) {
              final tx = _buildTransactionFromLine(
                line: combinedLines,
                dateStr: rawDateStr,
                date: txDate,
                amounts: windowAmounts,
                bankName: bankName,
                accountNumber: accountNumber,
              );

              if (tx != null) {
                parsedList.add(tx);
                if (tx.type == TransactionType.expense) {
                  totalDebit += tx.amount;
                } else {
                  totalCredit += tx.amount;
                }
                i += windowSize;
                matchedInWindow = true;
                break;
              }
            }
          }

          if (matchedInWindow) continue;
        }

        final quickTx = _parseSingleLineQuick(line, bankName, accountNumber);
        if (quickTx != null) {
          parsedList.add(quickTx);
          if (quickTx.type == TransactionType.expense) {
            totalDebit += quickTx.amount;
          } else {
            totalCredit += quickTx.amount;
          }
        }
      }

      // 4. Fallback: Universal Regex Extractor
      if (parsedList.isEmpty) {
        final universalMatches = _extractUniversalTransactions(normalizedText, bankName, accountNumber);
        for (final tx in universalMatches) {
          parsedList.add(tx);
          if (tx.type == TransactionType.expense) {
            totalDebit += tx.amount;
          } else {
            totalCredit += tx.amount;
          }
        }
      }

      if (parsedList.isEmpty) {
        return PdfParseResult(
          isSuccess: false,
          statusMessage: 'Could not extract financial transactions. Try copying the statement text and pasting it directly in the "PASTE TEXT" tab!',
          transactions: [],
          rawTextSnippet: normalizedText.length > 300 ? normalizedText.substring(0, 300) : normalizedText,
        );
      }

      return PdfParseResult(
        isSuccess: true,
        statusMessage: 'Successfully parsed ${parsedList.length} transactions from $bankName!',
        bankName: bankName,
        accountNumber: accountNumber,
        transactions: parsedList,
        totalDebit: totalDebit,
        totalCredit: totalCredit,
        rawTextSnippet: normalizedText.length > 300 ? normalizedText.substring(0, 300) : normalizedText,
      );
    } catch (e) {
      return PdfParseResult(
        isSuccess: false,
        statusMessage: 'Failed to parse statement text: $e',
        transactions: [],
      );
    }
  }

  /// Specialized parser for Google Pay official statement PDF exports
  static List<TransactionModel> _parseOfficialGooglePayPdf(String text) {
    final List<TransactionModel> list = [];

    final gpayTxRegex = RegExp(
      r'(\d{1,2})\s+([A-Za-z]{3}),?\s+(\d{4})\s+(\d{1,2}:\d{2})\s+([AP]M)\s+(Paid\s+to|Received\s+from|Transfer\s+to|Money\s+sent\s+to)\s+([\s\S]+?)\s+(?:UPI\s+Transaction\s+ID:|Google\s+transaction\s+ID:|Transaction\s+ID:)\s*([0-9A-Za-z]+)\s+[\s\S]+?(?:₹|INR|Rs\.?)\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    );

    final matches = gpayTxRegex.allMatches(text);

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
      final amount = double.tryParse(rawAmt);

      if (amount == null || amount <= 0) continue;

      payee = payee.replaceAll(RegExp(r'\s+'), ' ').trim();
      final isCredit = action.contains('received');
      final dateStr = '$day $month $year $time $ampm';
      DateTime dt;
      try {
        dt = DateFormat('dd MMM yyyy hh:mm a', 'en_US').parseLoose(dateStr);
      } catch (_) {
        dt = DateTime.now();
      }

      final category = SmsParserService.determineCategory(payee, payee);

      list.add(
        TransactionModel(
          id: 'gpay_${upiId.substring(0, 8 < upiId.length ? 8 : upiId.length)}_${list.length}',
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
    }

    return list;
  }

  static List<TransactionModel> _extractUniversalTransactions(String text, String? bankName, String? accountNumber) {
    final List<TransactionModel> list = [];

    final regex = RegExp(
      r'(?:Paid to|Received from|Sent to|Transfer to|Payment to|UPI/)\s*([A-Za-z0-9\s._-]{2,30})[^\d\n]*?(?:₹|INR|Rs\.?|\$)\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    );

    for (final match in regex.allMatches(text)) {
      final name = match.group(1)!.trim();
      final amtStr = match.group(2)!.replaceAll(',', '').trim();
      final amount = double.tryParse(amtStr);

      if (amount != null && amount > 0) {
        final fullMatch = match.group(0)!.toLowerCase();
        final isCredit = fullMatch.contains('received') || fullMatch.contains('credited') || fullMatch.contains('refund');

        list.add(
          TransactionModel(
            id: 'pdf_uni_${_uuid.v4().substring(0, 8)}',
            title: name.isNotEmpty ? name : 'Payment',
            amount: amount,
            type: isCredit ? TransactionType.income : TransactionType.expense,
            category: SmsParserService.categorizeTransaction(name, name),
            date: DateTime.now(),
            personName: name.isNotEmpty ? name : null,
            note: match.group(0),
            bankName: bankName,
            accountNumber: accountNumber,
            source: 'pdf_statement',
          ),
        );
      }
    }

    return list;
  }

  static List<double> _extractAmountsFromLine(String line, RegExp _) {
    final List<double> amounts = [];

    final curMatches = RegExp(r'(?:₹|INR|Rs\.?|\$)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false).allMatches(line);
    for (final m in curMatches) {
      final raw = m.group(1)?.replaceAll(',', '').trim();
      if (raw != null) {
        final v = double.tryParse(raw);
        if (v != null && v > 0) amounts.add(v);
      }
    }

    if (amounts.isNotEmpty) return amounts;

    final decimalMatches = RegExp(r'\b(\d{1,3}(?:,\d{2,3})*\.\d{2})\b').allMatches(line);
    for (final m in decimalMatches) {
      final raw = m.group(1)?.replaceAll(',', '').trim();
      if (raw != null) {
        final v = double.tryParse(raw);
        if (v != null && v > 0) amounts.add(v);
      }
    }

    if (amounts.isNotEmpty) return amounts;

    final spaceMatches = RegExp(r'(?:\s|^)([1-9]\d{1,2}(?:,\d{2,3})*|\d{2,7})(?:\s|$)').allMatches(line);
    for (final m in spaceMatches) {
      final raw = m.group(1)?.replaceAll(',', '').trim();
      if (raw != null) {
        final v = double.tryParse(raw);
        if (v != null && v > 0 && v != 2024 && v != 2025 && v != 2026 && v != 2027) amounts.add(v);
      }
    }

    return amounts;
  }

  static TransactionModel? _buildTransactionFromLine({
    required String line,
    required String dateStr,
    required DateTime date,
    required List<double> amounts,
    String? bankName,
    String? accountNumber,
  }) {
    final nonZeroAmounts = amounts.where((a) => a > 0).toList();
    if (nonZeroAmounts.isEmpty) return null;

    final amount = nonZeroAmounts.first;
    final lower = line.toLowerCase();

    bool isCredit = lower.contains(' cr') ||
        lower.endsWith('cr') ||
        lower.contains('credit') ||
        lower.contains('salary') ||
        lower.contains('refund') ||
        lower.contains('received') ||
        lower.contains('money received') ||
        lower.contains('+');

    if (lower.contains(' dr') ||
        lower.contains('debit') ||
        lower.contains('paid to') ||
        lower.contains('sent to') ||
        lower.contains('spent') ||
        lower.contains('transfer to')) {
      isCredit = false;
    }

    String desc = line.replaceFirst(dateStr, '').trim();
    desc = desc.replaceAll(RegExp(r'(?:₹|INR|Rs\.?|\$)\s*[\d,]+(?:\.\d{1,2})?'), '');
    desc = desc.replaceAll(RegExp(r'\b(?:DR|CR|Dr\.|Cr\.|DEBIT|CREDIT|COMPLETED|SUCCESS|SUCCESSFUL)\b', caseSensitive: false), '');
    desc = desc.replaceAll(RegExp(r'\b(?:Google Pay|PhonePe|UPI Ref No|Txn ID|Transaction ID)[:\s0-9A-Za-z_-]+\b', caseSensitive: false), '');
    desc = desc.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (desc.isEmpty) desc = bankName ?? 'Transaction';

    String? person = SmsParserService.extractMerchant(desc);
    if (person == null || person == 'Unknown Merchant') {
      final upiMatch = RegExp(r'(?:UPI|Paid to|Received from|Transfer to)[/-:\s]+([A-Za-z\s]{3,25})', caseSensitive: false).firstMatch(desc);
      if (upiMatch != null) {
        person = upiMatch.group(1)!.trim();
      }
    }

    final category = SmsParserService.categorizeTransaction(desc, person ?? desc);

    return TransactionModel(
      id: 'pdf_${_uuid.v4().substring(0, 8)}',
      title: person != null && person.isNotEmpty && person != 'Unknown' ? person : desc,
      amount: amount,
      type: isCredit ? TransactionType.income : TransactionType.expense,
      category: category,
      date: date,
      personName: person,
      note: desc,
      bankName: bankName,
      accountNumber: accountNumber,
      source: 'pdf_statement',
    );
  }

  static TransactionModel? _parseSingleLineQuick(String line, String? bankName, String? accountNumber) {
    final lower = line.toLowerCase();
    if (!lower.contains('paid') &&
        !lower.contains('received') &&
        !lower.contains('sent') &&
        !lower.contains('credited') &&
        !lower.contains('debited') &&
        !lower.contains('upi') &&
        !lower.contains('transfer')) {
      return null;
    }

    final amtMatch = RegExp(r'(?:₹|INR|Rs\.?|\$)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false).firstMatch(line);
    if (amtMatch == null) return null;

    final rawAmt = amtMatch.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(rawAmt);
    if (amount == null || amount <= 0) return null;

    final isCredit = lower.contains('received') || lower.contains('credited') || lower.contains('refund') || lower.contains('salary');
    final merchant = SmsParserService.extractMerchant(line) ?? 'Transaction';
    final category = SmsParserService.categorizeTransaction(line, merchant);

    return TransactionModel(
      id: 'pdf_quick_${_uuid.v4().substring(0, 8)}',
      title: merchant,
      amount: amount,
      type: isCredit ? TransactionType.income : TransactionType.expense,
      category: category,
      date: DateTime.now(),
      personName: merchant != 'Transaction' ? merchant : null,
      note: line,
      bankName: bankName,
      accountNumber: accountNumber,
      source: 'pdf_statement',
    );
  }

  static DateTime? _parseStatementDate(String raw) {
    final cleaned = raw.replaceAll(',', '').trim();

    final patterns = [
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'dd/MM/yy',
      'dd-MM-yy',
      'd/M/yyyy',
      'd-M-yyyy',
      'd/M/yy',
      'd-M-yy',
      'dd MMM yyyy',
      'd MMM yyyy',
      'dd MMMM yyyy',
      'MMM dd yyyy',
      'MMMM dd yyyy',
      'yyyy-MM-dd',
      'yyyy/MM/dd',
    ];

    for (final pattern in patterns) {
      try {
        final f = DateFormat(pattern, 'en_US');
        final dt = f.parseLoose(cleaned);
        if (dt.year > 2000 && dt.year < 2050) {
          return dt;
        }
      } catch (_) {}
    }
    return null;
  }
}
