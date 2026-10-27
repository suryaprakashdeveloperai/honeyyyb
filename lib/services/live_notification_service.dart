import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import 'notification_parser_service.dart';

class LiveNotificationService {
  static const MethodChannel _channel = MethodChannel('com.suryaprakash.honeyyyb/notifications');
  static const EventChannel _eventChannel = EventChannel('com.suryaprakash.honeyyyb/notification_stream');

  static StreamSubscription? _subscription;
  static bool isListening = false;
  static final List<NotificationParseResult> detectedLiveNotifications = [];

  /// Checks whether Android Notification Access permission is enabled for Honeyyyb
  static Future<bool> isListenerEnabled() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final bool enabled = await _channel.invokeMethod<bool>('isListenerEnabled') ?? false;
        return enabled;
      } catch (e) {
        return false;
      }
    }
    return true;
  }

  /// Opens Android Settings screen to grant Notification Access
  static Future<void> openListenerSettings() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod('openListenerSettings');
      } catch (e) {
        debugPrint('Error opening listener settings: $e');
      }
    }
  }

  /// Starts listening to real-time incoming status bar notifications (GPay, PhonePe, Paytm, etc.)
  static void startRealtimeListener({
    required Function(TransactionModel transaction) onTransactionAutoDetected,
  }) {
    if (isListening) return;

    if (!kIsWeb && Platform.isAndroid) {
      _subscription = _eventChannel.receiveBroadcastStream().listen((dynamic event) {
        if (event is Map) {
          final map = Map<String, dynamic>.from(event);
          final title = (map['title'] as String?) ?? '';
          final body = (map['body'] as String?) ?? '';
          final packageName = (map['packageName'] as String?) ?? '';

          final result = NotificationParserService.parsePushNotification(
            title: title,
            body: body,
            packageName: packageName,
          );

          if (result.isFinancial && result.transaction != null) {
            detectedLiveNotifications.add(result);
            onTransactionAutoDetected(result.transaction!);
          }
        }
      }, onError: (dynamic error) {
        debugPrint('Notification stream error: $error');
      });

      isListening = true;
    }
  }

  /// Stops the real-time notification stream listener
  static void stopListener() {
    _subscription?.cancel();
    _subscription = null;
    isListening = false;
  }
}
