import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/challan.dart';
import '../utils/challan_pdf_generator.dart';
import '../db/db_helper.dart';
import 'add_challan_screen.dart';

class ChallanDetailScreen extends StatefulWidget {
  final int challanId;

  const ChallanDetailScreen({super.key, required this.challanId});

  @override
  State<ChallanDetailScreen> createState() => _ChallanDetailScreenState();
}

class _ChallanDetailScreenState extends State<ChallanDetailScreen> {
  Challan? _challan;
  bool _isLoading = true;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static const Color _pinkAccent = Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    _loadChallan();
  }

  Future<void> _loadChallan() async {
    setState(() => _isLoading = true);
    final c = await DBHelper.instance.getChallanById(widget.challanId);
    if (mounted) {
      setState(() {
        _challan = c;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteChallan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Challan?'),
        content: Text(
            'Are you sure you want to delete Challan #${_challan?.billNo} for ${_challan?.partyName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && _challan?.id != null) {
      await DBHelper.instance.deleteChallan(_challan!.id!);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(
        title: Text(_challan != null ? 'Challan #${_challan!.billNo}' : 'Challan Details'),
        actions: [
          if (_challan != null) ...[
            IconButton(
              icon: const Icon(Icons.share_outlined, color: _pinkAccent),
              tooltip: 'Share PDF',
              onPressed: () => ChallanPdfGenerator.shareChallan(_challan!),
            ),
            IconButton(
              icon: const Icon(Icons.print_outlined, color: _pinkAccent),
              tooltip: 'Print PDF',
              onPressed: () => ChallanPdfGenerator.printChallan(_challan!),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddChallanScreen(existingChallan: _challan),
                  ),
                );
                if (updated == true) {
                  _loadChallan();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Delete',
              onPressed: _deleteChallan,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _pinkAccent))
          : _challan == null
              ? const Center(child: Text('Challan not found.'))
              : Column(
                  children: [
                    // Top Action Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => ChallanPdfGenerator.shareChallan(_challan!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _pinkAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.share, size: 18),
                              label: const Text('Share PDF',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => ChallanPdfGenerator.printChallan(_challan!),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _pinkAccent,
                                side: const BorderSide(color: _pinkAccent),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.print, size: 18),
                              label: const Text('Print / Export',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 1),

                    // Interactive PDF View or Visual Memo Card View
                    Expanded(
                      child: PdfPreview(
                        build: (format) async {
                          final pdf = await ChallanPdfGenerator.generatePdf(_challan!);
                          return pdf.save();
                        },
                        allowPrinting: true,
                        allowSharing: true,
                        canChangePageFormat: false,
                        canChangeOrientation: false,
                        loadingWidget: const Center(
                            child: CircularProgressIndicator(color: _pinkAccent)),
                      ),
                    ),
                  ],
                ),
    );
  }
}
