import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../db/db_helper.dart';
import '../models/karigar.dart';
import '../models/karigar_work.dart';
import '../models/karigar_advance.dart';
import 'add_karigar_work_screen.dart';
import 'add_karigar_advance_screen.dart';

const _kAccent = Color(0xFFE07B1A);

class KarigarDetailScreen extends StatefulWidget {
  final Karigar karigar;
  const KarigarDetailScreen({super.key, required this.karigar});

  @override
  State<KarigarDetailScreen> createState() => _KarigarDetailScreenState();
}

class _KarigarDetailScreenState extends State<KarigarDetailScreen> {
  final DBHelper _db = DBHelper.instance;
  List<KarigarWork> _workList = [];
  List<KarigarAdvance> _advanceList = [];
  double _totalWork = 0;
  double _totalAdvance = 0;
  double _netPayable = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final karigarId = widget.karigar.id!;
    final work = await _db.getWorkForKarigar(karigarId);
    final advances = await _db.getAdvancesForKarigar(karigarId);
    final totalWork = await _db.getTotalWorkAmount(karigarId);
    final totalAdvance = await _db.getTotalAdvanceGiven(karigarId);
    setState(() {
      _workList = work;
      _advanceList = advances;
      _totalWork = totalWork;
      _totalAdvance = totalAdvance;
      _netPayable = totalWork - totalAdvance;
      _loading = false;
    });
  }

  // ─── Month Picker ───────────────────────────────────────────────────────────
  Future<DateTime?> _pickMonth() async {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    int selectedYear = now.year;
    int selectedMonth = now.month;
    DateTime? result;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Select Month',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Year toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [now.year - 1, now.year].map((y) {
                  final sel = selectedYear == y;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setS(() => selectedYear = y),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? _kAccent : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$y',
                            style: TextStyle(
                              color: sel ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Month grid
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.4,
                children: List.generate(12, (i) {
                  final sel = selectedMonth == i + 1;
                  return GestureDetector(
                    onTap: () => setS(() => selectedMonth = i + 1),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel ? _kAccent : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        months[i],
                        style: TextStyle(
                          color: sel ? Colors.white : Colors.black87,
                          fontSize: 12,
                          fontWeight:
                              sel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent, foregroundColor: Colors.white),
              onPressed: () {
                result = DateTime(selectedYear, selectedMonth);
                Navigator.pop(ctx);
              },
              child: const Text('Generate PDF'),
            ),
          ],
        ),
      ),
    );
    return result;
  }

  // ─── PDF Generate + Share ───────────────────────────────────────────────────
  Future<void> _generatePdf() async {
    final picked = await _pickMonth();
    if (picked == null) return;

    final monthName = DateFormat('MMMM yyyy').format(picked);

    // Filter work for selected month
    final monthWork = _workList
        .where((w) =>
            w.workDate.year == picked.year &&
            w.workDate.month == picked.month)
        .toList()
      ..sort((a, b) => a.workDate.compareTo(b.workDate));

    // Filter advances for selected month
    final monthAdvanceTotal = _advanceList
        .where((a) =>
            a.advanceDate.year == picked.year &&
            a.advanceDate.month == picked.month)
        .fold(0.0, (sum, a) => sum + a.amount);

    final totalPis =
        monthWork.fold(0.0, (sum, w) => sum + w.pis);
    final totalAmount =
        monthWork.fold(0.0, (sum, w) => sum + w.total);
    final netPayable = totalAmount - monthAdvanceTotal;

    final dateFormat = DateFormat('dd/MM/yyyy');

    // Build PDF
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('E07B1A'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      widget.karigar.name,
                      style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Payroll Report — $monthName',
                      style: const pw.TextStyle(
                          fontSize: 13, color: PdfColors.white),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Generated: ${dateFormat.format(DateTime.now())}',
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.white),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // Work table
              if (monthWork.isEmpty)
                pw.Text('No work recorded in this month.',
                    style: const pw.TextStyle(color: PdfColors.grey))
              else ...[
                pw.Text('Work List',
                    style: pw.TextStyle(
                        fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(
                      color: PdfColor.fromHex('E0DED8'), width: 0.5),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(30),
                    1: const pw.FixedColumnWidth(80),
                    2: const pw.FixedColumnWidth(60),
                    3: const pw.FixedColumnWidth(55),
                    4: const pw.FixedColumnWidth(60),
                    5: const pw.FlexColumnWidth(),
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('F5F4F0')),
                      children: ['Sr', 'Date', 'D.No', 'Pieces', 'Rate', 'Amount']
                          .map((h) => pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                child: pw.Text(h,
                                    style: pw.TextStyle(
                                        fontSize: 10,
                                        fontWeight: pw.FontWeight.bold)),
                              ))
                          .toList(),
                    ),
                    // Data rows
                    ...monthWork.asMap().entries.map((entry) {
                      final i = entry.key;
                      final w = entry.value;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: i.isEven
                              ? PdfColors.white
                              : PdfColor.fromHex('FAFAF8'),
                        ),
                        children: [
                          '${i + 1}',
                          dateFormat.format(w.workDate),
                          w.designNo,
                          w.pis.toStringAsFixed(0),
                          w.rate.toStringAsFixed(2),
                          'Rs.${w.total.toStringAsFixed(2)}',
                        ]
                            .map((t) => pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 5),
                                  child: pw.Text(t,
                                      style: const pw.TextStyle(fontSize: 10)),
                                ))
                            .toList(),
                      );
                    }),
                  ],
                ),
              ],

              pw.SizedBox(height: 20),

              // Summary box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                      color: PdfColor.fromHex('E07B1A'), width: 1),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Summary — $monthName',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.SizedBox(height: 8),
                    pw.Divider(color: PdfColor.fromHex('E0DED8')),
                    pw.SizedBox(height: 6),
                    _pdfRow('Total Pieces', totalPis.toStringAsFixed(0)),
                    _pdfRow('Total Work', 'Rs.${totalAmount.toStringAsFixed(2)}'),
                    _pdfRow('Total Advance', 'Rs.${monthAdvanceTotal.toStringAsFixed(2)}'),
                    pw.SizedBox(height: 4),
                    pw.Divider(color: PdfColor.fromHex('E0DED8')),
                    pw.SizedBox(height: 4),
                    _pdfRow(
                      'Net Payable',
                      'Rs.${netPayable.toStringAsFixed(2)}',
                      bold: true,
                    ),
                  ],
                ),
              ),

              pw.Spacer(),
              pw.Divider(color: PdfColor.fromHex('E0DED8')),
              pw.Text(
                'Party Ledger App  •  ${widget.karigar.name}  •  $monthName',
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final filename =
        '${widget.karigar.name}_${DateFormat('MMM_yyyy').format(picked)}.pdf';

    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  pw.Widget _pdfRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(
        title: Text(widget.karigar.name),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE8E8E4))),
        actions: [
          TextButton.icon(
            onPressed: _loading ? null : _generatePdf,
            icon: const Icon(Icons.picture_as_pdf_outlined,
                size: 18, color: _kAccent),
            label: const Text('PDF',
                style: TextStyle(
                    color: _kAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 12),
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _actionBtn(
                          label: 'Add Work',
                          icon: Icons.work_outline,
                          color: _kAccent,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddKarigarWorkScreen(
                                    karigar: widget.karigar),
                              ),
                            );
                            _loadData();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionBtn(
                          label: 'Add Advance',
                          icon: Icons.account_balance_wallet_outlined,
                          color: const Color(0xFFCC6600),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddKarigarAdvanceScreen(
                                    karigar: widget.karigar),
                              ),
                            );
                            _loadData();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Work History
                  _sectionHeader('Work History', Icons.work_outline),
                  const SizedBox(height: 8),
                  if (_workList.isEmpty)
                    _emptyCard('No work entries recorded yet.')
                  else
                    _card(
                      child: Column(
                        children: _workList.asMap().entries.map((entry) {
                          final i = entry.key;
                          final w = entry.value;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color:
                                            _kAccent.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${i + 1}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _kAccent),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'D.No: ${w.designNo}',
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.w600,
                                                fontSize: 14,
                                                color: Color(0xFF1C1C1E)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${w.pis.toStringAsFixed(0)} pcs × ₹${w.rate.toStringAsFixed(2)}  •  ${dateFormat.format(w.workDate)}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B6B6B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹${w.total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: _kAccent),
                                    ),
                                  ],
                                ),
                              ),
                              if (i < _workList.length - 1)
                                const Divider(
                                    height: 1,
                                    indent: 60,
                                    color: Color(0xFFEEECE8)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Advance History
                  _sectionHeader(
                      'Advance History', Icons.account_balance_wallet_outlined),
                  const SizedBox(height: 8),
                  if (_advanceList.isEmpty)
                    _emptyCard('No advances recorded yet.')
                  else
                    _card(
                      child: Column(
                        children: _advanceList.asMap().entries.map((entry) {
                          final i = entry.key;
                          final a = entry.value;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Color(0xFFFFF3E0),
                                      child: Icon(Icons.arrow_upward,
                                          size: 14,
                                          color: Color(0xFFCC6600)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            a.note ?? 'Advance',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: Color(0xFF1C1C1E)),
                                          ),
                                          Text(
                                            dateFormat.format(a.advanceDate),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B6B6B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹${a.amount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFFCC6600)),
                                    ),
                                  ],
                                ),
                              ),
                              if (i < _advanceList.length - 1)
                                const Divider(
                                    height: 1,
                                    indent: 44,
                                    color: Color(0xFFEEECE8)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: _kAccent.withOpacity(0.15),
          backgroundImage: widget.karigar.photoPath != null
              ? FileImage(File(widget.karigar.photoPath!))
              : null,
          child: widget.karigar.photoPath == null
              ? Text(
                  widget.karigar.name.isNotEmpty
                      ? widget.karigar.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _kAccent),
                )
              : null,
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.karigar.name,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E))),
            const Text('Worker',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B6B6B))),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DED8)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _statCol(
                      'Total Work', '₹${_totalWork.toStringAsFixed(0)}',
                      _kAccent)),
              Container(
                  width: 1, height: 40, color: const Color(0xFFEEECE8)),
              Expanded(
                  child: _statCol(
                      'Total Advance',
                      '₹${_totalAdvance.toStringAsFixed(0)}',
                      const Color(0xFFCC6600))),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEECE8)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Net Payable',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF444444))),
              Text(
                '₹${_netPayable.abs().toStringAsFixed(2)}${_netPayable < 0 ? ' (Extra paid)' : ''}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _netPayable > 0
                        ? const Color(0xFFCC3300)
                        : const Color(0xFF27AE60)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: color)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _kAccent),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1C1C1E))),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DED8)),
      ),
      child: child,
    );
  }

  Widget _emptyCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DED8)),
      ),
      child: Center(
        child: Text(msg,
            style: const TextStyle(
                color: Color(0xFF888888), fontSize: 13)),
      ),
    );
  }
}
