import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/party.dart';
import '../models/bill.dart';

class AddBillScreen extends StatefulWidget {
  final Party party;
  const AddBillScreen({super.key, required this.party});

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _designNoController = TextEditingController();
  final _colorController = TextEditingController();
  final _rateController = TextEditingController();
  double _total = 0.0;
  bool _saving = false;

  void _calculateTotal() {
    final rate = double.tryParse(_rateController.text) ?? 0;
    setState(() => _total = rate);
  }

  Future<void> _saveBill() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.party.id == null) return;

    setState(() => _saving = true);

    final bill = Bill(
      partyId: widget.party.id!,
      designNo: _designNoController.text.trim(),
      color: _colorController.text.trim(),
      rate: double.parse(_rateController.text),
      total: _total,
    );

    try {
      await DBHelper.instance.insertBill(bill);
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
    _designNoController.dispose();
    _colorController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bill Entry - ${widget.party.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _designNoController,
                decoration: const InputDecoration(labelText: 'Design No'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Design No is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Color'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Color is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rateController,
                decoration: const InputDecoration(labelText: 'Rate / Amount'),
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateTotal(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Rate is required';
                  if (double.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '₹${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _saveBill,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Bill'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
