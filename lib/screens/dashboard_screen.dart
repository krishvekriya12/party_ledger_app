import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/party.dart';

const _kAccent = Color(0xFF5C35CC);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DBHelper _db = DBHelper.instance;
  bool _loading = true;

  double _totalReceivable = 0;
  double _currentMonthPayroll = 0;
  List<Map<String, dynamic>> _monthlyPayroll = [];
  List<Map<String, dynamic>> _partnerLedger = [];
  List<Map<String, dynamic>> _monthlySummary = [];
  List<Map<String, dynamic>> _outstandingParties = [];
  List<Map<String, dynamic>> _billCycleReport = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final totalReceivable = await _db.getTotalReceivableFromParties();
    final currentMonthPayroll = await _db.getCurrentMonthKarigarPayroll();
    final monthlyPayroll = await _db.getMonthlyKarigarPayroll();
    final partnerLedger = await _db.getPartnerLedgerSummary();
    final monthlySummary = await _db.getMonthlyBusinessSummary();
    final outstandingParties = await _db.getOutstandingPartiesList();
    final billCycleReport = await _db.getBillCycleReport();
    setState(() {
      _totalReceivable = totalReceivable;
      _currentMonthPayroll = currentMonthPayroll;
      _monthlyPayroll = monthlyPayroll;
      _partnerLedger = partnerLedger;
      _monthlySummary = monthlySummary;
      _outstandingParties = outstandingParties;
      _billCycleReport = billCycleReport;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(title: const Text('Dashboard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Top stat cards
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          label: 'Party\nReceivable',
                          value: '₹${_totalReceivable.toStringAsFixed(0)}',
                          icon: Icons.call_received,
                          color: const Color(0xFFCC3300),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          label: 'This Month\nPayroll',
                          value: '₹${_currentMonthPayroll.toStringAsFixed(0)}',
                          icon: Icons.engineering_outlined,
                          color: const Color(0xFFE07B1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Outstanding parties
                  _sectionHeader('Outstanding Bills (Party-wise)',
                      Icons.receipt_long_outlined),
                  const SizedBox(height: 8),
                  _buildOutstandingParties(),
                  const SizedBox(height: 24),

                  // Bill cycle due
                  _sectionHeader('60-Day Bill Cycle — Due Alert',
                      Icons.alarm_outlined),
                  const SizedBox(height: 8),
                  _buildBillCycle(),
                  const SizedBox(height: 24),

                  // Monthly payroll
                  _sectionHeader(
                      'Karigar Monthly Payroll', Icons.engineering_outlined),
                  const SizedBox(height: 8),
                  _buildMonthlyPayroll(),
                  const SizedBox(height: 24),

                  // Partner ledger
                  _sectionHeader(
                      'Partner Ledger', Icons.people_outline),
                  const SizedBox(height: 8),
                  _buildPartnerLedger(),
                  const SizedBox(height: 24),

                  // Monthly summary
                  _sectionHeader(
                      'Monthly Business Summary', Icons.bar_chart),
                  const SizedBox(height: 8),
                  _buildMonthlySummary(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DED8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF888888),
                  height: 1.4)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: color)),
        ],
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

  Widget _card(Widget child) {
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DED8)),
      ),
      child: Text(msg,
          style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
    );
  }

  Widget _buildOutstandingParties() {
    if (_outstandingParties.isEmpty) {
      return _emptyCard('No outstanding bills pending 🎉');
    }
    return _card(
      Column(
        children: _outstandingParties.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final party = e['party'] as Party;
          final outstanding = e['outstanding'] as double;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCC3300).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        party.name.isNotEmpty ? party.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFCC3300)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(party.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF1C1C1E)))),
                    Text('₹${outstanding.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFCC3300),
                            fontSize: 14)),
                  ],
                ),
              ),
              if (i < _outstandingParties.length - 1)
                const Divider(height: 1, indent: 60, color: Color(0xFFEEECE8)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBillCycle() {
    if (_billCycleReport.isEmpty) {
      return _emptyCard('No bill cycles due.');
    }
    final dateFormat = DateFormat('dd/MM/yyyy');
    return _card(
      Column(
        children: _billCycleReport.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final party = e['party'] as Party;
          final outstanding = e['outstanding'] as double;
          final dueDate = e['dueDate'] as DateTime;
          final daysRemaining = e['daysRemaining'] as int;
          final isOverdue = e['isOverdue'] as bool;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: (isOverdue
                                ? const Color(0xFFCC3300)
                                : const Color(0xFFE07B1A))
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        isOverdue ? Icons.alarm_off : Icons.alarm,
                        size: 16,
                        color: isOverdue
                            ? const Color(0xFFCC3300)
                            : const Color(0xFFE07B1A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(party.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1C1C1E))),
                          Text(
                            isOverdue
                                ? 'Overdue by ${-daysRemaining} days  •  Due: ${dateFormat.format(dueDate)}'
                                : '$daysRemaining days left  •  Due: ${dateFormat.format(dueDate)}',
                            style: TextStyle(
                                fontSize: 11,
                                color: isOverdue
                                    ? const Color(0xFFCC3300)
                                    : const Color(0xFFE07B1A)),
                          ),
                        ],
                      ),
                    ),
                    Text('₹${outstanding.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isOverdue ? const Color(0xFFCC3300) : const Color(0xFF1C1C1E))),
                  ],
                ),
              ),
              if (i < _billCycleReport.length - 1)
                const Divider(height: 1, indent: 60, color: Color(0xFFEEECE8)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyPayroll() {
    if (_monthlyPayroll.isEmpty) return _emptyCard('No worker entries recorded yet.');
    return _card(
      Column(
        children: _monthlyPayroll.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(_formatMonth(m['month'] as String),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF1C1C1E)))),
                    Text('₹${(m['total'] as double).toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE07B1A),
                            fontSize: 14)),
                  ],
                ),
              ),
              if (i < _monthlyPayroll.length - 1)
                const Divider(height: 1, indent: 16, color: Color(0xFFEEECE8)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPartnerLedger() {
    if (_partnerLedger.isEmpty) return _emptyCard('No partners added yet.');
    return _card(
      Column(
        children: _partnerLedger.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final partner = e['partner'];
          final totalGiven = e['totalGiven'] as double;
          final totalSpent = e['totalSpent'] as double;
          final totalAdvance = (e['totalAdvance'] as double?) ?? 0.0;
          final net = e['net'] as double;
          final positive = net >= 0;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(partner.name as String,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1C1C1E))),
                          Text(
                            'Contributed: ₹${totalGiven.toStringAsFixed(0)}  •  Expenses: ₹${totalSpent.toStringAsFixed(0)}  •  Advance: ₹${totalAdvance.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${net.abs().toStringAsFixed(0)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: positive
                              ? const Color(0xFF27AE60)
                              : const Color(0xFFCC3300)),
                    ),
                  ],
                ),
              ),
              if (i < _partnerLedger.length - 1)
                const Divider(height: 1, indent: 16, color: Color(0xFFEEECE8)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlySummary() {
    if (_monthlySummary.isEmpty) return _emptyCard('No summary data available.');
    return Column(
      children: _monthlySummary.map((m) {
        final month = m['month'] as String;
        final bill = m['bill'] as double;
        final payment = m['payment'] as double;
        final karigarWork = m['karigarWork'] as double;
        final karigarAdvance = m['karigarAdvance'] as double;
        final partnerContribution = m['partnerContribution'] as double;
        final partnerExpense = m['partnerExpense'] as double;
        final partnerAdvance = (m['partnerAdvance'] as double?) ?? 0.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0DED8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_formatMonth(month),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _kAccent)),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFEEECE8)),
              const SizedBox(height: 8),
              _sumRow('Party Bill', bill, const Color(0xFF1A6DFF)),
              _sumRow('Party Payment', payment, Colors.teal),
              _sumRow('Worker Work', karigarWork, const Color(0xFFE07B1A)),
              _sumRow('Worker Advance', karigarAdvance, Colors.deepOrange),
              _sumRow('Partner Contribution', partnerContribution, const Color(0xFF27AE60)),
              _sumRow('Partner Expense', partnerExpense, const Color(0xFFCC3300)),
              _sumRow('Partner Advance', partnerAdvance, Colors.deepOrange),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _sumRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF444444))),
          Text('₹${value.toStringAsFixed(0)}',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
        ],
      ),
    );
  }

  String _formatMonth(String yyyyMM) {
    try {
      final parts = yyyyMM.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      return DateFormat('MMMM yyyy').format(DateTime(year, month));
    } catch (_) {
      return yyyyMM;
    }
  }
}
