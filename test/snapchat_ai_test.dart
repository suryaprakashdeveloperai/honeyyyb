import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyyyb/models/transaction.dart';
import 'package:honeyyyb/providers/finance_provider.dart';
import 'package:honeyyyb/services/ai_advisor_service.dart';
import 'package:honeyyyb/widgets/floating_honey_ai_bubble.dart';
import 'package:honeyyyb/widgets/honey_ai_avatar_widget.dart';
import 'package:honeyyyb/widgets/snapchat_ai_chat_modal.dart';
import 'package:provider/provider.dart';

void main() {
  group('Snapchat My AI & Honey AI Character Tests', () {
    testWidgets('HoneyAiAvatarWidget renders cleanly with online indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HoneyAiAvatarWidget(size: 48, showOnlineIndicator: true),
          ),
        ),
      );

      expect(find.byType(HoneyAiAvatarWidget), findsOneWidget);
    });

    testWidgets('FloatingHoneyAiBubble renders on screen inside Stack', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Center(child: Text('Background Content')),
                FloatingHoneyAiBubble(currentScreenName: 'Dashboard'),
              ],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FloatingHoneyAiBubble), findsOneWidget);
      expect(find.text('HONEY AI'), findsOneWidget);
      expect(find.text('Ask Co-Pilot'), findsOneWidget);
    });

    testWidgets('SnapchatAiChatModal renders message thread and quick chips', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => FinanceProvider(),
          child: const MaterialApp(
            home: Scaffold(
              body: SnapchatAiChatModal(currentScreenName: 'People Tracker'),
            ),
          ),
        ),
      );

      // Advance past delayed voice timer
      await tester.pump(const Duration(milliseconds: 500));

      // Verify header and screen context badge
      expect(find.text('Honey AI'), findsOneWidget);
      expect(find.text('MY AI'), findsOneWidget);
      expect(find.text('🌸 Epdi iruka da?'), findsOneWidget);
      expect(find.text('💰 Kaasu evlo iruku?'), findsOneWidget);
    });

    test('AiAdvisorService generates accurate romance & Priya advice', () {
      final sampleTxs = [
        TransactionModel(
          id: '1',
          title: 'Dinner with Priya',
          amount: 2200.0,
          type: TransactionType.expense,
          category: 'Romance & Dates 💖',
          personName: 'Priya Sharma',
          date: DateTime.now(),
        ),
      ];
      final budget = BudgetModel(monthlyLimit: 30000.0);

      final reply = AiAdvisorService.processQuery(
        query: 'How much on Priya?',
        transactions: sampleTxs,
        budget: budget,
        currency: '₹',
      );

      expect(reply, contains('Priya'));
      expect(reply, contains('2,200.00'));
    });
  });
}
