import 'package:hive_flutter/hive_flutter.dart';
import '../models/workout.dart';

class WorkoutRepository {
  static const String _boxName = 'workouts';

  Future<Box<Workout>> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<Workout>(_boxName);
    }
    return await Hive.openBox<Workout>(_boxName);
  }

  // Use this to get the box synchronously if you are sure it's open (e.g. in main.dart)
  Box<Workout> getBox() {
    return Hive.box<Workout>(_boxName);
  }

  Future<void> saveWorkout(Workout workout) async {
    final box = await _getBox();
    await box.put(workout.id, workout);
  }

  Future<void> deleteWorkout(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  Future<List<Workout>> getAllWorkouts() async {
    final box = await _getBox();
    // Sort by date descending
    final workouts = box.values.toList();
    workouts.sort((a, b) => b.date.compareTo(a.date));
    return workouts;
  }

  Future<Workout?> getWorkout(String id) async {
    final box = await _getBox();
    return box.get(id);
  }
  
  // Method to clear all workouts - mostly for debugging
  Future<void> clearAll() async {
    final box = await _getBox();
    await box.clear();
  }
}
