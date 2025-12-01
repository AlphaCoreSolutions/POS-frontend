import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
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

/// Manages 3 paired Bluetooth ESC/POS printers (blue_thermal_printer).
class BluetoothPrinterManager with ChangeNotifier {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

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

  /// Paired devices (BluetoothDevice).
  Future<List<BluetoothDevice>> bondedDevices() async {
    return await _bluetooth.getBondedDevices();
  }

  /// Connect to a MAC address with retry logic.
  Future<bool> connect(String macAddress, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint(
            '🔌 Connection attempt $attempt/$maxRetries for $macAddress');

        // Check if already connected
        _isConnected = (await _bluetooth.isConnected) ?? false;
        if (_isConnected) {
          debugPrint('⚠️ Already connected, disconnecting first...');
          await _bluetooth.disconnect();
          await Future.delayed(const Duration(milliseconds: 500));
        }

        // Get bonded devices
        final devices = await _bluetooth.getBondedDevices();
        final device = devices.firstWhere(
          (d) => d.address == macAddress,
          orElse: () => throw Exception(
              'Printer $macAddress not found in paired devices'),
        );

        debugPrint(
            '📡 Attempting to connect to ${device.name} ($macAddress)...');

        // Connect with timeout
        await _bluetooth.connect(device).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException('Connection timeout');
          },
        );

        // Wait for connection to stabilize
        await Future.delayed(const Duration(milliseconds: 500));

        _isConnected = (await _bluetooth.isConnected) ?? false;

        if (_isConnected) {
          debugPrint('✅ Connected successfully on attempt $attempt');
          notifyListeners();
          return true;
        } else {
          debugPrint('⚠️ Connection status false on attempt $attempt');
          if (attempt < maxRetries) {
            debugPrint('🔄 Retrying in 1 second...');
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      } catch (e) {
        debugPrint('❌ Connection attempt $attempt failed: $e');
        if (attempt < maxRetries) {
          debugPrint('🔄 Retrying in 1 second...');
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    _isConnected = false;
    notifyListeners();
    debugPrint('❌ All connection attempts failed for $macAddress');
    return false;
  }

  Future<void> disconnect() async {
    try {
      await _bluetooth.disconnect();
    } catch (e) {
      debugPrint('BT disconnect error: $e');
    } finally {
      _isConnected = false;
      notifyListeners();
    }
  }

  /// Send raw bytes to a connected printer.
  /// Enhanced for multi-printer Arabic printing reliability.
  Future<void> writeBytes(Uint8List bytes) async {
    debugPrint('📤 Starting writeBytes: ${bytes.length} bytes total');

    // Convert to List<int>
    final list = bytes.toList(growable: false);

    const chunkSize = 256;
    const interChunkDelayMs = 30;

    final totalChunks = (list.length / chunkSize).ceil();
    debugPrint('📤 Sending $totalChunks chunks...');

    for (int i = 0; i < list.length; i += chunkSize) {
      final end = math.min(i + chunkSize, list.length);
      final chunk = list.sublist(i, end);
      final chunkNumber = (i / chunkSize).floor() + 1;

      await _bluetooth.writeBytes(Uint8List.fromList(chunk));
      debugPrint(
          '📤 Chunk $chunkNumber/$totalChunks sent (${chunk.length} bytes)');

      await Future.delayed(const Duration(milliseconds: interChunkDelayMs));
    }

    // Buffer flush delay - critical for Arabic raster images
    final flushDelayMs = math.min(800 + (list.length ~/ 80), 4000);
    debugPrint('📤 Waiting ${flushDelayMs}ms for printer buffer to flush...');
    await Future.delayed(Duration(milliseconds: flushDelayMs));

    debugPrint('✅ writeBytes completed successfully');
  }

  SavedPrinter? getForRole(PrinterRole role) => _assigned[role];

  /// Connects to role's printer, runs the callback, then disconnects.
  /// Enhanced timing for multi-printer Arabic printing reliability.
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

    // Increased settle time before connect (especially when chaining printers)
    await Future.delayed(const Duration(milliseconds: 500));

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
      // Increased for Arabic raster images which need more processing
      debugPrint('⏳ Waiting for ${role.label} printer to finish printing...');
      await Future.delayed(const Duration(milliseconds: 1200));
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

      // Increased delay to avoid rapid reconnect to next printer
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}
