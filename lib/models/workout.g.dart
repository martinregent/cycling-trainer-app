// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutAdapter extends TypeAdapter<Workout> {
  @override
  final int typeId = 0;

  @override
  Workout read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Workout(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      duration: fields[2] as double,
      distance: fields[3] as double,
      avgPower: fields[4] as double,
      maxPower: fields[5] as double,
      avgHeartRate: fields[6] as double,
      maxHeartRate: fields[7] as double,
      elevationGain: fields[8] as double,
      calories: fields[9] as double,
      routeId: fields[10] as String?,
      dataPoints: (fields[11] as List).cast<WorkoutDataPoint>(),
    );
  }

  @override
  void write(BinaryWriter writer, Workout obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.duration)
      ..writeByte(3)
      ..write(obj.distance)
      ..writeByte(4)
      ..write(obj.avgPower)
      ..writeByte(5)
      ..write(obj.maxPower)
      ..writeByte(6)
      ..write(obj.avgHeartRate)
      ..writeByte(7)
      ..write(obj.maxHeartRate)
      ..writeByte(8)
      ..write(obj.elevationGain)
      ..writeByte(9)
      ..write(obj.calories)
      ..writeByte(10)
      ..write(obj.routeId)
      ..writeByte(11)
      ..write(obj.dataPoints);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutDataPointAdapter extends TypeAdapter<WorkoutDataPoint> {
  @override
  final int typeId = 1;

  @override
  WorkoutDataPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutDataPoint(
      timestamp: fields[0] as DateTime,
      power: fields[1] as double,
      cadence: fields[2] as double,
      speed: fields[3] as double,
      heartRate: fields[4] as int,
      distance: fields[5] as double,
      elevation: fields[6] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutDataPoint obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.power)
      ..writeByte(2)
      ..write(obj.cadence)
      ..writeByte(3)
      ..write(obj.speed)
      ..writeByte(4)
      ..write(obj.heartRate)
      ..writeByte(5)
      ..write(obj.distance)
      ..writeByte(6)
      ..write(obj.elevation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutDataPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
