import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceScannerScreen extends StatefulWidget {
  const DeviceScannerScreen({super.key});

  @override
  State<DeviceScannerScreen> createState() => _DeviceScannerScreenState();
}

class _DeviceScannerScreenState extends State<DeviceScannerScreen> {
  @override
  void initState() {
    super.initState();
    // Start scanning when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BluetoothProvider>().startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner Périphériques'),
        actions: [
          Consumer<BluetoothProvider>(
            builder: (context, bluetooth, child) {
              return IconButton(
                icon: Icon(
                  bluetooth.isScanning ? Icons.stop : Icons.refresh,
                ),
                onPressed: () {
                  if (bluetooth.isScanning) {
                    bluetooth.stopScan();
                  } else {
                    bluetooth.startScan();
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<BluetoothProvider>(
        builder: (context, bluetooth, child) {
          if (bluetooth.adapterState != BluetoothAdapterState.on) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bluetooth_disabled, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Bluetooth désactivé',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('Veuillez activer le Bluetooth'),
                ],
              ),
            );
          }

          if (bluetooth.isScanning && bluetooth.discoveredDevices.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Recherche de périphériques...'),
                ],
              ),
            );
          }

          if (bluetooth.discoveredDevices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bluetooth_searching, size: 64),
                  const SizedBox(height: 16),
                  const Text('Aucun périphérique trouvé'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => bluetooth.startScan(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Rechercher'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: bluetooth.discoveredDevices.length,
            itemBuilder: (context, index) {
              final result = bluetooth.discoveredDevices[index];
              final device = result.device;
              final deviceName = device.platformName.isNotEmpty
                  ? device.platformName
                  : 'Périphérique Inconnu';

              // Determine device type
              final isFTMS = result.advertisementData.serviceUuids
                  .any((uuid) => uuid.toString().contains('1826'));
              final isHeartRate = result.advertisementData.serviceUuids
                  .any((uuid) => uuid.toString().contains('180d'));

              String deviceType = 'Inconnu';
              IconData icon = Icons.bluetooth;

              if (isFTMS) {
                deviceType = 'Home Trainer (FTMS)';
                icon = Icons.directions_bike;
              } else if (isHeartRate) {
                deviceType = 'Capteur Cardiaque';
                icon = Icons.favorite;
              }

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  leading: Icon(icon, size: 32),
                  title: Text(deviceName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(deviceType),
                      Text(
                        'RSSI: ${result.rssi} dBm',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      
                      try {
                        if (isFTMS) {
                          await bluetooth.connectToTrainer(device);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Home trainer connecté'),
                            ),
                          );
                        } else if (isHeartRate) {
                          await bluetooth.connectToHeartRate(device);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Capteur cardiaque connecté'),
                            ),
                          );
                        }

                        if (navigator.mounted) {
                          navigator.pop();
                        }
                      } catch (e) {
                         messenger.showSnackBar(
                            SnackBar(
                              content: Text('Erreur de connexion: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                      }
                    },
                    child: const Text('Connecter'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    context.read<BluetoothProvider>().stopScan();
    super.dispose();
  }
}
