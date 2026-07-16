import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/party.dart';
import '../models/bill.dart';
import '../models/payment.dart';
import 'add_bill_screen.dart';
import 'add_payment_screen.dart';

class PartyDetailScreen extends StatefulWidget {
  final Party party;
  const PartyDetailScreen({super.key, required this.party});

  @override
  State<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends State<PartyDetailScreen> {
  final DBHelper _db = DBHelper.instance;
  List<Bill> _billList = [];
  List<Payment> _paymentList = [];
  double _totalBill = 0;
  double _totalPayment = 0;
  double _outstanding = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final partyId = widget.party.id!;
    final bills = await _db.getBillsForParty(partyId);
    final payments = await _db.getPaymentsForParty(partyId);
    final totalBill = await _db.getTotalBillAmount(partyId);
    final totalPayment = await _db.getTotalPaidAmount(partyId);

    setState(() {
      _billList = bills;
      _paymentList = payments;
      _totalBill = totalBill;
      _totalPayment = totalPayment;
      _outstanding = totalBill - totalPayment;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(widget.party.name)),
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
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Add Bill'),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddBillScreen(party: widget.party),
                        ),
                      );
                      _loadData();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.payments),
                    label: const Text('Add Payment'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddPaymentScreen(party: widget.party),
                        ),
                      );
                      _loadData();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Bill History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            if (_billList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No bills added yet.'),
              )
            else
              ..._billList.map((b) => ListTile(
                dense: true,
                title: Text('Design: ${b.designNo}  •  ${b.color}'),
                subtitle: Text(dateFormat.format(b.billDate)),
                trailing: Text(
                  '₹${b.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              )),
            const SizedBox(height: 20),
            const Text('Payment History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            if (_paymentList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No payment received yet.'),
              )
            else
              ..._paymentList.map((p) => ListTile(
                dense: true,
                title: Text(p.mode == PaymentMode.cash ? 'Cash' : 'Cheque'),
                subtitle: Text(dateFormat.format(p.paymentDate)),
                trailing: Text(
                  '₹${p.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
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
          backgroundImage: widget.party.photoPath != null
              ? FileImage(File(widget.party.photoPath!))
              : null,
          child: widget.party.photoPath == null
              ? Text(widget.party.name.isNotEmpty ? widget.party.name[0] : '?')
              : null,
        ),
        const SizedBox(width: 16),
        Text(widget.party.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                _summaryItem('Total Bill', _totalBill, Colors.green),
                _summaryItem('Total Payment', _totalPayment, Colors.teal),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Outstanding', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  '₹${_outstanding.abs().toStringAsFixed(2)} ${_outstanding < 0 ? "(Extra paid)" : ""}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _outstanding > 0 ? Colors.red : Colors.green,
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