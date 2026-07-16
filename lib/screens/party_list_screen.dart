import 'dart:io';
import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/party.dart';
import 'add_party_screen.dart';
import 'party_detail_screen.dart';

class PartyListScreen extends StatefulWidget {
  const PartyListScreen({super.key});

  @override
  State<PartyListScreen> createState() => _PartyListScreenState();
}

class _PartyListScreenState extends State<PartyListScreen> {
  final DBHelper _db = DBHelper.instance;
  List<Party> _parties = [];
  Map<int, double> _balances = {};
  Map<String, double> _grandTotal = {'totalBill': 0, 'totalPayment': 0, 'outstanding': 0};
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
      if (p.id != null) {
        balances[p.id!] = await _db.getOutstandingBalance(p.id!);
      }
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
      appBar: AppBar(title: const Text('Party')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildGrandTotalCard(),
                Expanded(
                  child: _parties.isEmpty
                      ? const Center(child: Text('No party added yet.\nTap + to add one.'))
                      : ListView.builder(
                          itemCount: _parties.length,
                          itemBuilder: (context, index) {
                            final party = _parties[index];
                            final balance = _balances[party.id] ?? 0.0;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: party.photoPath != null
                                    ? FileImage(File(party.photoPath!))
                                    : null,
                                child: party.photoPath == null
                                    ? Text(party.name.isNotEmpty ? party.name[0] : '?')
                                    : null,
                              ),
                              title: Text(party.name),
                              subtitle: Text(balance >= 0 ? 'Outstanding' : 'Extra Paid'),
                              trailing: Text(
                                '₹${balance.abs().toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: balance > 0 ? Colors.red : Colors.green,
                                ),
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PartyDetailScreen(party: party),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPartyScreen()),
          );
          _loadParties();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGrandTotalCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sabhi Party - Grand Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _totalItem('Total Bill', _grandTotal['totalBill'] ?? 0),
                _totalItem('Total Payment', _grandTotal['totalPayment'] ?? 0),
                _totalItem('Outstanding', _grandTotal['outstanding'] ?? 0, highlight: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalItem(String label, double value, {bool highlight = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: highlight ? Colors.red : Colors.black87,
          ),
        ),
      ],
    );
  }
}
