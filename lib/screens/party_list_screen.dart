import 'dart:io';
import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/party.dart';
import 'add_party_screen.dart';
import 'party_detail_screen.dart';

const _kPartyAccent = Color(0xFF1A6DFF);

class PartyListScreen extends StatefulWidget {
  const PartyListScreen({super.key});

  @override
  State<PartyListScreen> createState() => _PartyListScreenState();
}

class _PartyListScreenState extends State<PartyListScreen> {
  final DBHelper _db = DBHelper.instance;
  List<Party> _parties = [];
  Map<int, double> _balances = {};
  Map<String, double> _grandTotal = {
    'totalBill': 0,
    'totalPayment': 0,
    'outstanding': 0
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadParties();
  }

  Future<void> _loadParties() async {
    setState(() => _loading = true);
    final parties = await _db.getAllParties();
    final balances = <int, double>{};
    for (final p in parties) {
      if (p.id != null) balances[p.id!] = await _db.getOutstandingBalance(p.id!);
    }
    final grandTotal = await _db.getPartyGrandTotal();
    setState(() {
      _parties = parties;
      _balances = balances;
      _grandTotal = grandTotal;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(title: const Text('Party')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryBar(),
                Expanded(
                  child: _parties.isEmpty
                      ? const Center(
                          child: Text('No parties added yet.\nTap + to add one.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF888888))),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: _parties.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final party = _parties[index];
                            final balance = _balances[party.id] ?? 0.0;
                            return _PartyTile(
                              party: party,
                              balance: balance,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PartyDetailScreen(party: party),
                                  ),
                                );
                                _loadParties();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kPartyAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Party',
            style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddPartyScreen()));
          _loadParties();
        },
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DED8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _sumItem(
                'Total Bill', _grandTotal['totalBill'] ?? 0, _kPartyAccent),
          ),
          Container(width: 1, height: 36, color: const Color(0xFFEEECE8)),
          Expanded(
            child: _sumItem('Total Payment',
                _grandTotal['totalPayment'] ?? 0, Colors.teal),
          ),
          Container(width: 1, height: 36, color: const Color(0xFFEEECE8)),
          Expanded(
            child: _sumItem(
                'Outstanding',
                _grandTotal['outstanding'] ?? 0,
                const Color(0xFFCC3300),
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

class _PartyTile extends StatelessWidget {
  final Party party;
  final double balance;
  final VoidCallback onTap;

  const _PartyTile({
    required this.party,
    required this.balance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOutstanding = balance > 0;
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
                backgroundColor: _kPartyAccent.withOpacity(0.12),
                backgroundImage: party.photoPath != null
                    ? FileImage(File(party.photoPath!))
                    : null,
                child: party.photoPath == null
                    ? Text(
                        party.name.isNotEmpty
                            ? party.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _kPartyAccent,
                            fontSize: 16),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(party.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF1C1C1E))),
                    const SizedBox(height: 2),
                    Text(
                      isOutstanding ? 'Outstanding' : 'All clear',
                      style: TextStyle(
                          fontSize: 12,
                          color: isOutstanding
                              ? const Color(0xFFCC3300)
                              : const Color(0xFF27AE60)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${balance.abs().toStringAsFixed(0)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isOutstanding
                            ? const Color(0xFFCC3300)
                            : const Color(0xFF27AE60)),
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
