import 'package:flutter/material.dart';
import 'package:ditredi/ditredi.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' as math;
import '../models/gpx_route.dart';

/// First-person perspective 3D view - cyclist POV looking forward along the route
class Scene3DPOVView extends StatefulWidget {
  final GPXRoute route;
  final int currentPositionIndex;

  const Scene3DPOVView({
    super.key,
    required this.route,
    this.currentPositionIndex = 0,
  });

  @override
  State<Scene3DPOVView> createState() => _Scene3DPOVViewState();
}

class _Scene3DPOVViewState extends State<Scene3DPOVView> {
  final _controller = DiTreDiController(
    rotationX: 0, // Look straight ahead
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
  void didUpdateWidget(Scene3DPOVView oldWidget) {
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
    final latRad = startLat * math.pi / 180.0;
    final metersPerDegLon = 111320 * math.cos(latRad);
    const metersPerDegLat = 110574.0;

    _points3D = points.map((p) {
      final x = (p.longitude - startLon) * metersPerDegLon;
      final z = -(p.latitude - startLat) * metersPerDegLat;
      final y = (p.elevation - startEle) * 1.5; // Amplify elevation for POV
      return vector.Vector3(x, y, z);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_points3D == null || _points3D!.isEmpty) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Text('Chargement POV...', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    // Determine current cyclist position
    final clampedIndex = widget.currentPositionIndex.clamp(0, _points3D!.length - 1);
    final currentPos = _points3D![clampedIndex];

    // Get direction vector for cyclist (looking forward)
    vector.Vector3 forwardDir = vector.Vector3(0, 0, 1);
    if (clampedIndex < _points3D!.length - 1) {
      final nextPos = _points3D![clampedIndex + 1];
      forwardDir = (nextPos - currentPos).normalized();
    }

    // Create a "road" view: show the path ahead from cyclist's perspective
    List<Model3D> figures = [];

    // Draw the route as a "road" with lane markings
    if (_points3D!.length > clampedIndex + 1) {
      // Show next 50 points ahead of cyclist
      final lookAhead = math.min(clampedIndex + 50, _points3D!.length);

      // Center around cyclist for POV
      for (int i = clampedIndex; i < lookAhead - 1; i++) {
        final p1 = _points3D![i] - currentPos;
        final p2 = _points3D![i + 1] - currentPos;

        // Draw main road line in yellow
        figures.add(Line3D(
          p1,
          p2,
          width: 8,
          color: Colors.amber.shade400,
        ));

        // Add road edge lines (white dashed effect)
        // Left edge
        figures.add(Line3D(
          p1 + vector.Vector3(-3, 0, 0),
          p2 + vector.Vector3(-3, 0, 0),
          width: 2,
          color: Colors.white.withValues(alpha: 0.6),
        ));

        // Right edge
        figures.add(Line3D(
          p1 + vector.Vector3(3, 0, 0),
          p2 + vector.Vector3(3, 0, 0),
          width: 2,
          color: Colors.white.withValues(alpha: 0.6),
        ));
      }
    }

    // Add cyclist indicator at position (0,0,0)
    figures.add(Point3D(
      vector.Vector3.zero(),
      color: Colors.red,
      width: 8,
    ));

    // Add elevation markers along the path
    if (_points3D!.length > clampedIndex) {
      final lookAhead = math.min(clampedIndex + 30, _points3D!.length);
      for (int i = clampedIndex; i < lookAhead; i += 5) {
        final p = _points3D![i] - currentPos;
        // Color based on elevation change
        final color = p.y > 5 ? Colors.red : (p.y < -5 ? Colors.blue : Colors.grey);
        figures.add(Point3D(p, color: color, width: 4));
      }
    }

    return Container(
      color: Colors.sky[900], // Sky-like color for POV
      child: DiTreDi(
        figures: figures,
        controller: _controller,
        config: const DiTreDiConfig(
          defaultPointWidth: 2,
          supportZIndex: true,
          perspective: true,
          lightColor: Color(0xFF999999),
        ),
      ),
    );
  }
}
