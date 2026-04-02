import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../edit_point.dart';
import '../../parcours/domain/parcours.dart';
import '../map_point_circles.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_colors.dart';

class MapPage extends StatefulWidget {
  final String parcoursId;
  const MapPage({
    super.key,
    required this.parcoursId,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  MapboxMap? _mapboxMap;
  CircleAnnotationManager? _circleManager;
  PolylineAnnotationManager? _routePolylineManager;
  Cancelable? _circleTapCancel;
  StreamSubscription<geo.Position>? _positionSub;
  double? _currentLatitude;
  double? _currentLongitude;

  bool _isPaused = false;
  Parcours? _parcours;
  int _nextPointNumber = 1;
  /// Set from [ApiService.optimizeParcours] when the walking route is drawn.
  int? _optimizedDurationMin;

  Future<void> _ensureCircleManager() async {
    if (_mapboxMap == null) return;
    _circleManager ??=
        await _mapboxMap!.annotations.createCircleAnnotationManager();
  }

  /// Circle annotations must be created after the style is loaded, otherwise they may not appear.
  Future<void> _waitForStyleThenSyncMarkers() async {
    final map = _mapboxMap;
    if (map == null) return;

    await waitForMapStyleLoaded(map);
    if (!mounted) return;

    await _ensureCircleManager();
    _bindParcoursCircleTapsOnce();
    await _loadParcoursDetailAndSyncMarkers();
  }

  void _bindParcoursCircleTapsOnce() {
    final m = _circleManager;
    if (m == null || _circleTapCancel != null) return;
    _circleTapCancel = bindParcoursCircleTapHandler(
      manager: m,
      onPointId: (pointId) {
        unawaited(_onParcoursPointTapped(pointId));
      },
    );
  }

  Future<void> _onParcoursPointTapped(String pointId) async {
    await openPointDetailFromMap(
      context: context,
      pointId: pointId,
      parcoursId: widget.parcoursId,
      onClosedRefresh: _loadParcoursDetailAndSyncMarkers,
    );
  }

  Future<void> _loadParcoursDetailAndSyncMarkers() async {
    try {
      final json = await ApiService.getParcoursById(widget.parcoursId);
      if (!mounted) return;

      setState(() {
        _parcours = Parcours.fromJson(json);
        _nextPointNumber = (_parcours?.totalPoints ?? 0) + 1;
        _optimizedDurationMin = null;
      });

      await _ensureCircleManager();
      final manager = _circleManager;
      if (manager == null) return;

      await _syncOptimizedRoutePolyline(json);
      await syncParcoursPointCircles(
        manager: manager,
        parcoursJson: json,
      );
    } catch (_) {
      // Map stays usable; header may stay empty if the request fails.
    }
  }

  /// Walking route from backend [optimize] (Mapbox); falls back to straight segments if the API fails.
  Future<void> _syncOptimizedRoutePolyline(
    Map<String, dynamic> parcoursJson,
  ) async {
    final map = _mapboxMap;
    if (map == null) return;

    await waitForMapStyleLoaded(map);
    if (!mounted) return;

    _routePolylineManager ??=
        await map.annotations.createPolylineAnnotationManager();

    await _routePolylineManager!.deleteAll();

    final rawPts = parcoursJson['parcours_points'];
    final total = rawPts is List ? rawPts.length : 0;
    if (total < 2) {
      return;
    }

    Future<void> drawLine(List<Position> positions) async {
      await _routePolylineManager!.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: positions),
          lineColor: AppColors.primaryBlue.value,
          lineWidth: 5.0,
        ),
      );
    }

    var usedMapboxGeometry = false;
    try {
      if (_currentLatitude == null || _currentLongitude == null) {
        return;
      }

      final data = await ApiService.optimizeParcours(
        _currentLatitude!,
        _currentLongitude!,
        widget.parcoursId,
      );
      if (!mounted) return;

      final positions =
          parseGeoJsonLineStringPositions(data['geometry']);
      if (positions != null && positions.length >= 2) {
        final dur = data['duration_min'];
        setState(() {
          _optimizedDurationMin = dur is num ? dur.round() : null;
        });
        await drawLine(positions);
        usedMapboxGeometry = true;
      }
    } catch (_) {
      // No token / network / API error — try fallback below.
    }

    if (usedMapboxGeometry) return;

    final fallback = waypointPositionsFromParcoursJson(parcoursJson);
    if (fallback == null || fallback.length < 2 || !mounted) return;

    setState(() {
      _optimizedDurationMin = null;
    });
    await drawLine(fallback);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Itinéraire piéton indisponible (MAPBOX_TOKEN sur l’API). '
          'Tracé en ligne droite entre les points.',
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }

  String get _durationText {
    final durationMin =
        _optimizedDurationMin ?? _parcours?.durationMin;
    return '${durationMin ?? 0} min';
  }

  Future<void> _recenter() async {
    if (_mapboxMap == null) return;
    if (_currentLatitude == null || _currentLongitude == null) return;

    final cameraState = await _mapboxMap!.getCameraState();

    await _mapboxMap!.setCamera(
      CameraOptions(
        center: Point(
          coordinates: Position(_currentLongitude!, _currentLatitude!),
        ),
        // Preserve zoom level when recentring.
        zoom: cameraState.zoom,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _ensureLocationAndFollow();
  }

  Future<void> _ensureLocationAndFollow() async {
    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }
    if (permission == geo.LocationPermission.deniedForever ||
        permission == geo.LocationPermission.denied) {
      return;
    }

    final position = await geo.Geolocator.getCurrentPosition(
      desiredAccuracy: geo.LocationAccuracy.high,
    );

    _currentLatitude = position.latitude;
    _currentLongitude = position.longitude;

    if (_mapboxMap != null) {
      await _mapboxMap!.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(_currentLongitude!, _currentLatitude!),
          ),
          zoom: 18,
        ),
      );
    }

    // Keep tracking location, but do not auto-move the camera.
    _positionSub?.cancel();
    _positionSub = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 1, // meters before update
      ),
    ).listen((geo.Position pos) {
      if (_isPaused) return;
      _currentLatitude = pos.latitude;
      _currentLongitude = pos.longitude;
    });
  }

  @override
  void dispose() {
    _circleTapCancel?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          MapWidget(
            styleUri: 'mapbox://styles/mapbox/standard',
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(4.8357, 45.7640),
              ),
              zoom: 18,
            ),
            onMapCreated: (mapboxMap) async {
              _mapboxMap = mapboxMap;

              await _mapboxMap!.scaleBar.updateSettings(
                ScaleBarSettings(enabled: false),
              );

              await _mapboxMap!.location.updateSettings(
                LocationComponentSettings(enabled: true),
              );

              await _ensureLocationAndFollow();
              await _waitForStyleThenSyncMarkers();
            },
          ),
          Positioned(
            top: 40,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _parcours?.name ?? '',
                style: const TextStyle(
                  fontFamily: 'Gabarito',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/icons/time.png',
                        height: 18,
                        width: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _durationText,
                        style: const TextStyle(
                          fontFamily: 'Gabarito',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isPaused = !_isPaused;
                      });
                    },
                    child: _isPaused
                        ? const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 25,
                          )
                        : Image.asset(
                            'assets/icons/pause.png',
                            height: 25,
                            width: 25,
                            color: Colors.white,
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: InkWell(
                    onTap: () {
                      _positionSub?.cancel();
                      Navigator.of(context).pop(true);
                    },
                    child: Image.asset(
                      'assets/icons/stop.png',
                      height: 25,
                      width: 25,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 92,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              onPressed: _recenter,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (_currentLatitude == null || _currentLongitude == null) {
                    return;
                  }

                  final k = _nextPointNumber;
                  showDialog<bool>(
                    context: context,
                    builder: (_) => PointModal(
                      isEdit: false,
                      defaultName: 'Point #$k',
                      latitude: _currentLatitude!,
                      longitude: _currentLongitude!,
                      parcoursId: widget.parcoursId,
                    ),
                  ).then((created) async {
                    if (created == true && mounted) {
                      await _loadParcoursDetailAndSyncMarkers();
                    }
                  });
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ajouter un point',
                      style: TextStyle(
                        fontFamily: 'Gabarito',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Image(
                      image: AssetImage(
                        'assets/icons/plus-icon.png',
                      ),
                      height: 22,
                      width: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

