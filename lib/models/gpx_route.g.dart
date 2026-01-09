// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gpx_route.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GPXRouteAdapter extends TypeAdapter<GPXRoute> {
  @override
  final int typeId = 2;

  @override
  GPXRoute read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GPXRoute(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      distance: fields[3] as double,
      elevationGain: fields[4] as double,
      gpxData: fields[5] as String,
      isFavorite: fields[6] as bool,
      createdDate: fields[7] as DateTime,
      trackPoints: (fields[8] as List).cast<TrackPoint>(),
    );
  }

  @override
  void write(BinaryWriter writer, GPXRoute obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.distance)
      ..writeByte(4)
      ..write(obj.elevationGain)
      ..writeByte(5)
      ..write(obj.gpxData)
      ..writeByte(6)
      ..write(obj.isFavorite)
      ..writeByte(7)
      ..write(obj.createdDate)
      ..writeByte(8)
      ..write(obj.trackPoints);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GPXRouteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TrackPointAdapter extends TypeAdapter<TrackPoint> {
  @override
  final int typeId = 3;

  @override
  TrackPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrackPoint(
      latitude: fields[0] as double,
      longitude: fields[1] as double,
      elevation: fields[2] as double,
      distance: fields[3] as double,
      slope: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, TrackPoint obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.elevation)
      ..writeByte(3)
      ..write(obj.distance)
      ..writeByte(4)
      ..write(obj.slope);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
