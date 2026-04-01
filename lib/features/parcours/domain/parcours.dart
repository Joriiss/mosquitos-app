class Parcours {
  final String id;
  final String name;
  final DateTime createdAt;
  final double? distanceKm;
  final int? durationMin;
  final int totalPoints;
  final int treatedPoints;

  const Parcours({
    required this.id,
    required this.name,
    required this.createdAt,
    this.distanceKm,
    this.durationMin,
    required this.totalPoints,
    required this.treatedPoints,
  });

  factory Parcours.fromJson(Map<String, dynamic> json) {
    final parcoursPoints = (json['parcours_points'] as List?) ?? [];

    int treated = 0;
    for (final item in parcoursPoints) {
      if (item['is_completed_in_mission'] == true) {
        treated++;
      }
    }

    return Parcours(
      id: json['id'],
      name: json['name'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      distanceKm: json['distance_km'] != null
          ? (json['distance_km'] as num).toDouble()
          : null,
      durationMin: json['duration_min'],
      totalPoints: parcoursPoints.length,
      treatedPoints: treated,
    );
  }
}
