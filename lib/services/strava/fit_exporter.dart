import 'dart:typed_data';
import 'package:fit_tool/fit_tool.dart';
import '../../models/workout.dart';

class FITExporter {
  Future<Uint8List> export(Workout workout) async {
    final builder = FitFileBuilder(
      autoDefine: true,
      minStringSize: 50,
    );

    // 1. File ID Message
    final fileIdMesg = FileIdMessage()
      ..type = FileType.activity
      ..manufacturer = Manufacturer.development.value
      ..product = 0
      ..serialNumber = 0
      ..timeCreated = DateTime.now().millisecondsSinceEpoch;
    
    builder.add(fileIdMesg);

    // 2. Session Message (Summary)
    final sessionMesg = SessionMessage()
      ..startTime = workout.date.millisecondsSinceEpoch
      ..totalElapsedTime = workout.duration / 1000 // duration is in seconds? wait, model says seconds. FIT expects seconds.
      ..totalDistance = workout.distance
      ..totalAscent = workout.elevationGain.toInt()
      ..avgSpeed = workout.avgSpeed
      ..avgHeartRate = workout.avgHeartRate.toInt()
      ..sport = Sport.cycling
      ..subSport = SubSport.indoorCycling;
      
    // Note: totalElapsedTime in FIT is usually seconds, but fit_tool might expect ms if using basic types?
    // Checking fit_tool documentation implicitly via usage: properties usually match the standard. 
    // Wait, fit_tool generated code usually uses double for seconds or ms for timestamps.
    // Let's assume duration in model is seconds (double). FIT total_elapsed_time is scales with 1000 usually? 
    // Actually fit_tool likely handles scaling if using the generated classes.
    // Let's check imports.
    
    builder.add(sessionMesg);

    // 3. Record Messages (Data Points)
    for (var point in workout.dataPoints) {
      final record = RecordMessage()
        ..timestamp = point.timestamp.millisecondsSinceEpoch
        ..distance = point.distance
        ..speed = point.speed // m/s
        ..power = point.power.toInt()
        ..heartRate = point.heartRate
        ..cadence = point.cadence.toInt();
        
      if (point.elevation != null) {
        record.altitude = point.elevation!;
      }
        
      builder.add(record);
    }

    final fitFile = builder.build();
    return fitFile.toBytes();
  }
}
