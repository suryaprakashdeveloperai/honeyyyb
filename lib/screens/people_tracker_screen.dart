import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../theme/neo_brutalism_theme.dart';
import '../widgets/neo_card.dart';
import 'person_detail_screen.dart';

class PeopleTrackerScreen extends StatelessWidget {
  const PeopleTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final ledgers = provider.personLedgers;
    final currency = provider.currencySymbol;
    final formatter = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: NeoColors.honeyYellow,
        elevation: 0,
        title: Text(
          'PEOPLE & CONTACTS 👥',
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
            NeoCard(
              backgroundColor: NeoColors.electricPurple,
              child: Row(
                children: [
                  const Text('💸', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'P2P Expense Tracker',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Extracted from SMS & transactions to track who received or sent money!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withAlpha(230),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ALL CONTACTS (${ledgers.length})',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: NeoColors.borderBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (ledgers.isEmpty)
              NeoCard(
                backgroundColor: NeoColors.cardWhite,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('📱', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 8),
                        Text(
                          'No contacts extracted yet',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Parse bank SMS messages or tag a person name when adding transactions!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ledgers.length,
                itemBuilder: (context, index) {
                  final ledger = ledgers[index];
                  final net = ledger.netBalance;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: NeoCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PersonDetailScreen(ledger: ledger),
                          ),
                        );
                      },
                      backgroundColor: NeoColors.cardWhite,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: index % 2 == 0 ? NeoColors.honeyYellow : NeoColors.neonTeal,
                            child: Text(
                              ledger.personName[0].toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: NeoColors.borderBlack,
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: NeoColors.borderBlack,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sent: $currency${formatter.format(ledger.totalSent)} • Recv: $currency${formatter.format(ledger.totalReceived)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${net >= 0 ? '+' : ''}$currency${formatter.format(net)}',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: net >= 0 ? Colors.green[800] : NeoColors.spiderRed,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${ledger.transactions.length} txns',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right, color: NeoColors.borderBlack),
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
