import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';

class PrintService {
  static String get printUri => ApiConfig.instance.buildUrl('print');

  static Future<bool> printReceipt(Map<String, dynamic> receiptData) async {
    try {
      final url = Uri.parse('$printUri/receipt');
      final headers = {'Content-Type': 'application/json'};
      final body = json.encode(receiptData);

      final response = await http.post(url, headers: headers, body: body);

      return response.statusCode == 200;
    } catch (e) {
      print('Error printing receipt: $e');
      return false;
    }
  }

  static Future<List<String>> getAvailablePrinters() async {
    try {
      final url = Uri.parse('$printUri/printers');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((printer) => printer.toString()).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching printers: $e');
      return [];
    }
  }

  static Future<bool> testPrint(String printerName) async {
    try {
      final url = Uri.parse('$printUri/test');
      final headers = {'Content-Type': 'application/json'};
      final body = json.encode({'printer': printerName});

      final response = await http.post(url, headers: headers, body: body);

      return response.statusCode == 200;
    } catch (e) {
      print('Error testing printer: $e');
      return false;
    }
  }

  static Future<bool> connectPrinter(String printerName) async {
    try {
      final url = Uri.parse('$printUri/connect');
      final headers = {'Content-Type': 'application/json'};
      final body = json.encode({'printer': printerName});

      final response = await http.post(url, headers: headers, body: body);

      return response.statusCode == 200;
    } catch (e) {
      print('Error connecting to printer: $e');
      return false;
    }
  }

  static Future<bool> disconnectPrinter() async {
    try {
      final url = Uri.parse('$printUri/disconnect');
      final response = await http.post(url);

      return response.statusCode == 200;
    } catch (e) {
      print('Error disconnecting printer: $e');
      return false;
    }
  }

  static String formatReceipt({
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double tax,
    required double total,
    required double tips,
    required String paymentMethod,
    String? promoCode,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('2GO CAFE');
    buffer.writeln('================');
    buffer.writeln('');

    for (var item in items) {
      final name = item['name'] ?? 'Unknown Item';
      final quantity = item['quantity'] ?? 1;
      final price = item['price'] ?? 0.0;
      final lineTotal = quantity * price;

      buffer.writeln('$name x$quantity');
      buffer.writeln(
          '\$${price.toStringAsFixed(2)}    \$${lineTotal.toStringAsFixed(2)}');
    }

    buffer.writeln('');
    buffer.writeln('================');
    buffer.writeln('Subtotal: \$${subtotal.toStringAsFixed(2)}');
    if (promoCode != null) {
      buffer.writeln('Promo: $promoCode');
    }
    buffer.writeln('Tax: \$${tax.toStringAsFixed(2)}');
    buffer.writeln('Tips: \$${tips.toStringAsFixed(2)}');
    buffer.writeln('Total: \$${total.toStringAsFixed(2)}');
    buffer.writeln('');
    buffer.writeln('Payment: $paymentMethod');
    buffer.writeln('');
    buffer.writeln('Thank you for your business!');
    buffer.writeln(DateTime.now().toString());

    return buffer.toString();
  }
}
