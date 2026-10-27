import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import 'sms_parser.dart';

class SmsSyncResult {
  final int totalScanned;
  final int newTransactionsAdded;
  final int duplicatesSkipped;
  final DateTime startDate;
  final DateTime endDate;
  final List<TransactionModel> parsedTransactions;
  final String statusMessage;
  final bool isSuccess;

  SmsSyncResult({
    required this.totalScanned,
    required this.newTransactionsAdded,
    required this.duplicatesSkipped,
    required this.startDate,
    required this.endDate,
    required this.parsedTransactions,
    required this.statusMessage,
    required this.isSuccess,
  });
}

class AndroidSmsService {
  static const MethodChannel _channel = MethodChannel('com.suryaprakash.honeyyyb/sms_reader');
  static const Uuid _uuid = Uuid();

  /// Gets the start cutoff date for 4 months ago
  static DateTime getFourMonthsAgoDate() {
    final now = DateTime.now();
    int targetMonth = now.month - 4;
    int targetYear = now.year;
    if (targetMonth <= 0) {
      targetMonth += 12;
      targetYear -= 1;
    }
    final daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    final day = now.day > daysInMonth ? daysInMonth : now.day;
    return DateTime(targetYear, targetMonth, day, 0, 0, 0);
  }

  /// Scans device SMS inbox for messages starting from the last 4 months
  static Future<SmsSyncResult> scanLastFourMonthsInbox({
    List<TransactionModel> existingTransactions = const [],
  }) async {
    final now = DateTime.now();
    final startDate = getFourMonthsAgoDate();

    // Check if platform supports native SMS querying (Android)
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final bool isGranted = await _channel.invokeMethod<bool>('checkPermission') ?? false;
        if (!isGranted) {
          final bool requested = await _channel.invokeMethod<bool>('requestPermission') ?? false;
          if (!requested) {
            return SmsSyncResult(
              totalScanned: 0,
              newTransactionsAdded: 0,
              duplicatesSkipped: 0,
              startDate: startDate,
              endDate: now,
              parsedTransactions: [],
              statusMessage: 'SMS permission was denied. Please grant SMS access in settings.',
              isSuccess: false,
            );
          }
        }

        // Query Android Inbox via Pure Native MethodChannel (Zero Gradle dependencies!)
        final List<dynamic>? rawMessages = await _channel.invokeMethod<List<dynamic>>(
          'getSmsMessages',
          {'sinceEpoch': startDate.millisecondsSinceEpoch},
        );

        final List<Map<String, dynamic>> messages = (rawMessages ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        int scannedCount = 0;
        int duplicates = 0;
        final List<TransactionModel> newTxList = [];

        for (final msg in messages) {
          final dateEpoch = msg['date'] as int?;
          final msgDate = dateEpoch != null ? DateTime.fromMillisecondsSinceEpoch(dateEpoch) : now;

          // Check if message is within last 4 months window
          if (msgDate.isBefore(startDate)) {
            continue;
          }

          scannedCount++;
          final body = (msg['body'] as String?) ?? '';
          final address = msg['address'] as String?;
          if (body.isEmpty) continue;

          final parsed = SmsParserService.parseSms(
            body,
            messageDate: msgDate,
            senderAddress: address,
          );
          if (parsed.isTransaction && parsed.amount != null && parsed.type != null) {
            // Check for duplicate with existing transactions
            final isDuplicate = existingTransactions.any((tx) => _isSameTransaction(tx, parsed, msgDate));

            if (isDuplicate) {
              duplicates++;
            } else {
              final newTx = TransactionModel(
                id: _uuid.v4(),
                title: parsed.personOrMerchant != null
                    ? '${parsed.type == TransactionType.expense ? 'Paid' : 'Recv'}: ${parsed.personOrMerchant}'
                    : (parsed.type == TransactionType.expense ? 'Expense' : 'Income'),
                amount: parsed.amount!,
                type: parsed.type!,
                category: parsed.category,
                date: msgDate,
                personName: parsed.personOrMerchant,
                bankName: parsed.bankName,
                accountNumber: parsed.accountNumber,
                senderAddress: address,
                note: parsed.note ?? body,
                source: parsed.isTruecaller ? 'truecaller_sms' : 'sms_auto',
              );
              newTxList.add(newTx);
            }
          }
        }

        return SmsSyncResult(
          totalScanned: scannedCount,
          newTransactionsAdded: newTxList.length,
          duplicatesSkipped: duplicates,
          startDate: startDate,
          endDate: now,
          parsedTransactions: newTxList,
          statusMessage: 'Successfully scanned $scannedCount messages from the last 4 months and found ${newTxList.length} new transactions!',
          isSuccess: true,
        );
      } catch (e) {
        return SmsSyncResult(
          totalScanned: 0,
          newTransactionsAdded: 0,
          duplicatesSkipped: 0,
          startDate: startDate,
          endDate: now,
          parsedTransactions: [],
          statusMessage: 'Error querying native SMS inbox: $e',
          isSuccess: false,
        );
      }
    } else {
      // Return simulated 4-month data for Web/Desktop/iOS testing
      return _generateSimulatedFourMonthsSync(startDate, now, existingTransactions);
    }
  }

  static bool _isSameTransaction(TransactionModel tx, ParsedSmsResult parsed, DateTime msgDate) {
    if ((tx.amount - (parsed.amount ?? 0)).abs() < 0.01 &&
        tx.type == parsed.type &&
        (tx.date.year == msgDate.year && tx.date.month == msgDate.month && tx.date.day == msgDate.day)) {
      return true;
    }
    return false;
  }

  /// Simulated 4-month inbox data for Web/Desktop/Test environment
  static SmsSyncResult _generateSimulatedFourMonthsSync(
    DateTime startDate,
    DateTime endDate,
    List<TransactionModel> existingTransactions,
  ) {
    final simulatedSmsList = [
      {
        'body': 'Rs 1,500.00 debited from A/C XX4921 on 15-Aug-2026 for UPI/Priya Sharma/Flowers & Date. Bal: Rs 48,200.',
        'address': 'VK-HDFCBK',
        'date': DateTime.now().subtract(const Duration(days: 12)),
      },
      {
        'body': 'Your A/C XX4921 is credited by Rs 50,000.00 on 01-Aug-2026 by ACH TechCorp Salary. Bal: Rs 82,500.',
        'address': 'AD-HDFCBK',
        'date': DateTime.now().subtract(const Duration(days: 28)),
      },
      {
        'body': 'Paid Rs 450.00 to Starbucks Cafe on 20-Jul-2026 via Google Pay UPI. Ref: 98120491.',
        'address': 'GPAY',
        'date': DateTime.now().subtract(const Duration(days: 42)),
      },
      {
        'body': 'Debited Rs 2,800.00 for Dinner Date at Olive Bistro with Priya on 14-Jun-2026.',
        'address': 'PHONEPE',
        'date': DateTime.now().subtract(const Duration(days: 78)),
      },
      {
        'body': 'Your A/C XX4921 is credited by Rs 50,000.00 on 01-May-2026 by Salary TechCorp. Bal: Rs 95,000.',
        'address': 'AD-HDFCBK',
        'date': DateTime.now().subtract(const Duration(days: 110)),
      },
    ];

    final List<TransactionModel> newTxList = [];
    int duplicates = 0;

    for (final item in simulatedSmsList) {
      final body = item['body'] as String;
      final address = item['address'] as String;
      final date = item['date'] as DateTime;

      if (date.isBefore(startDate)) continue;

      final parsed = SmsParserService.parseSms(body, messageDate: date, senderAddress: address);
      if (parsed.isTransaction && parsed.amount != null && parsed.type != null) {
        final isDuplicate = existingTransactions.any((tx) => _isSameTransaction(tx, parsed, date));
        if (isDuplicate) {
          duplicates++;
        } else {
          newTxList.add(
            TransactionModel(
              id: _uuid.v4(),
              title: parsed.personOrMerchant != null
                  ? '${parsed.type == TransactionType.expense ? 'Paid' : 'Recv'}: ${parsed.personOrMerchant}'
                  : (parsed.type == TransactionType.expense ? 'Expense' : 'Income'),
              amount: parsed.amount!,
              type: parsed.type!,
              category: parsed.category,
              date: date,
              personName: parsed.personOrMerchant,
              bankName: parsed.bankName,
              accountNumber: parsed.accountNumber,
              senderAddress: address,
              note: parsed.note ?? body,
              source: parsed.isTruecaller ? 'truecaller_sms' : 'sms_auto',
            ),
          );
        }
      }
    }

    return SmsSyncResult(
      totalScanned: simulatedSmsList.length,
      newTransactionsAdded: newTxList.length,
      duplicatesSkipped: duplicates,
      startDate: startDate,
      endDate: endDate,
      parsedTransactions: newTxList,
      statusMessage: 'Simulated 4-month inbox sync completed: ${newTxList.length} transactions imported!',
      isSuccess: true,
    );
  }
}
