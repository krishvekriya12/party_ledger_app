import 'dart:convert';

class ChallanItem {
  final int? id;
  final int? challanId;
  final String particular;
  final Map<String, int> sizes; // e.g. {"XS": 5, "S": 10, "M": 15, "L": 20, "XL": 10}
  final int totalPcs;
  final double rate;
  final double amount;

  ChallanItem({
    this.id,
    this.challanId,
    required this.particular,
    required this.sizes,
    required this.totalPcs,
    required this.rate,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'challan_id': challanId,
      'particular': particular,
      'sizes_json': jsonEncode(sizes),
      'total_pcs': totalPcs,
      'rate': rate,
      'amount': amount,
    };
  }

  factory ChallanItem.fromMap(Map<String, dynamic> map) {
    Map<String, int> parsedSizes = {};
    if (map['sizes_json'] != null && map['sizes_json'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['sizes_json'] as String) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          parsedSizes[key] = (value as num).toInt();
        });
      } catch (_) {}
    }

    return ChallanItem(
      id: map['id'] as int?,
      challanId: map['challan_id'] as int?,
      particular: map['particular'] as String? ?? '',
      sizes: parsedSizes,
      totalPcs: (map['total_pcs'] as num?)?.toInt() ?? 0,
      rate: (map['rate'] as num?)?.toDouble() ?? 0.0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Challan {
  final int? id;
  final String billNo;
  final DateTime challanDate;
  final String fromName;
  final String partyName;
  final String gstin;
  final List<ChallanItem> items;
  final int totalPcs;
  final double totalAmount;
  final String preparedBy;
  final String note;
  final DateTime createdAt;

  Challan({
    this.id,
    required this.billNo,
    DateTime? challanDate,
    required this.fromName,
    required this.partyName,
    this.gstin = '',
    this.items = const [],
    required this.totalPcs,
    required this.totalAmount,
    this.preparedBy = '',
    this.note = 'Goods once sold will not be taken back.',
    DateTime? createdAt,
  })  : challanDate = challanDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bill_no': billNo,
      'challan_date': challanDate.toIso8601String(),
      'from_name': fromName,
      'party_name': partyName,
      'gstin': gstin,
      'total_pcs': totalPcs,
      'total_amount': totalAmount,
      'prepared_by': preparedBy,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Challan.fromMap(Map<String, dynamic> map, {List<ChallanItem> items = const []}) {
    return Challan(
      id: map['id'] as int?,
      billNo: map['bill_no'] as String? ?? '',
      challanDate: map['challan_date'] != null
          ? DateTime.parse(map['challan_date'] as String)
          : DateTime.now(),
      fromName: map['from_name'] as String? ?? '',
      partyName: map['party_name'] as String? ?? '',
      gstin: map['gstin'] as String? ?? '',
      items: items,
      totalPcs: (map['total_pcs'] as num?)?.toInt() ?? 0,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      preparedBy: map['prepared_by'] as String? ?? '',
      note: map['note'] as String? ?? 'Goods once sold will not be taken back.',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }
}
