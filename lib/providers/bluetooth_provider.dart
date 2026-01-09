import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/bluetooth/ftms_service.dart';
import '../services/bluetooth/heart_rate_service.dart';

class BluetoothProvider extends ChangeNotifier {
  // Discovered devices
  List<ScanResult> _discoveredDevices = [];
  List<ScanResult> get discoveredDevices => _discoveredDevices;

  // Connected devices
  BluetoothDevice? _connectedTrainer;
  BluetoothDevice? _connectedHeartRate;

  BluetoothDevice? get connectedTrainer => _connectedTrainer;
  BluetoothDevice? get connectedHeartRate => _connectedHeartRate;

  // Services
  FTMSService? _ftmsService;
  HeartRateService? _heartRateService;

  FTMSService? get ftmsService => _ftmsService;
  HeartRateService? get heartRateService => _heartRateService;

  // Metrics from devices
  double _power = 0;
  double _cadence = 0;
  double _speed = 0;
  int _heartRate = 0;

  double get power => _power;
  double get cadence => _cadence;
  double get speed => _speed;
  int get heartRate => _heartRate;

  // Scanning state
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  // Bluetooth state
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  BluetoothAdapterState get adapterState => _adapterState;

  BluetoothProvider() {
    _init();
  }

  void _init() {
    // Listen to Bluetooth adapter state
    FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      notifyListeners();
    });
  }

  /// Start scanning for BLE devices
  Future<void> startScan() async {
    if (_isScanning) return;

    _discoveredDevices.clear();
    _isScanning = true;
    notifyListeners();

    try {
      // Start scanning with FTMS and Heart Rate service UUIDs
      await FlutterBluePlus.startScan(
        withServices: [
          Guid("1826"), // FTMS
          Guid("180D"), // Heart Rate
        ],
        timeout: const Duration(seconds: 15),
      );

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        _discoveredDevices = results;
        notifyListeners();
      });

      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 15));
      await stopScan();
    } catch (e) {
      debugPrint('Error scanning: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  /// Connect to a trainer (FTMS device)
  Future<void> connectToTrainer(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedTrainer = device;

      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      // Find FTMS service
      for (var service in services) {
        if (service.uuid == Guid("1826")) {
          _ftmsService = FTMSService(service);
          await _ftmsService!.initialize();

          // Listen to metrics
          _ftmsService!.powerStream.listen((value) {
            _power = value;
            notifyListeners();
          });

          _ftmsService!.cadenceStream.listen((value) {
            _cadence = value;
            notifyListeners();
          });

          _ftmsService!.speedStream.listen((value) {
            _speed = value;
            notifyListeners();
          });

          break;
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error connecting to trainer: $e');
      rethrow;
    }
  }

  /// Connect to heart rate monitor
  Future<void> connectToHeartRate(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedHeartRate = device;

      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      // Find Heart Rate service
      for (var service in services) {
        if (service.uuid == Guid("180D")) {
          _heartRateService = HeartRateService(service);
          await _heartRateService!.initialize();

          // Listen to heart rate
          _heartRateService!.heartRateStream.listen((value) {
            _heartRate = value;
            notifyListeners();
          });

          break;
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error connecting to heart rate monitor: $e');
      rethrow;
    }
  }

  /// Disconnect from trainer
  Future<void> disconnectTrainer() async {
    if (_connectedTrainer != null) {
      await _connectedTrainer!.disconnect();
      _connectedTrainer = null;
      _ftmsService = null;
      _power = 0;
      _cadence = 0;
      _speed = 0;
      notifyListeners();
    }
  }

  /// Disconnect from heart rate monitor
  Future<void> disconnectHeartRate() async {
    if (_connectedHeartRate != null) {
      await _connectedHeartRate!.disconnect();
      _connectedHeartRate = null;
      _heartRateService = null;
      _heartRate = 0;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disconnectTrainer();
    disconnectHeartRate();
    super.dispose();
  }
}
