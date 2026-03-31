import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

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
      ),
    );
  }
}

