import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  MapboxMap? _mapboxMap;

  @override
  void initState() {
    super.initState();
    _ensureLocationAndCenter();
  }

  Future<void> _ensureLocationAndCenter() async {
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

          await _ensureLocationAndCenter();
        },
      ),
    );
  }
}

