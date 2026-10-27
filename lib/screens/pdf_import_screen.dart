import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../services/pdf_statement_parser.dart';
import '../theme/neo_brutalism_theme.dart';
import '../widgets/neo_badge.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';

class PdfImportScreen extends StatefulWidget {
  const PdfImportScreen({super.key});

  @override
  State<PdfImportScreen> createState() => _PdfImportScreenState();
}

class _PdfImportScreenState extends State<PdfImportScreen> with SingleTickerProviderStateMixin {
  static const _channel = MethodChannel('com.suryaprakash.honeyyyb/file_picker');

  late TabController _tabController;
  String? _fileName;
  Uint8List? _fileBytes;
  bool _isParsing = false;
  PdfParseResult? _parseResult;
  final Set<String> _selectedTxIds = {};

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pasteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _passwordController.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  Future<void> _pickPdfFile() async {
    try {
      final res = await _channel.invokeMethod<Map>('pickPdf');
      if (res != null) {
        final name = res['name'] as String? ?? 'Statement.pdf';
        final bytes = res['bytes'] as Uint8List?;

        if (bytes != null) {
          setState(() {
            _fileName = name;
            _fileBytes = bytes;
            _parseResult = null;
            _selectedTxIds.clear();
          });

          _parsePdf();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File selection cancelled or error: $e'),
            backgroundColor: NeoColors.spiderRed,
          ),
        );
      }
    }
  }

  Future<void> _parsePdf() async {
    if (_fileBytes == null) return;

    setState(() => _isParsing = true);

    try {
      final result = await PdfStatementParserService.parsePdfBytes(
        _fileBytes!,
        password: _passwordController.text.trim().isNotEmpty ? _passwordController.text.trim() : null,
      );

      if (mounted) {
        setState(() {
          _parseResult = result;
          _selectedTxIds.addAll(result.transactions.map((t) => t.id));
          _isParsing = false;
        });

        if (!result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.statusMessage),
              backgroundColor: NeoColors.spiderRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isParsing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Parsing failed: $e'),
            backgroundColor: NeoColors.spiderRed,
          ),
        );
      }
    }
  }

  /// Parses raw pasted text directly without PDF conversion loss
  void _parsePastedText() {
    final text = _pasteController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste some statement text first!'),
          backgroundColor: NeoColors.spiderRed,
        ),
      );
      return;
    }

    setState(() {
      _isParsing = true;
      _fileName = 'Pasted_Text_Statement';
    });

    // Pure direct text parsing with zero encoding overhead
    final result = PdfStatementParserService.parseStatementText(text);

    setState(() {
      _parseResult = result;
      _selectedTxIds.clear();
      _selectedTxIds.addAll(result.transactions.map((t) => t.id));
      _isParsing = false;
    });

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.statusMessage),
          backgroundColor: NeoColors.spiderRed,
        ),
      );
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      setState(() {
        _pasteController.text = data.text!;
      });
      _parsePastedText();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clipboard is empty!'),
            backgroundColor: NeoColors.honeyYellow,
          ),
        );
      }
    }
  }

  void _loadSamplePastedText() {
    final now = DateTime.now();
    final f = DateFormat('dd/MM/yyyy');
    final d1 = f.format(now.subtract(const Duration(days: 1)));
    final d2 = f.format(now.subtract(const Duration(days: 4)));
    final d3 = f.format(now.subtract(const Duration(days: 10)));
    final d4 = f.format(now.subtract(const Duration(days: 18)));
    final d5 = f.format(now.subtract(const Duration(days: 28)));

    final sample = '''
HDFC Bank Account Statement - A/C XX4921

$d1 UPI/PRIYA SHARMA/Flowers and Dinner Date Night ₹1,850.00 DR
$d2 POS STARBUCKS CAFE COFFEE ₹450.00 DR
$d3 ACH MONTHLY TECHCORP SALARY ₹48,000.00 CR
$d4 UPI/SWIGGY FOOD DELIVERY ₹380.00 DR
$d5 UPI/RAHUL VERMA/Trip Split ₹1,200.00 CR
$d5 UPI/AMAZON SHOPPING/Earphones ₹2,499.00 DR
''';

    _pasteController.text = sample.trim();
    _parsePastedText();
  }

  void _loadDemoPdf() async {
    setState(() => _isParsing = true);

    final document = PdfDocument();
    final page = document.pages.add();
    final font = PdfStandardFont(PdfFontFamily.helvetica, 11);

    final now = DateTime.now();
    final f = DateFormat('dd/MM/yyyy');
    final d1 = f.format(now.subtract(const Duration(days: 2)));
    final d2 = f.format(now.subtract(const Duration(days: 6)));
    final d3 = f.format(now.subtract(const Duration(days: 14)));

    final text = '''
HDFC Bank Account Statement
Account Ending: XX4921
Customer Name: Surya Prakash

$d1 UPI/PRIYA SHARMA/940192 Flowers Date Night 1,850.00 DR
$d2 POS STARBUCKS CAFE COFFEE 450.00 DR
$d3 ACH MONTHLY SALARY TECHCORP 48,000.00 CR
''';

    page.graphics.drawString(text, font, bounds: const Rect.fromLTWH(10, 10, 500, 400));
    final List<int> bytesList = document.saveSync();
    document.dispose();

    setState(() {
      _fileName = 'Demo_HDFC_Statement.pdf';
      _fileBytes = Uint8List.fromList(bytesList);
      _selectedTxIds.clear();
    });

    await _parsePdf();
  }

  void _handleImport() {
    if (_parseResult == null || _parseResult!.transactions.isEmpty) return;

    final selectedTransactions = _parseResult!.transactions.where((t) => _selectedTxIds.contains(t.id)).toList();

    if (selectedTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 transaction to import!'),
          backgroundColor: NeoColors.spiderRed,
        ),
      );
      return;
    }

    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final count = provider.importTransactionsList(selectedTransactions);

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
                'IMPORT COMPLETE 🎉',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'Successfully added $count individual payments from your statement into your Honeyyyb ledger and analytics!',
          style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        actions: [
          NeoButton(
            color: NeoColors.cardWhite,
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(
              'VIEW DASHBOARD',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: NeoColors.borderBlack,
              ),
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
          'STATEMENT INGESTION 📄',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: NeoColors.borderBlack,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: NeoColors.borderBlack,
          unselectedLabelColor: Colors.black54,
          indicatorColor: NeoColors.borderBlack,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.copy_rounded, size: 18), text: 'PASTE TEXT 📋'),
            Tab(icon: Icon(Icons.picture_as_pdf_rounded, size: 18), text: 'UPLOAD PDF 📁'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: PASTE RAW TEXT (Bulletproof multi-line parser)
                _buildPasteTextTab(formatter, currency),

                // TAB 2: PDF FILE UPLOADER
                _buildPdfUploadTab(formatter, currency),
              ],
            ),
          ),

          // Sticky Bottom Import Bar if transactions are parsed
          if (_parseResult != null && _parseResult!.transactions.isNotEmpty)
            _buildStickyImportBar(currency, formatter),
        ],
      ),
    );
  }

  Widget _buildPasteTextTab(NumberFormat formatter, String currency) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeoCard(
            backgroundColor: NeoColors.honeyYellow,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('📋', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PASTE ANY STATEMENT OR PASSBOOK TEXT',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: NeoColors.borderBlack,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Copy all text from NetBanking, GPay, SMS, or PDF and paste here. We split every single line into individual payments automatically!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: NeoButton(
                        color: NeoColors.cardWhite,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        onPressed: _pasteFromClipboard,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.paste_rounded, size: 16, color: NeoColors.borderBlack),
                            const SizedBox(width: 4),
                            Text(
                              'PASTE CLIPBOARD',
                              style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: NeoButton(
                        color: NeoColors.neonTeal,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        onPressed: _loadSamplePastedText,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.text_snippet_rounded, size: 16, color: NeoColors.borderBlack),
                            const SizedBox(width: 4),
                            Text(
                              'LOAD SAMPLE',
                              style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900),
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
          const SizedBox(height: 14),

          // Big Text Area
          Container(
            decoration: BoxDecoration(
              color: NeoColors.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NeoColors.borderBlack, width: 2.5),
            ),
            child: TextField(
              controller: _pasteController,
              maxLines: 7,
              style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Paste statement text here (eg: 15/08/2026 UPI/Priya Sharma 1850.00 DR)...',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: NeoColors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: NeoButton(
                  color: NeoColors.mintGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: _isParsing ? null : _parsePastedText,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isParsing)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: NeoColors.borderBlack),
                        )
                      else ...[
                        const Icon(Icons.auto_awesome_rounded, size: 18, color: NeoColors.borderBlack),
                        const SizedBox(width: 6),
                        Text(
                          'SPLIT & PARSE PAYMENTS ⚡',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: NeoColors.borderBlack,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              NeoButton(
                color: NeoColors.cardWhite,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                onPressed: () {
                  setState(() {
                    _pasteController.clear();
                    _parseResult = null;
                    _selectedTxIds.clear();
                  });
                },
                child: const Icon(Icons.clear_rounded, color: NeoColors.spiderRed, size: 20),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Results Preview
          if (_parseResult != null) _buildParsedResultsView(formatter, currency),
        ],
      ),
    );
  }

  Widget _buildPdfUploadTab(NumberFormat formatter, String currency) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      child: const Icon(Icons.picture_as_pdf_rounded, color: NeoColors.spiderRed, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BANK & GPAY PDF STATEMENTS',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: NeoColors.borderBlack,
                            ),
                          ),
                          Text(
                            'Select native text PDF statements from HDFC, SBI, ICICI, Axis, GPay',
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
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: NeoButton(
                        color: NeoColors.cardWhite,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        onPressed: _isParsing ? null : _pickPdfFile,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.upload_file_rounded, color: NeoColors.borderBlack, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _fileName != null ? 'CHANGE PDF' : 'PICK PDF FILE',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: NeoButton(
                        color: NeoColors.neonTeal,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        onPressed: _isParsing ? null : _loadDemoPdf,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_circle_fill_rounded, color: NeoColors.borderBlack, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'LOAD DEMO PDF',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900),
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
          const SizedBox(height: 14),

          // Password Field (For protected bank statements)
          NeoCard(
            backgroundColor: NeoColors.cardWhite,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 16, color: NeoColors.borderBlack),
                    const SizedBox(width: 6),
                    Text(
                      'PDF PASSWORD (IF PROTECTED)',
                      style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: 'Enter PDF Password (e.g. DOB or PAN)...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: NeoColors.textSecondary),
                    filled: true,
                    fillColor: NeoColors.creamBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: NeoColors.borderBlack, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Results Preview
          if (_parseResult != null) _buildParsedResultsView(formatter, currency),
        ],
      ),
    );
  }

  Widget _buildParsedResultsView(NumberFormat formatter, String currency) {
    if (_parseResult == null || _parseResult!.transactions.isEmpty) {
      return NeoCard(
        backgroundColor: NeoColors.cardWhite,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _parseResult?.statusMessage ?? 'No transactions found.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: NeoColors.spiderRed),
            ),
          ),
        ),
      );
    }

    final txs = _parseResult!.transactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Header Card
        NeoCard(
          backgroundColor: NeoColors.cardWhite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _parseResult!.bankName ?? 'Statement',
                          style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                        if (_parseResult!.accountNumber != null)
                          Text(
                            'A/C: ${_parseResult!.accountNumber}',
                            style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                      ],
                    ),
                  ),
                  NeoBadge(
                    label: '${txs.length} FOUND',
                    color: NeoColors.honeyYellow,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: NeoColors.pastelPink.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: NeoColors.borderBlack, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TOTAL DEBIT', style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w900)),
                          Text(
                            '-$currency${formatter.format(_parseResult!.totalDebit)}',
                            style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w900, color: NeoColors.spiderRed),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: NeoColors.mintGreen.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: NeoColors.borderBlack, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TOTAL CREDIT', style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w900)),
                          Text(
                            '+$currency${formatter.format(_parseResult!.totalCredit)}',
                            style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.green[800]),
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
        const SizedBox(height: 14),

        // List Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'INDIVIDUAL PAYMENTS (${_selectedTxIds.length}/${txs.length} SELECTED)',
              style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  if (_selectedTxIds.length == txs.length) {
                    _selectedTxIds.clear();
                  } else {
                    _selectedTxIds.addAll(txs.map((t) => t.id));
                  }
                });
              },
              child: Text(
                _selectedTxIds.length == txs.length ? 'DESELECT ALL' : 'SELECT ALL',
                style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: NeoColors.spiderRed),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Individual Transaction Tiles
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: txs.length,
          itemBuilder: (ctx, index) {
            final tx = txs[index];
            final isSelected = _selectedTxIds.contains(tx.id);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? NeoColors.cardWhite : NeoColors.creamBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: NeoColors.borderBlack, width: 2),
                boxShadow: isSelected
                    ? [
                        const BoxShadow(
                          color: NeoColors.borderBlack,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                leading: Checkbox(
                  value: isSelected,
                  activeColor: NeoColors.honeyYellow,
                  checkColor: NeoColors.borderBlack,
                  side: const BorderSide(color: NeoColors.borderBlack, width: 2),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedTxIds.add(tx.id);
                      } else {
                        _selectedTxIds.remove(tx.id);
                      }
                    });
                  },
                ),
                title: Text(
                  tx.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                subtitle: Row(
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(tx.date),
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: NeoColors.textSecondary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${tx.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                trailing: Text(
                  '${tx.type == TransactionType.expense ? '-' : '+'}$currency${formatter.format(tx.amount)}',
                  style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: tx.type == TransactionType.expense ? NeoColors.spiderRed : Colors.green[800],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStickyImportBar(String currency, NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: NeoColors.cardWhite,
        border: Border(top: BorderSide(color: NeoColors.borderBlack, width: 3)),
      ),
      child: SafeArea(
        top: false,
        child: NeoButton(
          isFullWidth: true,
          color: NeoColors.honeyYellow,
          padding: const EdgeInsets.symmetric(vertical: 14),
          onPressed: _handleImport,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_task_rounded, color: NeoColors.borderBlack, size: 20),
              const SizedBox(width: 8),
              Text(
                'IMPORT ${_selectedTxIds.length} PAYMENTS TO LEDGER 🚀',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: NeoColors.borderBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
