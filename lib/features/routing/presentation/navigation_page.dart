import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/location/location_service.dart';
import '../../places/domain/entities/place.dart';
import '../domain/routing_models.dart';
import '../domain/routing_service.dart';
class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key, required this.place, this.routingService});
  final Place place;
  final RoutingService? routingService;
  @override
  State<NavigationPage> createState() => _NavigationPageState();
}
class _NavigationPageState extends State<NavigationPage> {
  TravelMode _mode = TravelMode.car;
  bool _loading = true;
  String? _error;
  RoutingResult? _result;
  LatLng? _currentPosition;
  @override
  void initState() {
    super.initState();
    _initRoute();
  }
  Future<void> _initRoute() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final position = await LocationService().tryGetCurrentPosition();
      if (position != null) {
        _currentPosition = LatLng(position.latitude, position.longitude);
      }
      final origin = _currentPosition != null
          ? RoutePoint(latitude: _currentPosition!.latitude, longitude: _currentPosition!.longitude)
          : const RoutePoint(latitude: 33.3675, longitude: 6.8675); // El Oued center fallback
      final destination = RoutePoint(latitude: widget.place.latitude!, longitude: widget.place.longitude!);
      if (widget.routingService != null) {
        _result = await widget.routingService!.calculateRoute(
          placeId: widget.place.id,
          origin: origin,
          destination: destination,
          mode: _mode,
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final destination = LatLng(widget.place.latitude!, widget.place.longitude!);
    final routeOption = _result?.routes.isNotEmpty == true ? _result!.routes.first : null;
    return Scaffold(
      appBar: AppBar(
        title: Text('الملاحة إلى ${widget.place.name}'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _currentPosition ?? destination,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ouedna.app',
              ),
              if (routeOption != null && routeOption.geometry.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routeOption.geometry,
                      strokeWidth: 5,
                      color: Colors.blue.shade700,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: destination,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 44),
                  ),
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 36),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: TravelMode.values.map((mode) {
                    final selected = _mode == mode;
                    return ChoiceChip(
                      label: Text(mode.label),
                      selected: selected,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _mode = mode);
                          _initRoute();
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: TextStyle(color: Colors.red.shade900)),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _initRoute, child: const Text('إعادة المحاولة')),
                    ],
                  ),
                ),
              ),
            )
          else if (routeOption != null)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.directions_outlined, color: Colors.teal),
                          const SizedBox(width: 8),
                          Text('${(routeOption.distanceMeters / 1000).toStringAsFixed(1)} كم'),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.teal),
                          const SizedBox(width: 8),
                          Text('${(routeOption.durationSeconds / 60).toStringAsFixed(0)} دقيقة'),
                        ],
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
