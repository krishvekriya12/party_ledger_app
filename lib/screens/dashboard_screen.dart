import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/party.dart';

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
      appBar: AppBar(title: const Text('Business Dashboard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildTopCards(),
                  const SizedBox(height: 20),
                  _sectionTitle('Outstanding Bill Pending (Party-wise)'),
                  _buildOutstandingPartiesList(),
                  const SizedBox(height: 20),
                  _sectionTitle('Party Bill Cycle - 60 Din | Due Date Report'),
                  _buildBillCycleReport(),
                  const SizedBox(height: 20),
                  _sectionTitle('Karigar Monthly Payroll'),
                  _buildMonthlyPayroll(),
                  const SizedBox(height: 20),
                  _sectionTitle('Partner Ledger (Kisko Kitna Diya)'),
                  _buildPartnerLedger(),
                  const SizedBox(height: 20),
                  _sectionTitle('Every Month Calculation'),
                  _buildMonthlySummary(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildTopCards() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Total Payment Lena Hai\n(Party se)',
            _totalReceivable,
            Colors.red,
            Icons.call_received,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'Is Mahine ki\nKarigar Payroll',
            _currentMonthPayroll,
            Colors.orange,
            Icons.engineering,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, double value, Color color, IconData icon) {
    return Card(
      color: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              '₹${value.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutstandingPartiesList() {
    if (_outstandingParties.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Koi outstanding bill pending nahi hai. 🎉'),
        ),
      );
    }
    return Card(
      child: Column(
        children: _outstandingParties.map((e) {
          final party = e['party'] as Party;
          final outstanding = e['outstanding'] as double;
          return ListTile(
            dense: true,
            title: Text(party.name),
            trailing: Text(
              '₹${outstanding.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBillCycleReport() {
    if (_billCycleReport.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Koi bill cycle due nahi hai.'),
        ),
      );
    }
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Card(
      child: Column(
        children: _billCycleReport.map((e) {
          final party = e['party'] as Party;
          final outstanding = e['outstanding'] as double;
          final dueDate = e['dueDate'] as DateTime;
          final daysRemaining = e['daysRemaining'] as int;
          final isOverdue = e['isOverdue'] as bool;

          return ListTile(
            dense: true,
            title: Text(party.name),
            subtitle: Text(
              isOverdue
                  ? 'OVERDUE by ${-daysRemaining} din  •  Due: ${dateFormat.format(dueDate)}'
                  : 'Due in $daysRemaining din  •  Due: ${dateFormat.format(dueDate)}',
              style: TextStyle(color: isOverdue ? Colors.red : Colors.orange, fontSize: 12),
            ),
            trailing: Text(
              '₹${outstanding.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isOverdue ? Colors.red : Colors.black87,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyPayroll() {
    if (_monthlyPayroll.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Koi karigar work entry nahi hai abhi.'),
        ),
      );
    }
    return Card(
      child: Column(
        children: _monthlyPayroll.map((m) {
          return ListTile(
            dense: true,
            title: Text(_formatMonth(m['month'] as String)),
            trailing: Text(
              '₹${(m['total'] as double).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPartnerLedger() {
    if (_partnerLedger.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Koi partner add nahi hai abhi.'),
        ),
      );
    }
    return Card(
      child: Column(
        children: _partnerLedger.map((e) {
          final partner = e['partner'];
          final totalGiven = e['totalGiven'] as double;
          final totalSpent = e['totalSpent'] as double;
          final net = e['net'] as double;
          return ListTile(
            dense: true,
            title: Text(partner.name as String),
            subtitle: Text('Diya: ₹${totalGiven.toStringAsFixed(0)}  •  Kharcha: ₹${totalSpent.toStringAsFixed(0)}'),
            trailing: Text(
              '₹${net.abs().toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: net >= 0 ? Colors.green : Colors.red,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlySummary() {
    if (_monthlySummary.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Abhi tak koi data nahi hai.'),
        ),
      );
    }
    return Column(
      children: _monthlySummary.map((m) {
        final month = m['month'] as String;
        final bill = m['bill'] as double;
        final payment = m['payment'] as double;
        final karigarWork = m['karigarWork'] as double;
        final karigarAdvance = m['karigarAdvance'] as double;
        final partnerContribution = m['partnerContribution'] as double;
        final partnerExpense = m['partnerExpense'] as double;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatMonth(month),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Divider(),
                _summaryRow('Party Bill', bill, Colors.green),
                _summaryRow('Party Payment', payment, Colors.teal),
                _summaryRow('Karigar Kaam', karigarWork, Colors.orange),
                _summaryRow('Karigar Upad', karigarAdvance, Colors.deepOrange),
                _summaryRow('Partner Diya', partnerContribution, Colors.blue),
                _summaryRow('Partner Kharcha', partnerExpense, Colors.red),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _summaryRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text('₹${value.toStringAsFixed(2)}',
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
      final date = DateTime(year, month);
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return yyyyMM;
    }
  }
}
