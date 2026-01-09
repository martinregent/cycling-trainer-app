import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../widgets/device_status_card.dart';
import 'device_scanner_screen.dart';
import 'workout_screen.dart';
import 'route_library_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cycling Trainer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeviceScannerScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Device Status Cards
            Consumer<BluetoothProvider>(
              builder: (context, bluetooth, child) {
                return Column(
                  children: [
                    DeviceStatusCard(
                      title: 'Elite Suito',
                      subtitle: bluetooth.connectedTrainer != null
                          ? 'Connecté'
                          : 'Déconnecté',
                      isConnected: bluetooth.connectedTrainer != null,
                      icon: Icons.directions_bike,
                      onTap: () {
                        if (bluetooth.connectedTrainer == null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DeviceScannerScreen(),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DeviceStatusCard(
                      title: 'Whoop 5',
                      subtitle: bluetooth.connectedHeartRate != null
                          ? 'Connecté'
                          : 'Déconnecté',
                      isConnected: bluetooth.connectedHeartRate != null,
                      icon: Icons.favorite,
                      onTap: () {
                        if (bluetooth.connectedHeartRate == null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DeviceScannerScreen(),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Start Workout Button
            Consumer<BluetoothProvider>(
              builder: (context, bluetooth, child) {
                final canStart = bluetooth.connectedTrainer != null;

                return ElevatedButton.icon(
                  onPressed: canStart
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WorkoutScreen(),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Démarrer Entraînement'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Route Library Button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RouteLibraryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('Bibliothèque de Parcours'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),

            const SizedBox(height: 16),

            // History Button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('Historique'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),

            const Spacer(),

            // Recent Workouts Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Séances Récentes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aucune séance enregistrée',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
