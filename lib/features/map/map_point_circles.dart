import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../theme/app_colors.dart';

/// Annotation layers need the style to be loaded first, or circles/polylines may not show.
Future<void> waitForMapStyleLoaded(MapboxMap map) async {
  for (var i = 0; i < 120; i++) {
    try {
      if (await map.style.isStyleLoaded()) return;
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

/// Draws mission points as circles: grey (non-treatable label), red (treatable, not done), green (treated).
Future<void> syncParcoursPointCircles({
  required CircleAnnotationManager manager,
  required Map<String, dynamic> parcoursJson,
}) async {
  await manager.deleteAll();

  final raw = parcoursJson['parcours_points'];
  if (raw is! List) return;

  for (final item in raw) {
    Map<String, dynamic>? row;
    if (item is Map<String, dynamic>) {
      row = item;
    } else if (item is Map) {
      row = Map<String, dynamic>.from(item);
    } else {
      continue;
    }

    final pRaw = row['point'];
    Map<String, dynamic>? p;
    if (pRaw is Map<String, dynamic>) {
      p = pRaw;
    } else if (pRaw is Map) {
      p = Map<String, dynamic>.from(pRaw);
    } else {
      continue;
    }

    final lat = (p['latitude'] as num?)?.toDouble();
    final lng = (p['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) continue;

    final fill = markerFillColorForPoint(p);

    await manager.create(
      CircleAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        circleColor: fill,
        circleRadius: 14,
        circleOpacity: 1,
      ),
    );
  }
}

int markerFillColorForPoint(Map<String, dynamic> point) {
  final label = point['label'];
  Map<String, dynamic>? labelMap;
  if (label is Map<String, dynamic>) {
    labelMap = label;
  } else if (label is Map) {
    labelMap = Map<String, dynamic>.from(label);
  }

  final isTreatable = labelMap != null && labelMap['is_treatable'] == true;
  if (!isTreatable) {
    return const Color(0xFF9E9E9E).value;
  }
  if (point['is_treated'] == true) {
    return const Color(0xFF2E7D32).value;
  }
  return AppColors.accentRed.value;
}
