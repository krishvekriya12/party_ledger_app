import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/challan.dart';
import '../utils/challan_pdf_generator.dart';
import 'add_challan_screen.dart';
import 'challan_detail_screen.dart';

class ChallanListScreen extends StatefulWidget {
  const ChallanListScreen({super.key});

  @override
  State<ChallanListScreen> createState() => _ChallanListScreenState();
}

class _ChallanListScreenState extends State<ChallanListScreen> {
  List<Challan> _challanList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static const Color _pinkAccent = Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    _loadChallans();
  }

  Future<void> _loadChallans() async {
    setState(() => _isLoading = true);
    final list = await DBHelper.instance.getAllChallans(query: _searchQuery);
    if (mounted) {
      setState(() {
        _challanList = list;
        _isLoading = false;
      });
    }
  }

  int get _totalPcs {
    return _challanList.fold(0, (sum, c) => sum + c.totalPcs);
  }

  double get _totalAmount {
    return _challanList.fold(0.0, (sum, c) => sum + c.totalAmount);
  }

  Future<void> _deleteChallan(Challan c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Challan?'),
        content: Text('Are you sure you want to delete Bill No. #${c.billNo} (${c.partyName})?'),
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

    if (confirm == true && c.id != null) {
      await DBHelper.instance.deleteChallan(c.id!);
      _loadChallans();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(
        title: const Text('Challan & Bill of Supply'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChallans,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _pinkAccent,
        foregroundColor: Colors.white,
        onPressed: () async {
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddChallanScreen()),
          );
          if (res == true) {
            _loadChallans();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Challan', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & Summary Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Party Name or Bill No...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF888888)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _loadChallans();
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                    _loadChallans();
                  },
                ),
                const SizedBox(height: 12),

                // Top Stats Summary
                Row(
                  children: [
                    Expanded(
                      child: _statBox(
                        'Total Challans',
                        '${_challanList.length}',
                        const Color(0xFF5C35CC),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statBox(
                        'Total Pcs',
                        '${_totalPcs} pis',
                        const Color(0xFF009688),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statBox(
                        'Total Amount',
                        '₹${_totalAmount.toStringAsFixed(0)}',
                        _pinkAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE0DED8)),

          // Challans List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _pinkAccent))
                : _challanList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No challans found matching "$_searchQuery".'
                                  : 'No Challans created yet.',
                              style: const TextStyle(
                                  color: Color(0xFF888888), fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: _pinkAccent),
                              onPressed: () async {
                                final res = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const AddChallanScreen()),
                                );
                                if (res == true) _loadChallans();
                              },
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('Create First Challan',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _challanList.length,
                        itemBuilder: (context, index) {
                          final c = _challanList[index];
                          final particularsStr = c.items
                              .map((i) => i.particular)
                              .where((p) => p.isNotEmpty)
                              .join(', ');

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE0DED8)),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                final updated = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ChallanDetailScreen(challanId: c.id!),
                                  ),
                                );
                                if (updated == true) {
                                  _loadChallans();
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Bill No, Date, Actions
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _pinkAccent.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Bill No. ${c.billNo}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: _pinkAccent,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _dateFormat.format(c.challanDate),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF888888),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Party Name
                                    Text(
                                      c.partyName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1C1C1E),
                                      ),
                                    ),
                                    if (particularsStr.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        particularsStr,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B6B6B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    const Divider(
                                        height: 1, color: Color(0xFFEEECE8)),
                                    const SizedBox(height: 10),

                                    // Row 3: Totals & Action Buttons
                                    Row(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${c.totalPcs} pis',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF888888),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              '₹${c.totalAmount.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: _pinkAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        // Quick Share Button
                                        IconButton(
                                          icon: const Icon(Icons.share_outlined,
                                              color: _pinkAccent, size: 20),
                                          tooltip: 'Share PDF',
                                          onPressed: () =>
                                              ChallanPdfGenerator.shareChallan(c),
                                        ),
                                        // Quick Print / Preview Button
                                        IconButton(
                                          icon: const Icon(
                                              Icons.print_outlined,
                                              color: Color(0xFF444444),
                                              size: 20),
                                          tooltip: 'Print PDF',
                                          onPressed: () =>
                                              ChallanPdfGenerator.printChallan(c),
                                        ),
                                        // Popup Menu for Edit / Delete
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert,
                                              color: Color(0xFF888888), size: 20),
                                          onSelected: (val) async {
                                            if (val == 'edit') {
                                              final updated =
                                                  await Navigator.push<bool>(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => AddChallanScreen(
                                                      existingChallan: c),
                                                ),
                                              );
                                              if (updated == true) {
                                                _loadChallans();
                                              }
                                            } else if (val == 'delete') {
                                              _deleteChallan(c);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Edit'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete,
                                                      size: 18, color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('Delete',
                                                      style: TextStyle(
                                                          color: Colors.red)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF6B6B6B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
