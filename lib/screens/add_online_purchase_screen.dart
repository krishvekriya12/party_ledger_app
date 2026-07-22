import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/online_purchase.dart';

class AddOnlinePurchaseScreen extends StatefulWidget {
  const AddOnlinePurchaseScreen({super.key});

  @override
  State<AddOnlinePurchaseScreen> createState() => _AddOnlinePurchaseScreenState();
}

class _AddOnlinePurchaseScreenState extends State<AddOnlinePurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _partyNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final purchase = OnlinePurchase(
      partyName: _partyNameController.text.trim(),
      amount: double.parse(_amountController.text),
      purchaseDate: _selectedDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    try {
      await DBHelper.instance.insertOnlinePurchase(purchase);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _partyNameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF009688); // Teal for Online module
    final dateStr =
        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(
        title: const Text('Add Purchase'),
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
              // Party Name
              _field(
                controller: _partyNameController,
                label: 'Party Name',
                icon: Icons.store_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Party name required' : null,
              ),
              const SizedBox(height: 12),
              // Amount
              _field(
                controller: _amountController,
                label: 'Bill Amount (₹)',
                icon: Icons.currency_rupee,
                keyboard: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Amount required';
                  if (double.tryParse(v) == null) return 'Enter valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Date picker
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE0DED8)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: Color(0xFF888888)),
                      const SizedBox(width: 10),
                      const Text('Purchase Date',
                          style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                      const Spacer(),
                      Text(dateStr,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1C1C1E))),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_outlined,
                          size: 16, color: Color(0xFF888888)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Note
              _field(
                controller: _noteController,
                label: 'Note (optional)',
                icon: Icons.notes_outlined,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Purchase',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF888888)),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0DED8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0DED8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF009688), width: 1.5),
        ),
      ),
    );
  }
}
