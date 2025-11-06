// lib/components/printer_setup_dialog.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import 'package:visionpos/services/bluetooth_printing_service.dart'
    show BluetoothPrinterManager, SavedPrinter, PrinterRole, PrinterRoleX;

Future<void> showPrinterSetupDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PrinterSetupDialog(),
  );
}

class PrinterSetupDialog extends StatefulWidget {
  const PrinterSetupDialog({super.key});

  @override
  State<PrinterSetupDialog> createState() => _PrinterSetupDialogState();
}

class _PrinterSetupDialogState extends State<PrinterSetupDialog> {
  final _bt = BluetoothPrinterManager();

  // Paired devices from plugin. Structure: {'name': '...', 'macAdress': '...'}
  List<Map<String, dynamic>> _paired = [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  // Local selection map by role → mac address
  final Map<PrinterRole, String?> _selectedMac = {
    PrinterRole.customer: null,
    PrinterRole.falafel: null,
    PrinterRole.shawarmaSnacks: null,
  };

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _bt.load(); // loads saved assignments to _bt.assigned
      await _loadPaired();
      // Prime selections from saved assignments
      for (final role in _selectedMac.keys) {
        final sp = _bt.assigned[role];
        _selectedMac[role] = sp?.mac;
      }
    } catch (e) {
      _error = 'Failed to load printers: $e';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadPaired() async {
    // For classic ESC/POS, "pairedBluetooths" is enough (plugin enumerates paired list)
    final devices = await PrintBluetoothThermal.pairedBluetooths;
    _paired = devices
        .map<Map<String, dynamic>>((d) => {'name': d.name, 'mac': d.macAdress})
        .toList();
  }

  Future<void> _refreshPaired() async {
    setState(() {
      _refreshing = true;
      _error = null;
    });
    try {
      await _loadPaired();
    } catch (e) {
      _error = 'Refresh failed: $e';
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _saveAssignments() async {
    for (final entry in _selectedMac.entries) {
      final role = entry.key;
      final mac = entry.value;
      if (mac == null || mac.isEmpty) {
        await _bt.assign(role, null);
        continue;
      }
      final match =
          _paired.firstWhere((p) => p['mac'] == mac, orElse: () => {});
      if (match.isEmpty) continue;
      final sp = SavedPrinter(name: match['name'] ?? 'Printer', mac: mac);
      await _bt.assign(role, sp);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Printers saved')),
      );
    }
  }

  Future<void> _testPrint(PrinterRole role) async {
    final sp = _bt.assigned[role];
    final mac = _selectedMac[role] ?? sp?.mac;
    if (mac == null || mac.isEmpty) {
      _showSnack('No printer selected for ${role.label}');
      return;
    }
    try {
      // Minimal 80mm English test using esc_pos_utils
      final profile = await CapabilityProfile.load(); // default profile
      final generator = Generator(PaperSize.mm80, profile);
      final bytes = <int>[];
      bytes.addAll(generator.text('--- TEST PRINT ---',
          styles: const PosStyles(
              align: PosAlign.center,
              height: PosTextSize.size2,
              width: PosTextSize.size2)));
      bytes.addAll(generator.hr());
      bytes.addAll(generator.text('Role: ${role.label}',
          styles: const PosStyles(align: PosAlign.left)));
      bytes.addAll(generator.text('Paper: 80mm',
          styles: const PosStyles(align: PosAlign.left)));
      bytes.addAll(generator.text('Language: English',
          styles: const PosStyles(align: PosAlign.left)));
      bytes.addAll(generator.hr());
      bytes.addAll(generator.text('Date: ${DateTime.now()}',
          styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(generator.feed(2));
      // optional "cut" for printers that support it
      try {
        bytes.addAll(generator.cut());
      } catch (_) {}

      // withPrinter will connect, run, then disconnect safely
      final ok = await _bt.withPrinter(role, () async {
        await _bt.writeBytes(Uint8List.fromList(bytes));
      });
      _showSnack(ok
          ? '✅ Test sent to ${role.label}'
          : '⚠️ Failed to print on ${role.label}');
    } catch (e) {
      _showSnack('Error: $e');
    }
  }

  Future<void> _testAll() async {
    await _saveAssignments(); // ensure latest selections are stored
    for (final role in [
      PrinterRole.customer,
      PrinterRole.falafel,
      PrinterRole.shawarmaSnacks
    ]) {
      await _testPrint(role);
      // small pause to avoid rapid reconnects
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.print),
          const SizedBox(width: 8),
          const Text('Printer Setup'),
          const Spacer(),
          IconButton(
            tooltip: 'Refresh paired list',
            onPressed: _refreshing ? null : _refreshPaired,
            icon: _refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 560,
          child: _loading
              ? const Center(
                  child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error != null)
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      ),

                    // Paired devices list as hint
                    _PairedHint(paired: _paired),

                    const Divider(),

                    _RolePicker(
                      title: 'Customer receipt',
                      role: PrinterRole.customer,
                      paired: _paired,
                      value: _selectedMac[PrinterRole.customer],
                      onChanged: (val) {
                        setState(
                            () => _selectedMac[PrinterRole.customer] = val);
                      },
                    ),
                    _TestRow(onTest: () => _testPrint(PrinterRole.customer)),

                    const SizedBox(height: 8),
                    _RolePicker(
                      title: 'Falafel (Category 7)',
                      role: PrinterRole.falafel,
                      paired: _paired,
                      value: _selectedMac[PrinterRole.falafel],
                      onChanged: (val) {
                        setState(() => _selectedMac[PrinterRole.falafel] = val);
                      },
                    ),
                    _TestRow(onTest: () => _testPrint(PrinterRole.falafel)),

                    const SizedBox(height: 8),
                    _RolePicker(
                      title: 'Shawarma & Snacks (Categories 6, 8, 9)',
                      role: PrinterRole.shawarmaSnacks,
                      paired: _paired,
                      value: _selectedMac[PrinterRole.shawarmaSnacks],
                      onChanged: (val) {
                        setState(() =>
                            _selectedMac[PrinterRole.shawarmaSnacks] = val);
                      },
                    ),
                    _TestRow(
                        onTest: () => _testPrint(PrinterRole.shawarmaSnacks)),

                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _bt.isConnected
                            ? 'Status: Connected'
                            : 'Status: Not connected',
                        style: TextStyle(
                          color: _bt.isConnected ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        OutlinedButton.icon(
          onPressed: _testAll,
          icon: const Icon(Icons.print),
          label: const Text('Test all'),
        ),
        ElevatedButton.icon(
          onPressed: _saveAssignments,
          icon: const Icon(Icons.save),
          label: const Text('Save'),
        ),
      ],
    );
  }
}

class _PairedHint extends StatelessWidget {
  final List<Map<String, dynamic>> paired;
  const _PairedHint({required this.paired});

  @override
  Widget build(BuildContext context) {
    if (paired.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'No paired Bluetooth printers found.\n'
          'Pair your ESC/POS printers in device settings, then Refresh.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Paired devices:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: paired
                .map((p) => Chip(
                      label: Text('${p['name']}'),
                      avatar: const Icon(Icons.print, size: 18),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _RolePicker extends StatelessWidget {
  final String title;
  final PrinterRole role;
  final List<Map<String, dynamic>> paired;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _RolePicker({
    required this.title,
    required this.role,
    required this.paired,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = paired
        .map<DropdownMenuItem<String>>((p) => DropdownMenuItem<String>(
              value: p['mac'],
              child: Row(
                children: [
                  const Icon(Icons.print, size: 18, color: Colors.brown),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text('${p['name']}',
                          overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Text(
                    p['mac'] ?? '',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ))
        .toList();

    return Row(
      children: [
        SizedBox(
          width: 210,
          child:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            items: items,
            onChanged: onChanged,
            decoration: const InputDecoration(
              labelText: 'Select printer',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

class _TestRow extends StatelessWidget {
  final VoidCallback onTest;
  const _TestRow({required this.onTest});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onTest,
        icon: const Icon(Icons.print),
        label: const Text('Test'),
      ),
    );
  }
}
