import 'package:hive/hive.dart';

part 'gpx_route.g.dart';

@HiveType(typeId: 2)
class GPXRoute extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  double distance; // meters

  @HiveField(4)
  double elevationGain; // meters

  @HiveField(5)
  String gpxData; // XML content

  @HiveField(6)
  bool isFavorite;

  @HiveField(7)
  DateTime createdDate;

  @HiveField(8)
  List<TrackPoint> trackPoints;

  GPXRoute({
    required this.id,
    required this.name,
    this.description,
    required this.distance,
    required this.elevationGain,
    required this.gpxData,
    this.isFavorite = false,
    required this.createdDate,
    this.trackPoints = const [],
  });
}

@HiveType(typeId: 3)
class TrackPoint {
  @HiveField(0)
  double latitude;

  @HiveField(1)
  double longitude;

  @HiveField(2)
  double elevation;

  @HiveField(3)
  double distance; // cumulative distance in meters

  @HiveField(4)
  double slope; // percentage

  TrackPoint({
    required this.latitude,
    required this.longitude,
    required this.elevation,
    required this.distance,
    required this.slope,
  });
}
