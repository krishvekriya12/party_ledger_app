class PartnerExpense {
  final int? id;
  final int partnerId;
  final double amount;
  final String description;
  final DateTime expenseDate;

  PartnerExpense({
    this.id,
    required this.partnerId,
    required this.amount,
    required this.description,
    DateTime? expenseDate,
  }) : expenseDate = expenseDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partner_id': partnerId,
      'amount': amount,
      'description': description,
      'expense_date': expenseDate.toIso8601String(),
    };
  }

  factory PartnerExpense.fromMap(Map<String, dynamic> map) {
    return PartnerExpense(
      id: map['id'] as int?,
      partnerId: map['partner_id'] as int,
      amount: map['amount'] as double,
      description: map['description'] as String,
      expenseDate: DateTime.parse(map['expense_date'] as String),
    );
  }
}
