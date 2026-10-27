import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/person_ledger.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../theme/neo_brutalism_theme.dart';
import '../widgets/neo_badge.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';
import 'add_transaction_screen.dart';

class PersonDetailScreen extends StatelessWidget {
  final PersonLedger ledger;

  const PersonDetailScreen({super.key, required this.ledger});

  void _showSettleUpDialog(BuildContext context, FinanceProvider provider, String personName, double currentNet) {
    final defaultAmt = currentNet.abs() > 0 ? currentNet.abs().toStringAsFixed(0) : '500';
    final controller = TextEditingController(text: defaultAmt);
    // If net is negative, we spent more on them (they owe us => settlement is Income)
    // If net is positive, they spent more on us (we owe them => settlement is Expense)
    TransactionType settleType = currentNet < 0 ? TransactionType.income : TransactionType.expense;

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
            'SETTLE BALANCE WITH $personName',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record payment settlement to balance your ledger:',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  prefixText: '${provider.currencySymbol} ',
                  labelText: 'Settlement Amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: NeoColors.borderBlack, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setDialogState(() => settleType = TransactionType.income),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: settleType == TransactionType.income ? NeoColors.mintGreen : NeoColors.cardWhite,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: NeoColors.borderBlack, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            'THEY PAID ME',
                            style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => setDialogState(() => settleType = TransactionType.expense),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: settleType == TransactionType.expense ? NeoColors.pastelPink : NeoColors.cardWhite,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: NeoColors.borderBlack, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            'I PAID THEM',
                            style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
                final amt = double.tryParse(controller.text.trim());
                if (amt != null && amt > 0) {
                  provider.settleBalance(
                    personName: personName,
                    amount: amt,
                    type: settleType,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 Recorded settlement of ${provider.currencySymbol}$amt with $personName!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text('RECORD SETTLEMENT', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: NeoColors.cardWhite)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final currency = provider.currencySymbol;
    final formatter = NumberFormat('#,##0.00');

    // Filter updated transactions for this person
    final personTxs = provider.transactions
        .where((t) => t.personName?.toLowerCase() == ledger.personName.toLowerCase())
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    double sent = 0;
    double received = 0;
    for (final t in personTxs) {
      if (t.type == TransactionType.expense) {
        sent += t.amount;
      } else {
        received += t.amount;
      }
    }
    final net = received - sent;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: NeoColors.honeyYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: NeoColors.borderBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          ledger.personName.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
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
            // Person Summary Card
            NeoCard(
              backgroundColor: NeoColors.neonTeal,
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: NeoColors.spiderRed,
                        child: Text(
                          ledger.personName[0].toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ledger.personName,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: NeoColors.borderBlack,
                              ),
                            ),
                            Text(
                              'Total Exchanged: $currency${formatter.format(sent + received)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: NeoColors.borderBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatMiniBox(
                          title: 'SENT TO THEM',
                          amount: '$currency${formatter.format(sent)}',
                          color: NeoColors.pastelPink,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatMiniBox(
                          title: 'RECV FROM THEM',
                          amount: '$currency${formatter.format(received)}',
                          color: NeoColors.mintGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: NeoColors.cardWhite,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: NeoColors.borderBlack, width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'NET BALANCE:',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: NeoColors.borderBlack,
                          ),
                        ),
                        Text(
                          '${net >= 0 ? '+' : ''}$currency${formatter.format(net)}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: net >= 0 ? Colors.green[800] : NeoColors.spiderRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Action Buttons (Add Payment & Settle Up)
                  Row(
                    children: [
                      Expanded(
                        child: NeoButton(
                          color: NeoColors.honeyYellow,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddTransactionScreen(
                                  initialPersonName: ledger.personName,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_outline, color: NeoColors.borderBlack, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'ADD ENTRY ➕',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: NeoColors.borderBlack,
                                ),
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
                          onPressed: () => _showSettleUpDialog(context, provider, ledger.personName, net),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.handshake_rounded, color: NeoColors.borderBlack, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'SETTLE UP 🤝',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: NeoColors.borderBlack,
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
            const SizedBox(height: 20),

            Text(
              'TRANSACTION TIMELINE',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: NeoColors.borderBlack,
              ),
            ),
            const SizedBox(height: 12),

            if (personTxs.isEmpty)
              const NeoCard(
                child: Center(
                  child: Text('No transactions recorded with this person.'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: personTxs.length,
                itemBuilder: (context, index) {
                  final tx = personTxs[index];
                  final isExp = tx.type == TransactionType.expense;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: NeoCard(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: isExp ? NeoColors.cardWhite : const Color(0xFFE8F5E9),
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
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: NeoColors.borderBlack,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    NeoBadge(label: tx.category),
                                    Text(
                                      DateFormat('MMM d, h:mm a').format(tx.date),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black54,
                                      ),
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
      ),
    );
  }
}

class _StatMiniBox extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;

  const _StatMiniBox({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NeoColors.borderBlack, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: NeoColors.borderBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: NeoColors.borderBlack,
            ),
          ),
        ],
      ),
    );
  }
}
