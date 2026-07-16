enum PaymentMode { cash, cheque }

class Payment {
  final int? id;
  final int partyId;
  final double amount;
  final PaymentMode mode;
  final DateTime paymentDate;

  Payment({
    this.id,
    required this.partyId,
    required this.amount,
    required this.mode,
    DateTime? paymentDate,
  }) : paymentDate = paymentDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'party_id': partyId,
      'amount': amount,
      'mode': mode.name,
      'payment_date': paymentDate.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      partyId: map['party_id'] as int,
      amount: map['amount'] as double,
      mode: PaymentMode.values.byName(map['mode'] as String),
      paymentDate: DateTime.parse(map['payment_date'] as String),
    );
  }
}
