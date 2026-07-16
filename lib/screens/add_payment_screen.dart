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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment - ${widget.party.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Payment Amount'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Amount is required';
                  if (double.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              const Text('Payment Mode', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<PaymentMode>(
                      title: const Text('Cash'),
                      value: PaymentMode.cash,
                      // ignore: deprecated_member_use
                      groupValue: _mode,
                      // ignore: deprecated_member_use
                      onChanged: (v) => setState(() => _mode = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<PaymentMode>(
                      title: const Text('Cheque'),
                      value: PaymentMode.cheque,
                      // ignore: deprecated_member_use
                      groupValue: _mode,
                      // ignore: deprecated_member_use
                      onChanged: (v) => setState(() => _mode = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _savePayment,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
