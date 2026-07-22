class PartnerContribution {
  final int? id;
  final int partnerId;
  final double amount;
  final DateTime contributionDate;
  final String? note;

  PartnerContribution({
    this.id,
    required this.partnerId,
    required this.amount,
    DateTime? contributionDate,
    this.note,
  }) : contributionDate = contributionDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partner_id': partnerId,
      'amount': amount,
      'contribution_date': contributionDate.toIso8601String(),
      'note': note,
    };
  }

  factory PartnerContribution.fromMap(Map<String, dynamic> map) {
    return PartnerContribution(
      id: map['id'] as int?,
      partnerId: map['partner_id'] as int,
      amount: map['amount'] as double,
      contributionDate: DateTime.parse(map['contribution_date'] as String),
      note: map['note'] as String?,
    );
  }
}
