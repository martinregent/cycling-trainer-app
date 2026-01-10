import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/gpx_route.dart';

class SlopeProfileWidget extends StatelessWidget {
  final GPXRoute route;
  final int currentPositionIndex;
  final double currentDistance;

  const SlopeProfileWidget({
    super.key,
    required this.route,
    required this.currentPositionIndex,
    required this.currentDistance,
  });

  /// Calculate slope percentage between two points
  double _calculateSlope(TrackPoint p1, TrackPoint p2) {
    if (p1 == p2) return 0.0;

    // Convert to Cartesian coordinates
    final latRad = p1.latitude * math.pi / 180.0;
    final metersPerDegLon = 111320 * math.cos(latRad);
    const metersPerDegLat = 110574.0;

    final dx = (p2.longitude - p1.longitude) * metersPerDegLon;
    final dz = (p2.latitude - p1.latitude) * metersPerDegLat;
    final dy = p2.elevation - p1.elevation;

    final horizontalDistance = math.sqrt(dx * dx + dz * dz);
    if (horizontalDistance == 0) return 0.0;

    return (dy / horizontalDistance) * 100.0; // Slope percentage
  }

  /// Get slope segments for the next 200m
  List<Map<String, dynamic>> _getSlopeSegments() {
    if (route.trackPoints.isEmpty || currentPositionIndex >= route.trackPoints.length) {
      return [];
    }

    final segments = <Map<String, dynamic>>[];
    const segmentLength = 50.0; // meters
    const numSegments = 4; // 200m / 50m

    int startIndex = currentPositionIndex;

    for (int seg = 0; seg < numSegments; seg++) {
      int endIndex = startIndex;
      double segmentDistance = 0.0;

      // Find the point at the target distance
      while (endIndex < route.trackPoints.length - 1 && segmentDistance < segmentLength) {
        final currentPoint = route.trackPoints[endIndex];
        final nextPoint = route.trackPoints[endIndex + 1];

        // Calculate distance between points
        final latRad = currentPoint.latitude * math.pi / 180.0;
        final metersPerDegLon = 111320 * math.cos(latRad);
        const metersPerDegLat = 110574.0;

        final dx = (nextPoint.longitude - currentPoint.longitude) * metersPerDegLon;
        final dz = (nextPoint.latitude - currentPoint.latitude) * metersPerDegLat;
        final pointDistance = math.sqrt(dx * dx + dz * dz);

        if (segmentDistance + pointDistance >= segmentLength) {
          // We've found the end point
          endIndex++;
          segmentDistance += pointDistance;
          break;
        }

        segmentDistance += pointDistance;
        endIndex++;
      }

      if (endIndex <= startIndex) {
        endIndex = math.min(startIndex + 1, route.trackPoints.length - 1);
      }

      final startPoint = route.trackPoints[startIndex];
      final endPoint = route.trackPoints[endIndex];
      final slope = _calculateSlope(startPoint, endPoint);

      segments.add({
        'distance': segmentLength,
        'slope': slope,
        'elevationStart': startPoint.elevation,
        'elevationEnd': endPoint.elevation,
      });

      startIndex = endIndex;
    }

    return segments;
  }

  /// Get current slope (immediate next 50m)
  double _getCurrentSlope() {
    if (route.trackPoints.isEmpty || currentPositionIndex >= route.trackPoints.length - 1) {
      return 0.0;
    }

    final segments = _getSlopeSegments();
    if (segments.isEmpty) return 0.0;

    return segments.first['slope'] as double;
  }

  /// Get color based on slope
  Color _getSlopeColor(double slope) {
    if (slope > 8) return Colors.red; // > 8% = very steep
    if (slope > 5) return Colors.orange; // 5-8% = steep
    if (slope > 2) return Colors.yellow; // 2-5% = moderate uphill
    if (slope > -2) return Colors.green; // -2 to +2% = flat
    if (slope > -5) return Colors.cyan; // -2 to -5% = moderate downhill
    return Colors.blue; // < -5% = steep downhill
  }

  @override
  Widget build(BuildContext context) {
    final currentSlope = _getCurrentSlope();
    final segments = _getSlopeSegments();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current slope header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pente immédiate',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '${currentSlope.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getSlopeColor(currentSlope),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSlopeColor(currentSlope).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentSlope > 0 ? '📈 Montée' : currentSlope < 0 ? '📉 Descente' : '➡️ Plat',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Slope profile for next 200m
            const Text(
              'Profil des 200m à venir (par 50m)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (segments.isEmpty)
              const Center(
                child: Text('Fin de la trace', style: TextStyle(color: Colors.grey)),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(segments.length, (index) {
                    final segment = segments[index];
                    final slope = segment['slope'] as double;
                    final color = _getSlopeColor(slope);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        children: [
                          // Bar chart for slope
                          Container(
                            width: 40,
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: color, width: 1.5),
                              borderRadius: BorderRadius.circular(4),
                              color: color.withValues(alpha: 0.1),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Zero line
                                Positioned(
                                  top: 40,
                                  child: Container(
                                    width: 40,
                                    height: 1,
                                    color: Colors.grey.withValues(alpha: 0.5),
                                  ),
                                ),
                                // Slope indicator bar
                                Align(
                                  alignment: slope >= 0
                                      ? Alignment.bottomCenter
                                      : Alignment.topCenter,
                                  child: Container(
                                    width: 30,
                                    height: (slope.abs() / 10 * 40).clamp(2.0, 40.0),
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${slope.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          Text(
                            '${(index + 1) * 50}m',
                            style: const TextStyle(fontSize: 8, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
