import 'package:hive/hive.dart';

part 'workout.g.dart';

@HiveType(typeId: 0)
class Workout extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  double duration; // seconds

  @HiveField(3)
  double distance; // meters

  @HiveField(4)
  double avgPower;

  @HiveField(5)
  double maxPower;

  @HiveField(6)
  double avgHeartRate;

  @HiveField(7)
  double maxHeartRate;

  @HiveField(8)
  double elevationGain; // meters

  @HiveField(9)
  double calories;

  @HiveField(10)
  String? routeId; // Reference to GPXRoute

  @HiveField(11)
  List<WorkoutDataPoint> dataPoints;

  Workout({
    required this.id,
    required this.date,
    required this.duration,
    required this.distance,
    this.avgPower = 0,
    this.maxPower = 0,
    this.avgHeartRate = 0,
    this.maxHeartRate = 0,
    this.elevationGain = 0,
    this.calories = 0,
    this.routeId,
    this.dataPoints = const [],
  });

  String get formattedDuration {
    final hours = (duration / 3600).floor();
    final minutes = ((duration % 3600) / 60).floor();
    final seconds = (duration % 60).floor();
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get avgSpeed {
    if (duration == 0) return 0;
    return (distance / duration) * 3.6; // m/s to km/h
  }
}

@HiveType(typeId: 1)
class WorkoutDataPoint {
  @HiveField(0)
  DateTime timestamp;

  @HiveField(1)
  double power;

  @HiveField(2)
  double cadence;

  @HiveField(3)
  double speed;

  @HiveField(4)
  int heartRate;

  @HiveField(5)
  double distance;

  @HiveField(6)
  double? elevation;

  WorkoutDataPoint({
    required this.timestamp,
    required this.power,
    required this.cadence,
    required this.speed,
    required this.heartRate,
    required this.distance,
    this.elevation,
  });
}
