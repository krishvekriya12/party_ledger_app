enum OnlinePlatform { flipkart, meesho }

class OnlineSalePayment {
  final int? id;
  final OnlinePlatform platform;
  final int partnerId;
  final double amount;
  final DateTime paymentDate;
  final String? note;

  OnlineSalePayment({
    this.id,
    required this.platform,
    required this.partnerId,
    required this.amount,
    DateTime? paymentDate,
    this.note,
  }) : paymentDate = paymentDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'platform': platform.name,
      'partner_id': partnerId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'note': note,
    };
  }

  factory OnlineSalePayment.fromMap(Map<String, dynamic> map) {
    return OnlineSalePayment(
      id: map['id'] as int?,
      platform: OnlinePlatform.values.byName(map['platform'] as String),
      partnerId: map['partner_id'] as int,
      amount: map['amount'] as double,
      paymentDate: DateTime.parse(map['payment_date'] as String),
      note: map['note'] as String?,
    );
  }
}
