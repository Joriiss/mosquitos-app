class Intervention {
  final String id;
  final String interventionType;
  final String comment;
  final String? performedBy;
  final DateTime performedAt;

  Intervention({
    required this.id,
    required this.interventionType,
    required this.comment,
    this.performedBy,
    required this.performedAt,
  });

  factory Intervention.fromJson(Map<String, dynamic> json) {
    return Intervention(
      id: json['id'],
      interventionType: json['intervention_type'],
      comment: json['comment'] ?? '',
      performedBy: json['performed_by'] != null ? json['performed_by']['username'] : null,
      performedAt: DateTime.parse(json['performed_at']),
    );
  }
}