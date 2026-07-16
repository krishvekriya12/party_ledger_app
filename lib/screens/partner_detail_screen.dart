import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/partner.dart';
import 'add_contribution_screen.dart';
import 'add_expense_screen.dart';

class PartnerDetailScreen extends StatefulWidget {
  final Partner partner;
  const PartnerDetailScreen({super.key, required this.partner});

  @override
  State<PartnerDetailScreen> createState() => _PartnerDetailScreenState();
}

class _PartnerDetailScreenState extends State<PartnerDetailScreen> {
  final DBHelper _db = DBHelper.instance;
  List<Map<String, dynamic>> _history = [];
  double _totalContribution = 0;
  double _totalExpense = 0;
  double _netBalance = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final partnerId = widget.partner.id!;
    final history = await _db.getPartnerFullHistory(partnerId);
    final totalContribution = await _db.getTotalContribution(partnerId);
    final totalExpense = await _db.getTotalExpense(partnerId);

    setState(() {
      _history = history;
      _totalContribution = totalContribution;
      _totalExpense = totalExpense;
      _netBalance = totalContribution - totalExpense;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(widget.partner.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 12),
                  _buildSummaryCard(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_card),
                          label: const Text('Add Paisa Diya'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddContributionScreen(partner: widget.partner),
                              ),
                            );
                            _loadData();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.remove_circle_outline),
                          label: const Text('Add Kharcha'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddExpenseScreen(partner: widget.partner),
                              ),
                            );
                            _loadData();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Poora Record (Date-wise)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(),
                  if (_history.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Koi record nahi hai abhi.'),
                    )
                  else
                    ..._history.map((h) {
                      final isContribution = h['type'] == 'contribution';
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          isContribution ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isContribution ? Colors.green : Colors.red,
                        ),
                        title: Text(h['label'] as String),
                        subtitle: Text(dateFormat.format(h['date'] as DateTime)),
                        trailing: Text(
                          '₹${(h['amount'] as double).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isContribution ? Colors.green : Colors.red,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage:
              widget.partner.photoPath != null ? FileImage(File(widget.partner.photoPath!)) : null,
          child: widget.partner.photoPath == null
              ? Text(widget.partner.name.isNotEmpty ? widget.partner.name[0] : '?')
              : null,
        ),
        const SizedBox(width: 16),
        Text(widget.partner.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryItem('Total Diya', _totalContribution, Colors.green),
                _summaryItem('Total Kharcha', _totalExpense, Colors.red),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Net Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '₹${_netBalance.abs().toStringAsFixed(2)} ${_netBalance < 0 ? "(Extra kharcha)" : ""}',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _netBalance >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text('₹${value.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }
}
