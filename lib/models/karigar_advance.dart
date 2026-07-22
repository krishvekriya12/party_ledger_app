class KarigarAdvance {
  final int? id;
  final int karigarId;
  final double amount;
  final DateTime advanceDate;
  final String? note;

  KarigarAdvance({
    this.id,
    required this.karigarId,
    required this.amount,
    DateTime? advanceDate,
    this.note,
  }) : advanceDate = advanceDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'karigar_id': karigarId,
      'amount': amount,
      'advance_date': advanceDate.toIso8601String(),
      'note': note,
    };
  }

  factory KarigarAdvance.fromMap(Map<String, dynamic> map) {
    return KarigarAdvance(
      id: map['id'] as int?,
      karigarId: map['karigar_id'] as int,
      amount: map['amount'] as double,
      advanceDate: DateTime.parse(map['advance_date'] as String),
      note: map['note'] as String?,
    );
  }
}
