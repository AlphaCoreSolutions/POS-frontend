import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:visionpos/services/arabic_font_loader.dart';
import 'package:intl/intl.dart';

/// Unified ReceiptBuilder for Customer and Kitchen receipts with 100% Arabic support
/// and guaranteed Android compatibility (returns List<int> ready for Android).
///
/// Features:
/// - Single builder for all receipt types (customer, kitchen)
/// - Automatic Arabic text rendering as raster images
/// - Android-compatible output (List<int>, not Uint8List)
/// - No helpers needed - just send Arabic data and print
/// - Automatic font loading and validation
/// - RTL text support with proper shaping
/// - Arabic-Indic numerals (٠١٢٣٤٥٦٧٨٩)
///
/// Usage:
/// ```dart
/// final builder = await ReceiptBuilder.create();
///
/// // Customer receipt
/// final bytes = await builder.printCustomer(orderData);
/// await printer.writeBytes(Uint8List.fromList(bytes));
///
/// // Kitchen ticket
/// final bytes = await builder.printKitchen(orderData, 'مطبخ الفلافل', items);
/// await printer.writeBytes(Uint8List.fromList(bytes));
/// ```
class ReceiptBuilder {
  final PaperSize paper;
  final CapabilityProfile profile;
  final int widthPx;
  final String arabicFontFamily;
  final String arabicFontAssetPath;
  final bool debug;
  final bool useArabicIndicDigits;

  // Private constructor
  ReceiptBuilder._(
    this.paper,
    this.profile,
    this.widthPx,
    this.arabicFontFamily,
    this.arabicFontAssetPath, {
    required this.debug,
    required this.useArabicIndicDigits,
  });

  /// Create a new ReceiptBuilder with automatic font loading.
  /// This is the ONLY method you need to call - everything is configured automatically!
  ///
  /// Returns a builder ready to print customer receipts and kitchen tickets in Arabic.
  /// All output is Android-compatible (List<int>).
  static Future<ReceiptBuilder> create({
    PaperSize paper = PaperSize.mm80,
    String? profileName,
    String arabicFontFamily = 'NotoNaskhArabic',
    String arabicFontAssetPath = 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
    bool debug = false,
    int? widthPxOverride,
    bool useArabicIndicDigits = true, // Default to Arabic numerals
  }) async {
    final sessionId = DateTime.now().millisecondsSinceEpoch;
    final sw = Stopwatch()..start();

    developer.log(
      '🏗️ [BUILDER-$sessionId] Creating ReceiptBuilder with Arabic font: $arabicFontFamily',
      name: 'ReceiptBuilder',
    );

    // Load capability profile
    final profile =
        await CapabilityProfile.load(name: profileName ?? 'default');
    final widthPx = widthPxOverride ?? ((paper == PaperSize.mm58) ? 384 : 576);

    developer.log(
      '✓ [BUILDER-$sessionId] Profile loaded: paper=$paper, width=${widthPx}px',
      name: 'ReceiptBuilder',
    );

    // CRITICAL: Load Arabic font (required for rendering)
    try {
      await ArabicFontLoader.ensureLoaded(
        family: arabicFontFamily,
        assetPath: arabicFontAssetPath,
      );

      developer.log(
        '✓ [BUILDER-$sessionId] Arabic font loaded successfully in ${sw.elapsedMilliseconds}ms',
        name: 'ReceiptBuilder',
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ [BUILDER-$sessionId] CRITICAL: Failed to load Arabic font!',
        name: 'ReceiptBuilder',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      throw StateError('Failed to load Arabic font: $e');
    }

    developer.log(
      '✅ [BUILDER-$sessionId] ReceiptBuilder ready for printing',
      name: 'ReceiptBuilder',
    );

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

  // ---------------------------------------------------------------------------
  // TABLE RENDERING HELPERS
  // ---------------------------------------------------------------------------
  /// Render table header: الصنف | الكمية | المجموع
  Future<List<int>> _arabicTableHeaderLine(Generator g) async {
    return await _arabicThreeColumnLine(
      g,
      right: 'الصنف',
      center: 'الكمية',
      left: 'المجموع',
      fontSize: 14, // Decreased for better fitting
    );
  }

  /// Render table row with three columns
  Future<List<int>> _arabicTableRowLine(
    Generator g, {
    required String item,
    required String quantity,
    required String total,
  }) async {
    return await _arabicThreeColumnLine(
      g,
      right: item,
      center: quantity,
      left: total,
      fontSize: 14, // Decreased for better fitting
    );
  }

  /// Render kitchen table header: الصنف | الكمية
  Future<List<int>> _arabicKitchenTableHeaderLine(Generator g) async {
    return await _arabicTwoColumnLine(
      g,
      right: 'الصنف',
      left: 'الكمية',
      fontSize: 14, // Decreased for better fitting
    );
  }

  /// Render kitchen table row with two columns
  Future<List<int>> _arabicKitchenTableRowLine(
    Generator g, {
    required String item,
    required String quantity,
  }) async {
    return await _arabicTwoColumnLine(
      g,
      right: item,
      left: quantity,
      fontSize: 16, // Decreased for better fitting
    );
  }

  /// Render two-column line for kitchen table display
  Future<List<int>> _arabicTwoColumnLine(
    Generator g, {
    required String right,
    required String left,
    double fontSize = 24,
    double verticalPadding = 2,
  }) async {
    right = useArabicIndicDigits ? _toArabicDigits(right) : right;
    left = useArabicIndicDigits ? _toArabicDigits(left) : left;

    // Define margins and usable width for proper paper fitting
    const int horizontalMargin = 8; // 8px margin on each side
    final int usableWidth = widthPx - (horizontalMargin * 2);

    // Define column widths (in pixels) - Optimized for kitchen readability with margins
    final int rightColWidth = (usableWidth * 0.65).toInt(); // 65% for item name
    final int leftColWidth = (usableWidth * 0.35)
        .toInt(); // 35% for quantity (larger for visibility)

    // Right column (item name) - RTL
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

    // Left column (quantity) - Center aligned
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

    // Calculate height based on tallest paragraph
    final double maxHeight =
        [pRight.height, pLeft.height].reduce((a, b) => a > b ? a : b);
    final int height = (maxHeight + verticalPadding * 2).ceil().clamp(24, 4096);

    // Render to canvas
    Uint8List pngBytes;
    try {
      final rec = ui.PictureRecorder();
      final canvas = ui.Canvas(rec);
      final bg = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
      canvas.drawRect(
          ui.Rect.fromLTWH(0, 0, widthPx.toDouble(), height.toDouble()), bg);

      final double dy =
          ((height - maxHeight) / 2).clamp(0.0, height.toDouble());

      // Apply horizontal margins for proper fitting
      const double marginOffset = 8.0;

      // Draw right column with margin
      canvas.drawParagraph(pRight, ui.Offset(marginOffset, dy));

      // Draw left column
      canvas.drawParagraph(
          pLeft, ui.Offset(marginOffset + rightColWidth.toDouble(), dy));

      final picture = rec.endRecording();
      final uiImg = await picture.toImage(widthPx, height);
      final byteData = await uiImg.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) throw StateError('toByteData returned null');
      pngBytes = byteData.buffer.asUint8List();
    } catch (e, st) {
      _e(debug, '_arabicTwoColumnLine() ✗ rasterize failed: $e\n$st');
      rethrow;
    }

    // Decode and convert to ESC/POS raster
    final decoded = img.decodePng(pngBytes) ?? img.decodeImage(pngBytes);
    if (decoded == null) {
      throw StateError('PNG decode returned null');
    }
    return g.imageRaster(
      decoded,
      align: PosAlign.left,
      highDensityHorizontal: true,
      highDensityVertical: true,
    );
  }

  /// Render three-column line for table display
  Future<List<int>> _arabicThreeColumnLine(
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

    // Define margins and usable width for proper paper fitting
    const int horizontalMargin = 8; // 8px margin on each side
    final int usableWidth = widthPx - (horizontalMargin * 2);

    // Define column widths (in pixels) - Optimized for 80mm paper with margins
    final int rightColWidth = (usableWidth * 0.45).toInt(); // 45% for item name
    final int centerColWidth = (usableWidth * 0.20).toInt(); // 20% for quantity
    final int leftColWidth = (usableWidth * 0.35).toInt(); // 35% for total

    // Right column (item name) - RTL
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

    // Center column (quantity) - Center aligned
    final pStyleCenter = ui.ParagraphStyle(
      textAlign: ui.TextAlign.center,
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      locale: const ui.Locale('ar'),
    );
    final builderCenter = ui.ParagraphBuilder(pStyleCenter)..pushStyle(tStyle);
    builderCenter.addText(center);
    final pCenter = builderCenter.build()
      ..layout(ui.ParagraphConstraints(width: centerColWidth.toDouble()));

    // Left column (total) - LTR, left aligned
    final pStyleLeft = ui.ParagraphStyle(
      textAlign: ui.TextAlign.left,
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      locale: const ui.Locale('en'),
    );
    final builderLeft = ui.ParagraphBuilder(pStyleLeft)..pushStyle(tStyle);
    builderLeft.addText(left);
    final pLeft = builderLeft.build()
      ..layout(ui.ParagraphConstraints(width: leftColWidth.toDouble()));

    // Calculate height based on tallest paragraph
    final double maxHeight = [pRight.height, pCenter.height, pLeft.height]
        .reduce((a, b) => a > b ? a : b);
    final int height = (maxHeight + verticalPadding * 2).ceil().clamp(24, 4096);

    // Render to canvas
    Uint8List pngBytes;
    try {
      final rec = ui.PictureRecorder();
      final canvas = ui.Canvas(rec);
      final bg = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
      canvas.drawRect(
          ui.Rect.fromLTWH(0, 0, widthPx.toDouble(), height.toDouble()), bg);

      final double dy =
          ((height - maxHeight) / 2).clamp(0.0, height.toDouble());

      // Apply horizontal margins for proper fitting
      const double marginOffset = 8.0;

      // Draw right column with margin
      canvas.drawParagraph(pRight, ui.Offset(marginOffset, dy));

      // Draw center column
      canvas.drawParagraph(
          pCenter, ui.Offset(marginOffset + rightColWidth.toDouble(), dy));

      // Draw left column
      canvas.drawParagraph(
          pLeft,
          ui.Offset(
              marginOffset + (rightColWidth + centerColWidth).toDouble(), dy));

      final picture = rec.endRecording();
      final uiImg = await picture.toImage(widthPx, height);
      final byteData = await uiImg.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) throw StateError('toByteData returned null');
      pngBytes = byteData.buffer.asUint8List();
    } catch (e, st) {
      _e(debug, '_arabicThreeColumnLine() ✗ rasterize failed: $e\n$st');
      rethrow;
    }

    // Decode and convert to ESC/POS raster
    final decoded = img.decodePng(pngBytes) ?? img.decodeImage(pngBytes);
    if (decoded == null) {
      throw StateError('PNG decode returned null');
    }
    return g.imageRaster(
      decoded,
      align: PosAlign.left,
      highDensityHorizontal: true,
      highDensityVertical: true,
    );
  }

  // ---------------------------------------------------------------------------
  // CUSTOMER RECEIPT (Arabic, with items)
  // ---------------------------------------------------------------------------
  /// Expects:
  /// order = {
  /// 'orderNumber': ...,
  /// 'paymentMethod': 'Cash'|'Card'|...,
  /// 'subtotal': num?, 'tax': num?, 'tips': num?, 'total': num?
  /// }
  /// items = [
  /// {'name': 'شاورما', 'quantity': 2, 'unitPrice': 1.50, 'notes': 'بدون بصل'},
  /// ...
  /// ]
  ///
  /// If totals not provided, they'll be computed from items (unitPrice * qty).
  Future<Uint8List> buildCustomer(
    Map<String, dynamic> order, {
    List<Map<String, dynamic>>? items,
  }) async {
    final g = Generator(paper, profile);
    final List<int> bytes = [];
    final sw = Stopwatch()..start();

    // Extract items from API response structure (data.orderItems or direct items)
    final List<Map<String, dynamic>> list = items ??
        (order['data']?['orderItems'] as List?)?.cast<Map<String, dynamic>>() ??
        (order['orderItems'] as List?)?.cast<Map<String, dynamic>>() ??
        (order['items'] as List?)?.cast<Map<String, dynamic>>() ??
        [];

    _d(debug, 'buildCustomer() → items=${list.length}');

    // ═══════════════════════════════════════════════════════════════
    // INITIALIZATION - Reset printer state
    // ═══════════════════════════════════════════════════════════════
    bytes.addAll(g.reset()); // Reset printer to ensure clean state

    // ═══════════════════════════════════════════════════════════════
    // HEADER SECTION - Centered Section Name & Order Number
    // ═══════════════════════════════════════════════════════════════

    // Store name (if provided)
    final storeName = (order['storeName'] ?? '').toString();
    if (storeName.isNotEmpty) {
      bytes.addAll(await _arabicTextLineHybrid(
        g,
        storeName,
        align: PosAlign.center,
        fontSize: 20,
      ));
    }

    // Receipt Title - First line centered
    bytes.addAll(await _arabicTextLineHybrid(
      g,
      'فاتورة البيع',
      align: PosAlign.center,
      fontSize: 22,
    ));

    // Order Number - Second line centered
    final orderNo =
        (order['data']?['orderNumber'] ?? order['orderNumber'] ?? '')
            .toString();
    if (orderNo.isNotEmpty) {
      bytes.addAll(await _arabicTextLineHybrid(
        g,
        'رقم الطلب: ${_digits(orderNo)}',
        align: PosAlign.center,
        fontSize: 18,
      ));
    }

    // Payment Method - Centered
    final paymentMethod =
        order['data']?['paymentMethod'] ?? order['paymentMethod'];
    final payAr = _paymentMethodArabic(paymentMethod?.toString() ?? '');
    if (payAr.isNotEmpty) {
      bytes.addAll(await _arabicTextLineHybrid(
        g,
        'طريقة الدفع: $payAr',
        align: PosAlign.center,
        fontSize: 16,
      ));
    }

    bytes.addAll(g.hr(ch: '='));

    // ═══════════════════════════════════════════════════════════════
    // ITEMS TABLE SECTION - With Borders
    // ═══════════════════════════════════════════════════════════════
    bytes.addAll(g.hr(ch: '═')); // Top border
    bytes.addAll(await _arabicTableHeaderLine(g));
    bytes.addAll(g.hr(ch: '─')); // Header separator

    for (int i = 0; i < list.length; i++) {
      final it = list[i];
      // API response uses 'productName' or 'name'
      final String name = (it['productName'] ?? it['name'] ?? 'صنف').toString();
      final num qty = _asNum(it['quantity'], fallback: 1);
      // API response uses 'totalAfterTax' or 'total' for line total
      final num lineTotal =
          _asNum(it['totalAfterTax'] ?? it['total'], fallback: 0);

      // Item Row
      bytes.addAll(await _arabicTableRowLine(
        g,
        item: name,
        quantity: _digits(qty.toString()),
        total: _digits(_money(lineTotal)),
      ));

      // Item Notes (if any)
      final notes = (it['notes'] ?? '').toString().trim();
      if (notes.isNotEmpty) {
        bytes.addAll(await _arabicTextLineHybrid(
          g,
          '   ← $notes',
          align: PosAlign.right,
          fontSize: 14,
        ));
      }
    }

    bytes.addAll(g.hr(ch: '═')); // Bottom border of table

    // ═══════════════════════════════════════════════════════════════
    // TOTALS SECTION - Right-aligned format
    // ═══════════════════════════════════════════════════════════════
    final apiData = order['data'] ?? order;

    num subtotal = _asNum(
        apiData['totalAfterDiscount'] ?? apiData['grandTotal'],
        fallback: 0);
    num discount = _asNum(apiData['discountTotal'], fallback: 0);
    num tax = _asNum(apiData['taxTotal'], fallback: 0);
    num tips = _asNum(apiData['tips'], fallback: 0);
    num total = _asNum(apiData['totalAfterTax'] ?? apiData['grandTotal'],
        fallback: subtotal);

    // Subtotal (only show if different from total)
    if (discount > 0 || tax > 0) {
      bytes.addAll(await _arabicTextLineHybrid(
        g,
        'الإجمالي الفرعي: ${_digits(_money(subtotal - discount))}',
        align: PosAlign.right,
        fontSize: 16,
      ));
    }

    // Discount (if any)
    if (discount > 0) {
      bytes.addAll(await _arabicTextLineHybrid(
        g,
        'الخصم: ${_digits('- ${_money(discount)}')}',
        align: PosAlign.right,
        fontSize: 16,
      ));
    }

    // Tax (if any)
    if (tax > 0) {
      bytes.addAll(await _arabicTextLineHybrid(
        g,
        'الضريبة: ${_digits(_money(tax))}',
        align: PosAlign.right,
        fontSize: 16,
      ));
    }

    // Tips (if any)
    if (tips > 0) {
      bytes.addAll(await _arabicTextLineHybrid(
        g,
        'الإكرامية: ${_digits(_money(tips))}',
        align: PosAlign.right,
        fontSize: 16,
      ));
    }

    bytes.addAll(g.hr(ch: '='));

    // Grand Total
    bytes.addAll(await _arabicTextLineHybrid(
      g,
      'الإجمالي: ${_digits(_money(total))}',
      align: PosAlign.right,
      fontSize: 20,
    ));

    bytes.addAll(g.hr(ch: '='));

    // ═══════════════════════════════════════════════════════════════
    // FOOTER SECTION - Thank you & DateTime
    // ═══════════════════════════════════════════════════════════════
    bytes.addAll(await _arabicTextLineHybrid(
      g,
      'شكراً لزيارتكم',
      align: PosAlign.center,
      fontSize: 16,
    ));

    // Print datetime in footer
    final now = DateTime.now();
    bytes.addAll(await _arabicTextLineHybrid(
      g,
      _digits(DateFormat('yyyy/MM/dd - hh:mm a').format(now)),
      align: PosAlign.center,
      fontSize: 14,
    ));

    // Minimal spacing before cut - no excessive white space
    bytes.addAll(g.feed(3)); // Just 3 lines to ensure paper advances before cut

    // Cut commands
    bytes.addAll(g.cut()); // Standard cut
    bytes.addAll(g.cut(mode: PosCutMode.partial)); // Partial cut as backup

    final out = Uint8List.fromList(bytes);
    _d(debug,
        'buildCustomer() ✓ ${out.length} bytes in ${sw.elapsedMilliseconds}ms');
    return out;
  }

  // ---------------------------------------------------------------------------
  // KITCHEN TICKET (Arabic, items for a single section)
  // ---------------------------------------------------------------------------
  Future<Uint8List> buildKitchen(
    Map<String, dynamic> order, {
    required String kitchenName,
    required List<Map<String, dynamic>> items,
  }) async {
    final g = Generator(paper, profile);
    final List<int> bytes = [];
    final sw = Stopwatch()..start();
    _d(debug,
        'buildKitchen() → start; kitchen="$kitchenName", items=${items.length}');

    try {
      // ═══════════════════════════════════════════════════════════════
      // INITIALIZATION - Reset printer state
      // ═══════════════════════════════════════════════════════════════
      bytes.addAll(g.reset()); // Reset printer to ensure clean state

      // ═══════════════════════════════════════════════════════════════
      // KITCHEN HEADER SECTION - Centered Section Name & Order Number
      // ═══════════════════════════════════════════════════════════════
      bytes.addAll(g.emptyLines(1));

      // Kitchen Name - First line centered
      _d(debug, 'buildKitchen() → rendering kitchen name: "$kitchenName"');
      final nameBytes = await _arabicTextLineHybrid(
        g,
        kitchenName,
        align: PosAlign.center,
        fontSize: 22, // Reduced for better fitting
      );
      _d(debug,
          'buildKitchen() ✓ kitchen name rendered: ${nameBytes.length} bytes');
      bytes.addAll(nameBytes);

      // Order Number - Second line centered
      final orderNo =
          (order['data']?['orderNumber'] ?? order['orderNumber'] ?? '')
              .toString();
      if (orderNo.isNotEmpty) {
        bytes.addAll(await _arabicTextLineHybrid(
          g,
          'طلب رقم: ${_digits(orderNo)}',
          align: PosAlign.center,
          fontSize: 18,
        ));
      }

      bytes.addAll(g.hr(ch: '='));

      // ═══════════════════════════════════════════════════════════════
      // ITEMS TABLE SECTION - With Borders
      // ═══════════════════════════════════════════════════════════════
      bytes.addAll(g.hr(ch: '═')); // Top border
      bytes.addAll(await _arabicKitchenTableHeaderLine(g));
      bytes.addAll(g.hr(ch: '─')); // Header separator

      // Items
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        // API response uses 'productName' or 'name'
        final String name =
            (item['productName'] ?? item['name'] ?? 'صنف').toString();
        final num qty = _asNum(item['quantity'], fallback: 1);
        final String notes = (item['notes'] ?? '').toString().trim();

        _d(debug,
            'buildKitchen() → rendering item ${i + 1}/${items.length}: "$name" (qty: $qty)');

        // Item Row
        try {
          final itemBytes = await _arabicKitchenTableRowLine(
            g,
            item: name,
            quantity: _digits(qty.toString()),
          );
          _d(debug,
              'buildKitchen() ✓ item rendered: ${itemBytes.length} bytes');
          bytes.addAll(itemBytes);
        } catch (e, st) {
          _e(debug, 'buildKitchen() ✗ FAILED to render item "$name": $e\n$st');
          rethrow;
        }

        // Special Instructions/Notes (if present)
        if (notes.isNotEmpty) {
          _d(debug, 'buildKitchen() → rendering notes: "$notes"');
          try {
            final notesBytes = await _arabicTextLineHybrid(
              g,
              '   ★ $notes',
              align: PosAlign.right,
              fontSize: 16,
            );
            _d(debug,
                'buildKitchen() ✓ notes rendered: ${notesBytes.length} bytes');
            bytes.addAll(notesBytes);
            bytes.addAll(g.emptyLines(1));
          } catch (e, st) {
            _e(debug,
                'buildKitchen() ✗ FAILED to render notes "$notes": $e\n$st');
            developer.log(
              '⚠️ buildKitchen() - Failed to render notes, continuing without them.',
              name: 'ReceiptBuilder',
              error: e,
              stackTrace: st,
            );
          }
        }
      }

      bytes.addAll(g.hr(ch: '═')); // Bottom border of table

      // ═══════════════════════════════════════════════════════════════
      // FOOTER - DateTime and Cut
      // ═══════════════════════════════════════════════════════════════
      // Print datetime
      final now = DateTime.now();
      bytes.addAll(await _arabicTextLineHybrid(
        g,
        _digits(DateFormat('yyyy/MM/dd - hh:mm a').format(now)),
        align: PosAlign.center,
        fontSize: 14,
      ));

      // Minimal spacing before cut - no excessive white space
      bytes.addAll(
          g.feed(3)); // Just 3 lines to ensure paper advances before cut

      // Cut commands
      bytes.addAll(g.cut()); // Standard cut
      bytes.addAll(g.cut(mode: PosCutMode.partial)); // Partial cut as backup

      final out = Uint8List.fromList(bytes);
      _d(debug,
          'buildKitchen() ✓ ${out.length} bytes in ${sw.elapsedMilliseconds}ms');
      return out;
    } catch (e, st) {
      _e(debug, 'buildKitchen() ✗✗✗ CRITICAL ERROR: $e\n$st');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // RASTER HELPERS (Arabic shaping + two-column "label ... value")
  // ---------------------------------------------------------------------------
  /// Draw a single Arabic (or mixed) line as raster and return ESC/POS bytes.
  Future<List<int>> _arabicTextLineAsRaster(
    Generator g,
    String text, {
    PosAlign align = PosAlign.center,
    double fontSize = 22,
    double verticalPadding = 2, // Default padding
  }) async {
    // Font is guaranteed to be loaded by create() method

    // Log input
    _d(debug,
        '_arabicTextLineAsRaster() → text: "$text" (len=${text.length}, fontSize=$fontSize, align=$align)');

    text = useArabicIndicDigits ? _toArabicDigits(text) : text;
    final bool hasArabic = _containsArabic(text);

    _d(debug,
        '_arabicTextLineAsRaster() → Arabic detected: $hasArabic, font: $arabicFontFamily');

    // Apply margins for proper paper fitting
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

    // Build paragraph with usable width (excluding margins)
    ui.Paragraph paragraph;
    try {
      _d(debug, '_arabicTextLineAsRaster() → building paragraph...');
      final builder = ui.ParagraphBuilder(paragraphStyle)..pushStyle(textStyle);
      builder.addText(text);
      paragraph = builder.build()
        ..layout(ui.ParagraphConstraints(width: usableWidth.toDouble()));
      _d(debug,
          '_arabicTextLineAsRaster() ✓ paragraph built (height: ${paragraph.height}px)');
    } catch (e, st) {
      _e(debug,
          '_arabicTextLineAsRaster() ✗ FAILED to build/layout paragraph: $e\n$st');
      rethrow;
    }

    final double paraH = paragraph.height;
    final int height = (paraH + verticalPadding * 2).ceil().clamp(24, 4096);
    _d(debug,
        '_arabicTextLineAsRaster() → rendering to ${widthPx}x${height}px canvas');

    // Rasterize to PNG
    Uint8List pngBytes;
    try {
      final rec = ui.PictureRecorder();
      final canvas = ui.Canvas(rec);
      final bg = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
      canvas.drawRect(
          ui.Rect.fromLTWH(0, 0, widthPx.toDouble(), height.toDouble()), bg);
      final double dy = ((height - paraH) / 2).clamp(0.0, height.toDouble());
      // Draw paragraph with horizontal margin
      const double marginOffset = 8.0;
      canvas.drawParagraph(paragraph, ui.Offset(marginOffset, dy));
      final picture = rec.endRecording();

      _d(debug, '_arabicTextLineAsRaster() → converting to image...');
      final uiImg = await picture.toImage(widthPx, height);
      final byteData = await uiImg.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        _e(debug, '_arabicTextLineAsRaster() ✗ toByteData returned null');
        throw StateError('toByteData returned null');
      }

      pngBytes = byteData.buffer.asUint8List();
      _d(debug,
          '_arabicTextLineAsRaster() ✓ rasterized to PNG (${pngBytes.length} bytes)');
    } catch (e, st) {
      _e(debug, '_arabicTextLineAsRaster() ✗ FAILED to rasterize: $e\n$st');
      rethrow;
    }

    // Decode PNG to image
    _d(debug, '_arabicTextLineAsRaster() → decoding PNG...');
    final decoded = img.decodePng(pngBytes) ?? img.decodeImage(pngBytes);
    if (decoded == null) {
      _e(debug, '_arabicTextLineAsRaster() ✗ PNG decode returned null');
      throw StateError('PNG decode returned null');
    }
    _d(debug,
        '_arabicTextLineAsRaster() ✓ PNG decoded (${decoded.width}x${decoded.height})');

    // Convert to ESC/POS raster
    _d(debug, '_arabicTextLineAsRaster() → converting to ESC/POS raster...');
    try {
      final rasterBytes = g.imageRaster(
        decoded,
        align: align,
        highDensityHorizontal: true,
        highDensityVertical: true,
      );
      _d(debug,
          '_arabicTextLineAsRaster() ✓ converted to ESC/POS (${rasterBytes.length} bytes)');
      return rasterBytes;
    } catch (e, st) {
      _e(debug,
          '_arabicTextLineAsRaster() ✗ FAILED to convert to ESC/POS raster: $e\n$st');
      rethrow;
    }
  }

  // ===========================================================================
  // PUBLIC API - These are the ONLY methods you need to call!
  // ===========================================================================

  /// Print a customer receipt in Arabic.
  /// Returns List<int> ready for Android printing (no conversion needed).
  ///
  /// Just call: await printer.writeBytes(Uint8List.fromList(bytes));
  Future<List<int>> printCustomer(Map<String, dynamic> order) async {
    final bytes = await buildCustomer(order);
    return bytes.toList(growable: false); // Android-compatible
  }

  /// Print a kitchen ticket in Arabic.
  /// Returns List<int> ready for Android printing (no conversion needed).
  ///
  /// Just call: await printer.writeBytes(Uint8List.fromList(bytes));
  Future<List<int>> printKitchen(
    Map<String, dynamic> order, {
    required String kitchenName,
    required List<Map<String, dynamic>> items,
  }) async {
    final bytes =
        await buildKitchen(order, kitchenName: kitchenName, items: items);
    return bytes.toList(growable: false); // Android-compatible
  }

  // ---------------------------------------------------------------------------
  // HYBRID HELPERS: Try direct text first, fallback to raster
  // ---------------------------------------------------------------------------
  /// Try direct text, fallback to raster if fails or useRasterFallback is true.
  Future<List<int>> _arabicTextLineHybrid(
    Generator g,
    String text, {
    PosAlign align = PosAlign.center,
    double fontSize = 22,
  }) async {
    // Force raster for Arabic text to ensure it prints correctly on all printers.
    return _arabicTextLineAsRaster(g, text,
        align: align, fontSize: fontSize, verticalPadding: 2);
  }

  // ---------------------------------------------------------------------------
  // Small helpers
  // ---------------------------------------------------------------------------
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

  String _money(num v) => '\$${v.toStringAsFixed(2)}';

  num _asNum(dynamic v, {num fallback = 0}) {
    if (v is num) return v;
    if (v is String) {
      final p = num.tryParse(v);
      if (p != null) return p;
    }
    return fallback;
  }

  bool _containsArabic(String s) =>
      RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(s);

  String _paymentMethodArabic(String en) {
    final s = en.trim().toLowerCase();
    switch (s) {
      case 'cash':
      case 'cash on delivery':
        return 'نقداً';
      case 'card':
      case 'credit':
      case 'debit':
      case 'visa':
      case 'mastercard':
        return 'بطاقة';
      case 'wallet':
      case 'ewallet':
      case 'e-wallet':
        return 'محفظة إلكترونية';
      case 'online':
      case 'gateway':
      case 'stripe':
      case 'paytabs':
      case 'paypal':
        return 'دفع إلكتروني';
      default:
        return en.isEmpty ? '' : en;
    }
  }

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

// ---------------- logging ----------------
void _d(bool debug, String msg) {
  if (debug) {
    final t = DateTime.now().toIso8601String().substring(11, 23);
    // ignore: avoid_print
    print('[RB][D][$t] $msg');
  }
}

void _e(bool debug, String msg) {
  final t = DateTime.now().toIso8601String().substring(11, 23);
  // ignore: avoid_print
  print('[RB][E][$t] $msg');
}
