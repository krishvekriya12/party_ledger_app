import 'dart:io';
import 'package:flutter/material.dart';

import 'add_karigar_screen.dart';
import '../db/db_helper.dart';
import '../models/karigar.dart';
import 'karigar_detail_screen.dart';

class KarigarListScreen extends StatefulWidget {
  const KarigarListScreen({super.key});

  @override
  State<KarigarListScreen> createState() => _KarigarListScreenState();
}

class _KarigarListScreenState extends State<KarigarListScreen> {
  final DBHelper _db = DBHelper.instance;
  List<Karigar> _karigars = [];
  Map<int, double> _netPayables = {};
  Map<String, double> _grandTotal = {'totalWork': 0, 'totalAdvance': 0, 'netPayable': 0};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadKarigars();
  }

  Future<void> _loadKarigars() async {
    setState(() => _loading = true);
    final karigars = await _db.getAllKarigars();
    final netPayables = <int, double>{};
    for (final k in karigars) {
      if (k.id != null) {
        netPayables[k.id!] = await _db.getKarigarNetPayable(k.id!);
      }
    }
    final grandTotal = await _db.getKarigarGrandTotal();
    setState(() {
      _karigars = karigars;
      _netPayables = netPayables;
      _grandTotal = grandTotal;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Karigar')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildGrandTotalCard(),
          Expanded(
            child: _karigars.isEmpty
                ? const Center(child: Text('No karigar added yet.\nTap + to add one.'))
                : ListView.builder(
              itemCount: _karigars.length,
              itemBuilder: (context, index) {
                final karigar = _karigars[index];
                final netPayable = _netPayables[karigar.id] ?? 0.0;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: karigar.photoPath != null
                        ? FileImage(File(karigar.photoPath!))
                        : null,
                    child: karigar.photoPath == null
                        ? Text(karigar.name.isNotEmpty ? karigar.name[0] : '?')
                        : null,
                  ),
                  title: Text(karigar.name),
                  subtitle: Text(
                    netPayable >= 0 ? 'Net Payable' : 'Advance Extra',
                  ),
                  trailing: Text(
                    '₹${netPayable.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: netPayable > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KarigarDetailScreen(karigar: karigar),
                      ),
                    );
                    _loadKarigars();
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
            MaterialPageRoute(builder: (_) => const AddKarigarScreen()),
          );
          _loadKarigars();
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
            const Text('Sabhi Karigar - Grand Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _totalItem('Total Kaam', _grandTotal['totalWork'] ?? 0),
                _totalItem('Total Upad', _grandTotal['totalAdvance'] ?? 0),
                _totalItem('Net Payable', _grandTotal['netPayable'] ?? 0, highlight: true),
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
