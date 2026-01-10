import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/gpx_route.dart';

class RouteMap extends StatefulWidget {
  final GPXRoute? route;
  final int currentPositionIndex;

  const RouteMap({
    super.key,
    this.route,
    this.currentPositionIndex = 0,
  });

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  final MapController _mapController = MapController();
  
  @override
  void didUpdateWidget(RouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPositionIndex != oldWidget.currentPositionIndex && 
        widget.route != null &&
        widget.currentPositionIndex < widget.route!.trackPoints.length) {
      
      final point = widget.route!.trackPoints[widget.currentPositionIndex];
      _mapController.move(
        LatLng(point.latitude, point.longitude), 
        _mapController.camera.zoom
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.route == null || widget.route!.trackPoints.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Text('Aucun parcours chargé'),
        ),
      );
    }

    final points = widget.route!.trackPoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();
        
    final currentPoint = widget.route!.trackPoints.isNotEmpty 
        ? widget.route!.trackPoints[
            widget.currentPositionIndex.clamp(0, widget.route!.trackPoints.length - 1)
          ]
        : null;

    final initialCenter = points.isNotEmpty 
        ? points.first 
        : const LatLng(48.8566, 2.3522); // Paris default

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 13.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.cycling_trainer_app',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: points,
              color: Colors.blue,
              strokeWidth: 4.0,
            ),
          ],
        ),
        if (currentPoint != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(currentPoint.latitude, currentPoint.longitude),
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
