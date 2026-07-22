class PartnerAdvance {
  final int? id;
  final int partnerId;
  final double amount;
  final DateTime advanceDate;
  final String? note;

  PartnerAdvance({
    this.id,
    required this.partnerId,
    required this.amount,
    DateTime? advanceDate,
    this.note,
  }) : advanceDate = advanceDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partner_id': partnerId,
      'amount': amount,
      'advance_date': advanceDate.toIso8601String(),
      'note': note,
    };
  }

  factory PartnerAdvance.fromMap(Map<String, dynamic> map) {
    return PartnerAdvance(
      id: map['id'] as int?,
      partnerId: map['partner_id'] as int,
      amount: map['amount'] as double,
      advanceDate: DateTime.parse(map['advance_date'] as String),
      note: map['note'] as String?,
    );
  }
}
