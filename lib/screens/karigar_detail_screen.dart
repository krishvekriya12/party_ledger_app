import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/karigar.dart';
import '../models/karigar_work.dart';
import '../models/karigar_advance.dart';
import 'add_karigar_work_screen.dart';
import 'add_karigar_advance_screen.dart';

class KarigarDetailScreen extends StatefulWidget {
  final Karigar karigar;
  const KarigarDetailScreen({super.key, required this.karigar});

  @override
  State<KarigarDetailScreen> createState() => _KarigarDetailScreenState();
}

class _KarigarDetailScreenState extends State<KarigarDetailScreen> {
  final DBHelper _db = DBHelper.instance;
  List<KarigarWork> _workList = [];
  List<KarigarAdvance> _advanceList = [];
  double _totalWork = 0;
  double _totalAdvance = 0;
  double _netPayable = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final karigarId = widget.karigar.id!;
    final work = await _db.getWorkForKarigar(karigarId);
    final advances = await _db.getAdvancesForKarigar(karigarId);
    final totalWork = await _db.getTotalWorkAmount(karigarId);
    final totalAdvance = await _db.getTotalAdvanceGiven(karigarId);

    setState(() {
      _workList = work;
      _advanceList = advances;
      _totalWork = totalWork;
      _totalAdvance = totalAdvance;
      _netPayable = totalWork - totalAdvance;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(widget.karigar.name)),
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
                    icon: const Icon(Icons.work),
                    label: const Text('Add Work'),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddKarigarWorkScreen(karigar: widget.karigar),
                        ),
                      );
                      _loadData();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.money),
                    label: const Text('Add Upad'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddKarigarAdvanceScreen(karigar: widget.karigar),
                        ),
                      );
                      _loadData();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Work History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            if (_workList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No work entries yet.'),
              )
            else
              ..._workList.map((w) => ListTile(
                dense: true,
                title: Text('Design: ${w.designNo}  •  ${w.pis} pis × ₹${w.rate}'),
                subtitle: Text(dateFormat.format(w.workDate)),
                trailing: Text(
                  '₹${w.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              )),
            const SizedBox(height: 20),
            const Text('Upad (Advance) History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            if (_advanceList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No advance given yet.'),
              )
            else
              ..._advanceList.map((a) => ListTile(
                dense: true,
                title: Text(a.note ?? 'Advance'),
                subtitle: Text(dateFormat.format(a.advanceDate)),
                trailing: Text(
                  '₹${a.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              )),
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
          backgroundImage: widget.karigar.photoPath != null
              ? FileImage(File(widget.karigar.photoPath!))
              : null,
          child: widget.karigar.photoPath == null
              ? Text(widget.karigar.name.isNotEmpty ? widget.karigar.name[0] : '?')
              : null,
        ),
        const SizedBox(width: 16),
        Text(widget.karigar.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                _summaryItem('Total Kaam', _totalWork, Colors.green),
                _summaryItem('Total Upad', _totalAdvance, Colors.orange),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Net Payable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '₹${_netPayable.abs().toStringAsFixed(2)} ${_netPayable < 0 ? "(Extra diya)" : ""}',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _netPayable > 0 ? Colors.red : Colors.green,
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
