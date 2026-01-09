import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/gpx_route.dart';

class ElevationProfile extends StatelessWidget {
  final GPXRoute route;
  final double currentDistance;

  const ElevationProfile({
    super.key,
    required this.route,
    required this.currentDistance,
  });

  @override
  Widget build(BuildContext context) {
    if (route.trackPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final points = route.trackPoints;
    final maxElevation = points.map((p) => p.elevation).reduce((a, b) => a > b ? a : b);
    final minElevation = points.map((p) => p.elevation).reduce((a, b) => a < b ? a : b);
    final totalDistance = points.last.distance;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profil d\'élévation',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: totalDistance,
                minY: minElevation * 0.9, // Add some padding below
                maxY: maxElevation * 1.1, // Add some padding above
                lineTouchData: const LineTouchData(enabled: false), // Disable touch for now
                lineBarsData: [
                  LineChartBarData(
                    spots: points
                        .map((p) => FlSpot(p.distance, p.elevation))
                        .toList(),
                    isCurved: true,
                    color: Colors.blue.withOpacity(0.5),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                ],
                // Add current position indicator using ExtraLines
                extraLinesData: ExtraLinesData(
                  verticalLines: [
                    VerticalLine(
                      x: currentDistance,
                      color: Colors.red,
                      strokeWidth: 2,
                      dashArray: [5, 5],
                      label: VerticalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                        labelResolver: (line) => '',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${minElevation.toStringAsFixed(0)}m',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              Text(
                '${(totalDistance / 1000).toStringAsFixed(1)}km',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              Text(
                '${maxElevation.toStringAsFixed(0)}m',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
