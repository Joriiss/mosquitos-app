class Label {
  final String id;
  final String name;
  final String? color;

  Label({
    required this.id,
    required this.name,
    this.color,
  });

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      id: json['id'],
      name: json['name'],
      color: json['color'],
    );
  }
}

class Point {
  final String id;
  String name;
  double latitude;
  double longitude;
  String? photoUrl;
  String comment;
  String description;
  Label label;
  bool isTreated;
  DateTime? lastTreatmentDate;

  Point({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.photoUrl,
    required this.comment,
    required this.description,
    required this.label,
    this.isTreated = false,
    this.lastTreatmentDate,
  });

  factory Point.fromJson(Map<String, dynamic> json) {
    final photos = (json['photos'] as List?) ?? [];

    return Point(
      id: json['id'],
      name: json['name'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      photoUrl: photos.isNotEmpty ? photos.first['image'] : null,
      comment: json['comment'] ?? '',
      description: json['description'] ?? '',
      label: Label.fromJson(json['label']),
      isTreated: json['is_treated'] ?? false,
      lastTreatmentDate: json['last_treatment_date'] != null
          ? DateTime.parse(json['last_treatment_date'])
          : null,
    );
  }
}
