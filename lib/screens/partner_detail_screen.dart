import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/partner.dart';
import 'add_contribution_screen.dart';
import 'add_expense_screen.dart';
import 'add_partner_advance_screen.dart';

const _kAccent = Color(0xFF27AE60);

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
  double _totalAdvance = 0;
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
    final totalAdvance = await _db.getTotalAdvanceForPartner(partnerId);
    setState(() {
      _history = history;
      _totalContribution = totalContribution;
      _totalExpense = totalExpense;
      _totalAdvance = totalAdvance;
      _netBalance = totalContribution - totalExpense - totalAdvance;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(title: Text(widget.partner.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _actionBtn(
                          label: 'Contribution',
                          icon: Icons.add_card_outlined,
                          color: _kAccent,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddContributionScreen(
                                    partner: widget.partner),
                              ),
                            );
                            _loadData();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _actionBtn(
                          label: 'Expense',
                          icon: Icons.remove_shopping_cart_outlined,
                          color: const Color(0xFFCC3300),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddExpenseScreen(
                                    partner: widget.partner),
                              ),
                            );
                            _loadData();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionBtn(
                          label: 'Advance',
                          icon: Icons.account_balance_wallet_outlined,
                          color: Colors.deepOrange,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddPartnerAdvanceScreen(
                                    partner: widget.partner),
                              ),
                            );
                            _loadData();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // History
                  Row(
                    children: const [
                      Icon(Icons.history, size: 16, color: _kAccent),
                      SizedBox(width: 6),
                      Text('All Records (Date-wise)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1C1C1E))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_history.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0DED8)),
                      ),
                      child: const Center(
                        child: Text('No records found yet.',
                            style: TextStyle(
                                color: Color(0xFF888888), fontSize: 13)),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0DED8)),
                      ),
                      child: Column(
                        children: _history.asMap().entries.map((entry) {
                          final i = entry.key;
                          final h = entry.value;
                          final type = h['type'] as String;
                          final isContrib = type == 'contribution';
                          final isAdvance = type == 'advance';
                          final Color itemColor = isContrib
                              ? _kAccent
                              : (isAdvance ? Colors.deepOrange : const Color(0xFFCC3300));
                          final IconData itemIcon = isContrib
                              ? Icons.arrow_downward
                              : Icons.arrow_upward;

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: itemColor.withOpacity(0.12),
                                      child: Icon(
                                        itemIcon,
                                        size: 14,
                                        color: itemColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            h['label'] as String,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: Color(0xFF1C1C1E)),
                                          ),
                                          Text(
                                            dateFormat.format(
                                                h['date'] as DateTime),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B6B6B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹${(h['amount'] as double).toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: itemColor),
                                    ),
                                  ],
                                ),
                              ),
                              if (i < _history.length - 1)
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

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: _kAccent.withOpacity(0.12),
          backgroundImage: widget.partner.photoPath != null
              ? FileImage(File(widget.partner.photoPath!))
              : null,
          child: widget.partner.photoPath == null
              ? Text(
                  widget.partner.name.isNotEmpty
                      ? widget.partner.name[0].toUpperCase()
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
            Text(widget.partner.name,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E))),
            const Text('Partner',
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
                    'Contribution',
                    '₹${_totalContribution.toStringAsFixed(0)}',
                    _kAccent),
              ),
              Container(
                  width: 1, height: 40, color: const Color(0xFFEEECE8)),
              Expanded(
                child: _statCol(
                    'Expense',
                    '₹${_totalExpense.toStringAsFixed(0)}',
                    const Color(0xFFCC3300)),
              ),
              Container(
                  width: 1, height: 40, color: const Color(0xFFEEECE8)),
              Expanded(
                child: _statCol(
                    'Advance',
                    '₹${_totalAdvance.toStringAsFixed(0)}',
                    Colors.deepOrange),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEECE8)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Net Balance',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF444444))),
              Text(
                '₹${_netBalance.abs().toStringAsFixed(2)}${_netBalance < 0 ? ' (Overdrawn)' : ''}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _netBalance >= 0
                        ? _kAccent
                        : const Color(0xFFCC3300)),
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
}
