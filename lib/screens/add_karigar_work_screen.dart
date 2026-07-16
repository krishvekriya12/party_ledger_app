import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/karigar.dart';
import '../models/karigar_work.dart';

class AddKarigarWorkScreen extends StatefulWidget {
  final Karigar karigar;
  const AddKarigarWorkScreen({super.key, required this.karigar});

  @override
  State<AddKarigarWorkScreen> createState() => _AddKarigarWorkScreenState();
}

class _AddKarigarWorkScreenState extends State<AddKarigarWorkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _designNoController = TextEditingController();
  final _pisController = TextEditingController();
  final _rateController = TextEditingController();
  double _total = 0.0;
  bool _saving = false;

  void _calculateTotal() {
    final pis = double.tryParse(_pisController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    setState(() => _total = pis * rate);
  }

  Future<void> _saveWork() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.karigar.id == null) return;

    setState(() => _saving = true);

    final work = KarigarWork(
      karigarId: widget.karigar.id!,
      designNo: _designNoController.text.trim(),
      pis: double.parse(_pisController.text),
      rate: double.parse(_rateController.text),
      total: _total,
    );

    try {
      await DBHelper.instance.insertKarigarWork(work);
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
    _pisController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Work Entry - ${widget.karigar.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _designNoController,
                decoration: const InputDecoration(labelText: 'Design No (D.No)'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Design No is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pisController,
                decoration: const InputDecoration(labelText: 'Pis (Quantity)'),
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateTotal(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Pis is required';
                  if (double.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rateController,
                decoration: const InputDecoration(labelText: 'Rate (per pis)'),
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
                onPressed: _saving ? null : _saveWork,
                child: _saving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Save Work Entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
