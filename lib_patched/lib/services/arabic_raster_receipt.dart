// lib/services/arabic_raster_receipt.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:esc_pos_utils/esc_pos_utils.dart';

class ArabicRasterReceipt {
  final PaperSize paper;
  final CapabilityProfile profile;
  final int widthPx; // ~384 for 58mm, ~576 for 80mm
  final String fontFamily; // 'NotoNaskhArabic'

  ArabicRasterReceipt({
    required this.paper,
    required this.profile,
    required this.widthPx,
    required this.fontFamily,
  });

  /// Builds a receipt from blocks of text. Arabic lines use RTL rendering.
  Future<Uint8List> build({
    required List<_Block> blocks,
    bool feedAndCut = true,
  }) async {
    final gen = Generator(paper, profile);
    final List<int> bytes = [];

    for (final block in blocks) {
      final uiImg = await _renderParagraph(
        text: block.text,
        fontSize: block.fontSize,
        bold: block.bold,
        align: block.align,
        isRtl: block.isRtl,
      );

      final pngBytes = await uiImg.toByteData(format: ui.ImageByteFormat.png);
      if (pngBytes == null) continue;

      final decoded = img.decodePng(pngBytes.buffer.asUint8List());
      if (decoded == null) continue;

      bytes.addAll(gen.imageRaster(decoded, align: _toPosAlign(block.align)));
    }

    if (feedAndCut) {
      bytes.addAll(gen.feed(2));
      bytes.addAll(gen.cut());
    }

    return Uint8List.fromList(bytes);
  }

  PosAlign _toPosAlign(TextAlign a) {
    switch (a) {
      case TextAlign.center:
        return PosAlign.center;
      case TextAlign.right:
        return PosAlign.right;
      case TextAlign.left:
      default:
        return PosAlign.left;
    }
  }

  Future<ui.Image> _renderParagraph({
    required String text,
    required double fontSize,
    required bool bold,
    required TextAlign align,
    required bool isRtl,
  }) async {
    final style = ui.TextStyle(
      fontFamily: fontFamily,
      color: const ui.Color(0xFF000000),
      fontSize: fontSize,
      fontWeight: bold ? ui.FontWeight.w600 : ui.FontWeight.w400,
    );

    final paraStyle = ui.ParagraphStyle(
      textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      textAlign: _toUiAlign(align),
      maxLines: null,
    );

    final builder = ui.ParagraphBuilder(paraStyle)
      ..pushStyle(style)
      ..addText(text);
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: widthPx.toDouble()));

    final height = paragraph.height.ceil();
    final pictureRecorder = ui.PictureRecorder();
    final canvas = ui.Canvas(pictureRecorder);

    // white background to avoid dither noise
    final paintBg = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, widthPx.toDouble(), height.toDouble()), paintBg);

    canvas.drawParagraph(paragraph, const ui.Offset(0, 0));
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(widthPx, height);

    return image;
  }

  ui.TextAlign _toUiAlign(TextAlign a) {
    switch (a) {
      case TextAlign.center:
        return ui.TextAlign.center;
      case TextAlign.right:
        return ui.TextAlign.right;
      case TextAlign.left:
      default:
        return ui.TextAlign.left;
    }
  }
}

class _Block {
  final String text;
  final double fontSize;
  final bool bold;
  final TextAlign align;
  final bool isRtl;

  const _Block({
    required this.text,
    this.fontSize = 22, // tweak to taste
    this.bold = false,
    this.align = TextAlign.left,
    this.isRtl = false,
  });
}

/// Helper to build receipt content
class ReceiptBlocks {
  static _Block title(String text, {bool rtl = false}) => _Block(
      text: text,
      fontSize: 26,
      bold: true,
      align: TextAlign.center,
      isRtl: rtl);

  static _Block line(String text,
          {bool rtl = false, TextAlign align = TextAlign.left}) =>
      _Block(text: text, fontSize: 22, bold: false, align: align, isRtl: rtl);

  static _Block small(String text,
          {bool rtl = false, TextAlign align = TextAlign.left}) =>
      _Block(text: text, fontSize: 18, bold: false, align: align, isRtl: rtl);

  static _Block separator() => _Block(text: '——————————————', fontSize: 20);
}
