class Parcours {
  final String id;
  final String name;
  final DateTime createdAt;
  final double? distanceKm;
  final int? durationMin;
  final int totalPoints;
  /// Points with `is_treated` or whose label is not treatable (or missing label).
  final int resolvedCount;

  const Parcours({
    required this.id,
    required this.name,
    required this.createdAt,
    this.distanceKm,
    this.durationMin,
    required this.totalPoints,
    required this.resolvedCount,
  });

  factory Parcours.fromJson(Map<String, dynamic> json) {
    final parcoursPoints = (json['parcours_points'] as List?) ?? [];

    int resolved = 0;
    for (final raw in parcoursPoints) {
      if (raw is! Map<String, dynamic>) continue;
      final p = raw['point'];
      if (p is! Map<String, dynamic>) continue;
      final treated = p['is_treated'] == true;
      final label = p['label'];
      final isTreatable =
          label is Map<String, dynamic> && label['is_treatable'] == true;
      if (treated || !isTreatable) {
        resolved++;
      }
    }

    return Parcours(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      distanceKm: _parseDouble(json['distance_km']),
      durationMin: _parseInt(json['duration_min']),
      totalPoints: parcoursPoints.length,
      resolvedCount: resolved,
    );
  }
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.round();
  if (v is String) return int.tryParse(v);
  return null;
}
