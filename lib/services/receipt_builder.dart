import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:intl/intl.dart';
import 'package:visionpos/services/arabic_font_loader.dart';

typedef ProductResolver = dynamic Function(int productId);

class ReceiptBuilder {
  final PaperSize paper;
  final CapabilityProfile profile;
  final int widthPx;
  final String arabicFontFamily;
  final String arabicFontAssetPath;
  final bool debug;
  final bool useArabicIndicDigits;

  ReceiptBuilder._(
    this.paper,
    this.profile,
    this.widthPx,
    this.arabicFontFamily,
    this.arabicFontAssetPath, {
    required this.debug,
    required this.useArabicIndicDigits,
  });

  // -------------------------------
  // Factories
  // -------------------------------
  static Future<ReceiptBuilder> create({
    PaperSize paper = PaperSize.mm80,
    String? profileName,
    String arabicFontFamily = 'NotoNaskhArabic',
    String arabicFontAssetPath = 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
    bool debug = false,
    int? widthPxOverride,
    bool useArabicIndicDigits = true,

    /// Some 80mm Xprinters corrupt 576-dot rasters. 512 is safe for them.
    bool forceSafe80mmWidth = true,
  }) async {
    final sessionId = DateTime.now().millisecondsSinceEpoch;
    final sw = Stopwatch()..start();

    final profile =
        await CapabilityProfile.load(name: profileName ?? 'default');

    final widthPx = widthPxOverride ??
        ((paper == PaperSize.mm58) ? 384 : (forceSafe80mmWidth ? 512 : 576));

    developer.log(
      '🧱 [RB-$sessionId] create(): paper=$paper widthPx=$widthPx',
      name: 'ReceiptBuilder',
    );

    try {
      await ArabicFontLoader.ensureLoaded(
        family: arabicFontFamily,
        assetPath: arabicFontAssetPath,
      );
      developer.log(
        '✓ [RB-$sessionId] Arabic font loaded in ${sw.elapsedMilliseconds}ms',
        name: 'ReceiptBuilder',
      );
    } catch (e, st) {
      developer.log(
        '❌ [RB-$sessionId] Failed to load Arabic font',
        name: 'ReceiptBuilder',
        error: e,
        stackTrace: st,
        level: 1000,
      );
      throw StateError('Failed to load Arabic font: $e');
    }

    return ReceiptBuilder._(
      paper,
      profile,
      widthPx,
      arabicFontFamily,
      arabicFontAssetPath,
      debug: debug,
      useArabicIndicDigits: useArabicIndicDigits,
    );
  }

  static Future<ReceiptBuilder> createCustomerBuilder({
    String arabicFontFamily = 'NotoNaskhArabic',
    String arabicFontAssetPath = 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
    String? profileName,
    bool debug = false,
    bool useArabicIndicDigits = true,
  }) =>
      create(
        paper: PaperSize.mm80,
        profileName: profileName,
        arabicFontFamily: arabicFontFamily,
        arabicFontAssetPath: arabicFontAssetPath,
        debug: debug,
        useArabicIndicDigits: useArabicIndicDigits,
      );

  static Future<ReceiptBuilder> createKitchenBuilder({
    String arabicFontFamily = 'NotoNaskhArabic',
    String arabicFontAssetPath = 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
    String? profileName,
    bool debug = false,
    bool useArabicIndicDigits = true,
  }) =>
      create(
        paper: PaperSize.mm58,
        profileName: profileName,
        arabicFontFamily: arabicFontFamily,
        arabicFontAssetPath: arabicFontAssetPath,
        debug: debug,
        useArabicIndicDigits: useArabicIndicDigits,
      );

  // ==========================================
  // Public API (preferred)
  // ==========================================
  Future<List<int>> printCustomer(
    dynamic order, {
    ProductResolver? resolve,
    String storeName = '',
    List<dynamic>? items, // pass your cart items explicitly
    String? orderNumber, // override with the server number
  }) async {
    final bytes = await _buildCustomer(
      order,
      resolve: resolve,
      storeName: storeName,
      items: items,
      orderNumberOverride: orderNumber,
    );
    return bytes.toList(growable: false);
  }

  Future<List<int>> printKitchen(
    dynamic order, {
    required String kitchenName,
    required List<dynamic> items,
    ProductResolver? resolve,
    String? orderNumber, // override with the same server number
  }) async {
    final bytes = await _buildKitchen(
      order,
      kitchenName: kitchenName,
      items: items,
      resolve: resolve,
      orderNumberOverride: orderNumber,
    );
    return bytes.toList(growable: false);
  }

  // =====================================================
  // BACKWARD-COMPAT
  // =====================================================
  @Deprecated('Use printCustomer (List<int>)')
  Future<Uint8List> buildCustomer(
    dynamic order, {
    List<dynamic>? items,
    ProductResolver? resolve,
    String storeName = '',
    String? orderNumber,
  }) async {
    return _buildCustomer(
      order,
      items: items,
      resolve: resolve,
      storeName: storeName,
      orderNumberOverride: orderNumber,
    );
  }

  @Deprecated('Use printKitchen (List<int>)')
  Future<Uint8List> buildKitchen(
    dynamic order, {
    required String kitchenName,
    required List<dynamic> items,
    ProductResolver? resolve,
    String? orderNumber,
  }) async {
    return _buildKitchen(
      order,
      kitchenName: kitchenName,
      items: items,
      resolve: resolve,
      orderNumberOverride: orderNumber,
    );
  }

  // =======================
  // Internal builders
  // =======================
  Future<Uint8List> _buildCustomer(
    dynamic order, {
    List<dynamic>? items,
    ProductResolver? resolve,
    String storeName = '',
    String? orderNumberOverride,
  }) async {
    final g = Generator(paper, profile);
    final List<int> bytes = [];
    final sw = Stopwatch()..start();

    bytes.addAll(g.reset());

    if (storeName.trim().isNotEmpty) {
      bytes.addAll(await _arabicTextLineHybrid(
        g,
        storeName,
        align: PosAlign.center,
        fontSize: 26,
      ));
    }

    bytes.addAll(await _arabicTextLineHybrid(
      g,
      'فاتورة البيع',
      align: PosAlign.center,
      fontSize: 28,
    ));

    final extracted = _extractOrderNumber(order);
    final orderNoStr =
        (orderNumberOverride != null && orderNumberOverride.trim().isNotEmpty)
            ? orderNumberOverride.trim()
            : extracted;

    if (orderNoStr.isNotEmpty) {
      bytes.addAll(await _arabicTextLineHybrid(
        g,
        'رقم الطلب: ${_digits(orderNoStr)}',
        align: PosAlign.center,
        fontSize: 24,
      ));
    }

    final payAr = _extractPaymentMethodArabic(order);
    if (payAr.isNotEmpty) {
      bytes.addAll(await _arabicTextLineHybrid(
        g,
        'طريقة الدفع: $payAr',
        align: PosAlign.center,
        fontSize: 20,
      ));
    }

    bytes.addAll(g.hr(ch: '='));
    bytes.addAll(g.hr(ch: '='));
    bytes.addAll(await _arabicThreeColumnHeader(g));
    bytes.addAll(g.hr(ch: '-')); // <- fixed (no extra parenthesis)

    final orderItems = items ?? _extractItems(order);
    for (final it in orderItems) {
      final int productId = _asInt(_pick(it, ['productId', 'ProductId']), 0);
      final double qty = _asNumDouble(_pick(it, ['quantity', 'Quantity']), 1.0);

      String name = _asString(_pick(it, ['productName', 'name']), '').trim();
      double lineTotal =
          _asNumDouble(_pick(it, ['totalAfterTax', 'total']), -1.0);

      if (name.isEmpty && resolve != null) {
        final prod = resolve(productId);
        if (prod != null) name = _bestProductName(prod);
      }
      if (name.isEmpty) name = 'صنف';

      if (lineTotal < 0) {
        double unitPrice = _asNumDouble(
          _pick(it, ['unitPrice', 'price', 'sellingPrice']),
          -1,
        );
        if (unitPrice < 0 && resolve != null) {
          final prod = resolve(productId);
          if (prod != null) {
            unitPrice = _bestSellingPrice(prod, 0.0);
          }
        }
        lineTotal = (unitPrice >= 0) ? unitPrice * qty : 0.0;
      }

      bytes.addAll(await _arabicThreeColumnRow(
        g,
        right: name,
        center: _digits(_fmtNum(qty)),
        left: _digits(_money(lineTotal)),
      ));

      final notes = _asString(_pick(it, ['notes', 'Notes']), '').trim();
      if (notes.isNotEmpty) {
        bytes.addAll(await _arabicTextLineHybrid(
          g,
          '   ← $notes',
          align: PosAlign.right,
          fontSize: 16,
        ));
      }
    }

    bytes.addAll(g.hr(ch: '='));

    final totals = _extractTotals(order);
    if (totals.subtotalShown) {
      bytes.addAll(await _arabicTextLineHybrid(
        g,
        'الإجمالي الفرعي: ${_digits(_money(totals.subtotalForPrint))}',
        align: PosAlign.right,
        fontSize: 20,
      ));
    }
    if (totals.discount > 0) {
      bytes.addAll(await _arabicTextLineHybrid(
        g,
        'الخصم: ${_digits('- ${_money(totals.discount)}')}',
        align: PosAlign.right,
        fontSize: 20,
      ));
    }
    if (totals.tax > 0) {
      bytes.addAll(await _arabicTextLineHybrid(
        g,
        'الضريبة: ${_digits(_money(totals.tax))}',
        align: PosAlign.right,
        fontSize: 20,
      ));
    }
    if (totals.tips > 0) {
      bytes.addAll(await _arabicTextLineHybrid(
        g,
        'الإكرامية: ${_digits(_money(totals.tips))}',
        align: PosAlign.right,
        fontSize: 20,
      ));
    }

    bytes.addAll(g.hr(ch: '='));
    bytes.addAll(await _arabicTextLineHybrid(
      g,
      'الإجمالي: ${_digits(_money(totals.total))}',
      align: PosAlign.right,
      fontSize: 26,
    ));
    bytes.addAll(g.hr(ch: '='));

    bytes.addAll(await _arabicTextLineHybrid(
      g,
      'شكراً لزيارتكم',
      align: PosAlign.center,
      fontSize: 22,
    ));

    final now = DateTime.now();
    bytes.addAll(await _arabicTextLineHybrid(
      g,
      _digits(DateFormat('yyyy/MM/dd - hh:mm a').format(now)),
      align: PosAlign.center,
      fontSize: 18,
    ));

    // extra feed, then one partial cut: avoids end-of-receipt retries
    final feedLines = (paper == PaperSize.mm80) ? 5 : 4;
    bytes.addAll(g.feed(feedLines));
    bytes.addAll(g.cut(mode: PosCutMode.partial));

    final out = Uint8List.fromList(bytes);
    developer.log(
      '🧾 Customer bytes=${out.length} in ${sw.elapsedMilliseconds}ms',
      name: 'ReceiptBuilder',
    );
    return out;
  }

  Future<Uint8List> _buildKitchen(
    dynamic order, {
    required String kitchenName,
    required List<dynamic> items,
    ProductResolver? resolve,
    String? orderNumberOverride,
  }) async {
    final g = Generator(paper, profile);
    final List<int> bytes = [];
    final sw = Stopwatch()..start();

    bytes.addAll(g.reset());

    bytes.addAll(g.emptyLines(1));
    bytes.addAll(await _arabicTextLineHybrid(
      g,
      kitchenName,
      align: PosAlign.center,
      fontSize: 24,
    ));

    final extracted = _extractOrderNumber(order);
    final orderNoStr =
        (orderNumberOverride != null && orderNumberOverride.trim().isNotEmpty)
            ? orderNumberOverride.trim()
            : extracted;

    if (orderNoStr.isNotEmpty) {
      bytes.addAll(await _arabicTextLineHybrid(
        g,
        'طلب رقم: ${_digits(orderNoStr)}',
        align: PosAlign.center,
        fontSize: 24,
      ));
    }

    bytes.addAll(g.hr(ch: '='));
    bytes.addAll(g.hr(ch: '='));
    bytes.addAll(await _arabicTwoColumnHeader(g));
    bytes.addAll(g.hr(ch: '-'));

    for (final it in items) {
      final int productId = _asInt(_pick(it, ['productId', 'ProductId']), 0);
      final double qty = _asNumDouble(_pick(it, ['quantity', 'Quantity']), 1.0);

      String name = _asString(_pick(it, ['productName', 'name']), '').trim();
      if (name.isEmpty && resolve != null) {
        final prod = resolve(productId);
        if (prod != null) name = _bestProductName(prod);
      }
      if (name.isEmpty) name = 'صنف';

      bytes.addAll(await _arabicTwoColumnRow(
        g,
        right: name,
        left: _digits(_fmtNum(qty)),
      ));

      final notes = _asString(_pick(it, ['notes', 'Notes']), '').trim();
      if (notes.isNotEmpty) {
        bytes.addAll(await _arabicTextLineHybrid(
          g,
          '   ★ $notes',
          align: PosAlign.right,
          fontSize: 17,
        ));
        bytes.addAll(g.emptyLines(1));
      }
    }

    bytes.addAll(g.hr(ch: '='));

    final now = DateTime.now();
    bytes.addAll(await _arabicTextLineHybrid(
      g,
      _digits(DateFormat('yyyy/MM/dd - hh:mm a').format(now)),
      align: PosAlign.center,
      fontSize: 18,
    ));

    final feedLines = (paper == PaperSize.mm58) ? 4 : 5;
    bytes.addAll(g.feed(feedLines));
    bytes.addAll(g.cut(mode: PosCutMode.partial));

    final out = Uint8List.fromList(bytes);
    developer.log(
      '🍳 Kitchen bytes=${out.length} in ${sw.elapsedMilliseconds}ms',
      name: 'ReceiptBuilder',
    );
    return out;
  }

  // ===============================
  // Raster/table helpers
  // ===============================
  Future<List<int>> _arabicThreeColumnHeader(Generator g) async {
    return _arabicThreeColumnRow(
      g,
      right: 'الصنف',
      center: 'الكمية',
      left: 'المجموع',
      fontSize: 20,
    );
  }

  Future<List<int>> _arabicTwoColumnHeader(Generator g) async {
    return _arabicTwoColumnRow(
      g,
      right: 'الصنف',
      left: 'الكمية',
      fontSize: 16,
    );
  }

  Future<List<int>> _arabicTwoColumnRow(
    Generator g, {
    required String right,
    required String left,
    double fontSize = 24,
    double verticalPadding = 2,
  }) async {
    right = useArabicIndicDigits ? _toArabicDigits(right) : right;
    left = useArabicIndicDigits ? _toArabicDigits(left) : left;

    const int horizontalMargin = 8;
    final int usableWidth = widthPx - (horizontalMargin * 2);
    final int rightColWidth = (usableWidth * 0.65).toInt();
    final int leftColWidth = (usableWidth * 0.35).toInt();

    final pStyleRight = ui.ParagraphStyle(
      textAlign: ui.TextAlign.right,
      textDirection: ui.TextDirection.rtl,
      maxLines: 3,
      locale: const ui.Locale('ar'),
    );
    final tStyle = ui.TextStyle(
      color: const ui.Color(0xFF000000),
      fontSize: fontSize,
      fontFamily: arabicFontFamily,
    );
    final builderRight = ui.ParagraphBuilder(pStyleRight)..pushStyle(tStyle);
    builderRight.addText(right);
    final pRight = builderRight.build()
      ..layout(ui.ParagraphConstraints(width: rightColWidth.toDouble()));

    final pStyleLeft = ui.ParagraphStyle(
      textAlign: ui.TextAlign.center,
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      locale: const ui.Locale('ar'),
    );
    final builderLeft = ui.ParagraphBuilder(pStyleLeft)..pushStyle(tStyle);
    builderLeft.addText(left);
    final pLeft = builderLeft.build()
      ..layout(ui.ParagraphConstraints(width: leftColWidth.toDouble()));

    final double maxHeight =
        (pRight.height > pLeft.height) ? pRight.height : pLeft.height;
    final int height = (maxHeight + verticalPadding * 2).ceil().clamp(24, 4096);

    final rec = ui.PictureRecorder();
    final canvas = ui.Canvas(rec);
    final bg = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, widthPx.toDouble(), height.toDouble()), bg);

    const double margin = 8.0;
    final double dy = ((height - maxHeight) / 2).clamp(0.0, height.toDouble());
    canvas.drawParagraph(pRight, ui.Offset(margin, dy));
    canvas.drawParagraph(
        pLeft, ui.Offset(margin + rightColWidth.toDouble(), dy));

    final picture = rec.endRecording();
    final uiImg = await picture.toImage(widthPx, height);
    final byteData = await uiImg.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw StateError('toByteData returned null');
    final pngBytes = byteData.buffer.asUint8List();

    final decoded = img.decodePng(pngBytes) ?? img.decodeImage(pngBytes);
    if (decoded == null) throw StateError('PNG decode returned null');

    return g.imageRaster(
      decoded,
      align: PosAlign.left,
      highDensityHorizontal: true,
      highDensityVertical: true,
    );
  }

  Future<List<int>> _arabicThreeColumnRow(
    Generator g, {
    required String right,
    required String center,
    required String left,
    double fontSize = 22,
    double verticalPadding = 2,
  }) async {
    right = useArabicIndicDigits ? _toArabicDigits(right) : right;
    center = useArabicIndicDigits ? _toArabicDigits(center) : center;
    left = useArabicIndicDigits ? _toArabicDigits(left) : left;

    const int horizontalMargin = 8;
    final int usableWidth = widthPx - (horizontalMargin * 2);

    final int rightColWidth = (usableWidth * 0.45).toInt();
    final int centerColWidth = (usableWidth * 0.20).toInt();
    final int leftColWidth = (usableWidth * 0.35).toInt();

    final pStyleRight = ui.ParagraphStyle(
      textAlign: ui.TextAlign.right,
      textDirection: ui.TextDirection.rtl,
      maxLines: 3,
      locale: const ui.Locale('ar'),
    );
    final tStyle = ui.TextStyle(
      color: const ui.Color(0xFF000000),
      fontSize: fontSize,
      fontFamily: arabicFontFamily,
    );

    final bRight = ui.ParagraphBuilder(pStyleRight)..pushStyle(tStyle);
    bRight.addText(right);
    final pRight = bRight.build()
      ..layout(ui.ParagraphConstraints(width: rightColWidth.toDouble()));

    final pStyleCenter = ui.ParagraphStyle(
      textAlign: ui.TextAlign.center,
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      locale: const ui.Locale('ar'),
    );
    final bCenter = ui.ParagraphBuilder(pStyleCenter)..pushStyle(tStyle);
    bCenter.addText(center);
    final pCenter = bCenter.build()
      ..layout(ui.ParagraphConstraints(width: centerColWidth.toDouble()));

    final pStyleLeft = ui.ParagraphStyle(
      textAlign: ui.TextAlign.left,
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      locale: const ui.Locale('en'),
    );
    final bLeft = ui.ParagraphBuilder(pStyleLeft)..pushStyle(tStyle);
    bLeft.addText(left);
    final pLeft = bLeft.build()
      ..layout(ui.ParagraphConstraints(width: leftColWidth.toDouble()));

    final double maxHeight = [pRight.height, pCenter.height, pLeft.height]
        .reduce((a, b) => a > b ? a : b);
    final int height = (maxHeight + verticalPadding * 2).ceil().clamp(24, 4096);

    final rec = ui.PictureRecorder();
    final canvas = ui.Canvas(rec);
    final bg = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, widthPx.toDouble(), height.toDouble()), bg);

    const double margin = 8.0;
    final double dy = ((height - maxHeight) / 2).clamp(0.0, height.toDouble());

    canvas.drawParagraph(pRight, ui.Offset(margin, dy));
    canvas.drawParagraph(
        pCenter, ui.Offset(margin + rightColWidth.toDouble(), dy));
    canvas.drawParagraph(pLeft,
        ui.Offset(margin + (rightColWidth + centerColWidth).toDouble(), dy));

    final picture = rec.endRecording();
    final uiImg = await picture.toImage(widthPx, height);
    final byteData = await uiImg.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw StateError('toByteData returned null');
    final pngBytes = byteData.buffer.asUint8List();

    final decoded = img.decodePng(pngBytes) ?? img.decodeImage(pngBytes);
    if (decoded == null) throw StateError('PNG decode returned null');

    return g.imageRaster(
      decoded,
      align: PosAlign.left,
      highDensityHorizontal: true,
      highDensityVertical: true,
    );
  }

  Future<List<int>> _arabicTextLineHybrid(
    Generator g,
    String text, {
    PosAlign align = PosAlign.center,
    double fontSize = 22,
  }) {
    return _arabicTextLineAsRaster(
      g,
      text,
      align: align,
      fontSize: fontSize,
      verticalPadding: 2,
    );
  }

  Future<List<int>> _arabicTextLineAsRaster(
    Generator g,
    String text, {
    PosAlign align = PosAlign.center,
    double fontSize = 22,
    double verticalPadding = 2,
  }) async {
    text = useArabicIndicDigits ? _toArabicDigits(text) : text;
    final bool hasArabic = _containsArabic(text);

    const int horizontalMargin = 8;
    final int usableWidth = widthPx - (horizontalMargin * 2);

    final paragraphStyle = ui.ParagraphStyle(
      textAlign: _mapAlign(align),
      textDirection: hasArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      maxLines: 6,
      locale: ui.Locale(hasArabic ? 'ar' : 'en'),
    );
    final textStyle = ui.TextStyle(
      color: const ui.Color(0xFF000000),
      fontSize: fontSize,
      fontFamily: arabicFontFamily,
    );

    final builder = ui.ParagraphBuilder(paragraphStyle)..pushStyle(textStyle);
    builder.addText(text);
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: usableWidth.toDouble()));

    final double paraH = paragraph.height;
    final int height = (paraH + verticalPadding * 2).ceil().clamp(24, 4096);

    final rec = ui.PictureRecorder();
    final canvas = ui.Canvas(rec);
    final bg = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, widthPx.toDouble(), height.toDouble()), bg);

    const double margin = 8.0;
    final double dy = ((height - paraH) / 2).clamp(0.0, height.toDouble());
    canvas.drawParagraph(paragraph, ui.Offset(margin, dy));

    final picture = rec.endRecording();
    final uiImg = await picture.toImage(widthPx, height);
    final byteData = await uiImg.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw StateError('toByteData returned null');
    final pngBytes = byteData.buffer.asUint8List();

    final decoded = img.decodePng(pngBytes) ?? img.decodeImage(pngBytes);
    if (decoded == null) throw StateError('PNG decode returned null');

    return g.imageRaster(
      decoded,
      align: align,
      highDensityHorizontal: true,
      highDensityVertical: true,
    );
  }

  // =================
  // Extractors/Utils
  // =================
  String _extractOrderNumber(dynamic order) {
    if (order == null) return '';

    final candidates = <dynamic>[
      // data envelope
      _pick(order, ['data.orderNumber']),
      _pick(order, ['data.OrderNumber']),
      _pick(order, ['data.orderNo']),
      _pick(order, ['data.OrderNo']),
      _pick(order, ['data.id']),
      _pick(order, ['data.Id']),
      _pick(order, ['data.orderId']),
      _pick(order, ['data.OrderId']),
      // flat
      _pick(order, ['orderNumber']),
      _pick(order, ['OrderNumber']),
      _pick(order, ['orderNo']),
      _pick(order, ['OrderNo']),
      _pick(order, ['id']),
      _pick(order, ['Id']),
      _pick(order, ['orderId']),
      _pick(order, ['OrderId']),
      _pick(order, ['number']),
      _pick(order, ['Number']),
    ];

    for (final c in candidates) {
      if (c == null) continue;
      final s = c.toString().trim();
      if (s.isEmpty) continue;
      if (s == '0' || s.toLowerCase() == 'null') continue; // invalid
      return s;
    }
    return '';
  }

  String _extractPaymentMethodArabic(dynamic order) {
    final d = (order is Map<String, dynamic>)
        ? order['data'] as Map<String, dynamic>?
        : null;
    final pm = (d?['paymentMethod'] ?? order['paymentMethod'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    switch (pm) {
      case '1':
      case 'cash':
      case 'cash on delivery':
        return 'نقداً';
      case '2':
      case 'card':
      case 'credit':
      case 'debit':
      case 'visa':
      case 'mastercard':
        return 'بطاقة';
      case '3':
      case 'wallet':
      case 'ewallet':
      case 'e-wallet':
        return 'محفظة إلكترونية';
      case '4':
      case 'online':
      case 'gateway':
      case 'stripe':
      case 'paytabs':
      case 'paypal':
        return 'دفع إلكتروني';
      default:
        return pm.isEmpty ? '' : pm;
    }
  }

  _Totals _extractTotals(dynamic order) {
    final dataObj = _pick(order, ['data']) ?? order;
    final subtotal = _asNumDouble(
        _pick(dataObj, ['totalAfterDiscount', 'grandTotal', 'GrandTotal']),
        0.0);
    final discount = _asNumDouble(_pick(dataObj, ['discountTotal']), 0.0);
    final tax = _asNumDouble(_pick(dataObj, ['taxTotal']), 0.0);
    final tips = _asNumDouble(_pick(dataObj, ['tips', 'tip']), 0.0);
    final total = _asNumDouble(
        _pick(dataObj, ['totalAfterTax', 'grandTotal', 'GrandTotal']),
        subtotal);

    final subtotalShown = (discount > 0 || tax > 0);
    final subtotalForPrint = subtotal - discount;
    return _Totals(
      discount: discount,
      tax: tax,
      tips: tips,
      total: total,
      subtotalForPrint: subtotalForPrint,
      subtotalShown: subtotalShown,
    );
  }

  List<dynamic> _extractItems(dynamic order) {
    final l = (_pick(order, ['data.orderItems']) as List?) ??
        (_pick(order, ['orderItems']) as List?) ??
        (_pick(order, ['items']) as List?) ??
        <dynamic>[];
    return l;
  }

  // ----- product helpers -----
  String _bestProductName(dynamic prod) {
    if (prod == null) return '';
    if (prod is Map) {
      for (final k in ['productName', 'name', 'title']) {
        final v = prod[k];
        if (v is String && v.trim().isNotEmpty) return v;
      }
    }
    try {
      final v = (prod as dynamic).productName;
      if (v is String && v.trim().isNotEmpty) return v;
    } catch (_) {}
    try {
      final v = (prod as dynamic).name;
      if (v is String && v.trim().isNotEmpty) return v;
    } catch (_) {}
    try {
      final json = (prod as dynamic).toJson?.call();
      if (json is Map) {
        for (final k in ['productName', 'name', 'title']) {
          final v = json[k];
          if (v is String && v.trim().isNotEmpty) return v;
        }
      }
    } catch (_) {}
    return '';
  }

  double _bestSellingPrice(dynamic prod, double fallback) {
    if (prod == null) return fallback;
    if (prod is Map) {
      for (final k in ['sellingPrice', 'price']) {
        final v = prod[k];
        if (v is num) return v.toDouble();
        if (v is String) {
          final p = double.tryParse(v);
          if (p != null) return p;
        }
      }
    }
    try {
      final v = (prod as dynamic).sellingPrice;
      if (v is num) return v.toDouble();
    } catch (_) {}
    try {
      final v = (prod as dynamic).price;
      if (v is num) return v.toDouble();
    } catch (_) {}
    try {
      final json = (prod as dynamic).toJson?.call();
      if (json is Map) {
        for (final k in ['sellingPrice', 'price']) {
          final v = json[k];
          if (v is num) return v.toDouble();
          if (v is String) {
            final p = double.tryParse(v);
            if (p != null) return p;
          }
        }
      }
    } catch (_) {}
    return fallback;
  }

  // ---------------- small helpers ----------------
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

  String _money(num v) => v.toStringAsFixed(2);
  String _fmtNum(num v) =>
      (v == v.roundToDouble()) ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  num _asNum(dynamic v, {num fallback = 0}) {
    if (v is num) return v;
    if (v is String) {
      final p = num.tryParse(v);
      if (p != null) return p;
    }
    return fallback;
  }

  double _asNumDouble(dynamic v, double fallback) =>
      _asNum(v, fallback: fallback).toDouble();
  int _asInt(dynamic v, int fallback) => _asNum(v, fallback: fallback).toInt();
  String _asString(dynamic v, String fallback) => (v is String) ? v : fallback;

  dynamic _pick(dynamic obj, List<String> keys) {
    for (final k in keys) {
      final parts = k.split('.');
      dynamic cur = obj;
      bool ok = true;
      for (final p in parts) {
        if (cur is Map && cur.containsKey(p)) {
          cur = cur[p];
        } else {
          ok = false;
          break;
        }
      }
      if (ok) return cur;
    }
    return null;
  }

  bool _containsArabic(String s) =>
      RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(s);

  String _digits(String s) => useArabicIndicDigits ? _toArabicDigits(s) : s;

  String _toArabicDigits(String s) {
    const latin = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arab = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (var i = 0; i < 10; i++) {
      s = s.replaceAll(latin[i], arab[i]);
    }
    return s;
  }
}

class _Totals {
  final double discount;
  final double tax;
  final double tips;
  final double total;
  final double subtotalForPrint;
  final bool subtotalShown;

  _Totals({
    required this.discount,
    required this.tax,
    required this.tips,
    required this.total,
    required this.subtotalForPrint,
    required this.subtotalShown,
  });
}
