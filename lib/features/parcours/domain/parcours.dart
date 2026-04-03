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

    // Deduplicate by point id (same point can be linked twice in DB); counts must match map markers.
    final seenIds = <String>{};
    var resolved = 0;
    var uniqueTotal = 0;

    for (final raw in parcoursPoints) {
      if (raw is! Map) continue;
      final row = Map<String, dynamic>.from(raw);
      final p = row['point'];
      if (p is! Map) continue;
      final pointMap = Map<String, dynamic>.from(p);
      final id = pointMap['id']?.toString() ?? '';
      if (id.isEmpty || seenIds.contains(id)) continue;
      seenIds.add(id);
      uniqueTotal++;

      final treated = pointMap['is_treated'] == true;
      final label = pointMap['label'];
      final isTreatable =
          label is Map && Map<String, dynamic>.from(label)['is_treatable'] == true;
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
      totalPoints: uniqueTotal,
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
