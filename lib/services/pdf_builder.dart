// lib/services/pdf_builder.dart
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:visionpos/models/order_dto.dart';
import 'package:visionpos/models/product_model.dart';

Future<Uint8List> buildReceiptPdfBytes(
  OrderDto order,
  List<Product> products, {
  bool is80mm = false, // set per device
}) async {
  // Make sure pubspec.yaml lists this exact asset path
  final fontData =
      await rootBundle.load('lib/assets/fonts/NotoNaskhArabic-Regular.ttf');
  final ttf = pw.Font.ttf(fontData);

  final pageFormat = is80mm ? PdfPageFormat.roll80 : PdfPageFormat.roll57;
  final doc = pw.Document();

  String _fmtQty(double q) =>
      (q.truncateToDouble() == q) ? q.toStringAsFixed(0) : q.toStringAsFixed(2);

  pw.Widget _rtl(String text,
      {double size = 11,
      pw.TextAlign align = pw.TextAlign.left,
      pw.FontWeight? weight}) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(font: ttf, fontSize: size, fontWeight: weight),
      ),
    );
  }

  final byId = {for (final p in products) p.productId: p};

  doc.addPage(
    pw.Page(
      pageFormat: pageFormat,
      margin: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      build: (ctx) {
        final children = <pw.Widget>[];

        // Header
        children.add(_rtl('أبو كاف',
            size: 16, align: pw.TextAlign.center, weight: pw.FontWeight.bold));
        children.add(pw.SizedBox(height: 6));
        children.add(pw.Divider());

        // Items
        for (final it in order.orderItems) {
          final pr = byId[it.productId];
          final name = pr?.productName ?? 'غير معروف';
          final unit = pr?.sellingPrice ?? 0.0;
          final qty = it.quantity;
          final disc = it.discount;
          final lineTotal = (unit * qty) - disc;

          children.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(child: _rtl('$name ×${_fmtQty(qty)}', size: 11)),
                pw.SizedBox(width: 8),
                pw.Text(lineTotal.toStringAsFixed(2),
                    style: pw.TextStyle(font: ttf, fontSize: 11)),
              ],
            ),
          );

          if (disc > 0) {
            children.add(_rtl('خصم: ${disc.toStringAsFixed(2)}',
                size: 9, align: pw.TextAlign.right));
          }
        }

        children.add(pw.SizedBox(height: 4));
        children.add(pw.Divider());

        // Totals
        final grand = order.grandTotal.toDouble();
        final tip = (order.tips != 0.0 ? order.tips : order.tips).toDouble();
        final pm = order.paymentMethod;

        children.add(
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _rtl('الإجمالي', size: 12, weight: pw.FontWeight.bold),
              pw.Text(grand.toStringAsFixed(2),
                  style: pw.TextStyle(
                      font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        );

        if (tip > 0) {
          children.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _rtl('البقشيش', size: 11),
                pw.Text(tip.toStringAsFixed(2),
                    style: pw.TextStyle(font: ttf, fontSize: 11)),
              ],
            ),
          );
        }

        children.add(
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _rtl('طريقة الدفع', size: 11),
              pw.Text(pm.toString(),
                  style: pw.TextStyle(font: ttf, fontSize: 11)),
            ],
          ),
        );

        children.add(pw.SizedBox(height: 6));
        children.add(pw.Divider());
        children.add(pw.SizedBox(height: 6));

        // Footer
        children.add(_rtl('شكرًا لزيارتكم',
            size: 12, align: pw.TextAlign.center, weight: pw.FontWeight.bold));
        children.add(pw.SizedBox(height: 6));
        children.add(
          pw.Text(
            DateTime.now().toString(),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(font: ttf, fontSize: 9),
          ),
        );

        return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: children);
      },
    ),
  );

  return doc.save();
}
