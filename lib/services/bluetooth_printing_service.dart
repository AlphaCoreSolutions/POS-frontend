import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Roles for the three printers in the shop.
enum PrinterRole { customer, falafel, shawarmaSnacks }

extension PrinterRoleX on PrinterRole {
  String get key => toString().split('.').last;
  String get label {
    switch (this) {
      case PrinterRole.customer:
        return 'Customer';
      case PrinterRole.falafel:
        return 'Falafel Kitchen';
      case PrinterRole.shawarmaSnacks:
        return 'Shawarma & Snacks Kitchen';
    }
  }
}

/// Lightweight model for a saved Bluetooth printer.
class SavedPrinter {
  final String name;
  final String mac;

  const SavedPrinter({required this.name, required this.mac});

  Map<String, String> toJson() => {'name': name, 'mac': mac};

  factory SavedPrinter.fromJson(Map<String, dynamic> json) =>
      SavedPrinter(name: json['name'] as String, mac: json['mac'] as String);
}

/// Manages 3 paired Bluetooth ESC/POS printers (print_bluetooth_thermal).
class BluetoothPrinterManager with ChangeNotifier {
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Saved printer assignments by role.
  final Map<PrinterRole, SavedPrinter?> _assigned = {
    PrinterRole.customer: null,
    PrinterRole.falafel: null,
    PrinterRole.shawarmaSnacks: null,
  };

  Map<PrinterRole, SavedPrinter?> get assigned => Map.unmodifiable(_assigned);

  /// Load saved printers from SharedPreferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final role in PrinterRole.values) {
      final raw = prefs.getString('printer_${role.key}');
      if (raw != null) {
        final parts = raw.split('|');
        if (parts.length >= 2) {
          _assigned[role] = SavedPrinter(name: parts[0], mac: parts[1]);
        }
      }
    }
    notifyListeners();
  }

  /// Save assignment.
  Future<void> assign(PrinterRole role, SavedPrinter? p) async {
    final prefs = await SharedPreferences.getInstance();
    if (p == null) {
      await prefs.remove('printer_${role.key}');
    } else {
      await prefs.setString('printer_${role.key}', '${p.name}|${p.mac}');
    }
    _assigned[role] = p;
    notifyListeners();
  }

  /// Paired devices (BluetoothInfo).
  Future<List<BluetoothInfo>> bondedDevices() async {
    return await PrintBluetoothThermal.pairedBluetooths;
  }

  /// Connect to a MAC address.
  Future<bool> connect(String macAddress) async {
    try {
      _isConnected = await PrintBluetoothThermal.connectionStatus;
      if (_isConnected) {
        await PrintBluetoothThermal.disconnect;
      }

      final devices = await PrintBluetoothThermal.pairedBluetooths;
      final match = devices.firstWhere(
        (d) => (d.macAdress) == macAddress,
      );
      if ((match.macAdress).isEmpty) return false;

      await PrintBluetoothThermal.connect(macPrinterAddress: match.macAdress);
      _isConnected = await PrintBluetoothThermal.connectionStatus;
      notifyListeners();
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      notifyListeners();
      debugPrint('BT connect error: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (e) {
      debugPrint('BT disconnect error: $e');
    } finally {
      _isConnected = false;
      notifyListeners();
    }
  }

  /// Send raw bytes to a connected printer.
  /// Some plugin versions expect List<int> over the channel (not Uint8List).
  /// We also chunk to avoid BT buffer overflows.
  /// Send raw bytes to a connected printer, throttled for BT SPP stability.
  Future<void> writeBytes(Uint8List bytes) async {
    debugPrint('📤 Starting writeBytes: ${bytes.length} bytes total');

    // Init printer (ESC @)
    final init = <int>[0x1B, 0x40];
    await _sendList(init);
    await Future.delayed(
        const Duration(milliseconds: 50)); // Allow init to process

    final list = bytes.toList(growable: false);

    const chunkSize = 256; // 128–512 is typical; 256 is a safe middle
    const interChunkDelayMs = 20; // 10–30ms often works best

    final totalChunks = (list.length / chunkSize).ceil();
    debugPrint('📤 Sending $totalChunks chunks...');

    for (int i = 0; i < list.length; i += chunkSize) {
      final end = math.min(i + chunkSize, list.length);
      final chunk = list.sublist(i, end);
      final chunkNumber = (i / chunkSize).floor() + 1;

      await _sendList(chunk);
      debugPrint(
          '📤 Chunk $chunkNumber/$totalChunks sent (${chunk.length} bytes)');

      await Future.delayed(const Duration(milliseconds: interChunkDelayMs));
    }

    // Feed and ensure printer processes the data
    await _sendList(List<int>.filled(4, 0x0A));

    // Critical: Wait for printer buffer to flush completely
    // Calculate dynamic delay based on data size (more data = more time needed)
    final flushDelayMs = math.min(500 + (list.length ~/ 100), 3000);
    debugPrint('📤 Waiting ${flushDelayMs}ms for printer buffer to flush...');
    await Future.delayed(Duration(milliseconds: flushDelayMs));

    debugPrint('✅ writeBytes completed successfully');
  }

  Future<void> _sendList(List<int> data) async {
    // Try positional call, then named param fallback (covers plugin variations)
    try {
      await PrintBluetoothThermal.writeBytes(data);
    } catch (_) {}
  }

  SavedPrinter? getForRole(PrinterRole role) => _assigned[role];

  /// Connects to role's printer, runs the callback, then disconnects.
  Future<bool> withPrinter(
    PrinterRole role,
    FutureOr<void> Function() action,
  ) async {
    final target = _assigned[role];
    if (target == null) {
      debugPrint('⚠️ No printer assigned for role: ${role.label}');
      return false;
    }

    debugPrint(
        '🔌 Connecting to ${role.label} printer (MAC: ${target.mac})...');

    // small settle time before connect (especially when chaining printers)
    await Future.delayed(const Duration(milliseconds: 150));

    final ok = await connect(target.mac);
    if (!ok) {
      debugPrint('❌ Failed to connect to ${role.label} printer');
      return false;
    }

    debugPrint('✅ Connected to ${role.label} printer');

    try {
      debugPrint('🖨️ Executing print action for ${role.label}...');
      await action();
      debugPrint('✅ Print action completed for ${role.label}');

      // CRITICAL: Additional wait to ensure printer finishes printing
      // The writeBytes method already waits, but add safety margin
      debugPrint('⏳ Waiting for ${role.label} printer to finish printing...');
      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint('✅ ${role.label} printer should have completed printing');

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ BT action error for ${role.label}: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    } finally {
      debugPrint('🔌 Disconnecting from ${role.label} printer...');
      await disconnect();
      debugPrint('✅ Disconnected from ${role.label} printer');

      // Avoid rapid reconnect to next printer
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }
}
