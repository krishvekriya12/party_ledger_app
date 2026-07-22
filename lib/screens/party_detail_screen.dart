import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/party.dart';
import '../models/bill.dart';
import '../models/payment.dart';
import 'add_bill_screen.dart';
import 'add_payment_screen.dart';

const _kAccent = Color(0xFF1A6DFF);

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
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(title: Text(widget.party.name)),
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
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _actionBtn(
                          label: 'Add Bill',
                          icon: Icons.receipt_long_outlined,
                          color: _kAccent,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddBillScreen(party: widget.party),
                              ),
                            );
                            _loadData();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionBtn(
                          label: 'Add Payment',
                          icon: Icons.payments_outlined,
                          color: Colors.teal,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddPaymentScreen(party: widget.party),
                              ),
                            );
                            _loadData();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bill History
                  _sectionHeader('Bill History', Icons.receipt_long_outlined),
                  const SizedBox(height: 8),
                  if (_billList.isEmpty)
                    _emptyCard('No bills recorded yet.')
                  else
                    _card(
                      child: Column(
                        children: _billList.asMap().entries.map((entry) {
                          final i = entry.key;
                          final b = entry.value;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _kAccent.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${i + 1}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _kAccent),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${b.designNo}  •  ${b.color}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: Color(0xFF1C1C1E)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${b.pis.toStringAsFixed(0)} pcs × ₹${b.rate.toStringAsFixed(2)}  •  ${dateFormat.format(b.billDate)}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B6B6B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹${b.total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: _kAccent),
                                    ),
                                  ],
                                ),
                              ),
                              if (i < _billList.length - 1)
                                const Divider(
                                    height: 1,
                                    indent: 60,
                                    color: Color(0xFFEEECE8)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Payment History
                  _sectionHeader('Payment History', Icons.payments_outlined),
                  const SizedBox(height: 8),
                  if (_paymentList.isEmpty)
                    _emptyCard('No payments recorded yet.')
                  else
                    _card(
                      child: Column(
                        children: _paymentList.asMap().entries.map((entry) {
                          final i = entry.key;
                          final p = entry.value;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor:
                                          Colors.teal.withOpacity(0.12),
                                      child: const Icon(Icons.arrow_downward,
                                          size: 14, color: Colors.teal),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.mode == PaymentMode.cash
                                                ? 'Cash'
                                                : 'Cheque',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: Color(0xFF1C1C1E)),
                                          ),
                                          Text(
                                            dateFormat.format(p.paymentDate),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B6B6B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹${p.amount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.teal),
                                    ),
                                  ],
                                ),
                              ),
                              if (i < _paymentList.length - 1)
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
          backgroundImage: widget.party.photoPath != null
              ? FileImage(File(widget.party.photoPath!))
              : null,
          child: widget.party.photoPath == null
              ? Text(
                  widget.party.name.isNotEmpty
                      ? widget.party.name[0].toUpperCase()
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
            Text(widget.party.name,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E))),
            const Text('Party',
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
                    'Total Bill', '₹${_totalBill.toStringAsFixed(0)}', _kAccent),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFEEECE8)),
              Expanded(
                child: _statCol(
                    'Total Payment', '₹${_totalPayment.toStringAsFixed(0)}',
                    Colors.teal),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEECE8)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Outstanding',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF444444))),
              Text(
                '₹${_outstanding.abs().toStringAsFixed(2)}${_outstanding < 0 ? ' (Extra paid)' : ''}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _outstanding > 0
                        ? const Color(0xFFCC3300)
                        : const Color(0xFF27AE60)),
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

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _kAccent),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1C1C1E))),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DED8)),
      ),
      child: child,
    );
  }

  Widget _emptyCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DED8)),
      ),
      child: Center(
        child: Text(msg,
            style:
                const TextStyle(color: Color(0xFF888888), fontSize: 13)),
      ),
    );
  }
}
