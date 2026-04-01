class Label {
  final String id;
  final String name;

  Label({required this.id, required this.name});

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      id: json['id'],
      name: json['name'],
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
    required this.label,
    this.isTreated = false,
    this.lastTreatmentDate,
  });

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      id: json['id'],
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      photoUrl: json['photo'],
      comment: json['comment'] ?? '',
      label: Label.fromJson(json['label']),
      isTreated: json['is_treated'] ?? false,
      lastTreatmentDate: json['last_treatment_date'] != null
          ? DateTime.parse(json['last_treatment_date'])
          : null,
    );
  }
}

