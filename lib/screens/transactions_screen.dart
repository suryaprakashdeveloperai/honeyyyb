import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../services/statement_generator_service.dart';
import '../theme/neo_brutalism_theme.dart';
import '../widgets/neo_badge.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_text_field.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _exportCsv(BuildContext context, FinanceProvider provider) {
    final csvContent = StatementGeneratorService.generateCsv(
      transactions: provider.filteredTransactions,
      currency: provider.currencySymbol,
    );

    Clipboard.setData(ClipboardData(text: csvContent));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeoColors.honeyYellow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: NeoColors.borderBlack, width: 3),
        ),
        title: Row(
          children: [
            const Icon(Icons.table_chart_rounded, color: NeoColors.borderBlack),
            const SizedBox(width: 8),
            Text(
              'CSV EXPORT COPIED!',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎉 Exported ${provider.filteredTransactions.length} transactions in standard CSV spreadsheet format (Excel / Google Sheets compatible) to your clipboard!',
              style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: NeoColors.cardWhite,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: NeoColors.borderBlack, width: 1.5),
              ),
              child: Text(
                '${csvContent.split('\n').take(3).join('\n')}\n...',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
              ),
            ),
          ],
        ),
        actions: [
          NeoButton(
            color: NeoColors.cardWhite,
            onPressed: () => Navigator.pop(ctx),
            child: Text('DONE', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _printStatement(BuildContext context, FinanceProvider provider) {
    final bytes = StatementGeneratorService.generatePdfStatementBytes(
      transactions: provider.filteredTransactions,
      currency: provider.currencySymbol,
      periodTitle: provider.dateFilterMode == 'All' ? 'All Time' : provider.dateFilterMode,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeoColors.honeyYellow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: NeoColors.borderBlack, width: 3),
        ),
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: NeoColors.spiderRed),
            const SizedBox(width: 8),
            Text(
              'PDF STATEMENT READY',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ],
        ),
        content: Text(
          '📄 Generated official Honeyyyb statement document (${(bytes.lengthInBytes / 1024).toStringAsFixed(1)} KB) containing ${provider.filteredTransactions.length} transactions with complete financial and romance breakdowns!',
          style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        actions: [
          NeoButton(
            color: NeoColors.cardWhite,
            onPressed: () => Navigator.pop(ctx),
            child: Text('DISMISS', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final transactions = provider.filteredTransactions;
    final currency = provider.currencySymbol;
    final formatter = NumberFormat('#,##0.00');

    final dateModes = ['All', 'Today', 'This Week', 'This Month', 'Last 4 Months'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: NeoColors.honeyYellow,
        elevation: 0,
        title: Text(
          'TRANSACTIONS HISTORY 📜',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: NeoColors.borderBlack,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart_outlined, color: NeoColors.borderBlack),
            tooltip: 'Export CSV',
            onPressed: () => _exportCsv(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: NeoColors.borderBlack),
            tooltip: 'Print Statement PDF',
            onPressed: () => _printStatement(context, provider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3.0),
          child: Container(color: NeoColors.borderBlack, height: 3.0),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input
            NeoTextField(
              controller: _searchController,
              label: 'SEARCH TRANSACTIONS',
              hint: 'Search title, person name, or note...',
              prefixIcon: Icons.search_rounded,
              onChanged: (val) => provider.setSearchQuery(val),
            ),
            const SizedBox(height: 10),

            // Date Range Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: dateModes.map((mode) {
                  final isSelected = provider.dateFilterMode == mode;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => provider.setDateFilter(mode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? NeoColors.borderBlack : NeoColors.cardWhite,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: NeoColors.borderBlack, width: 2),
                        ),
                        child: Text(
                          mode,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? NeoColors.cardWhite : NeoColors.borderBlack,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Category Filter Scroll Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(provider, 'All'),
                  ...TransactionModel.defaultCategories.map(
                    (cat) => _filterChip(provider, cat.name),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Results Counter Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${transactions.length} TRANSACTIONS FOUND',
                  style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black54),
                ),
                Text(
                  'Total: $currency${formatter.format(transactions.fold(0.0, (s, t) => s + (t.type == TransactionType.expense ? -t.amount : t.amount)))}',
                  style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Transaction List
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🔍', style: TextStyle(fontSize: 42)),
                          const SizedBox(height: 10),
                          Text(
                            'No transactions found',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        final isExp = tx.type == TransactionType.expense;

                        return Dismissible(
                          key: Key(tx.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: NeoColors.spiderRed,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: NeoColors.borderBlack, width: 3),
                            ),
                            child: const Icon(Icons.delete_forever, color: Colors.white, size: 26),
                          ),
                          onDismissed: (_) {
                            provider.deleteTransaction(tx.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Transaction deleted!'),
                                backgroundColor: NeoColors.spiderRed,
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: NeoCard(
                              padding: const EdgeInsets.all(10),
                              backgroundColor: NeoColors.cardWhite,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isExp ? NeoColors.pastelPink : NeoColors.mintGreen,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: NeoColors.borderBlack, width: 2),
                                    ),
                                    child: Icon(
                                      isExp ? Icons.arrow_upward : Icons.arrow_downward,
                                      color: NeoColors.borderBlack,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: NeoColors.borderBlack,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            NeoBadge(label: tx.category),
                                            if (tx.personName != null && tx.personName!.isNotEmpty)
                                              NeoBadge(
                                                label: '👤 ${tx.personName}',
                                                color: NeoColors.honeyYellow,
                                              ),
                                            Text(
                                              DateFormat('dd MMM yyyy, hh:mm a').format(tx.date),
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10,
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
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: isExp ? NeoColors.spiderRed : Colors.green[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(FinanceProvider provider, String category) {
    final isSelected = provider.selectedCategoryFilter == category;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => provider.setCategoryFilter(category),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? NeoColors.honeyYellow : NeoColors.cardWhite,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: NeoColors.borderBlack, width: 2),
            boxShadow: [
              if (isSelected)
                const BoxShadow(color: NeoColors.borderBlack, offset: Offset(2, 2)),
            ],
          ),
          child: Text(
            category,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: NeoColors.borderBlack,
            ),
          ),
        ),
      ),
    );
  }
}
