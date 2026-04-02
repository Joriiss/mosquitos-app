import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../edit_point.dart';
import '../../models/intervention_model.dart';
import '../../models/point_model.dart' as point_model;
import '../../services/api_service.dart';
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

    final pid = p['id'];
    if (pid == null) continue;

    final fill = markerFillColorForPoint(p);

    await manager.create(
      CircleAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        circleColor: fill,
        circleRadius: 14,
        circleOpacity: 1,
        customData: {'point_id': pid.toString()},
      ),
    );
  }
}

/// Tap on a circle → identify point via [customData] and open [PointModal] (view / edit UI).
Cancelable bindParcoursCircleTapHandler({
  required CircleAnnotationManager manager,
  required void Function(String pointId) onPointId,
}) {
  return manager.tapEvents(
    onTap: (CircleAnnotation annotation) {
      final raw = annotation.customData?['point_id'];
      final id = raw?.toString();
      if (id == null || id.isEmpty) return;
      onPointId(id);
    },
  );
}

/// Loads point + history, shows [PointModal] in edit mode (read-only submit).
Future<void> openPointDetailFromMap({
  required BuildContext context,
  required String pointId,
  required String parcoursId,
  Future<void> Function()? onClosedRefresh,
}) async {
  try {
    final raw = await ApiService.getPointById(pointId);
    final historyRaw = await ApiService.getPointHistory(pointId);
    if (!context.mounted) return;

    final missionPoint = point_model.Point.fromJson(raw);
    final interventions = historyRaw.map<Intervention>((e) {
      final m = e is Map<String, dynamic>
          ? e
          : Map<String, dynamic>.from(e as Map);
      return Intervention.fromJson(m);
    }).toList();

    final saved = await showDialog<dynamic>(
      context: context,
      builder: (ctx) => PointModal(
        isEdit: true,
        point: missionPoint,
        interventions: interventions,
        latitude: missionPoint.latitude,
        longitude: missionPoint.longitude,
        parcoursId: parcoursId,
      ),
    );
    if (context.mounted &&
        (saved == true || saved == kPointModalDeleted)) {
      await onClosedRefresh?.call();
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de charger le point')),
      );
    }
  }
}

/// Straight path through waypoints in [visit_order] when optimize API fails (e.g. no MAPBOX_TOKEN).
List<Position>? waypointPositionsFromParcoursJson(
  Map<String, dynamic> parcoursJson,
) {
  final raw = parcoursJson['parcours_points'];
  if (raw is! List || raw.length < 2) return null;

  final items = <Map<String, dynamic>>[];
  for (final e in raw) {
    if (e is Map<String, dynamic>) {
      items.add(e);
    } else if (e is Map) {
      items.add(Map<String, dynamic>.from(e));
    }
  }

  items.sort((a, b) {
    final ao = a['visit_order'];
    final bo = b['visit_order'];
    final ai = ao is num ? ao.toInt() : 0;
    final bi = bo is num ? bo.toInt() : 0;
    return ai.compareTo(bi);
  });

  final out = <Position>[];
  for (final pp in items) {
    final p = pp['point'];
    Map<String, dynamic>? pmap;
    if (p is Map<String, dynamic>) {
      pmap = p;
    } else if (p is Map) {
      pmap = Map<String, dynamic>.from(p);
    } else {
      continue;
    }
    final lat = pmap['latitude'];
    final lng = pmap['longitude'];
    if (lat is! num || lng is! num) continue;
    out.add(Position(lng.toDouble(), lat.toDouble()));
  }
  return out.length >= 2 ? out : null;
}

/// Mapbox GeoJSON [LineString] / [MultiLineString] → positions [lng, lat].
List<Position>? parseGeoJsonLineStringPositions(dynamic geometry) {
  if (geometry is! Map) return null;
  final type = geometry['type'];
  final coords = geometry['coordinates'];
  if (coords is! List) return null;

  final out = <Position>[];

  if (type == 'LineString') {
    for (final c in coords) {
      if (c is List && c.length >= 2) {
        out.add(
          Position(
            (c[0] as num).toDouble(),
            (c[1] as num).toDouble(),
          ),
        );
      }
    }
  } else if (type == 'MultiLineString') {
    for (final line in coords) {
      if (line is! List) continue;
      for (final c in line) {
        if (c is List && c.length >= 2) {
          out.add(
            Position(
              (c[0] as num).toDouble(),
              (c[1] as num).toDouble(),
            ),
          );
        }
      }
    }
  } else {
    return null;
  }

  return out.length >= 2 ? out : null;
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
