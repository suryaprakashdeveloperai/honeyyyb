import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../theme/neo_brutalism_theme.dart';
import '../widgets/honey_ai_avatar_widget.dart';
import '../widgets/neo_badge.dart';
import '../widgets/neo_banner.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';
import '../widgets/snapchat_ai_chat_modal.dart';
import 'add_transaction_screen.dart';
import 'budget_goals_screen.dart';
import 'live_notification_screen.dart';
import 'people_tracker_screen.dart';
import 'sms_import_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final currency = provider.currencySymbol;
    final formatter = NumberFormat('#,##0.00');

    final balance = provider.totalBalance;
    final income = provider.totalIncome;
    final expense = provider.totalExpense;
    final recentTxs = provider.transactions.take(6).toList();
    final topLedgers = provider.personLedgers.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding & Romantic Subtitle Banner
          NeoHeaderBanner(
            onSmsTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SmsImportScreen()),
              );
            },
          ),
          const SizedBox(height: 20),

          // Total Balance Hero Card
          NeoCard(
            backgroundColor: NeoColors.cardWhite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'TOTAL NET BALANCE',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: NeoColors.borderBlack,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    NeoBadge(
                      label: balance >= 0 ? 'HEALTHY' : 'SPENDING ALERT',
                      color: balance >= 0 ? NeoColors.mintGreen : NeoColors.spiderRed,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$currency${formatter.format(balance)}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: NeoColors.borderBlack,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Income vs Expense Sub-cards
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: NeoColors.mintGreen.withAlpha(76),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: NeoColors.borderBlack, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.arrow_downward, size: 16, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  'INCOME',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$currency${formatter.format(income)}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.green[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: NeoColors.spiderRed.withAlpha(51),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: NeoColors.borderBlack, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.arrow_upward, size: 16, color: NeoColors.spiderRed),
                                const SizedBox(width: 4),
                                Text(
                                  'EXPENSES',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$currency${formatter.format(expense)}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: NeoColors.spiderRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 4-Month SMS Inbox Auto-Sync Banner
          NeoCard(
            backgroundColor: NeoColors.honeyYellow,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: NeoColors.spiderRed,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: NeoColors.borderBlack, width: 2),
                  ),
                  child: const Icon(Icons.sync_alt_rounded, color: NeoColors.cardWhite, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AUTO-SYNC LAST 4 MONTHS',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: NeoColors.borderBlack,
                        ),
                      ),
                      Text(
                        'Reads bank SMS & updates payments',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                NeoButton(
                  color: NeoColors.mintGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  onPressed: provider.isSyncingSms
                      ? null
                      : () async {
                          final res = await provider.syncLastFourMonthsSms();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  res.isSuccess
                                      ? '🎉 ${res.newTransactionsAdded} new payments synced from last 4 months!'
                                      : res.statusMessage,
                                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                                ),
                                backgroundColor: res.isSuccess ? Colors.green[800] : NeoColors.spiderRed,
                              ),
                            );
                          }
                        },
                  child: provider.isSyncingSms
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: NeoColors.borderBlack),
                        )
                      : Text(
                          'SYNC',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Honey AI Interactive Co-Pilot Card (Snapchat My AI style)
          InkWell(
            onTap: () {
              SnapchatAiChatModal.show(context, currentScreenName: 'Dashboard');
            },
            child: NeoCard(
              backgroundColor: NeoColors.pastelPink,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const HoneyAiAvatarWidget(size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'HONEY AI CO-PILOT',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: NeoColors.borderBlack,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('🌸', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Text(
                          'Tap to chat • Priya spends, date budget & advice',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: NeoColors.cardWhite,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: NeoColors.borderBlack, width: 1.5),
                    ),
                    child: Text(
                      'CHAT',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: NeoColors.borderBlack,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Quick Action Buttons Grid (4 Grid items)
          Row(
            children: [
              Expanded(
                child: NeoButton(
                  color: NeoColors.honeyYellow,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline, color: NeoColors.borderBlack, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'ADD MONEY',
                        style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NeoButton(
                  color: NeoColors.pastelPink,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BudgetGoalsScreen()),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.track_changes_rounded, color: NeoColors.borderBlack, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'BUDGETS 🎯',
                        style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: NeoButton(
                  color: NeoColors.neonTeal,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LiveNotificationScreen()),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_active_outlined, color: NeoColors.borderBlack, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'GPAY / NOTIFS 📲',
                        style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NeoButton(
                  color: NeoColors.cardWhite,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SmsImportScreen()),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.picture_as_pdf_outlined, color: NeoColors.borderBlack, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'UPLOAD PDF 📄',
                        style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // People Ledger Quick Banner
          if (topLedgers.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PEOPLE LEDGER 👥',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: NeoColors.borderBlack,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PeopleTrackerScreen()),
                    );
                  },
                  child: Text(
                    'VIEW ALL',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: NeoColors.borderBlack,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: topLedgers.map((ledger) {
                  final net = ledger.netBalance;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: NeoCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      backgroundColor: NeoColors.cardWhite,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: NeoColors.honeyYellow,
                            child: Text(
                              ledger.personName[0].toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.w900,
                                color: NeoColors.borderBlack,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ledger.personName,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${net >= 0 ? '+' : ''}$currency${formatter.format(net)}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: net >= 0 ? Colors.green[800] : NeoColors.spiderRed,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Recent Transactions Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT TRANSACTIONS',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: NeoColors.borderBlack,
                ),
              ),
              Text(
                '${provider.transactions.length} ITEMS',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (recentTxs.isEmpty)
            const NeoCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No transactions added yet. Click Add Money or Parse SMS!'),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentTxs.length,
              itemBuilder: (context, index) {
                final tx = recentTxs[index];
                final isExp = tx.type == TransactionType.expense;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: NeoCard(
                    padding: const EdgeInsets.all(12),
                    backgroundColor: NeoColors.cardWhite,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isExp ? NeoColors.pastelPink : NeoColors.mintGreen,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: NeoColors.borderBlack, width: 2),
                          ),
                          child: Icon(
                            isExp ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 20,
                            color: NeoColors.borderBlack,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: NeoColors.borderBlack,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  NeoBadge(label: tx.category),
                                  if (tx.personName != null)
                                    NeoBadge(
                                      label: '👤 ${tx.personName}',
                                      color: NeoColors.honeyYellow,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${isExp ? '-' : '+'}$currency${formatter.format(tx.amount)}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: isExp ? NeoColors.spiderRed : Colors.green[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
