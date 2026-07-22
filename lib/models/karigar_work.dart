class KarigarWork {
  final int? id;
  final int karigarId;
  final String designNo; // D.No
  final double pis; // quantity/pieces
  final double rate;
  final double total; // pis * rate
  final DateTime workDate;

  KarigarWork({
    this.id,
    required this.karigarId,
    required this.designNo,
    required this.pis,
    required this.rate,
    required this.total,
    DateTime? workDate,
  }) : workDate = workDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'karigar_id': karigarId,
      'design_no': designNo,
      'pis': pis,
      'rate': rate,
      'total': total,
      'work_date': workDate.toIso8601String(),
    };
  }

  factory KarigarWork.fromMap(Map<String, dynamic> map) {
    return KarigarWork(
      id: map['id'] as int?,
      karigarId: map['karigar_id'] as int,
      designNo: map['design_no'] as String,
      pis: map['pis'] as double,
      rate: map['rate'] as double,
      total: map['total'] as double,
      workDate: DateTime.parse(map['work_date'] as String),
    );
  }
}
