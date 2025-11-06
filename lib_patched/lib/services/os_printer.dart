import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class PlatformPrinter {
  static const _channel = MethodChannel('os_printer');

  /// Prints PDF bytes with OS print framework.
  static Future<void> printPdf(Uint8List pdfBytes,
      {String jobName = 'Receipt'}) async {
    if (Platform.isAndroid) {
      // Write to a temp file and pass the file path to native
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/$jobName-${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(pdfBytes, flush: true);
      await _channel.invokeMethod('printPdf', {
        'path': file.path,
        'jobName': jobName,
      });
    } else if (Platform.isIOS) {
      await _channel.invokeMethod('printPdfBytes', {
        'bytes': pdfBytes,
        'jobName': jobName,
      });
    } else {
      throw UnsupportedError('Printing is only implemented on Android/iOS');
    }
  }
}
