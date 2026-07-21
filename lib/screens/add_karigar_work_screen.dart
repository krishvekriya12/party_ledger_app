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
  DateTime _selectedDate = DateTime.now();
  double _total = 0.0;
  bool _saving = false;

  void _calculateTotal() {
    final pis = double.tryParse(_pisController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    setState(() => _total = pis * rate);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
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
      workDate: _selectedDate,
    );
    try {
      await DBHelper.instance.insertKarigarWork(work);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    const accent = Color(0xFFE07B1A);
    final dateStr = '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(
        title: Text('Work Entry — ${widget.karigar.name}'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE8E8E4))),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _field(controller: _designNoController, label: 'Design No (D.No)', icon: Icons.tag,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Design No is required' : null),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: _pisController, label: 'Pieces', icon: Icons.layers_outlined,
                      keyboard: TextInputType.number,
                      onChanged: (_) => _calculateTotal(),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Pieces is required';
                        if (double.tryParse(v) == null) return 'Enter valid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: _rateController, label: 'Rate (₹)', icon: Icons.currency_rupee,
                      keyboard: TextInputType.number,
                      onChanged: (_) => _calculateTotal(),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Rate is required';
                        if (double.tryParse(v) == null) return 'Enter valid number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Total preview
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF444444))),
                    Text('₹${_total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accent)),
                  ],
                ),
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
                      const Text('Work Date', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                      const Spacer(),
                      Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF888888)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveWork,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent, foregroundColor: Colors.white, elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Work', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({required TextEditingController controller, required String label, required IconData icon,
      TextInputType keyboard = TextInputType.text, void Function(String)? onChanged, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller, keyboardType: keyboard, onChanged: onChanged, validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF888888)),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0DED8))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0DED8))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE07B1A), width: 1.5)),
      ),
    );
  }
}
