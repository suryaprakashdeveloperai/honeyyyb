import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../theme/neo_brutalism_theme.dart';
import '../widgets/neo_badge.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';

class BudgetGoalsScreen extends StatelessWidget {
  const BudgetGoalsScreen({super.key});

  void _showEditMonthlyBudgetDialog(BuildContext context, FinanceProvider provider) {
    final controller = TextEditingController(text: provider.budget.monthlyLimit.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeoColors.honeyYellow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: NeoColors.borderBlack, width: 3),
        ),
        title: Text(
          'SET MONTHLY BUDGET',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            prefixText: '${provider.currencySymbol} ',
            labelText: 'Monthly Spending Target',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: NeoColors.borderBlack, width: 2),
            ),
          ),
        ),
        actions: [
          NeoButton(
            color: NeoColors.cardWhite,
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800)),
          ),
          NeoButton(
            color: NeoColors.borderBlack,
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                provider.updateMonthlyBudget(val);
              }
              Navigator.pop(ctx);
            },
            child: Text('SAVE', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: NeoColors.cardWhite)),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, FinanceProvider provider) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    String selectedEmoji = '💖';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: NeoColors.honeyYellow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: NeoColors.borderBlack, width: 3),
          ),
          title: Text(
            'NEW ROMANCE / SAVINGS GOAL',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: 'Goal Title (e.g. Anniversary Trip)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: NeoColors.borderBlack, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  prefixText: '${provider.currencySymbol} ',
                  labelText: 'Target Amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: NeoColors.borderBlack, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['💖', '🌴', '🎁', '🍷', '💍', '🚗'].map((e) {
                  final isSel = selectedEmoji == e;
                  return InkWell(
                    onTap: () => setDialogState(() => selectedEmoji = e),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSel ? NeoColors.borderBlack : NeoColors.cardWhite,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: NeoColors.borderBlack, width: 1.5),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 18)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            NeoButton(
              color: NeoColors.cardWhite,
              onPressed: () => Navigator.pop(ctx),
              child: Text('CANCEL', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800)),
            ),
            NeoButton(
              color: NeoColors.borderBlack,
              onPressed: () {
                final title = titleController.text.trim();
                final target = double.tryParse(targetController.text.trim());
                if (title.isNotEmpty && target != null && target > 0) {
                  provider.addGoal(
                    GoalModel(
                      id: 'goal_${const Uuid().v4().substring(0, 8)}',
                      title: '$title $selectedEmoji',
                      targetAmount: target,
                      emoji: selectedEmoji,
                      targetDate: DateTime.now().add(const Duration(days: 60)),
                    ),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: Text('ADD GOAL', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: NeoColors.cardWhite)),
            ),
          ],
        ),
      ),
    );
  }

  void _showContributeDialog(BuildContext context, FinanceProvider provider, GoalModel goal) {
    final controller = TextEditingController(text: '500');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeoColors.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: NeoColors.borderBlack, width: 3),
        ),
        title: Text(
          'CONTRIBUTE TO ${goal.title.toUpperCase()}',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            prefixText: '${provider.currencySymbol} ',
            labelText: 'Contribution Amount',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: NeoColors.borderBlack, width: 2),
            ),
          ),
        ),
        actions: [
          NeoButton(
            color: NeoColors.cardWhite,
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800)),
          ),
          NeoButton(
            color: NeoColors.honeyYellow,
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                provider.contributeToGoal(goal.id, val);
              }
              Navigator.pop(ctx);
            },
            child: Text('CONFIRM', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final currency = provider.currencySymbol;
    final formatter = NumberFormat('#,##0.00');

    final monthlySpent = provider.thisMonthExpense;
    final monthlyLimit = provider.budget.monthlyLimit;
    final monthlyProgress = monthlyLimit > 0 ? (monthlySpent / monthlyLimit).clamp(0.0, 1.0) : 0.0;
    final remainingBudget = (monthlyLimit - monthlySpent).clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: NeoColors.honeyYellow,
        elevation: 0,
        title: Text(
          'BUDGETS & ROMANCE GOALS 🎯',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: NeoColors.borderBlack,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3.0),
          child: Container(color: NeoColors.borderBlack, height: 3.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Monthly Budget Card
            NeoCard(
              backgroundColor: NeoColors.honeyYellow,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL MONTHLY BUDGET',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      InkWell(
                        onTap: () => _showEditMonthlyBudgetDialog(context, provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: NeoColors.cardWhite,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: NeoColors.borderBlack, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.edit, size: 12),
                              const SizedBox(width: 4),
                              Text('EDIT', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '$currency${formatter.format(monthlySpent)}',
                        style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        ' / $currency${formatter.format(monthlyLimit)}',
                        style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54),
                      ),
                      const Spacer(),
                      NeoBadge(
                        label: '${(monthlyProgress * 100).toStringAsFixed(0)}% USED',
                        color: monthlyProgress > 0.9 ? NeoColors.spiderRed : NeoColors.cardWhite,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: NeoColors.cardWhite,
                        border: Border.all(color: NeoColors.borderBlack, width: 1.5),
                      ),
                      child: LinearProgressIndicator(
                        value: monthlyProgress,
                        backgroundColor: NeoColors.cardWhite,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          monthlyProgress > 0.9 ? NeoColors.spiderRed : NeoColors.borderBlack,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Remaining this month: $currency${formatter.format(remainingBudget)}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Category Limits Header
            Text(
              'CATEGORY SPENDING LIMITS',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: NeoColors.borderBlack,
              ),
            ),
            const SizedBox(height: 8),

            ...provider.budget.categoryLimits.entries.map((entry) {
              final cat = entry.key;
              final limit = entry.value;
              final spent = provider.transactions
                  .where((t) => t.type == TransactionType.expense && t.category == cat && t.date.month == DateTime.now().month)
                  .fold(0.0, (s, t) => s + t.amount);
              final prog = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: NeoCard(
                  padding: const EdgeInsets.all(12),
                  backgroundColor: cat.contains('Romance') ? NeoColors.pastelPink : NeoColors.cardWhite,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cat,
                            style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '$currency${formatter.format(spent)} / $currency${formatter.format(limit)}',
                            style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: prog,
                          minHeight: 6,
                          backgroundColor: Colors.black12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            prog > 0.9 ? NeoColors.spiderRed : (cat.contains('Romance') ? Colors.redAccent : NeoColors.borderBlack),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // Romance & Relationship Goals Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ROMANCE & SAVINGS MILESTONES 💖',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: NeoColors.borderBlack,
                  ),
                ),
                InkWell(
                  onTap: () => _showAddGoalDialog(context, provider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: NeoColors.honeyYellow,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: NeoColors.borderBlack, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add, size: 14),
                        const SizedBox(width: 4),
                        Text('ADD GOAL', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (provider.goals.isEmpty)
              NeoCard(
                backgroundColor: NeoColors.cardWhite,
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No active romance goals yet. Tap + ADD GOAL to create your first milestone!',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              )
            else
              ...provider.goals.map((goal) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: NeoCard(
                    backgroundColor: NeoColors.cardWhite,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(goal.emoji, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.title,
                                    style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900),
                                  ),
                                  Text(
                                    'Saved $currency${formatter.format(goal.currentAmount)} of $currency${formatter.format(goal.targetAmount)}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            NeoBadge(
                              label: '${(goal.progress * 100).toStringAsFixed(0)}%',
                              color: goal.isCompleted ? NeoColors.mintGreen : NeoColors.honeyYellow,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: goal.progress,
                            minHeight: 8,
                            backgroundColor: Colors.black12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              goal.isCompleted ? Colors.green : NeoColors.borderBlack,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => provider.deleteGoal(goal.id),
                              child: Text('Delete', style: GoogleFonts.spaceGrotesk(fontSize: 11, color: NeoColors.spiderRed)),
                            ),
                            const SizedBox(width: 8),
                            NeoButton(
                              color: NeoColors.honeyYellow,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              onPressed: () => _showContributeDialog(context, provider, goal),
                              child: Text(
                                '+ ADD FUNDS',
                                style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
