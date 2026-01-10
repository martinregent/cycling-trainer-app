import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/workout.dart';
import 'models/gpx_route.dart';
import 'providers/bluetooth_provider.dart';
import 'screens/home_screen.dart';
import 'services/strava/strava_service.dart';
import 'config/strava_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(WorkoutAdapter());
    Hive.registerAdapter(WorkoutDataPointAdapter());
    Hive.registerAdapter(GPXRouteAdapter());
    Hive.registerAdapter(TrackPointAdapter());

    // Open boxes
    await Hive.openBox<Workout>('workouts');
    await Hive.openBox<GPXRoute>('routes');
  } catch (e) {
    debugPrint('Error initializing Hive: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
        // StravaService initialized with credentials from strava_config.dart
        Provider(
          create: (_) => StravaService(
            clientId: StravaConfig.clientId,
            clientSecret: StravaConfig.clientSecret,
          ),
          dispose: (_, service) => service.dispose(),
        ),
      ],
      child: MaterialApp(
        title: 'Cycling Trainer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
