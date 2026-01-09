import 'package:flutter/material.dart';
import 'package:ditredi/ditredi.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' as math;
import '../models/gpx_route.dart';

class Scene3DView extends StatefulWidget {
  final GPXRoute route;
  final int currentPositionIndex;

  const Scene3DView({
    super.key,
    required this.route,
    this.currentPositionIndex = 0,
  });

  @override
  State<Scene3DView> createState() => _Scene3DViewState();
}

class _Scene3DViewState extends State<Scene3DView> {
  final _controller = DiTreDiController(
    rotationX: -30,
    rotationY: 0,
    userScale: 1.0,
  );
  
  List<vector.Vector3>? _points3D;


  @override
  void initState() {
    super.initState();
    _processRoute();
  }

  @override
  void didUpdateWidget(Scene3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.route != oldWidget.route) {
      _processRoute();
    }
  }

  void _processRoute() {
    if (widget.route.trackPoints.isEmpty) return;

    final points = widget.route.trackPoints;
    final startLat = points.first.latitude;
    final startLon = points.first.longitude;
    final startEle = points.first.elevation;

    // Convert to local Cartesian coordinates (meters)
    // Simple projection: 
    // X = (lon - startLon) * meters_per_deg_lon
    // Z = (lat - startLat) * meters_per_deg_lat  (using Z as North-South for 3D usually)
    // Y = (ele - startEle) (Y is up)
    
    final latRad = startLat * math.pi / 180.0;
    final metersPerDegLon = 111320 * math.cos(latRad);
    const metersPerDegLat = 110574.0;

    _points3D = points.map((p) {
      final x = (p.longitude - startLon) * metersPerDegLon;
      final z = -(p.latitude - startLat) * metersPerDegLat; // Invert Z to match map intuition (North up/forward)
      final y = (p.elevation - startEle) * 1.0; // Vertical scale
      return vector.Vector3(x, y, z);
    }).toList();

    // Center calculation removed as not needed for follow camera
  }

  @override
  Widget build(BuildContext context) {
    if (_points3D == null || _points3D!.isEmpty) {
      return Container(
        color: Colors.grey[900],
        child: const Center(child: Text('Chargement 3D...', style: TextStyle(color: Colors.white))),
      );
    }

    // Determine current cyclist position
    final clampedIndex = widget.currentPositionIndex.clamp(0, _points3D!.length - 1);
    final currentPos = _points3D![clampedIndex];

    // Translate world so cyclist is at (0,0,0)
    // This creates a "follow camera" effect perfectly
    final centeredPoints = _points3D!.map((p) => p - currentPos).toList();
    final centeredPos = vector.Vector3.zero();

    // Create route segments
    List<Model3D> figures = [];
    
    // Add ground grid first
    figures.addAll(_buildGrid(vector.Vector3.zero()));

    // Add route line segments
    if (centeredPoints.length > 1) {
      for (int i = 0; i < centeredPoints.length - 1; i++) {
        figures.add(Line3D(
          centeredPoints[i],
          centeredPoints[i + 1],
          width: 4,
          color: Colors.blueAccent,
        ));
      }
    }

    // Add cyclist marker
    figures.add(Point3D(
      centeredPos,
      color: Colors.red,
      width: 15,
    ));

    return Container(
      color: Colors.grey[900], // Dark background for 3D
      child: DiTreDi(
        figures: figures,
        controller: _controller,
        config: const DiTreDiConfig(
          defaultPointWidth: 2,
          supportZIndex: true,
          perspective: true,
        ),
      ),
    );
  }

  List<Line3D> _buildGrid(vector.Vector3 center) {
    final lines = <Line3D>[];
    const gridSize = 500.0; // meters
    const step = 50.0;
    
    // Grid purely based on local (0,0,0)
    const y = -2.0; // Slightly below cyclist

    // Color for grid
    final color = Colors.white.withValues(alpha:0.1);

    for (var x = -gridSize; x <= gridSize; x += step) {
      lines.add(Line3D(
        vector.Vector3(x, y, -gridSize), 
        vector.Vector3(x, y, gridSize),
        width: 1,
        color: color,
      ));
    }

    for (var z = -gridSize; z <= gridSize; z += step) {
      lines.add(Line3D(
        vector.Vector3(-gridSize, y, z), 
        vector.Vector3(gridSize, y, z),
        width: 1,
        color: color,
      ));
    }

    return lines;
  }
}
