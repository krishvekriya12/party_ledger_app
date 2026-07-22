import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/online_sale_payment.dart';
import '../models/partner.dart';

class AddOnlineSalePaymentScreen extends StatefulWidget {
  const AddOnlineSalePaymentScreen({super.key});

  @override
  State<AddOnlineSalePaymentScreen> createState() =>
      _AddOnlineSalePaymentScreenState();
}

class _AddOnlineSalePaymentScreenState
    extends State<AddOnlineSalePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  OnlinePlatform _selectedPlatform = OnlinePlatform.flipkart;
  Partner? _selectedPartner;
  List<Partner> _partners = [];
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;
  bool _loadingPartners = true;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    final partners = await DBHelper.instance.getAllPartners();
    setState(() {
      _partners = partners;
      _loadingPartners = false;
    });
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPartner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pehle partner select karo')),
      );
      return;
    }
    setState(() => _saving = true);

    final payment = OnlineSalePayment(
      platform: _selectedPlatform,
      partnerId: _selectedPartner!.id!,
      amount: double.parse(_amountController.text),
      paymentDate: _selectedDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    try {
      await DBHelper.instance.insertOnlineSalePayment(payment);
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
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _selectedPlatform == OnlinePlatform.flipkart
        ? const Color(0xFF1A6DFF) // Flipkart blue
        : const Color(0xFFE91E63); // Meesho Pink/Red
    final dateStr =
        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(
        title: const Text('Add Sale Payment'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE8E8E4))),
      ),
      body: _loadingPartners
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Platform Selector
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
                          const Text(
                            'Platform Select Karo',
                            style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<OnlinePlatform>(
                                  title: const Text('Flipkart', style: TextStyle(fontSize: 14)),
                                  value: OnlinePlatform.flipkart,
                                  groupValue: _selectedPlatform,
                                  activeColor: const Color(0xFF1A6DFF),
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (v) =>
                                      setState(() => _selectedPlatform = v!),
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<OnlinePlatform>(
                                  title: const Text('Meesho', style: TextStyle(fontSize: 14)),
                                  value: OnlinePlatform.meesho,
                                  groupValue: _selectedPlatform,
                                  activeColor: const Color(0xFFE91E63),
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (v) =>
                                      setState(() => _selectedPlatform = v!),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Partner dropdown
                    _partners.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFFB74D)),
                            ),
                            child: const Text(
                              '⚠️ Koi partner nahi mila. Pehle Partners module me partner add karo.',
                              style: TextStyle(color: Color(0xFFE65100), fontSize: 13),
                            ),
                          )
                        : DropdownButtonFormField<Partner>(
                            value: _selectedPartner,
                            decoration: const InputDecoration(
                              labelText: 'Partner Select Karo',
                              prefixIcon: Icon(Icons.person_outline, size: 18),
                            ),
                            items: _partners
                                .map((p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p.name),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedPartner = v),
                            validator: (v) =>
                                v == null ? 'Partner select karna padega' : null,
                          ),
                    const SizedBox(height: 12),
                    // Amount field
                    _field(
                      controller: _amountController,
                      label: 'Payment Amount (₹)',
                      icon: Icons.currency_rupee,
                      keyboard: TextInputType.number,
                      focusedColor: accent,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Amount required';
                        if (double.tryParse(v) == null) return 'Valid amount entering karo';
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
                            const Text('Payment Date',
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
                      focusedColor: accent,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_saving || _partners.isEmpty) ? null : _save,
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
                            : const Text('Save Payment',
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
    required Color focusedColor,
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
          borderSide: BorderSide(color: focusedColor, width: 1.5),
        ),
      ),
    );
  }
}
