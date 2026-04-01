import 'dart:async';

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
  Timer? _timer;
  bool _isPaused = false;

  double? currentLatitude;
  double? currentLongitude;

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

      if (_mapboxMap == null) return;

      _mapboxMap!.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(
              pos.longitude,
              pos.latitude,
            ),
          ),
        ),
      );

      try {
        await ApiService.sendTrack(
          parcoursId: widget.parcoursId,
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
      } catch (_) {}
    });
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
                      Navigator.of(context).pop();
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
            child: Container(
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
