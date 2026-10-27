import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../services/notification_parser_service.dart';
import '../theme/neo_brutalism_theme.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';

class LiveNotificationScreen extends StatefulWidget {
  const LiveNotificationScreen({super.key});

  @override
  State<LiveNotificationScreen> createState() => _LiveNotificationScreenState();
}

class _LiveNotificationScreenState extends State<LiveNotificationScreen> {
  final TextEditingController _titleController = TextEditingController(text: 'Google Pay');
  final TextEditingController _bodyController = TextEditingController(text: 'Paid ₹450 to Starbucks Cafe');
  NotificationParseResult? _lastResult;

  final List<Map<String, String>> _notificationPresets = [
    {
      'title': 'Google Pay',
      'body': 'Paid ₹1,500 to Priya Sharma (Date Night)',
    },
    {
      'title': 'PhonePe',
      'body': 'Payment of ₹850 to Zomato was successful.',
    },
    {
      'title': 'Paytm Payments Bank',
      'body': 'Money Sent! ₹3,200 sent to Rahul Verma for Rent split',
    },
    {
      'title': 'HDFC Bank Alert',
      'body': 'Rs 48,000.00 credited to A/c XX4921 towards SALARY AUG 2026',
    },
    {
      'title': 'Google Pay',
      'body': 'You received ₹2,000 from Priya Sharma',
    },
  ];

  void _parseAndIngest() {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (body.isEmpty) return;

    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final result = provider.ingestPushNotification(title: title, body: body);

    setState(() {
      _lastResult = result;
    });

    if (result.isFinancial) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Recorded ₹${result.transaction!.amount} for ${result.transaction!.title}!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final currency = provider.currencySymbol;
    final formatter = NumberFormat('#,##0.00');

    final notificationTxs = provider.transactions.where((t) => t.source == 'push_notification').toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: NeoColors.honeyYellow,
        elevation: 0,
        title: Text(
          'GPAY & PUSH NOTIFICATIONS 📲',
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
            // Instructions Banner
            NeoCard(
              backgroundColor: NeoColors.honeyYellow,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: NeoColors.cardWhite,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: NeoColors.borderBlack, width: 2),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: NeoColors.borderBlack, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LIVE GPAY / PHONEPE CAPTURE',
                          style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Captures and parses transaction popups from GPay, PhonePe, Paytm, & Banks instantly.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Ingestion Box
            Text(
              'QUICK NOTIFICATION INGESTOR',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: NeoColors.borderBlack,
              ),
            ),
            const SizedBox(height: 8),

            NeoCard(
              backgroundColor: NeoColors.cardWhite,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      labelText: 'App / Title (e.g. Google Pay)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: NeoColors.borderBlack, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _bodyController,
                    maxLines: 2,
                    style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Notification Content / Message',
                      hintText: 'e.g. Paid ₹1,500 to Priya Sharma',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: NeoColors.borderBlack, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  NeoButton(
                    color: NeoColors.honeyYellow,
                    isFullWidth: true,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: _parseAndIngest,
                    child: Text(
                      'INGEST NOTIFICATION 🚀',
                      style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (_lastResult != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _lastResult!.isFinancial ? NeoColors.mintGreen : NeoColors.pastelPink,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: NeoColors.borderBlack, width: 1.5),
                      ),
                      child: Text(
                        _lastResult!.summary,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 1-Tap Presets
            Text(
              '1-TAP SAMPLE NOTIFICATIONS',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: NeoColors.borderBlack,
              ),
            ),
            const SizedBox(height: 8),

            ..._notificationPresets.map((preset) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    _titleController.text = preset['title']!;
                    _bodyController.text = preset['body']!;
                    _parseAndIngest();
                  },
                  child: NeoCard(
                    backgroundColor: NeoColors.cardWhite,
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(preset['title']!, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900)),
                              Text(preset['body']!, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54)),
                            ],
                          ),
                        ),
                        const Icon(Icons.add_circle_outline_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            }),

            if (notificationTxs.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'RECENTLY INGESTED NOTIFICATIONS (${notificationTxs.length})',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: NeoColors.borderBlack,
                ),
              ),
              const SizedBox(height: 8),
              ...notificationTxs.take(5).map((tx) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: NeoCard(
                    backgroundColor: NeoColors.mintGreen,
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tx.title, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900)),
                              Text(
                                '${tx.category} • ${DateFormat('dd MMM, hh:mm a').format(tx.date)}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$currency${formatter.format(tx.amount)}',
                          style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
