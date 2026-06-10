import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import '../models/expense.dart';

class ExportService {
  // PdfColors.white70 does not exist — use explicit RGBA
  static const PdfColor _white70 = PdfColor(1, 1, 1, 0.7);

  /// Export transactions as PDF
  static Future<void> exportPDF({
    required BuildContext context,
    required List<Expense> expenses,
    required String currency,
    required String bookName,
    DateTime? filterMonth,
  }) async {
    try {
      final List<Expense> data = _filterExpenses(expenses, filterMonth);
      if (data.isEmpty) {
        _showSnack(context, 'No transactions to export for this period.');
        return;
      }

      final pdf = pw.Document();

      final double totalIncome = data
          .where((e) => e.type == 'income')
          .fold(0, (s, e) => s + e.amount);
      final double totalExpense = data
          .where((e) => e.type == 'expense')
          .fold(0, (s, e) => s + e.amount);
      final double balance = totalIncome - totalExpense;

      final periodLabel = filterMonth != null
          ? DateFormat('MMMM yyyy').format(filterMonth)
          : 'All Time';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) {
            return [
              // ── Header ──────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red800,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      bookName,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Transaction Report — $periodLabel',
                      style: pw.TextStyle(color: _white70, fontSize: 13),
                    ),
                    pw.Text(
                      'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                      style: pw.TextStyle(color: _white70, fontSize: 11),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // ── Summary cards ────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _summaryBox('Total Income',
                      '$currency${totalIncome.toStringAsFixed(2)}',
                      PdfColors.green100, PdfColors.green800),
                  _summaryBox('Total Expense',
                      '$currency${totalExpense.toStringAsFixed(2)}',
                      PdfColors.red100, PdfColors.red800),
                  _summaryBox(
                      'Balance',
                      '$currency${balance.toStringAsFixed(2)}',
                      balance >= 0 ? PdfColors.blue100 : PdfColors.orange100,
                      balance >= 0 ? PdfColors.blue800 : PdfColors.orange800),
                ],
              ),

              pw.SizedBox(height: 20),

              // ── Table ────────────────────────────────────────
              pw.Text(
                'Transactions (${data.length})',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),

              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Category', 'Note/Title', 'Type', 'Amount'],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                headerDecoration:
                const pw.BoxDecoration(color: PdfColors.red800),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 9),
                rowDecoration: const pw.BoxDecoration(),
                oddRowDecoration:
                const pw.BoxDecoration(color: PdfColors.grey100),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(3),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(2),
                },
                data: data.map((e) {
                  final date = DateTime.parse(e.date);
                  return [
                    DateFormat('dd MMM yy').format(date),
                    e.category,
                    e.title.isEmpty ? e.category : e.title,
                    e.type == 'income' ? 'Income' : 'Expense',
                    '${e.type == 'income' ? '+' : '-'}$currency${e.amount.toStringAsFixed(2)}',
                  ];
                }).toList(),
              ),
            ];
          },
        ),
      );

      final dir = await getTemporaryDirectory();
      final fileName =
          'spendwise_${periodLabel.replaceAll(' ', '_').toLowerCase()}'
          '_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // share_plus >=13.x: ShareParams replaces the old positional API
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: '$bookName — Transaction Report ($periodLabel)',
        ),
      );
    } catch (e) {
      _showSnack(context, 'Failed to export PDF: $e');
    }
  }

  /// Export transactions as CSV
  static Future<void> exportCSV({
    required BuildContext context,
    required List<Expense> expenses,
    required String currency,
    required String bookName,
    DateTime? filterMonth,
  }) async {
    try {
      final List<Expense> data = _filterExpenses(expenses, filterMonth);
      if (data.isEmpty) {
        _showSnack(context, 'No transactions to export for this period.');
        return;
      }

      final periodLabel = filterMonth != null
          ? DateFormat('MMMM yyyy').format(filterMonth)
          : 'All Time';

      final List<List<dynamic>> rows = [
        ['SpendWise — $bookName'],
        ['Period: $periodLabel'],
        ['Generated: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}'],
        [],
        ['Date', 'Category', 'Title/Note', 'Type', 'Amount', 'Currency'],
        ...data.map((e) {
          final date = DateTime.parse(e.date);
          return [
            DateFormat('yyyy-MM-dd').format(date),
            e.category,
            e.title.isEmpty ? e.category : e.title,
            e.type,
            e.type == 'income' ? e.amount : -e.amount,
            currency,
          ];
        }),
        [],
        ['Summary'],
        [
          'Total Income', '', '', '',
          data
              .where((e) => e.type == 'income')
              .fold(0.0, (s, e) => s + e.amount),
          currency,
        ],
        [
          'Total Expense', '', '', '',
          data
              .where((e) => e.type == 'expense')
              .fold(0.0, (s, e) => s + e.amount),
          currency,
        ],
      ];

      final csv = const ListToCsvConverter().convert(rows);

      final dir = await getTemporaryDirectory();
      final fileName =
          'spendwise_${periodLabel.replaceAll(' ', '_').toLowerCase()}'
          '_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csv);

      // share_plus >=13.x API
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: '$bookName — Transactions CSV ($periodLabel)',
        ),
      );
    } catch (e) {
      _showSnack(context, 'Failed to export CSV: $e');
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static List<Expense> _filterExpenses(List<Expense> all, DateTime? month) {
    if (month == null) return List.from(all)..sort(_byDateDesc);
    return all
        .where((e) {
      final d = DateTime.parse(e.date);
      return d.month == month.month && d.year == month.year;
    })
        .toList()
      ..sort(_byDateDesc);
  }

  static int _byDateDesc(Expense a, Expense b) =>
      DateTime.parse(b.date).compareTo(DateTime.parse(a.date));

  static pw.Widget _summaryBox(
      String label, String value, PdfColor bg, PdfColor fg) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 4),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(color: fg, fontSize: 9)),
            pw.SizedBox(height: 2),
            pw.Text(value,
                style: pw.TextStyle(
                    color: fg,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  static void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}