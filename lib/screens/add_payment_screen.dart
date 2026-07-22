import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/party.dart';
import '../models/payment.dart';

class AddPaymentScreen extends StatefulWidget {
  final Party party;
  const AddPaymentScreen({super.key, required this.party});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  PaymentMode _mode = PaymentMode.cash;
  bool _saving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.party.id == null) return;
    setState(() => _saving = true);
    final payment = Payment(
      partyId: widget.party.id!,
      amount: double.parse(_amountController.text),
      mode: _mode,
      paymentDate: _selectedDate,
    );
    try {
      await DBHelper.instance.insertPayment(payment);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() { _amountController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const accent = Colors.teal;
    final dateStr = '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(
        title: Text('Payment — ${widget.party.name}'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE8E8E4))),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Payment Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee, size: 18),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Amount is required';
                  if (double.tryParse(v) == null) return 'Enter valid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Date
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE0DED8)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF888888)),
                      const SizedBox(width: 10),
                      const Text('Payment Date', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                      const Spacer(),
                      Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF888888)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Mode
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0DED8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Mode', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<PaymentMode>(
                            title: const Text('Cash', style: TextStyle(fontSize: 14)),
                            value: PaymentMode.cash,
                            groupValue: _mode,
                            activeColor: accent,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) => setState(() => _mode = v!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<PaymentMode>(
                            title: const Text('Cheque', style: TextStyle(fontSize: 14)),
                            value: PaymentMode.cheque,
                            groupValue: _mode,
                            activeColor: accent,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) => setState(() => _mode = v!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _savePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
