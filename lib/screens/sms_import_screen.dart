import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../services/sms_parser.dart';
import '../theme/neo_brutalism_theme.dart';
import '../widgets/neo_badge.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_text_field.dart';
import 'pdf_import_screen.dart';

class SmsImportScreen extends StatefulWidget {
  const SmsImportScreen({super.key});

  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen> {
  final TextEditingController _smsController = TextEditingController();
  ParsedSmsResult? _previewResult;
  List<TransactionModel> _multiStatementTxs = [];

  final List<String> _samplePresets = [
    '[Truecaller] Debited Rs 1,850.00 to Priya Sharma via Truecaller Pay. Ref 902194.',
    'Truecaller: Paid INR 350.00 to Starbucks Cafe on HDFC Bank Card XX9201.',
    'Dear Customer, your A/C XX4921 has been debited by Rs 1,200.00 to Priya Sharma via GPay UPI. Ref 902194.',
    'Your A/C XX4921 is credited with INR 48,000.00 towards Monthly Salary stipend from TechCorp. Ref SAL9901.',
    'Paid Rs 420.00 to Swiggy Food Delivery via Paytm UPI. Ref SWG9102.',
    'Received Rs 2,500.00 from Rahul Verma via PhonePe UPI transfer.',
    '[Truecaller] Sent Rs 850.00 to Priya Sharma towards Date Night Flowers & Ice Cream 💖. UPI Txn 1092',
    'Debited Rs 12,500.00 towards House Rent payment via HDFC Bank NetBanking. Ref RNT1091',
  ];

  void _onSmsChanged(String text) {
    if (text.trim().isEmpty) {
      setState(() {
        _previewResult = null;
        _multiStatementTxs = [];
      });
      return;
    }

    if (text.contains('\n')) {
      final multi = SmsParserService.parseMultiTextStatements(text);
      if (multi.isNotEmpty) {
        setState(() {
          _multiStatementTxs = multi;
          _previewResult = null;
        });
        return;
      }
    }

    setState(() {
      _previewResult = SmsParserService.parseSms(text);
      _multiStatementTxs = [];
    });
  }

  void _loadPreset(String text) {
    _smsController.text = text;
    _onSmsChanged(text);
  }

  Future<void> _handleSyncFourMonths() async {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final result = await provider.syncLastFourMonthsSms();

    if (!mounted) return;

    if (result.isSuccess) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: NeoColors.borderBlack, width: 3),
          ),
          backgroundColor: NeoColors.cardWhite,
          title: Row(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '4-MONTH SMS SYNC COMPLETE',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.statusMessage,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              NeoCard(
                backgroundColor: NeoColors.honeyYellow,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Messages Scanned:', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
                        Text('${result.totalScanned}', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('New Added:', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
                        Text('+${result.newTransactionsAdded}', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, color: Colors.green[900])),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Duplicates Skipped:', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
                        Text('${result.duplicatesSkipped}', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            NeoButton(
              color: NeoColors.neonTeal,
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'AWESOME!',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.statusMessage),
          backgroundColor: NeoColors.spiderRed,
        ),
      );
    }
  }

  void _saveSmsTransaction() {
    if (_previewResult == null || !_previewResult!.isTransaction) return;

    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final tx = TransactionModel(
      id: 'sms_${DateTime.now().millisecondsSinceEpoch}',
      title: _previewResult!.personOrMerchant ?? 'SMS Transaction',
      amount: _previewResult!.amount ?? 0.0,
      type: _previewResult!.type ?? TransactionType.expense,
      category: _previewResult!.category,
      date: _previewResult!.messageDate ?? DateTime.now(),
      personName: _previewResult!.personOrMerchant,
      note: _previewResult!.note,
      bankName: _previewResult!.bankName,
      accountNumber: _previewResult!.accountNumber,
      source: 'sms_import',
    );

    provider.addTransaction(tx);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Added ${tx.title} (${provider.currencySymbol}${tx.amount.toStringAsFixed(2)}) to Ledger!'),
        backgroundColor: Colors.green[700],
      ),
    );

    setState(() {
      _smsController.clear();
      _previewResult = null;
    });
  }

  void _saveMultiTransactions() {
    if (_multiStatementTxs.isEmpty) return;

    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final count = provider.importTransactionsList(_multiStatementTxs);

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
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'STATEMENT IMPORTED 🎉',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'Successfully added $count transactions into your Honeyyyb ledger and analytics!',
          style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        actions: [
          NeoButton(
            color: NeoColors.cardWhite,
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _smsController.clear();
                _multiStatementTxs = [];
              });
            },
            child: Text(
              'DONE',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900),
            ),
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: NeoColors.honeyYellow,
        elevation: 0,
        title: Text(
          'SMS & STATEMENT INGESTION 💬',
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
            // 4-Month Sync Banner Card
            NeoCard(
              backgroundColor: NeoColors.honeyYellow,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: NeoColors.cardWhite,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: NeoColors.borderBlack, width: 2),
                        ),
                        child: const Icon(Icons.sync_rounded, color: NeoColors.borderBlack, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AUTOMATIC 4-MONTH INBOX SYNC',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: NeoColors.borderBlack,
                              ),
                            ),
                            Text(
                              'Scans HDFC, SBI, ICICI, Axis, GPay, Paytm, Truecaller Smart SMS',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  NeoButton(
                    isFullWidth: true,
                    color: NeoColors.mintGreen,
                    onPressed: provider.isSyncingSms ? null : _handleSyncFourMonths,
                    child: provider.isSyncingSms
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: NeoColors.borderBlack),
                              ),
                              SizedBox(width: 8),
                              Text('SYNCING SMS INBOX...'),
                            ],
                          )
                        : Text(
                            'SYNC LAST 4 MONTHS (120 DAYS) ⚡',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: NeoColors.borderBlack,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // PDF Statement Banner
            NeoCard(
              backgroundColor: NeoColors.cardWhite,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: NeoColors.creamBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: NeoColors.borderBlack, width: 2),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: NeoColors.borderBlack, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UPLOAD PDF STATEMENT',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: NeoColors.borderBlack,
                          ),
                        ),
                        Text(
                          'Direct bank & GPay statement parser',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  NeoButton(
                    color: NeoColors.honeyYellow,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PdfImportScreen()),
                      );
                    },
                    child: Text(
                      'UPLOAD PDF',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Intro Card for manual paste
            NeoCard(
              backgroundColor: NeoColors.neonTeal,
              child: Row(
                children: [
                  const Text('🤖', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manual SMS & Statement Parser',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: NeoColors.borderBlack,
                          ),
                        ),
                        Text(
                          'Paste a single SMS or paste full multi-line GPay/PhonePe statements below.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: NeoColors.borderBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // SMS Text Area
            NeoTextField(
              controller: _smsController,
              label: 'PASTE SMS OR STATEMENT TEXT HERE',
              hint: 'e.g. 01 JUN 2026\n11:37 AM | Paid to SANGEETHA P | ₹47 | UPI: 615282315505',
              maxLines: 5,
              onChanged: _onSmsChanged,
            ),
            const SizedBox(height: 16),

            // Multi-line Statement Results Card
            if (_multiStatementTxs.isNotEmpty) ...[
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
                            'STATEMENT DETECTED 🎉',
                            style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w900),
                          ),
                        ),
                        NeoBadge(
                          label: '${_multiStatementTxs.length} TRANSACTIONS',
                          color: NeoColors.honeyYellow,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Found ${_multiStatementTxs.length} individual payments across your statement dates! Tap below to import all directly into your ledger.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),
                    NeoButton(
                      isFullWidth: true,
                      color: NeoColors.mintGreen,
                      onPressed: _saveMultiTransactions,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: NeoColors.borderBlack, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'IMPORT ALL ${_multiStatementTxs.length} PAYMENTS 🚀',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: NeoColors.borderBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Single SMS Preview Box
            if (_previewResult != null && _multiStatementTxs.isEmpty) ...[
              Text(
                'LIVE EXTRACTION PREVIEW',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: NeoColors.borderBlack,
                ),
              ),
              const SizedBox(height: 8),
              NeoCard(
                backgroundColor: _previewResult!.isTransaction
                    ? (_previewResult!.type == TransactionType.expense
                        ? NeoColors.pastelPink
                        : NeoColors.mintGreen)
                    : NeoColors.softGrey,
                child: _previewResult!.isTransaction
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  NeoBadge(
                                    label: _previewResult!.type == TransactionType.expense ? 'EXPENSE (DEBIT)' : 'INCOME (CREDIT)',
                                    color: _previewResult!.type == TransactionType.expense ? NeoColors.spiderRed : Colors.green,
                                  ),
                                  if (_previewResult!.isTruecaller)
                                    const NeoBadge(
                                      label: '⚡ TRUECALLER SMART',
                                      color: NeoColors.neonTeal,
                                      icon: Icons.verified_rounded,
                                    ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${_previewResult!.type == TransactionType.expense ? '-' : '+'}$currency${formatter.format(_previewResult!.amount ?? 0)}',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: NeoColors.borderBlack,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_previewResult!.personOrMerchant != null)
                            Row(
                              children: [
                                Text(
                                  'PERSON / RECIPIENT: ',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _previewResult!.personOrMerchant!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 6),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              Text(
                                'CATEGORY: ',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              NeoBadge(label: _previewResult!.category),
                            ],
                          ),
                          if (_previewResult!.bankName != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'BANK/CARD: ${_previewResult!.bankName} ${_previewResult!.accountNumber ?? ''}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          if (_previewResult!.referenceId != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'REF/UTR: ${_previewResult!.referenceId!}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ],
                      )
                    : Center(
                        child: Text(
                          'No transaction pattern detected in text.',
                          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              if (_previewResult!.isTransaction)
                NeoButton(
                  isFullWidth: true,
                  color: NeoColors.honeyYellow,
                  onPressed: _saveSmsTransaction,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: NeoColors.borderBlack),
                      const SizedBox(width: 8),
                      Text(
                        'EXTRACT & SAVE TRANSACTION',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: NeoColors.borderBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],

            // Sample Presets for Testing
            Text(
              'TEST SAMPLE BANK SMS PRESETS',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: NeoColors.borderBlack,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _samplePresets.length,
              itemBuilder: (context, idx) {
                final preset = _samplePresets[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: NeoCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    onTap: () => _loadPreset(preset),
                    backgroundColor: NeoColors.cardWhite,
                    child: Row(
                      children: [
                        const Icon(Icons.touch_app_rounded, size: 18, color: NeoColors.borderBlack),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            preset,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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
