import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/karigar.dart';
import '../models/karigar_advance.dart';

class AddKarigarAdvanceScreen extends StatefulWidget {
  final Karigar karigar;
  const AddKarigarAdvanceScreen({super.key, required this.karigar});

  @override
  State<AddKarigarAdvanceScreen> createState() => _AddKarigarAdvanceScreenState();
}

class _AddKarigarAdvanceScreenState extends State<AddKarigarAdvanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveAdvance() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.karigar.id == null) return;
    setState(() => _saving = true);
    final advance = KarigarAdvance(
      karigarId: widget.karigar.id!,
      amount: double.parse(_amountController.text),
      advanceDate: _selectedDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );
    try {
      await DBHelper.instance.insertKarigarAdvance(advance);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally { setState(() => _saving = false); }
  }

  @override
  void dispose() { _amountController.dispose(); _noteController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFCC6600);
    final dateStr = '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(
        title: Text('Advance — ${widget.karigar.name}'),
        backgroundColor: Colors.white, foregroundColor: const Color(0xFF1C1C1E),
        elevation: 0, shape: const Border(bottom: BorderSide(color: Color(0xFFE8E8E4))),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _amountController, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Advance Amount (₹)', prefixIcon: Icon(Icons.currency_rupee, size: 18)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Amount is required';
                  if (double.tryParse(v) == null) return 'Enter valid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE0DED8))),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF888888)),
                      const SizedBox(width: 10),
                      const Text('Date', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                      const Spacer(),
                      Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF888888)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)', prefixIcon: Icon(Icons.notes, size: 18)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveAdvance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent, foregroundColor: Colors.white, elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Advance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
