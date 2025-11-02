import 'package:flutter/material.dart';

class PrinterSection extends StatelessWidget {
  final bool connected;
  final Function() onShowPrinterDialog;

  const PrinterSection({
    super.key,
    required this.connected,
    required this.onShowPrinterDialog,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onShowPrinterDialog,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(24, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Icon(
        Icons.print,
        size: 15,
        color: const Color(0xFFB87333),
      ),
    );
  }
}
