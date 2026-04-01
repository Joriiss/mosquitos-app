import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

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
  StreamSubscription<geo.Position>? _positionSub;

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

    if (_mapboxMap != null) {
      await _mapboxMap!.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(position.longitude, position.latitude),
          ),
          zoom: 14,
        ),
      );
    }

    // Start continuous follow
    _positionSub?.cancel();
    _positionSub = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 1, // meters before update
      ),
    ).listen((geo.Position pos) {
      if (_mapboxMap == null) return;
      _mapboxMap!.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(pos.longitude, pos.latitude),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapWidget(
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
    );
  }
}

