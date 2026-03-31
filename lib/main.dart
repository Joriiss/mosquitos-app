import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'config/mapbox_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  MapboxOptions.setAccessToken(MapboxConfig.token);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mapbox Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MapPage(),
    );
  }
}

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
