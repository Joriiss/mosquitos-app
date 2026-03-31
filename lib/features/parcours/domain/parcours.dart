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
}

