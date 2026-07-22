import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/online_sale_payment.dart';
import '../models/partner.dart';

/// Shows all sale payments for a specific partner on a specific platform
/// Date → Amount list format
class OnlinePartnerPaymentsScreen extends StatefulWidget {
  final Partner partner;
  final OnlinePlatform platform;

  const OnlinePartnerPaymentsScreen({
    super.key,
    required this.partner,
    required this.platform,
  });

  @override
  State<OnlinePartnerPaymentsScreen> createState() =>
      _OnlinePartnerPaymentsScreenState();
}

class _OnlinePartnerPaymentsScreenState
    extends State<OnlinePartnerPaymentsScreen> {
  final DBHelper _db = DBHelper.instance;
  List<OnlineSalePayment> _payments = [];
  double _total = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final payments = await _db.getSalePaymentsForPartner(
      widget.partner.id!,
      widget.platform.name,
    );
    final total = await _db.getTotalSalePaymentForPartner(
      widget.partner.id!,
      widget.platform.name,
    );
    setState(() {
      _payments = payments;
      _total = total;
      _loading = false;
    });
  }

  Future<void> _deletePayment(OnlineSalePayment payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payment?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          '₹${payment.amount.toStringAsFixed(2)} ka payment delete karna chahte ho?',
        ),
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
    if (confirm == true && payment.id != null) {
      await _db.deleteOnlineSalePayment(payment.id!);
      _loadData();
    }
  }

  Color get _platformColor =>
      widget.platform == OnlinePlatform.flipkart ? const Color(0xFF1A6DFF) : const Color(0xFFE91E63);

  String get _platformName =>
      widget.platform == OnlinePlatform.flipkart ? 'Flipkart' : 'Meesho';

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(
        title: Text('${widget.partner.name} • $_platformName'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE8E8E4))),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Total card
                Container(
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
                        backgroundColor: _platformColor.withOpacity(0.1),
                        child: Icon(
                          widget.platform == OnlinePlatform.flipkart
                              ? Icons.shopping_cart_outlined
                              : Icons.storefront_outlined,
                          color: _platformColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_platformName • ${widget.partner.name}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF888888),
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Received: ₹${_total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _platformColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _platformColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_payments.length} Payments',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _platformColor),
                        ),
                      )
                    ],
                  ),
                ),
                // Payment list — Date → Amount
                Expanded(
                  child: _payments.isEmpty
                      ? const Center(
                          child: Text(
                            'No payments found.\nAdd a new payment.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF888888)),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          itemCount: _payments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final p = _payments[index];
                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onLongPress: () => _deletePayment(p),
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
                                        radius: 16,
                                        backgroundColor: _platformColor.withOpacity(0.12),
                                        child: Icon(Icons.arrow_downward,
                                            color: _platformColor, size: 16),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              dateFormat.format(p.paymentDate),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: Color(0xFF1C1C1E)),
                                            ),
                                            if (p.note != null) ...[
                                              const SizedBox(height: 2),
                                              Text(p.note!,
                                                  style: const TextStyle(
                                                      color: Color(0xFF6B6B6B),
                                                      fontSize: 11))
                                            ],
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '₹${p.amount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: _platformColor,
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
            ),
    );
  }
}
