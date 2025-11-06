import 'dart:async';
import 'package:flutter/material.dart';

class BarcodeService {
  static Future<String?> scanBarcode(BuildContext context) async {
    // This would integrate with a barcode scanning plugin
    // For now, return a mock implementation
    try {
      // Show a dialog for manual barcode entry
      final result = await showDialog<String>(
        context: context,
        builder: (context) => BarcodeInputDialog(),
      );
      return result;
    } catch (e) {
      print('Error scanning barcode: $e');
      return null;
    }
  }

  static Future<bool> validateBarcode(String barcode) async {
    // Basic validation - check if barcode is not empty and has reasonable length
    return barcode.isNotEmpty && barcode.length >= 8;
  }

  static Future<Map<String, dynamic>?> lookupProductByBarcode(
      String barcode) async {
    // This would make an API call to lookup product by barcode
    // For now, return null to indicate not found
    try {
      // Mock implementation - in real app, this would call an API
      return null;
    } catch (e) {
      print('Error looking up product by barcode: $e');
      return null;
    }
  }

  static Widget generateQRCode(String data, {double size = 200}) {
    // Placeholder for QR code generation
    // In a real implementation, you would use qr_flutter package
    return Container(
      width: size,
      height: size,
      color: Colors.grey[300],
      child: Center(
        child: Text('QR Code\n$data'),
      ),
    );
  }

  static String generateBarcodeData({
    required int productId,
    required String productName,
    required double price,
  }) {
    // Generate a simple barcode data string
    return 'PRD-$productId-$productName-$price';
  }
}

class BarcodeInputDialog extends StatefulWidget {
  const BarcodeInputDialog({super.key});

  @override
  _BarcodeInputDialogState createState() => _BarcodeInputDialogState();
}

class _BarcodeInputDialogState extends State<BarcodeInputDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter Barcode'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Scan or enter barcode manually',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text('OK'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
