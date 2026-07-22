import 'dart:io';
import 'package:flutter/material.dart';
import 'add_karigar_screen.dart';
import '../db/db_helper.dart';
import '../models/karigar.dart';
import 'karigar_detail_screen.dart';

const _kAccent = Color(0xFFE07B1A);

class KarigarListScreen extends StatefulWidget {
  const KarigarListScreen({super.key});

  @override
  State<KarigarListScreen> createState() => _KarigarListScreenState();
}

class _KarigarListScreenState extends State<KarigarListScreen> {
  final DBHelper _db = DBHelper.instance;
  List<Karigar> _karigars = [];
  Map<int, double> _netPayables = {};
  Map<String, double> _grandTotal = {
    'totalWork': 0,
    'totalAdvance': 0,
    'netPayable': 0
  };
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
      if (k.id != null) netPayables[k.id!] = await _db.getKarigarNetPayable(k.id!);
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
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(title: const Text('Workers')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryBar(),
                Expanded(
                  child: _karigars.isEmpty
                      ? const Center(
                          child: Text(
                            'No workers added yet.\nTap + to add one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF888888)),
                          ),
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: _karigars.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final karigar = _karigars[index];
                            final net = _netPayables[karigar.id] ?? 0.0;
                            return _KarigarTile(
                              karigar: karigar,
                              netPayable: net,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        KarigarDetailScreen(karigar: karigar),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Worker',
            style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddKarigarScreen()));
          _loadKarigars();
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
            child:
                _sumItem('Total Work', _grandTotal['totalWork'] ?? 0, _kAccent),
          ),
          Container(width: 1, height: 36, color: const Color(0xFFEEECE8)),
          Expanded(
            child: _sumItem(
                'Total Advance', _grandTotal['totalAdvance'] ?? 0, Colors.deepOrange),
          ),
          Container(width: 1, height: 36, color: const Color(0xFFEEECE8)),
          Expanded(
            child: _sumItem('Net Payable',
                _grandTotal['netPayable'] ?? 0, const Color(0xFFCC3300),
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

class _KarigarTile extends StatelessWidget {
  final Karigar karigar;
  final double netPayable;
  final VoidCallback onTap;

  const _KarigarTile({
    required this.karigar,
    required this.netPayable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shouldPay = netPayable > 0;
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
                backgroundImage: karigar.photoPath != null
                    ? FileImage(File(karigar.photoPath!))
                    : null,
                child: karigar.photoPath == null
                    ? Text(
                        karigar.name.isNotEmpty
                            ? karigar.name[0].toUpperCase()
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
                    Text(karigar.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF1C1C1E))),
                    const SizedBox(height: 2),
                    Text(
                      shouldPay ? 'Payable' : 'Advance Paid',
                      style: TextStyle(
                          fontSize: 12,
                          color: shouldPay
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
                    '₹${netPayable.abs().toStringAsFixed(0)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: shouldPay
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
