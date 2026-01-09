import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// FTMS (Fitness Machine Service) implementation for Elite Suito
/// Handles Indoor Bike Data characteristic (0x2AD2)
class FTMSService {
  final BluetoothService service;

  // Characteristics
  BluetoothCharacteristic? _indoorBikeDataChar;
  BluetoothCharacteristic? _controlPointChar;

  // Streams for metrics
  final _powerController = StreamController<double>.broadcast();
  final _cadenceController = StreamController<double>.broadcast();
  final _speedController = StreamController<double>.broadcast();
  final _distanceController = StreamController<double>.broadcast();

  Stream<double> get powerStream => _powerController.stream;
  Stream<double> get cadenceStream => _cadenceController.stream;
  Stream<double> get speedStream => _speedController.stream;
  Stream<double> get distanceStream => _distanceController.stream;

  FTMSService(this.service);

  /// Initialize FTMS service and subscribe to notifications
  Future<void> initialize() async {
    // Find Indoor Bike Data characteristic
    for (var characteristic in service.characteristics) {
      if (characteristic.uuid == Guid("2AD2")) {
        _indoorBikeDataChar = characteristic;
      } else if (characteristic.uuid == Guid("2AD9")) {
        _controlPointChar = characteristic;
      }
    }

    if (_indoorBikeDataChar == null) {
      throw Exception('Indoor Bike Data characteristic not found');
    }

    // Enable notifications
    await _indoorBikeDataChar!.setNotifyValue(true);

    // Listen to data
    _indoorBikeDataChar!.lastValueStream.listen(_parseIndoorBikeData);
  }

  /// Parse Indoor Bike Data according to FTMS specification
  void _parseIndoorBikeData(List<int> data) {
    if (data.length < 2) return;

    try {
      final bytes = Uint8List.fromList(data);
      final buffer = ByteData.sublistView(bytes);

      // Flags (2 bytes)
      final flags = buffer.getUint16(0, Endian.little);
      int offset = 2;

      // Speed (bit 0) - uint16, resolution 0.01 km/h
      if (flags & 0x0001 != 0 && offset + 2 <= data.length) {
        final speedRaw = buffer.getUint16(offset, Endian.little);
        final speed = speedRaw / 100.0;
        _speedController.add(speed);
        offset += 2;
      }

      // Average Speed (bit 1) - skip if present
      if (flags & 0x0002 != 0) {
        offset += 2;
      }

      // Cadence (bit 2) - uint16, resolution 0.5 RPM
      if (flags & 0x0004 != 0 && offset + 2 <= data.length) {
        final cadenceRaw = buffer.getUint16(offset, Endian.little);
        final cadence = cadenceRaw / 2.0;
        _cadenceController.add(cadence);
        offset += 2;
      }

      // Average Cadence (bit 3) - skip if present
      if (flags & 0x0008 != 0) {
        offset += 2;
      }

      // Total Distance (bit 4) - uint24 (3 bytes), resolution 1 meter
      if (flags & 0x0010 != 0 && offset + 3 <= data.length) {
        final distanceRaw = buffer.getUint8(offset) |
            (buffer.getUint8(offset + 1) << 8) |
            (buffer.getUint8(offset + 2) << 16);
        final distance = distanceRaw.toDouble();
        _distanceController.add(distance);
        offset += 3;
      }

      // Resistance Level (bit 5) - skip if present
      if (flags & 0x0020 != 0) {
        offset += 2;
      }

      // Instantaneous Power (bit 6) - sint16, resolution 1 watt
      if (flags & 0x0040 != 0 && offset + 2 <= data.length) {
        final powerRaw = buffer.getInt16(offset, Endian.little);
        final power = powerRaw.toDouble();
        _powerController.add(power);
        offset += 2;
      }

      // Average Power (bit 7) - skip if present
      if (flags & 0x0080 != 0) {
        offset += 2;
      }

      debugPrint(
          'FTMS Data - Speed: ${_speedController.hasListener ? "streaming" : "no listener"}, '
          'Cadence: ${_cadenceController.hasListener ? "streaming" : "no listener"}, '
          'Power: ${_powerController.hasListener ? "streaming" : "no listener"}');
    } catch (e) {
      debugPrint('Error parsing FTMS data: $e');
    }
  }

  /// Set resistance level (0-100%)
  Future<void> setResistance(double resistancePercent) async {
    if (_controlPointChar == null) return;

    // OpCode 0x04 = Set Target Resistance Level
    // Parameter: uint8 (0-100)
    final command = Uint8List.fromList([
      0x04,
      resistancePercent.clamp(0, 100).toInt(),
    ]);

    await _controlPointChar!.write(command.toList());
  }

  /// Set target power (watts)
  Future<void> setTargetPower(int watts) async {
    if (_controlPointChar == null) return;

    // OpCode 0x05 = Set Target Power
    // Parameter: sint16 (watts)
    final buffer = ByteData(3);
    buffer.setUint8(0, 0x05);
    buffer.setInt16(1, watts, Endian.little);

    await _controlPointChar!.write(buffer.buffer.asUint8List().toList());
  }

  void dispose() {
    _powerController.close();
    _cadenceController.close();
    _speedController.close();
    _distanceController.close();
  }
}
