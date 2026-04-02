class Label {
  final String id;
  final String name;
  final String? color;
  /// When false, the point is not eligible for "treated" workflow (UI hides the toggle).
  final bool isTreatable;

  Label({
    required this.id,
    required this.name,
    this.color,
    this.isTreatable = true,
  });

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      isTreatable: json['is_treatable'] ?? true,
    );
  }
}

class Point {
  final String id;
  String name;
  double latitude;
  double longitude;
  List<String> photos; 
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
    this.photos = const [],
    required this.comment,
    required this.description,
    required this.label,
    this.isTreated = false,
    this.lastTreatmentDate,
  });

  factory Point.fromJson(Map<String, dynamic> json) {
     final rawPhotos = (json['photos'] as List?) ?? [];

    return Point(
      id: json['id'],
      name: json['name'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
       photos: rawPhotos
          .map((p) => p['image'] as String)
          .whereType<String>()
          .toList(),
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
