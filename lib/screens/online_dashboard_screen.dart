import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/online_purchase.dart';
import '../models/online_sale_payment.dart';
import '../models/partner.dart';
import 'add_online_purchase_screen.dart';
import 'add_online_sale_payment_screen.dart';
import 'online_partner_payments_screen.dart';

class OnlineDashboardScreen extends StatefulWidget {
  const OnlineDashboardScreen({super.key});

  @override
  State<OnlineDashboardScreen> createState() => _OnlineDashboardScreenState();
}

class _OnlineDashboardScreenState extends State<OnlineDashboardScreen>
    with SingleTickerProviderStateMixin {
  final DBHelper _db = DBHelper.instance;
  late TabController _tabController;

  // Purchase tab
  List<OnlinePurchase> _purchases = [];
  double _totalPurchase = 0;

  // Flipkart tab
  List<Map<String, dynamic>> _flipkartSummary = []; // [{partner, total}]
  double _totalFlipkart = 0;

  // Meesho tab
  List<Map<String, dynamic>> _meeshoSummary = [];
  double _totalMeesho = 0;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final purchases = await _db.getAllOnlinePurchases();
    final totalPurchase = await _db.getTotalOnlinePurchaseAmount();
    final flipkartSummary = await _db.getPartnerSaleSummaryForPlatform('flipkart');
    final totalFlipkart = await _db.getTotalSalePaymentForPlatform('flipkart');
    final meeshoSummary = await _db.getPartnerSaleSummaryForPlatform('meesho');
    final totalMeesho = await _db.getTotalSalePaymentForPlatform('meesho');

    setState(() {
      _purchases = purchases;
      _totalPurchase = totalPurchase;
      _flipkartSummary = flipkartSummary;
      _totalFlipkart = totalFlipkart;
      _meeshoSummary = meeshoSummary;
      _totalMeesho = totalMeesho;
      _loading = false;
    });
  }

  Future<void> _deletePurchase(OnlinePurchase purchase) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Purchase?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
            '${purchase.partyName} — ₹${purchase.amount.toStringAsFixed(2)} delete karna chahte ho?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && purchase.id != null) {
      await _db.deleteOnlinePurchase(purchase.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(
        title: const Text('Online Module'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE8E8E4))),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF009688),
          labelColor: const Color(0xFF009688),
          unselectedLabelColor: const Color(0xFF888888),
          indicatorWeight: 2.5,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'Purchase'),
            Tab(icon: Icon(Icons.shopping_cart_outlined), text: 'Flipkart'),
            Tab(icon: Icon(Icons.storefront_outlined), text: 'Meesho'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPurchaseTab(),
                _buildPlatformTab(
                  platform: OnlinePlatform.flipkart,
                  summary: _flipkartSummary,
                  total: _totalFlipkart,
                  color: const Color(0xFF1A6DFF),
                  icon: Icons.shopping_cart_outlined,
                ),
                _buildPlatformTab(
                  platform: OnlinePlatform.meesho,
                  summary: _meeshoSummary,
                  total: _totalMeesho,
                  color: const Color(0xFFE91E63),
                  icon: Icons.storefront_outlined,
                ),
              ],
            ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final tab = _tabController.index;
        final color = tab == 0
            ? const Color(0xFF009688)
            : tab == 1
                ? const Color(0xFF1A6DFF)
                : const Color(0xFFE91E63);
        return FloatingActionButton.extended(
          backgroundColor: color,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(tab == 0 ? 'Add Purchase' : 'Add Payment'),
          onPressed: () async {
            if (tab == 0) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddOnlinePurchaseScreen()),
              );
            } else {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddOnlineSalePaymentScreen()),
              );
            }
            _loadData();
          },
        );
      },
    );
  }

  Widget _buildPurchaseTab() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    const color = Color(0xFF009688);

    return Column(
      children: [
        _summaryCard(
          label: 'Total Purchase (Party se)',
          amount: _totalPurchase,
          color: color,
          icon: Icons.shopping_bag_outlined,
        ),
        Expanded(
          child: _purchases.isEmpty
              ? const Center(
                  child: Text(
                    'No purchases added yet.\nTap + to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF888888)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: _purchases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final p = _purchases[index];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onLongPress: () => _deletePurchase(p),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0DED8)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: color.withOpacity(0.12),
                                child: const Icon(Icons.store_outlined, color: color, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.partyName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Color(0xFF1C1C1E)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateFormat.format(p.purchaseDate),
                                      style: const TextStyle(
                                          fontSize: 12, color: Color(0xFF6B6B6B)),
                                    ),
                                    if (p.note != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        p.note!,
                                        style: const TextStyle(
                                            fontSize: 11, color: Color(0xFF888888)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                '₹${p.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: color,
                                ),
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
    );
  }

  Widget _buildPlatformTab({
    required OnlinePlatform platform,
    required List<Map<String, dynamic>> summary,
    required double total,
    required Color color,
    required IconData icon,
  }) {
    final platformName =
        platform == OnlinePlatform.flipkart ? 'Flipkart' : 'Meesho';
    return Column(
      children: [
        _summaryCard(
          label: 'Total $platformName Received',
          amount: total,
          color: color,
          icon: icon,
        ),
        Expanded(
          child: summary.isEmpty
              ? Center(
                  child: Text(
                    'No $platformName payments found.\nTap + to add one.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF888888)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: summary.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = summary[index];
                    final partner = item['partner'] as Partner;
                    final partnerTotal = item['total'] as double;

                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OnlinePartnerPaymentsScreen(
                                partner: partner,
                                platform: platform,
                              ),
                            ),
                          );
                          _loadData();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0DED8)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: color.withOpacity(0.12),
                                child: Text(
                                  partner.name.isNotEmpty
                                      ? partner.name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      partner.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Color(0xFF1C1C1E)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Online Partner payments',
                                      style: const TextStyle(
                                          fontSize: 12, color: Color(0xFF6B6B6B)),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '₹${partnerTotal.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right, color: color, size: 16),
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
    );
  }

  Widget _summaryCard({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DED8)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '₹${amount.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
