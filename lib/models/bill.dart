class Bill {
  final int? id;
  final int partyId;
  final String designNo;
  final String color;
  final double rate;
  final double total;
  final DateTime billDate;

  Bill({
    this.id,
    required this.partyId,
    required this.designNo,
    required this.color,
    required this.rate,
    required this.total,
    DateTime? billDate,
  }) : billDate = billDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'party_id': partyId,
      'design_no': designNo,
      'color': color,
      'rate': rate,
      'total': total,
      'bill_date': billDate.toIso8601String(),
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['id'] as int?,
      partyId: map['party_id'] as int,
      designNo: map['design_no'] as String,
      color: map['color'] as String,
      rate: map['rate'] as double,
      total: map['total'] as double,
      billDate: DateTime.parse(map['bill_date'] as String),
    );
  }
}