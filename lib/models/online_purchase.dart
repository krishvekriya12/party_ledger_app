class OnlinePurchase {
  final int? id;
  final String partyName;
  final double amount;
  final DateTime purchaseDate;
  final String? note;

  OnlinePurchase({
    this.id,
    required this.partyName,
    required this.amount,
    DateTime? purchaseDate,
    this.note,
  }) : purchaseDate = purchaseDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'party_name': partyName,
      'amount': amount,
      'purchase_date': purchaseDate.toIso8601String(),
      'note': note,
    };
  }

  factory OnlinePurchase.fromMap(Map<String, dynamic> map) {
    return OnlinePurchase(
      id: map['id'] as int?,
      partyName: map['party_name'] as String,
      amount: map['amount'] as double,
      purchaseDate: DateTime.parse(map['purchase_date'] as String),
      note: map['note'] as String?,
    );
  }
}
