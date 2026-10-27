import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../theme/neo_brutalism_theme.dart';
import '../widgets/neo_badge.dart';
import '../widgets/neo_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final currency = provider.currencySymbol;
    final formatter = NumberFormat('#,##0.00');

    final income = provider.totalIncome;
    final expense = provider.totalExpense;
    final balance = provider.totalBalance;
    final savingsRate = income > 0 ? ((income - expense) / income * 100).clamp(0.0, 100.0) : 0.0;

    // Calculate category spending map
    final Map<String, double> categoryTotals = {};
    for (final tx in provider.transactions) {
      if (tx.type == TransactionType.expense) {
        categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0.0) + tx.amount;
      }
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate last 7 days daily spend for weekly chart
    final now = DateTime.now();
    final List<double> last7DaysSpend = List.filled(7, 0.0);
    final List<String> last7DaysLabels = [];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      last7DaysLabels.add(DateFormat('E').format(day)); // Mon, Tue, etc.
      final dayTxs = provider.transactions.where((t) =>
          t.type == TransactionType.expense &&
          t.date.year == day.year &&
          t.date.month == day.month &&
          t.date.day == day.day);
      double dayTotal = 0;
      for (final t in dayTxs) {
        dayTotal += t.amount;
      }
      last7DaysSpend[6 - i] = dayTotal;
    }

    final maxDailySpend = last7DaysSpend.fold(0.0, (max, v) => v > max ? v : max);
    final chartMaxY = (maxDailySpend > 0 ? maxDailySpend : 1000.0) * 1.25;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: NeoColors.honeyYellow,
        elevation: 0,
        title: Text(
          'FINANCIAL ANALYTICS 📊',
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
            // Net Balance & Performance Card
            NeoCard(
              backgroundColor: NeoColors.honeyYellow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'NET LEDGER PERFORMANCE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: NeoColors.borderBlack,
                        ),
                      ),
                      NeoBadge(
                        label: balance >= 0 ? 'HEALTHY' : 'DEFICIT ALERT',
                        color: balance >= 0 ? NeoColors.mintGreen : NeoColors.spiderRed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${balance >= 0 ? '+' : ''}$currency${formatter.format(balance)}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: NeoColors.borderBlack,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: NeoColors.mintGreen,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: NeoColors.borderBlack, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('INCOME 🟢', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900)),
                              Text('$currency${formatter.format(income)}', style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: NeoColors.spiderRed,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: NeoColors.borderBlack, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('EXPENSES 🔴', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                              Text('$currency${formatter.format(expense)}', style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: NeoColors.cardWhite,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: NeoColors.borderBlack, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SAVINGS 🍯', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900)),
                              Text('${savingsRate.toStringAsFixed(1)}%', style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Weekly Daily Spending Bar Chart
            NeoCard(
              backgroundColor: NeoColors.cardWhite,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LAST 7 DAYS SPENDING 📅',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: NeoColors.borderBlack,
                        ),
                      ),
                      Text(
                        'Peak: $currency${NumberFormat('#,##0').format(maxDailySpend)}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 170,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: chartMaxY,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${last7DaysLabels[groupIndex]}\n$currency${NumberFormat('#,##0').format(rod.toY)}',
                                GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                final idx = val.toInt();
                                if (idx >= 0 && idx < last7DaysLabels.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(
                                      last7DaysLabels[idx],
                                      style: GoogleFonts.spaceGrotesk(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                        color: idx == 6 ? NeoColors.borderBlack : Colors.black54,
                                      ),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(7, (idx) {
                          final isToday = idx == 6;
                          return BarChartGroupData(
                            x: idx,
                            barRods: [
                              BarChartRodData(
                                toY: last7DaysSpend[idx],
                                color: isToday ? NeoColors.honeyYellow : NeoColors.mintGreen,
                                width: 22,
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(color: NeoColors.borderBlack, width: 2),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Category Pie Chart Distribution
            if (sortedCategories.isNotEmpty) ...[
              NeoCard(
                backgroundColor: NeoColors.cardWhite,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CATEGORY DISTRIBUTION 🍕',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: NeoColors.borderBlack,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection == null) {
                                        _touchedPieIndex = -1;
                                        return;
                                      }
                                      _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 3,
                                centerSpaceRadius: 28,
                                sections: List.generate(
                                  sortedCategories.take(5).length,
                                  (i) {
                                    final isTouched = i == _touchedPieIndex;
                                    final cat = sortedCategories[i];
                                    final info = TransactionModel.getCategoryInfo(cat.key);
                                    final double radius = isTouched ? 48.0 : 42.0;

                                    return PieChartSectionData(
                                      color: info.color,
                                      value: cat.value,
                                      title: '${(cat.value / (expense > 0 ? expense : 1) * 100).toStringAsFixed(0)}%',
                                      radius: radius,
                                      titleStyle: GoogleFonts.spaceGrotesk(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: NeoColors.borderBlack,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: sortedCategories.take(4).map((cat) {
                                final info = TransactionModel.getCategoryInfo(cat.key);
                                final pct = expense > 0 ? (cat.value / expense * 100).toStringAsFixed(0) : '0';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: info.color,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: NeoColors.borderBlack, width: 1.5),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          cat.key.split(' ').first,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      Text('$pct%', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Full Category Breakdown List
            Text(
              'EXPENSE CATEGORIES BREAKDOWN',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: NeoColors.borderBlack,
              ),
            ),
            const SizedBox(height: 10),

            if (sortedCategories.isEmpty)
              const NeoCard(
                child: Center(child: Text('No expenses recorded yet.')),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedCategories.length,
                itemBuilder: (context, index) {
                  final cat = sortedCategories[index];
                  final percentage = expense > 0 ? (cat.value / expense * 100) : 0.0;
                  final info = TransactionModel.getCategoryInfo(cat.key);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: NeoCard(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: NeoColors.cardWhite,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(info.emoji, style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        cat.key,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$currency${formatter.format(cat.value)} (${percentage.toStringAsFixed(1)}%)',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: NeoColors.borderBlack,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              minHeight: 8,
                              backgroundColor: NeoColors.softGrey,
                              color: info.color,
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
