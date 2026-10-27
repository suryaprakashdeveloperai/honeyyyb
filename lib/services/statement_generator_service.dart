import 'dart:typed_data';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/transaction.dart';

class StatementGeneratorService {
  /// Generates a standard CSV string of all transactions
  static String generateCsv({
    required List<TransactionModel> transactions,
    required String currency,
  }) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('Date,Title,Type,Category,Amount ($currency),Person / Payee,Bank / Source,Note,Ref ID');

    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm');
    for (final tx in transactions) {
      final dateStr = dateFormatter.format(tx.date);
      final title = _escapeCsv(tx.title);
      final type = tx.type == TransactionType.income ? 'Income' : 'Expense';
      final category = _escapeCsv(tx.category);
      final amount = tx.amount.toStringAsFixed(2);
      final person = _escapeCsv(tx.personName ?? '');
      final bank = _escapeCsv(tx.bankName ?? tx.source);
      final note = _escapeCsv(tx.note ?? '');
      final id = tx.id;

      buffer.writeln('$dateStr,$title,$type,$category,$amount,$person,$bank,$note,$id');
    }

    return buffer.toString();
  }

  /// Generates a printable PDF Statement document bytes
  static Uint8List generatePdfStatementBytes({
    required List<TransactionModel> transactions,
    required String currency,
    required String periodTitle,
  }) {
    final document = PdfDocument();
    final page = document.pages.add();
    final pageSize = page.getClientSize();

    final headerFont = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
    final subFont = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
    final bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 9);
    final boldBodyFont = PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold);

    // Header Title
    page.graphics.drawString(
      _sanitizeForPdf('HONEYYYB FINANCIAL STATEMENT'),
      headerFont,
      bounds: Rect.fromLTWH(0, 0, pageSize.width, 24),
      brush: PdfSolidBrush(PdfColor(0, 0, 0)),
    );

    page.graphics.drawString(
      _sanitizeForPdf('Statement Period: $periodTitle | Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}'),
      bodyFont,
      bounds: Rect.fromLTWH(0, 26, pageSize.width, 16),
      brush: PdfSolidBrush(PdfColor(100, 100, 100)),
    );

    // Calculate Summary Stats
    double totalIncome = 0.0;
    double totalExpense = 0.0;
    double romanceTotal = 0.0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
        if (tx.category.contains('Romance') || tx.category.contains('💖')) {
          romanceTotal += tx.amount;
        }
      }
    }
    final netBalance = totalIncome - totalExpense;
    final f = NumberFormat('#,##0.00');

    // Summary Box
    final summaryBounds = Rect.fromLTWH(0, 48, pageSize.width, 42);
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(255, 230, 0)), // Honey Yellow
      pen: PdfPen(PdfColor(0, 0, 0), width: 1.5),
      bounds: summaryBounds,
    );

    final safeCur = currency == '₹' ? 'INR ' : currency;
    final summaryText = 'Total Income: $safeCur${f.format(totalIncome)}  |  Total Spent: $safeCur${f.format(totalExpense)}  |  Net Savings: $safeCur${f.format(netBalance)}  |  Romance: $safeCur${f.format(romanceTotal)}';
    page.graphics.drawString(
      _sanitizeForPdf(summaryText),
      boldBodyFont,
      bounds: Rect.fromLTWH(8, 62, pageSize.width - 16, 20),
      brush: PdfSolidBrush(PdfColor(0, 0, 0)),
    );

    // Transactions Table
    final grid = PdfGrid();
    grid.columns.add(count: 5);
    grid.headers.add(1);

    final header = grid.headers[0];
    header.cells[0].value = 'Date';
    header.cells[1].value = 'Description / Payee';
    header.cells[2].value = 'Category';
    header.cells[3].value = 'Type';
    header.cells[4].value = 'Amount ($safeCur)';

    header.style = PdfGridRowStyle(
      backgroundBrush: PdfSolidBrush(PdfColor(0, 0, 0)),
      textBrush: PdfSolidBrush(PdfColor(255, 255, 255)),
      font: subFont,
    );

    final df = DateFormat('dd/MM/yyyy');
    for (final tx in transactions) {
      final row = grid.rows.add();
      final isExp = tx.type == TransactionType.expense;

      row.cells[0].value = df.format(tx.date);
      row.cells[1].value = _sanitizeForPdf(tx.personName != null && tx.personName!.isNotEmpty ? '${tx.title} (${tx.personName})' : tx.title);
      row.cells[2].value = _sanitizeForPdf(tx.category);
      row.cells[3].value = isExp ? 'DEBIT' : 'CREDIT';
      row.cells[4].value = '${isExp ? '-' : '+'}${f.format(tx.amount)}';

      row.style = PdfGridRowStyle(font: bodyFont);
    }

    grid.draw(page: page, bounds: Rect.fromLTWH(0, 100, pageSize.width, pageSize.height - 110));

    final bytes = document.saveSync();
    document.dispose();
    return Uint8List.fromList(bytes);
  }

  static String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  static String _sanitizeForPdf(String str) {
    return str
        .replaceAll('₹', 'INR ')
        .replaceAll('💖', '')
        .replaceAll('🍔', '')
        .replaceAll('🛍️', '')
        .replaceAll('🚗', '')
        .replaceAll('⚡', '')
        .replaceAll('🎬', '')
        .replaceAll('💸', '')
        .replaceAll('💰', '')
        .replaceAll('📌', '')
        .replaceAll('🐝', '')
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '')
        .trim();
  }
}
