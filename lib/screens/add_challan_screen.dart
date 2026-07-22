import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/challan.dart';
import '../models/party.dart';

class AddChallanScreen extends StatefulWidget {
  final Challan? existingChallan;

  const AddChallanScreen({super.key, this.existingChallan});

  @override
  State<AddChallanScreen> createState() => _AddChallanScreenState();
}

class _AddChallanScreenState extends State<AddChallanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  late TextEditingController _fromNameController;
  late TextEditingController _billNoController;
  late TextEditingController _partyNameController;
  late TextEditingController _gstinController;
  late TextEditingController _preparedByController;
  late TextEditingController _noteController;

  DateTime _selectedDate = DateTime.now();
  List<Party> _existingParties = [];
  bool _isLoading = false;

  // Item inputs structure
  final List<_ItemInputData> _items = [];

  // Default sizes pre-populated for each item
  final List<String> _standardSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL', '4XL'];

  @override
  void initState() {
    super.initState();
    final c = widget.existingChallan;

    _fromNameController = TextEditingController(
        text: c?.fromName.isNotEmpty == true ? c!.fromName : 'Yashvant Vissani');
    _billNoController = TextEditingController(text: c?.billNo ?? '');
    _partyNameController = TextEditingController(text: c?.partyName ?? '');
    _gstinController = TextEditingController(text: c?.gstin ?? '');
    _preparedByController = TextEditingController(
        text: c?.preparedBy.isNotEmpty == true ? c!.preparedBy : 'Yashvant Vissani');
    _noteController = TextEditingController(
        text: c?.note.isNotEmpty == true
            ? c!.note
            : 'Goods once sold will not be taken back.');

    if (c != null) {
      _selectedDate = c.challanDate;
      for (final item in c.items) {
        final itemData = _ItemInputData(
          particular: item.particular,
          rate: item.rate,
          sizeKeys: List.from(_standardSizes),
        );
        // Include any custom size key from existing item
        item.sizes.forEach((k, v) {
          if (!itemData.sizeKeys.contains(k)) {
            itemData.sizeKeys.add(k);
          }
          itemData.sizeControllers[k] =
              TextEditingController(text: v > 0 ? v.toString() : '');
        });
        // Ensure standard keys also have controllers
        for (final k in itemData.sizeKeys) {
          itemData.sizeControllers.putIfAbsent(
              k, () => TextEditingController(text: ''));
        }
        _items.add(itemData);
      }
    } else {
      _initAutoBillNo();
      _addNewItem();
    }

    _loadParties();
  }

  Future<void> _initAutoBillNo() async {
    final nextNo = await DBHelper.instance.getNextBillNo();
    if (mounted && _billNoController.text.isEmpty) {
      setState(() {
        _billNoController.text = nextNo;
      });
    }
  }

  Future<void> _loadParties() async {
    final parties = await DBHelper.instance.getAllParties();
    if (mounted) {
      setState(() {
        _existingParties = parties;
      });
    }
  }

  void _addNewItem() {
    final newItem = _ItemInputData(
      particular: '',
      rate: 0.0,
      sizeKeys: List.from(_standardSizes),
    );
    for (final s in _standardSizes) {
      newItem.sizeControllers[s] = TextEditingController();
    }
    setState(() {
      _items.add(newItem);
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one item is required.')),
      );
      return;
    }
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  void _addCustomSize(int itemIndex) {
    final customSizeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Size'),
        content: TextField(
          controller: customSizeController,
          decoration: const InputDecoration(
            hintText: 'e.g. 5XL, 28, 30, Free',
            labelText: 'Size Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newSize = customSizeController.text.trim();
              if (newSize.isNotEmpty) {
                final item = _items[itemIndex];
                if (!item.sizeKeys.contains(newSize)) {
                  setState(() {
                    item.sizeKeys.add(newSize);
                    item.sizeControllers[newSize] = TextEditingController();
                  });
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  int get _grandTotalPcs {
    int sum = 0;
    for (final item in _items) {
      sum += item.calculatedPcs;
    }
    return sum;
  }

  double get _grandTotalAmount {
    double sum = 0;
    for (final item in _items) {
      sum += item.calculatedAmount;
    }
    return sum;
  }

  Future<void> _saveChallan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) return;

    // Validate that at least one item has a particular description
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].particularController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter Particular / D.No for Item ${i + 1}')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final List<ChallanItem> challanItems = [];
      for (final itemInput in _items) {
        final Map<String, int> sizeMap = {};
        itemInput.sizeControllers.forEach((size, controller) {
          final q = int.tryParse(controller.text.trim()) ?? 0;
          if (q > 0) {
            sizeMap[size] = q;
          }
        });

        final rate = double.tryParse(itemInput.rateController.text.trim()) ?? 0.0;
        final itemPcs = itemInput.calculatedPcs;
        final itemAmount = itemPcs * rate;

        challanItems.add(
          ChallanItem(
            id: null,
            particular: itemInput.particularController.text.trim(),
            sizes: sizeMap,
            totalPcs: itemPcs,
            rate: rate,
            amount: itemAmount,
          ),
        );
      }

      final newChallan = Challan(
        id: widget.existingChallan?.id,
        billNo: _billNoController.text.trim(),
        challanDate: _selectedDate,
        fromName: _fromNameController.text.trim(),
        partyName: _partyNameController.text.trim(),
        gstin: _gstinController.text.trim().toUpperCase(),
        items: challanItems,
        totalPcs: _grandTotalPcs,
        totalAmount: _grandTotalAmount,
        preparedBy: _preparedByController.text.trim(),
        note: _noteController.text.trim(),
      );

      if (widget.existingChallan != null) {
        await DBHelper.instance.updateChallan(newChallan);
      } else {
        await DBHelper.instance.insertChallan(newChallan);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving challan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fromNameController.dispose();
    _billNoController.dispose();
    _partyNameController.dispose();
    _gstinController.dispose();
    _preparedByController.dispose();
    _noteController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFE91E63);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(
        title: Text(widget.existingChallan != null ? 'Edit Challan' : 'New Challan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Business / Header Details Card
                        _buildSectionHeader('Bill of Supply Header', Icons.business_outlined),
                        const SizedBox(height: 8),
                        _buildCard(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _fromNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'From (Company / Sender)',
                                    prefixIcon: Icon(Icons.storefront_outlined),
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty ? 'Enter sender name' : null,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _billNoController,
                                        decoration: const InputDecoration(
                                          labelText: 'Bill No.',
                                          prefixIcon: Icon(Icons.tag),
                                        ),
                                        validator: (v) => v == null || v.trim().isEmpty
                                            ? 'Enter bill no'
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: _selectedDate,
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime(2030),
                                          );
                                          if (picked != null) {
                                            setState(() => _selectedDate = picked);
                                          }
                                        },
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            labelText: 'Date',
                                            prefixIcon: Icon(Icons.calendar_today_outlined),
                                          ),
                                          child: Text(
                                            _dateFormat.format(_selectedDate),
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Party & GSTIN Card
                        _buildSectionHeader('Party Details', Icons.person_outline),
                        const SizedBox(height: 8),
                        _buildCard(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                Autocomplete<String>(
                                  initialValue: TextEditingValue(text: _partyNameController.text),
                                  optionsBuilder: (textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return _existingParties.map((p) => p.name);
                                    }
                                    return _existingParties
                                        .map((p) => p.name)
                                        .where((name) => name
                                            .toLowerCase()
                                            .contains(textEditingValue.text.toLowerCase()));
                                  },
                                  onSelected: (selection) {
                                    _partyNameController.text = selection;
                                  },
                                  fieldViewBuilder:
                                      (context, controller, focusNode, onFieldSubmitted) {
                                    _partyNameController = controller;
                                    return TextFormField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: const InputDecoration(
                                        labelText: 'M/s. Party Name',
                                        prefixIcon: Icon(Icons.group_outlined),
                                      ),
                                      validator: (v) => v == null || v.trim().isEmpty
                                          ? 'Enter party name'
                                          : null,
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _gstinController,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: const InputDecoration(
                                    labelText: 'GSTIN / UIN No.',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                    hintText: '15-digit GSTIN (Optional)',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Particulars / Items Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionHeader('Particulars & Quantities', Icons.list_alt_outlined),
                            TextButton.icon(
                              onPressed: _addNewItem,
                              icon: const Icon(Icons.add, color: accentColor, size: 18),
                              label: const Text('Add Item',
                                  style: TextStyle(
                                      color: accentColor, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        ..._items.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final itemData = entry.value;
                          return _buildItemCard(idx, itemData);
                        }),

                        const SizedBox(height: 20),

                        // Footer Card (Prepared By & Notes)
                        _buildSectionHeader('Footer & Terms', Icons.notes_outlined),
                        const SizedBox(height: 8),
                        _buildCard(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _preparedByController,
                                  decoration: const InputDecoration(
                                    labelText: 'Prepared By',
                                    prefixIcon: Icon(Icons.edit_outlined),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _noteController,
                                  decoration: const InputDecoration(
                                    labelText: 'Terms / Note',
                                    prefixIcon: Icon(Icons.policy_outlined),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),

                  // Bottom Summary Bar & Save Action
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFE0DED8))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Total Pcs: $_grandTotalPcs pis',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B6B6B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '₹${_grandTotalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _saveChallan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: Text(
                            widget.existingChallan != null ? 'Update Challan' : 'Save Challan',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildItemCard(int index, _ItemInputData itemData) {
    const accentColor = Color(0xFFE91E63);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DED8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Title & Delete Button
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: accentColor.withOpacity(0.1),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Item Particular',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1C1C1E)),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _removeItem(index),
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Particular D.No and Rate
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: itemData.particularController,
                    decoration: const InputDecoration(
                      labelText: 'Particular / D.No',
                      hintText: 'e.g. D.No 101',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: itemData.rateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Rate (pis)',
                      prefixText: '₹',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Sizes Header & Add Custom Size Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sizes & Quantities (pis):',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
                InkWell(
                  onTap: () => _addCustomSize(index),
                  child: const Text(
                    '+ Add Size',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Size Inputs Grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: itemData.sizeKeys.map((sizeKey) {
                final controller = itemData.sizeControllers[sizeKey]!;
                return SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.08),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Text(
                          sizeKey,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(6),
                              bottomRight: Radius.circular(6),
                            ),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Item Total Summary
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pcs: ${itemData.calculatedPcs} pis',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF444444)),
                  ),
                  Text(
                    'Amount: ₹${itemData.calculatedAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: accentColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFE91E63)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1C1C1E),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DED8)),
      ),
      child: child,
    );
  }
}

class _ItemInputData {
  final TextEditingController particularController;
  final TextEditingController rateController;
  final List<String> sizeKeys;
  final Map<String, TextEditingController> sizeControllers = {};

  _ItemInputData({
    required String particular,
    required double rate,
    required this.sizeKeys,
  })  : particularController = TextEditingController(text: particular),
        rateController =
            TextEditingController(text: rate > 0 ? rate.toString() : '');

  int get calculatedPcs {
    int sum = 0;
    sizeControllers.forEach((_, c) {
      sum += int.tryParse(c.text.trim()) ?? 0;
    });
    return sum;
  }

  double get calculatedAmount {
    final rate = double.tryParse(rateController.text.trim()) ?? 0.0;
    return calculatedPcs * rate;
  }

  void dispose() {
    particularController.dispose();
    rateController.dispose();
    sizeControllers.forEach((_, c) => c.dispose());
  }
}
