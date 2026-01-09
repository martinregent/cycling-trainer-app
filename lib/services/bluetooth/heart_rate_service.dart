import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Heart Rate Service implementation for Whoop 5
/// Handles Heart Rate Measurement characteristic (0x2A37)
class HeartRateService {
  final BluetoothService service;

  // Characteristics
  BluetoothCharacteristic? _heartRateMeasurementChar;

  // Streams for metrics
  final _heartRateController = StreamController<int>.broadcast();
  final _rrIntervalsController = StreamController<List<double>>.broadcast();

  Stream<int> get heartRateStream => _heartRateController.stream;
  Stream<List<double>> get rrIntervalsStream => _rrIntervalsController.stream;

  HeartRateService(this.service);

  /// Initialize Heart Rate service and subscribe to notifications
  Future<void> initialize() async {
    // Find Heart Rate Measurement characteristic
    for (var characteristic in service.characteristics) {
      if (characteristic.uuid == Guid("2A37")) {
        _heartRateMeasurementChar = characteristic;
        break;
      }
    }

    if (_heartRateMeasurementChar == null) {
      throw Exception('Heart Rate Measurement characteristic not found');
    }

    // Enable notifications
    await _heartRateMeasurementChar!.setNotifyValue(true);

    // Listen to data
    _heartRateMeasurementChar!.lastValueStream.listen(_parseHeartRateData);
  }

  /// Parse Heart Rate Measurement according to BLE Heart Rate Service spec
  void _parseHeartRateData(List<int> data) {
    if (data.isEmpty) return;

    try {
      final bytes = Uint8List.fromList(data);
      final buffer = ByteData.sublistView(bytes);

      // Flags (1 byte)
      final flags = buffer.getUint8(0);
      int offset = 1;

      // Heart Rate Value
      int heartRate;
      if (flags & 0x01 == 0) {
        // Format: UINT8
        heartRate = buffer.getUint8(offset);
        offset += 1;
      } else {
        // Format: UINT16
        heartRate = buffer.getUint16(offset, Endian.little);
        offset += 2;
      }

      _heartRateController.add(heartRate);

      // Energy Expended (bit 3) - skip if present
      if (flags & 0x08 != 0) {
        offset += 2;
      }

      // RR-Intervals (bit 4) - for HRV analysis
      if (flags & 0x10 != 0) {
        List<double> rrIntervals = [];

        while (offset + 2 <= data.length) {
          final rrRaw = buffer.getUint16(offset, Endian.little);
          // Resolution: 1/1024 seconds, convert to milliseconds
          final rrMs = (rrRaw / 1024.0) * 1000.0;
          rrIntervals.add(rrMs);
          offset += 2;
        }

        if (rrIntervals.isNotEmpty) {
          _rrIntervalsController.add(rrIntervals);
        }
      }

      debugPrint('Heart Rate: $heartRate BPM');
    } catch (e) {
      debugPrint('Error parsing Heart Rate data: $e');
    }
  }

  void dispose() {
    _heartRateController.close();
    _rrIntervalsController.close();
  }
}
