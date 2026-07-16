import 'dart:io';
import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/partner.dart';
import 'add_partner_screen.dart';
import 'partner_detail_screen.dart';

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

  // User apni marzi se jitne chahe utne partner add kar sakta hai - no fixed limit
  Future<void> _loadPartners() async {
    setState(() => _loading = true);
    final partners = await _db.getAllPartners();
    final netBalances = <int, double>{};
    for (final p in partners) {
      if (p.id != null) {
        netBalances[p.id!] = await _db.getPartnerNetBalance(p.id!);
      }
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
      appBar: AppBar(title: const Text('Partners')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildGrandTotalCard(),
                Expanded(
                  child: _partners.isEmpty
                      ? const Center(child: Text('Koi partner add nahi hai.\nTap + to add one.'))
                      : ListView.builder(
                          itemCount: _partners.length,
                          itemBuilder: (context, index) {
                            final partner = _partners[index];
                            final netBalance = _netBalances[partner.id] ?? 0.0;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: partner.photoPath != null
                                    ? FileImage(File(partner.photoPath!))
                                    : null,
                                child: partner.photoPath == null
                                    ? Text(partner.name.isNotEmpty ? partner.name[0] : '?')
                                    : null,
                              ),
                              title: Text(partner.name),
                              subtitle: Text(netBalance >= 0 ? 'Balance' : 'Extra Kharcha'),
                              trailing: Text(
                                '₹${netBalance.abs().toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: netBalance >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PartnerDetailScreen(partner: partner),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPartnerScreen()),
          );
          _loadPartners();
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
            const Text('Sabhi Partner - Grand Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _totalItem('Total Diya', _grandTotal['totalContribution'] ?? 0),
                _totalItem('Total Kharcha', _grandTotal['totalExpense'] ?? 0),
                _totalItem('Net Balance', _grandTotal['netBalance'] ?? 0, highlight: true),
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
            color: highlight ? Colors.blue : Colors.black87,
          ),
        ),
      ],
    );
  }
}
