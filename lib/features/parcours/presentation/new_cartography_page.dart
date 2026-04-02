import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../services/api_service.dart';
import '../../../theme/app_colors.dart';
import '../../edit_point.dart';

class NewCartographyPage extends StatefulWidget {
  final String name;
  final String parcoursId;

  const NewCartographyPage({
    super.key,
    required this.name,
    required this.parcoursId,
  });

  @override
  State<NewCartographyPage> createState() => _NewCartographyPageState();
}

class _NewCartographyPageState extends State<NewCartographyPage> {
  MapboxMap? _mapboxMap;
  StreamSubscription<geo.Position>? _positionSub;

  int _elapsedSeconds = 0;
  String _elapsedText = '00:00';
  String _distanceText = '0 m';
  double _distanceKm = 0;
  Timer? _timer;
  bool _isPaused = false;

  double? currentLatitude;
  double? currentLongitude;
  double? _lastLatitude;
  double? _lastLongitude;
  bool _trackingStarted = false;

  // Live polyline representing the recorded path during this mission.
  PolylineAnnotationManager? _polylineManager;
  PolylineAnnotation? _pathAnnotation;
  final List<Position> _trackPositions = [];

  Future<void> _recenter() async {
    if (_mapboxMap == null) return;
    if (currentLatitude == null || currentLongitude == null) return;

    await _mapboxMap!.setCamera(
      CameraOptions(
        center: Point(
          coordinates: Position(currentLongitude!, currentLatitude!),
        ),
        zoom: 14,
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused) return;

      _elapsedSeconds++;

      final minutes =
          (_elapsedSeconds ~/ 60).remainder(60).toString().padLeft(2, '0');

      final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');

      setState(() {
        _elapsedText = '$minutes:$seconds';
      });
    });

    _ensureLocationAndFollow();
  }

  Future<void> _ensureLocationAndFollow() async {
    // Prevent multiple subscriptions when this method is called twice
    // (once in initState, once in onMapCreated).
    if (_trackingStarted) {
      if (_mapboxMap != null &&
          currentLatitude != null &&
          currentLongitude != null) {
        await _mapboxMap!.setCamera(
          CameraOptions(
            center: Point(
              coordinates: Position(currentLongitude!, currentLatitude!),
            ),
            zoom: 14,
          ),
        );
      }
      return;
    }

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

    currentLatitude = position.latitude;
    currentLongitude = position.longitude;
    _lastLatitude = position.latitude;
    _lastLongitude = position.longitude;
    _trackingStarted = true;
    _distanceKm = 0;
    _distanceText = '0 m';

    _trackPositions
      ..clear()
      ..add(Position(position.longitude, position.latitude));

    if (_mapboxMap != null) {
      await _mapboxMap!.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(
              position.longitude,
              position.latitude,
            ),
          ),
          zoom: 14,
        ),
      );
    }

    _positionSub?.cancel();

    _positionSub = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((geo.Position pos) async {
      currentLatitude = pos.latitude;
      currentLongitude = pos.longitude;

      if (_lastLatitude != null && _lastLongitude != null) {
        final nextPoint = Position(pos.longitude, pos.latitude);

        if (_trackPositions.isEmpty) {
          _trackPositions.add(nextPoint);
        } else if (_isPaused) {
          // Keep the polyline endpoint in sync, but do not add new segments.
          _trackPositions[_trackPositions.length - 1] = nextPoint;
        } else {
          final segmentMeters = _haversineMeters(
            _lastLatitude!,
            _lastLongitude!,
            pos.latitude,
            pos.longitude,
          );

          // Ignore tiny movements / GPS jitter.
          const minSegmentMeters = 2.0;
          if (segmentMeters >= minSegmentMeters) {
            _trackPositions.add(nextPoint);
            _distanceKm += segmentMeters / 1000.0;
            _distanceText = _formatDistance(_distanceKm);
            setState(() {});
          } else {
            // Update last point without extending the path.
            _trackPositions[_trackPositions.length - 1] = nextPoint;
          }
        }

        // Update last reference position to avoid jump when resuming.
        _lastLatitude = pos.latitude;
        _lastLongitude = pos.longitude;

        await _syncPathPolyline();
      }

      try {
        await ApiService.sendTrack(
          parcoursId: widget.parcoursId,
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
      } catch (_) {}
    });
  }

  double _degToRad(double deg) => deg * (pi / 180.0);

  // Great-circle distance between two lat/lon points (meters).
  double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0;

    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = pow(sin(dLat / 2), 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            pow(sin(dLon / 2), 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1.0) {
      final meters = distanceKm * 1000.0;
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${distanceKm.toStringAsFixed(2)} km';
  }

  Future<void> _setupPolyline() async {
    if (_mapboxMap == null) return;
    if (_polylineManager != null) return;

    _polylineManager =
        await _mapboxMap!.annotations.createPolylineAnnotationManager();
    await _syncPathPolyline();
  }

  Future<void> _syncPathPolyline() async {
    if (_polylineManager == null) return;
    if (_trackPositions.length < 2) return;

    final lineString = LineString(coordinates: _trackPositions);

    if (_pathAnnotation == null) {
      _pathAnnotation = await _polylineManager!.create(
        PolylineAnnotationOptions(
          geometry: lineString,
          lineColor: AppColors.primaryBlue.value,
          lineWidth: 4.0,
        ),
      );
      return;
    }

    _pathAnnotation!.geometry = lineString;
    await _polylineManager!.update(_pathAnnotation!);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _timer?.cancel();
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
              zoom: 12,
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
              await _setupPolyline();
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
                widget.name,
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
                        _elapsedText,
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
                const SizedBox(height: 8),
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
                        'assets/icons/length.png',
                        height: 18,
                        width: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _distanceText,
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
            bottom: 92,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: AppColors.primaryBlue,
              mini: true,
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
                  if (currentLatitude == null || currentLongitude == null) {
                    return;
                  }

                  showDialog(
                    context: context,
                    builder: (_) => PointModal(
                      isEdit: false,
                      latitude: currentLatitude!,
                      longitude: currentLongitude!,
                      parcoursId: widget.parcoursId,
                    ),
                  );
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
