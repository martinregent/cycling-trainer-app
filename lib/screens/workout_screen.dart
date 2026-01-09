import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/bluetooth_provider.dart';
import '../widgets/metric_tile.dart';
import '../widgets/route_map.dart';
import '../widgets/elevation_profile.dart';
import '../widgets/scene_3d_view.dart';
import 'package:uuid/uuid.dart';
import '../models/workout.dart';
import '../repositories/workout_repository.dart';
import '../models/gpx_route.dart';

class WorkoutScreen extends StatefulWidget {
  final GPXRoute? route;
  
  const WorkoutScreen({super.key, this.route});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  bool _isRecording = false;
  bool showMap = true;
  DateTime? _startTime;
  Timer? _timer;
  int _elapsedSeconds = 0;
  double _totalDistance = 0;
  final List<WorkoutDataPoint> _dataPoints = [];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;

      if (_isRecording) {
        _startTime = DateTime.now();
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _elapsedSeconds++;
            // Simulate 30km/h = 8.33 m/s for testing visualization if no device connected
            // Only if bluetooth speed is 0
            final provider = Provider.of<BluetoothProvider>(context, listen: false);
            double currentSpeed = provider.speed > 0 ? provider.speed : (provider.connectedTrainer != null ? 0 : 30.0);
            
            _totalDistance += (currentSpeed / 3.6);  // speed is km/h, convert to m/s
            
            // Record data point
            _dataPoints.add(WorkoutDataPoint(
              timestamp: DateTime.now(),
              power: provider.power,
              cadence: provider.cadence,
              speed: currentSpeed,
              heartRate: provider.heartRate,
              distance: _totalDistance,
              // elevation: currentElevation // TODO: Get elevation from route if available
            ));
          });
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _finishWorkout() {
    _timer?.cancel();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer la séance'),
        content: const Text(
          'Voulez-vous sauvegarder cette séance ?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to home
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Calculate aggregates
              double totalPower = 0;
              double maxPower = 0;
              double totalHeartRate = 0;
              double maxHeartRate = 0;
              
              if (_dataPoints.isNotEmpty) {
                for (var point in _dataPoints) {
                  totalPower += point.power;
                  if (point.power > maxPower) maxPower = point.power;
                  
                  totalHeartRate += point.heartRate;
                  if (point.heartRate > maxHeartRate) maxHeartRate = point.heartRate.toDouble();
                }
              }
              
              final avgPower = _dataPoints.isEmpty ? 0.0 : totalPower / _dataPoints.length;
              final avgHeartRate = _dataPoints.isEmpty ? 0.0 : totalHeartRate / _dataPoints.length;
              
              final workout = Workout(
                id: const Uuid().v4(),
                date: _startTime ?? DateTime.now(),
                duration: _elapsedSeconds.toDouble(),
                distance: _totalDistance,
                avgPower: avgPower,
                maxPower: maxPower,
                avgHeartRate: avgHeartRate,
                maxHeartRate: maxHeartRate,
                routeId: widget.route?.name, // Ideally use an ID, using name for now or null
                dataPoints: List.from(_dataPoints),
              );

              await WorkoutRepository().saveWorkout(workout);

              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to home
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Séance sauvegardée'),
                  ),
                );
              }
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Calculate current position index for route visualization
    int currentIndex = 0;
    if (widget.route != null && widget.route!.trackPoints.isNotEmpty) {
      final points = widget.route!.trackPoints;
      final currentDist = _totalDistance % widget.route!.distance;
      
      currentIndex = points.indexWhere((p) => p.distance >= currentDist);
      if (currentIndex == -1) currentIndex = points.length - 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entraînement'),
        actions: [
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'REC',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Consumer<BluetoothProvider>(
        builder: (context, bluetooth, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Duration Display
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          'Durée',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDuration(_elapsedSeconds),
                          style:
                              Theme.of(context).textTheme.displayLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontFeatures: [
                                      const FontFeature.tabularFigures(),
                                    ],
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Metrics Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    MetricTile(
                      title: 'Puissance',
                      value: bluetooth.power.toStringAsFixed(0),
                      unit: 'W',
                      icon: Icons.flash_on,
                      color: Colors.orange,
                    ),
                    MetricTile(
                      title: 'Cadence',
                      value: bluetooth.cadence.toStringAsFixed(0),
                      unit: 'RPM',
                      icon: Icons.speed,
                      color: Colors.blue,
                    ),
                    MetricTile(
                      title: 'Vitesse',
                      value: bluetooth.speed.toStringAsFixed(1),
                      unit: 'km/h',
                      icon: Icons.directions_bike,
                      color: Colors.green,
                    ),
                    MetricTile(
                      title: 'FC',
                      value: bluetooth.heartRate.toString(),
                      unit: 'BPM',
                      icon: Icons.favorite,
                      color: Colors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Visualisation (Map ou 3D)
                if (widget.route != null) ...[ 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(() => showMap = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: showMap ? Theme.of(context).primaryColor : Colors.grey[300],
                          foregroundColor: showMap ? Colors.white : Colors.black,
                        ),
                        child: const Text('Carte'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => setState(() => showMap = false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !showMap ? Theme.of(context).primaryColor : Colors.grey[300],
                          foregroundColor: !showMap ? Colors.white : Colors.black,
                        ),
                        child: const Text('3D'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (showMap)
                    SizedBox(
                      height: 300,
                      child: RouteMap(
                        route: widget.route!,
                        currentPositionIndex: currentIndex,
                      ),
                    )
                  else
                    SizedBox(
                      height: 300,
                      child: Scene3DView(
                        route: widget.route!,
                        currentPositionIndex: currentIndex,
                      ),
                    ),
                  const SizedBox(height: 24),
                
                  // Profil d'élévation
                  SizedBox(
                    height: 150,
                    child: ElevationProfile(
                      route: widget.route!,
                      currentDistance: (_totalDistance % widget.route!.distance),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.route, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              (_totalDistance / 1000).toStringAsFixed(2),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Text(
                              'km',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(Icons.local_fire_department,
                                color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              '0',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Text(
                              'kcal',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Control Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _toggleRecording,
                        icon: Icon(_isRecording ? Icons.pause : Icons.play_arrow),
                        label: Text(_isRecording ? 'Pause' : 'Démarrer'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(20),
                          backgroundColor: _isRecording ? Colors.orange : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _elapsedSeconds > 0 ? _finishWorkout : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('Terminer'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(20),
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
