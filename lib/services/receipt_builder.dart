import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:visionpos/services/arabic_font_loader.dart';

/// Builds ESC/POS receipts for 58mm or 80mm printers, with Arabic via image raster.
/// Now with deep debug logging.
class ReceiptBuilder {
  final PaperSize paper;
  final CapabilityProfile profile;
  final int widthPx;

  /// Optional Arabic font family (as declared in pubspec fonts: family: ...).
  final String? arabicFontFamily;

  /// Optional path to the TTF (for explicit FontLoader).
  final String? arabicFontAssetPath;

  /// Enable verbose internal logs.
  final bool debug;

  ReceiptBuilder._(
    this.paper,
    this.profile,
    this.widthPx,
    this.arabicFontFamily,
    this.arabicFontAssetPath, {
    required this.debug,
  });

  static Future<ReceiptBuilder> create({
    PaperSize paper = PaperSize.mm80,
    String? profileName,
    String?
        arabicFontFamily, // e.g. 'NotoKufiArabic' (must equal pubspec family)
    String?
        arabicFontAssetPath, // e.g. 'lib/assets/fonts/NotoKufiArabic-Regular.ttf'
    bool debug = false,
  }) async {
    final sw = Stopwatch()..start();
    _d(debug,
        'RB.create() → loading capability profile "${profileName ?? 'default'}"...');
    final profile =
        await CapabilityProfile.load(name: profileName ?? 'default');
    final widthPx = (paper == PaperSize.mm58) ? 384 : 576;
    _d(debug,
        'RB.create() ✓ profile loaded in ${sw.elapsedMilliseconds}ms; paper=$paper, widthPx=$widthPx');

    // Attempt to force-load the font into the engine so ParagraphBuilder will use it.
    if (arabicFontFamily != null && arabicFontAssetPath != null) {
      try {
        final swFont = Stopwatch()..start();
        _d(debug,
            'RB.create() → loading Arabic font "$arabicFontFamily" from "$arabicFontAssetPath"...');
        await ArabicFontLoader.ensureLoaded(
          family: arabicFontFamily,
          assetPath: arabicFontAssetPath,
        );
        _d(debug,
            'RB.create() ✓ Arabic font loaded in ${swFont.elapsedMilliseconds}ms');
      } catch (e, st) {
        _e(debug, 'RB.create() ✗ FAILED loading Arabic font: $e\n$st');
      }
    } else {
      _w(debug,
          'RB.create() ⚠ No Arabic font configured. Set arabicFontFamily + arabicFontAssetPath to avoid garbled text.');
    }

    return ReceiptBuilder._(
      paper,
      profile,
      widthPx,
      arabicFontFamily,
      arabicFontAssetPath,
      debug: debug,
    );
  }

  /// Customer receipt: full order.
  /// Customer receipt (EN): only order id/number + money section.
  /// NOTE: No items are printed; English text uses ESC/POS text, not raster.
  Future<Uint8List> buildCustomer(Map<String, dynamic> order) async {
    final g = Generator(paper, profile);
    final List<int> bytes = <int>[];

    // Title
    bytes.addAll(g.text(
      'RECEIPT',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    ));
    bytes.addAll(g.hr());

    // Order identifier(s)
    final orderNumber = (order['orderNumber'] ?? '').toString();
    if (orderNumber.isNotEmpty) {
      bytes.addAll(g.text(
        'Order No: $orderNumber',
        styles: const PosStyles(align: PosAlign.left, bold: true),
      ));
    }

    // Payment & timestamp
    final paymentMethod = (order['paymentMethod'] ?? '').toString();
    if (paymentMethod.isNotEmpty) {
      bytes.addAll(g.text(
        'Payment: $paymentMethod',
        styles: const PosStyles(align: PosAlign.left),
      ));
    }
    bytes.addAll(g.text(
      DateTime.now().toString(),
      styles: const PosStyles(align: PosAlign.center),
    ));

    bytes.addAll(g.hr());

    // Money section (English)
    final subtotal = _asNum(order['subtotal']);
    final tax = _asNum(order['tax']);
    final tips = _asNum(order['tips']);
    final total = _asNum(order['total']);

    bytes.addAll(g.row([
      PosColumn(
          text: 'Subtotal',
          width: 6,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: _money(subtotal),
          width: 6,
          styles: const PosStyles(align: PosAlign.right)),
    ]));
    bytes.addAll(g.row([
      PosColumn(
          text: 'Tax', width: 6, styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: _money(tax),
          width: 6,
          styles: const PosStyles(align: PosAlign.right)),
    ]));
    if (tips > 0) {
      bytes.addAll(g.row([
        PosColumn(
            text: 'Tips',
            width: 6,
            styles: const PosStyles(align: PosAlign.left)),
        PosColumn(
            text: _money(tips),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]));
    }

    bytes.addAll(g.hr());
    bytes.addAll(g.row([
      PosColumn(
        text: 'TOTAL',
        width: 6,
        styles: const PosStyles(align: PosAlign.left, bold: true),
      ),
      PosColumn(
        text: _money(total),
        width: 6,
        styles: const PosStyles(
            align: PosAlign.right,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2),
      ),
    ]));
    bytes.addAll(g.hr());

    bytes.addAll(g.text(
      'Thank you!',
      styles: const PosStyles(align: PosAlign.center),
    ));

    bytes.addAll(g.feed(2));
    bytes.addAll(g.cut());

    return Uint8List.fromList(bytes);
  }

  /// Kitchen ticket: only items for that section.
  Future<Uint8List> buildKitchen(
    Map<String, dynamic> order, {
    required String kitchenName,
    required List<dynamic> items,
  }) async {
    final g = Generator(paper, profile);
    final List<int> bytes = <int>[];
    final sw = Stopwatch()..start();
    _d(debug,
        'buildKitchen() → start; kitchen="$kitchenName", items=${items.length}');

    bytes.addAll(await _arabicTextLineAsRaster(
      g,
      kitchenName,
      align: PosAlign.center,
      fontSize: 28,
    ));
    bytes.addAll(g.hr());

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final String name = (item['name'] ?? 'Item').toString();
      final int qty = _asInt(item['quantity'] ?? 1);
      final String notes = (item['notes'] ?? '').toString();
      _d(debug,
          'buildKitchen() → item[$i]: qty=$qty, name="$name", notesLen=${notes.length}');

      bytes.addAll(await _arabicTextLineAsRaster(
        g,
        '$qty × $name',
        align: PosAlign.left,
        fontSize: 22,
      ));
      if (notes.isNotEmpty) {
        bytes.addAll(await _arabicTextLineAsRaster(
          g,
          'notes: $notes',
          align: PosAlign.left,
          fontSize: 20,
        ));
      }
    }

    bytes.addAll(g.hr());
    bytes.addAll(await _arabicTextLineAsRaster(
      g,
      ' Order #: ${order['orderNumber'] ?? ''}',
      align: PosAlign.left,
    ));
    final now = DateTime.now().toString();
    bytes.addAll(g.text(
      now,
      styles: const PosStyles(align: PosAlign.center),
    ));
    _d(debug, 'buildKitchen() → timestamp=$now');

    bytes.addAll(g.feed(1));
    bytes.addAll(g.cut());

    final out = Uint8List.fromList(bytes);
    _d(debug,
        'buildKitchen() ✓ done in ${sw.elapsedMilliseconds}ms; bytes=${out.length}');
    return out;
  }

  String _money(num? v) => '\$${(v ?? 0).toStringAsFixed(2)}';

  /// Render Arabic (or mixed) text as a raster image for ESC/POS.
  Future<List<int>> _arabicTextLineAsRaster(
    Generator g,
    String text, {
    PosAlign align = PosAlign.center,
    double fontSize = 22,
    double verticalPadding = 6,
  }) async {
    final sw = Stopwatch()..start();
    if (arabicFontFamily == null) {
      _w(debug,
          '_arabicTextLineAsRaster() ⚠ arabicFontFamily is NULL — Arabic will likely be garbled.');
    }
    _d(debug,
        '_arabicTextLineAsRaster() → text="$text" (len=${text.length}), align=$align, fontSize=$fontSize');

    // Build Paragraph with RTL + Arabic locale for correct shaping.
    final paragraphStyle = ui.ParagraphStyle(
      textAlign: _mapAlign(align),
      textDirection: ui.TextDirection.rtl,
      maxLines: 6,
      locale: const ui.Locale('en'),
    );
    final textStyle = ui.TextStyle(
      color: const ui.Color(0xFF000000),
      fontSize: fontSize,
      fontFamily: arabicFontFamily, // must match loaded pubspec family
    );

    ui.Paragraph paragraph;
    try {
      final bsw = Stopwatch()..start();
      final builder = ui.ParagraphBuilder(paragraphStyle)..pushStyle(textStyle);
      builder.addText(text);
      paragraph = builder.build()
        ..layout(ui.ParagraphConstraints(width: widthPx.toDouble()));
      _d(
          debug,
          '_arabicTextLineAsRaster() → layout done in ${bsw.elapsedMilliseconds}ms; '
          'height=${paragraph.height.toStringAsFixed(2)}, maxLines=${paragraph.maxIntrinsicWidth}, widthPx=$widthPx');
    } catch (e, st) {
      _e(debug,
          '_arabicTextLineAsRaster() ✗ paragraph build/layout failed: $e\n$st');
      rethrow;
    }

    final double paraH = paragraph.height;
    final int height = (paraH + verticalPadding * 2).ceil().clamp(24, 4096);
    _d(debug,
        '_arabicTextLineAsRaster() → target image size: ${widthPx}x$height (paraH=${paraH.toStringAsFixed(2)})');

    // Paint white background and draw paragraph.
    Uint8List pngBytes;
    try {
      final rec = ui.PictureRecorder();
      final canvas = ui.Canvas(rec);
      final paint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, widthPx.toDouble(), height.toDouble()),
        paint,
      );

      final double dy = ((height - paraH) / 2).clamp(0.0, height.toDouble());
      canvas.drawParagraph(paragraph, ui.Offset(0, dy));

      final picture = rec.endRecording();
      final isw = Stopwatch()..start();
      final uiImg = await picture.toImage(widthPx, height);
      final byteData = await uiImg.toByteData(format: ui.ImageByteFormat.png);
      pngBytes = byteData!.buffer.asUint8List();
      _d(debug,
          '_arabicTextLineAsRaster() → toImage+PNG in ${isw.elapsedMilliseconds}ms; pngBytes=${pngBytes.length}');
    } catch (e, st) {
      _e(debug,
          '_arabicTextLineAsRaster() ✗ rasterization to PNG failed: $e\n$st');
      rethrow;
    }

    // Decode PNG to Image package for ESC/POS.
    img.Image? decoded;
    try {
      final dsw = Stopwatch()..start();
      decoded = img.decodePng(pngBytes) ?? img.decodeImage(pngBytes);
      if (decoded == null) {
        throw StateError('decodePng/decodeImage returned null');
      }
      _d(
          debug,
          '_arabicTextLineAsRaster() → PNG decoded in ${dsw.elapsedMilliseconds}ms; '
          'decoded=${decoded.width}x${decoded.height}');
    } catch (e, st) {
      _e(debug, '_arabicTextLineAsRaster() ✗ PNG decode failed: $e\n$st');
      rethrow;
    }

    // ESC/POS raster command
    try {
      final rsw = Stopwatch()..start();
      final out = g.imageRaster(
        decoded,
        align: align,
        highDensityHorizontal: true,
        highDensityVertical: true,
      );
      _d(debug,
          '_arabicTextLineAsRaster() ✓ ESC/POS raster ok in ${rsw.elapsedMilliseconds}ms; bytes=${out.length}');
      return out;
    } catch (e, st) {
      _e(debug,
          '_arabicTextLineAsRaster() ✗ ESC/POS imageRaster failed: $e\n$st');
      rethrow;
    } finally {
      _d(debug, '_arabicTextLineAsRaster() total ${sw.elapsedMilliseconds}ms');
    }
  }

  ui.TextAlign _mapAlign(PosAlign a) {
    switch (a) {
      case PosAlign.left:
        return ui.TextAlign.left;
      case PosAlign.center:
        return ui.TextAlign.center;
      case PosAlign.right:
        return ui.TextAlign.right;
    }
  }
}

/// -------- helpers: safe numeric parsing + logging --------
int _asInt(dynamic v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is num) return v.toInt();
  if (v is String) {
    final p = num.tryParse(v);
    if (p != null) return p.toInt();
  }
  return fallback;
}

num _asNum(dynamic v, {num fallback = 0}) {
  if (v is num) return v;
  if (v is String) {
    final p = num.tryParse(v);
    if (p != null) return p;
  }
  return fallback;
}

void _d(bool debug, String msg) {
  if (debug) {
    // Prefix with a lightweight timestamp for easier log correlation.
    final t = DateTime.now().toIso8601String().substring(11, 23);
    // Use debugPrint to avoid truncation UI hiccups; adjust to print() if preferred.
    // ignore: avoid_print
    print('[RB][D][$t] $msg');
  }
}

void _w(bool debug, String msg) {
  if (debug) {
    final t = DateTime.now().toIso8601String().substring(11, 23);
    // ignore: avoid_print
    print('[RB][W][$t] $msg');
  }
}

void _e(bool debug, String msg) {
  final t = DateTime.now().toIso8601String().substring(11, 23);
  // ignore: avoid_print
  print('[RB][E][$t] $msg');
}
