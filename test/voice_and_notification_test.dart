import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyyyb/models/transaction.dart';
import 'package:honeyyyb/services/notification_parser_service.dart';
import 'package:honeyyyb/services/voice_assistant_service.dart';
import 'package:honeyyyb/widgets/floating_honey_ai_bubble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceAssistantService Tests', () {
    test('Correctly sanitizes markdown and emojis for natural human speech', () {
      const rawText = '🌸 **Honey AI Alert!** You spent ₹1,450.00 on *Priya* 💖. Bal: ₹48,000.';
      final speechText = VoiceAssistantService.sanitizeForSpeech(rawText);

      expect(speechText.contains('**'), isFalse);
      expect(speechText.contains('🌸'), isFalse);
      expect(speechText.contains('💖'), isFalse);
      expect(speechText.contains('Rupees'), isTrue);
      expect(speechText, contains('Honey AI Alert! You spent Rupees 1,450.00 on Priya'));
    });
  });

  group('Live Payment Notification Parser Tests', () {
    test('Auto-detects Google Pay UPI payment notification', () {
      final notif = NotificationParserService.parsePushNotification(
        title: 'Paid ₹850.00',
        body: 'You paid ₹850.00 to Starbucks Cafe using UPI.',
        packageName: 'com.google.android.apps.nbu.paisa.user',
      );

      expect(notif.isFinancial, isTrue);
      expect(notif.transaction?.amount, 850.0);
      expect(notif.transaction?.type, TransactionType.expense);
      expect(notif.transaction?.title, 'Starbucks Cafe');
      expect(notif.appName, 'Google Pay');
    });

    test('Auto-detects PhonePe credit notification', () {
      final notif = NotificationParserService.parsePushNotification(
        title: 'Money Received',
        body: 'You have received ₹2,500.00 from Priya Sharma via UPI.',
        packageName: 'com.phonepe.app',
      );

      expect(notif.isFinancial, isTrue);
      expect(notif.transaction?.amount, 2500.0);
      expect(notif.transaction?.type, TransactionType.income);
      expect(notif.transaction?.title, 'Priya Sharma');
      expect(notif.appName, 'PhonePe');
    });
  });

  group('Draggable Floating Honey AI Bubble Widget Tests', () {
    testWidgets('Renders draggable floating bubble and responds to pan gestures', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Main Screen Content')),
                FloatingHoneyAiBubble(
                  currentScreenName: 'Dashboard',
                  onTap: () => tapped = true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('HONEY AI'), findsOneWidget);
      expect(find.text('Ask Co-Pilot'), findsOneWidget);

      // Perform tap
      await tester.tap(find.text('HONEY AI'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tapped, isTrue);

      // Perform pan drag
      final gesture = await tester.startGesture(tester.getCenter(find.text('HONEY AI')));
      await gesture.moveBy(const Offset(50, -100));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('HONEY AI'), findsOneWidget);
    });
  });
}
