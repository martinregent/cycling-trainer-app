import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/gpx_route.dart';

class SlopeProfileChart extends StatelessWidget {
  final GPXRoute route;
  final int currentPositionIndex;
  final double currentDistance;

  const SlopeProfileChart({
    super.key,
    required this.route,
    required this.currentPositionIndex,
    required this.currentDistance,
  });

  /// Calculate slope percentage between two points
  double _calculateSlope(TrackPoint p1, TrackPoint p2) {
    if (p1 == p2) return 0.0;

    final latRad = p1.latitude * math.pi / 180.0;
    final metersPerDegLon = 111320 * math.cos(latRad);
    const metersPerDegLat = 110574.0;

    final dx = (p2.longitude - p1.longitude) * metersPerDegLon;
    final dz = (p2.latitude - p1.latitude) * metersPerDegLat;
    final dy = p2.elevation - p1.elevation;

    final horizontalDistance = math.sqrt(dx * dx + dz * dz);
    if (horizontalDistance == 0) return 0.0;

    return (dy / horizontalDistance) * 100.0;
  }

  /// Get slope segments for the next 200m
  List<Map<String, dynamic>> _getSlopeSegments() {
    if (route.trackPoints.isEmpty || currentPositionIndex >= route.trackPoints.length) {
      return [];
    }

    final segments = <Map<String, dynamic>>[];
    const segmentLength = 50.0;
    const numSegments = 4;

    int startIndex = currentPositionIndex;

    for (int seg = 0; seg < numSegments; seg++) {
      int endIndex = startIndex;
      double segmentDistance = 0.0;

      while (endIndex < route.trackPoints.length - 1 && segmentDistance < segmentLength) {
        final currentPoint = route.trackPoints[endIndex];
        final nextPoint = route.trackPoints[endIndex + 1];

        final latRad = currentPoint.latitude * math.pi / 180.0;
        final metersPerDegLon = 111320 * math.cos(latRad);
        const metersPerDegLat = 110574.0;

        final dx = (nextPoint.longitude - currentPoint.longitude) * metersPerDegLon;
        final dz = (nextPoint.latitude - currentPoint.latitude) * metersPerDegLat;
        final pointDistance = math.sqrt(dx * dx + dz * dz);

        if (segmentDistance + pointDistance >= segmentLength) {
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
        'slope': slope,
        'distance': segmentLength,
      });

      startIndex = endIndex;
    }

    return segments;
  }

  /// Get color based on slope
  Color _getSlopeColor(double slope) {
    if (slope > 8) return const Color(0xFFFF4444); // Red
    if (slope > 5) return const Color(0xFFFF8C00); // Orange
    if (slope > 2) return const Color(0xFFFFDD00); // Yellow
    if (slope > -2) return const Color(0xFF00CC44); // Green
    if (slope > -5) return const Color(0xFF00CCCC); // Cyan
    return const Color(0xFF0066FF); // Blue
  }

  @override
  Widget build(BuildContext context) {
    final segments = _getSlopeSegments();
    if (segments.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Text('Fin de trace', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final currentSlope = (segments.first['slope'] as double);
    final chartHeight = 120.0;
    final chartWidth = 300.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current slope indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pente actuelle',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Row(
                      children: [
                        Text(
                          '${currentSlope.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _getSlopeColor(currentSlope),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentSlope > 0.5 ? '📈' : currentSlope < -0.5 ? '📉' : '➡️',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Area chart with line
            SizedBox(
              width: chartWidth,
              height: chartHeight,
              child: CustomPaint(
                painter: SlopeChartPainter(
                  slopes: segments.map((s) => s['slope'] as double).toList(),
                  colors: segments.map((s) => _getSlopeColor(s['slope'] as double)).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Distance markers
            SizedBox(
              width: chartWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('0m', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  const Text('50m', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  const Text('100m', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  const Text('150m', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  const Text('200m', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SlopeChartPainter extends CustomPainter {
  final List<double> slopes;
  final List<Color> colors;

  SlopeChartPainter({required this.slopes, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (slopes.length < 2) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final baselineY = size.height / 2;
    final segmentWidth = size.width / slopes.length;
    const maxSlopeDisplay = 15.0; // Max slope to display
    final slopeScale = baselineY / maxSlopeDisplay;

    // Draw areas for each segment
    for (int i = 0; i < slopes.length; i++) {
      final slope = slopes[i].clamp(-maxSlopeDisplay, maxSlopeDisplay);
      final x = i * segmentWidth;
      final y = baselineY - (slope * slopeScale);
      final nextX = (i + 1) * segmentWidth;
      final nextSlope = i < slopes.length - 1
          ? slopes[i + 1].clamp(-maxSlopeDisplay, maxSlopeDisplay)
          : slope;
      final nextY = baselineY - (nextSlope * slopeScale);

      // Draw area with gradient
      final areaPath = Path()
        ..moveTo(x, baselineY)
        ..lineTo(x, y)
        ..lineTo(nextX, nextY)
        ..lineTo(nextX, baselineY)
        ..close();

      paint.color = colors[i].withValues(alpha: 0.3);
      canvas.drawPath(areaPath, paint);

      // Draw outline
      paint.color = colors[i];
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1;
      canvas.drawPath(areaPath, paint);
    }

    // Draw dashed line connecting slope points
    final pathPoints = <Offset>[];
    for (int i = 0; i < slopes.length; i++) {
      final slope = slopes[i].clamp(-maxSlopeDisplay, maxSlopeDisplay);
      final x = i * segmentWidth + segmentWidth / 2;
      final y = baselineY - (slope * slopeScale);
      pathPoints.add(Offset(x, y));
    }

    // Draw dashed line
    linePaint.color = Colors.black87;
    _drawDashedLine(canvas, pathPoints, linePaint);

    // Draw points
    for (final point in pathPoints) {
      canvas.drawCircle(point, 3, Paint()..color = Colors.black87);
    }

    // Draw baseline
    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      Paint()
        ..color = Colors.grey.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );
  }

  void _drawDashedLine(Canvas canvas, List<Offset> points, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;

    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final distance = math.sqrt(dx * dx + dy * dy);
      final steps = (distance / (dashWidth + dashSpace)).ceil();

      for (int step = 0; step < steps; step++) {
        final t1 = (step * (dashWidth + dashSpace)) / distance;
        final t2 = (step * (dashWidth + dashSpace) + dashWidth) / distance;

        if (t1 < 1) {
          final p1 = Offset(
            start.dx + dx * t1,
            start.dy + dy * t1,
          );
          final p2 = Offset(
            start.dx + dx * (t2.clamp(0.0, 1.0)),
            start.dy + dy * (t2.clamp(0.0, 1.0)),
          );
          canvas.drawLine(p1, p2, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(SlopeChartPainter oldDelegate) {
    return oldDelegate.slopes != slopes || oldDelegate.colors != colors;
  }
}
