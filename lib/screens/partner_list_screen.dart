import 'dart:io';
import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/partner.dart';
import 'add_partner_screen.dart';
import 'partner_detail_screen.dart';

const _kAccent = Color(0xFF27AE60);

class PartnerListScreen extends StatefulWidget {
  const PartnerListScreen({super.key});

  @override
  State<PartnerListScreen> createState() => _PartnerListScreenState();
}

class _PartnerListScreenState extends State<PartnerListScreen> {
  final DBHelper _db = DBHelper.instance;
  List<Partner> _partners = [];
  Map<int, double> _netBalances = {};
  Map<String, double> _grandTotal = {
    'totalContribution': 0,
    'totalExpense': 0,
    'netBalance': 0,
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    setState(() => _loading = true);
    final partners = await _db.getAllPartners();
    final netBalances = <int, double>{};
    for (final p in partners) {
      if (p.id != null) netBalances[p.id!] = await _db.getPartnerNetBalance(p.id!);
    }
    final grandTotal = await _db.getPartnerGrandTotal();
    setState(() {
      _partners = partners;
      _netBalances = netBalances;
      _grandTotal = grandTotal;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(title: const Text('Partners')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryBar(),
                Expanded(
                  child: _partners.isEmpty
                      ? const Center(
                          child: Text(
                            'No partners added yet.\nTap + to add one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF888888)),
                          ),
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: _partners.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final partner = _partners[index];
                            final net = _netBalances[partner.id] ?? 0.0;
                            return _PartnerTile(
                              partner: partner,
                              netBalance: net,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PartnerDetailScreen(
                                        partner: partner),
                                  ),
                                );
                                _loadPartners();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Partner',
            style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddPartnerScreen()));
          _loadPartners();
        },
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DED8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _sumItem('Contributed',
                _grandTotal['totalContribution'] ?? 0, _kAccent),
          ),
          Container(width: 1, height: 36, color: const Color(0xFFEEECE8)),
          Expanded(
            child: _sumItem('Expense',
                _grandTotal['totalExpense'] ?? 0, const Color(0xFFCC3300)),
          ),
          Container(width: 1, height: 36, color: const Color(0xFFEEECE8)),
          Expanded(
            child: _sumItem('Advance',
                _grandTotal['totalAdvance'] ?? 0, Colors.deepOrange),
          ),
          Container(width: 1, height: 36, color: const Color(0xFFEEECE8)),
          Expanded(
            child: _sumItem('Net Bal',
                _grandTotal['netBalance'] ?? 0, _kAccent,
                bold: true),
          ),
        ],
      ),
    );
  }

  Widget _sumItem(String label, double value, Color color,
      {bool bold = false}) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
        const SizedBox(height: 4),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
              color: color),
        ),
      ],
    );
  }
}

class _PartnerTile extends StatelessWidget {
  final Partner partner;
  final double netBalance;
  final VoidCallback onTap;

  const _PartnerTile({
    required this.partner,
    required this.netBalance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final positive = netBalance >= 0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0DED8)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _kAccent.withOpacity(0.12),
                backgroundImage: partner.photoPath != null
                    ? FileImage(File(partner.photoPath!))
                    : null,
                child: partner.photoPath == null
                    ? Text(
                        partner.name.isNotEmpty
                            ? partner.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _kAccent,
                            fontSize: 16),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(partner.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF1C1C1E))),
                    const SizedBox(height: 2),
                    Text(
                      positive ? 'Balance' : 'Overdrawn',
                      style: TextStyle(
                          fontSize: 12,
                          color: positive
                              ? _kAccent
                              : const Color(0xFFCC3300)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${netBalance.abs().toStringAsFixed(0)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: positive
                            ? _kAccent
                            : const Color(0xFFCC3300)),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 16, color: Color(0xFFBBBBBB)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
