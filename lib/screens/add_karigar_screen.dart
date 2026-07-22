import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../db/db_helper.dart';
import '../models/karigar.dart';

class AddKarigarScreen extends StatefulWidget {
  const AddKarigarScreen({super.key});

  @override
  State<AddKarigarScreen> createState() => _AddKarigarScreenState();
}

class _AddKarigarScreenState extends State<AddKarigarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  File? _photo;
  bool _saving = false;

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _saveKarigar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final karigar = Karigar(name: _nameController.text.trim(), photoPath: _photo?.path);
    try {
      await DBHelper.instance.insertKarigar(karigar);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally { setState(() => _saving = false); }
  }

  @override
  void dispose() { _nameController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE07B1A);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(title: const Text('Add Karigar'), backgroundColor: Colors.white, foregroundColor: const Color(0xFF1C1C1E), elevation: 0, shape: const Border(bottom: BorderSide(color: Color(0xFFE8E8E4)))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _pickPhoto(ImageSource.camera),
                      onLongPress: () => _pickPhoto(ImageSource.gallery),
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: accent.withOpacity(0.1),
                        backgroundImage: _photo != null ? FileImage(_photo!) : null,
                        child: _photo == null ? const Icon(Icons.camera_alt_outlined, size: 28, color: accent) : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('Tap = Camera  •  Long press = Gallery', style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Karigar Name', prefixIcon: Icon(Icons.handyman_outlined, size: 18)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveKarigar,
                  style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Karigar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
