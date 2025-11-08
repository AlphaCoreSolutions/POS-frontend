import 'dart:convert';
import 'dart:typed_data';
import 'package:esc_pos_utils/esc_pos_utils.dart';

/// A receipt builder specifically optimized for the XP-P501A printer model.
///
/// This builder uses the printer's built-in Arabic character support by:
/// 1. Sending an ESC/POS command to select the Arabic code page.
/// 2. Encoding the Dart string into a `windows-1256` byte array.
/// 3. Sending the raw encoded bytes to the printer.
///
/// This method is more efficient than image-based rendering but is specific
/// to printers that support this command and character set.
class XpP501aReceiptBuilder {
  final PaperSize paper;
  final CapabilityProfile profile;

  /// Enable verbose logs.
  final bool debug;

  /// Optional: convert 0-9 into Arabic-Indic (٠١٢٣٤٥٦٧٨٩). Default: false.
  final bool useArabicIndicDigits;

  XpP501aReceiptBuilder._(
    this.paper,
    this.profile, {
    required this.debug,
    required this.useArabicIndicDigits,
  });

  /// Factory to initialize the capability profile.
  static Future<XpP501aReceiptBuilder> create({
    PaperSize paper = PaperSize.mm80,
    String? profileName,
    bool debug = false,
    bool useArabicIndicDigits = false,
  }) async {
    final sw = Stopwatch()..start();
    _d(debug,
        'XpP501a.create() → loading profile "${profileName ?? 'default'}"...');
    final profile =
        await CapabilityProfile.load(name: profileName ?? 'default');
    _d(debug,
        'XpP501a.create() ✓ profile in ${sw.elapsedMilliseconds}ms; paper=$paper');

    return XpP501aReceiptBuilder._(
      paper,
      profile,
      debug: debug,
      useArabicIndicDigits: useArabicIndicDigits,
    );
  }

  // ---------------------------------------------------------------------------
  // CUSTOMER RECEIPT (Arabic, with items)
  // ---------------------------------------------------------------------------
  Future<Uint8List> buildCustomer(
    Map<String, dynamic> order, {
    List<Map<String, dynamic>>? items,
  }) async {
    final g = Generator(paper, profile);
    final List<int> bytes = [];
    final sw = Stopwatch()..start();
    final List<Map<String, dynamic>> list =
        (items ?? (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
    _d(debug, 'buildCustomer() → items=${list.length}');

    // ---- Header ----
    bytes.addAll(_arabicText(g, 'فاتورة',
        styles: PosStyles(
            bold: true, height: PosTextSize.size2, align: PosAlign.center)));
    bytes.addAll(g.hr());

    // ---- Order info ----
    final orderNo = (order['orderNumber'] ?? '').toString();
    if (orderNo.isNotEmpty) {
      bytes.addAll(_arabicRow(g, 'رقم الطلب', _digits(orderNo)));
    }
    final payAr =
        _paymentMethodArabic((order['paymentMethod'] ?? '').toString());
    if (payAr.isNotEmpty) {
      bytes.addAll(_arabicRow(g, 'طريقة الدفع', payAr));
    }
    bytes.addAll(_arabicRow(g, 'التاريخ والوقت', _digits(_formatNow())));
    bytes.addAll(g.hr());

    // ---- Items (Arabic) ----
    num computedSubtotal = 0;
    for (int i = 0; i < list.length; i++) {
      final it = list[i];
      final String name = (it['name'] ?? 'صنف').toString();
      final num qty = _asNum(it['quantity'], fallback: 1);
      final num unit = _pickPrice(it);
      final num lineTotal = unit * qty;
      computedSubtotal += lineTotal;

      bytes.addAll(_arabicRow(
          g, '${_digits(qty.toString())} × $name', _digits(_money(lineTotal))));
      bytes.addAll(_arabicRow(g, '  سعر الوحدة', _digits(_money(unit)),
          styles: PosStyles(height: PosTextSize.size1)));

      final notes = (it['notes'] ?? '').toString().trim();
      if (notes.isNotEmpty) {
        bytes.addAll(_arabicText(g, 'ملاحظات: $notes',
            styles: PosStyles(align: PosAlign.right)));
      }
    }
    bytes.addAll(g.hr());

    // ---- Money section ----
    num subtotal = _asNum(order['subtotal'], fallback: computedSubtotal);
    num tax = _asNum(order['tax'], fallback: 0);
    num tips = _asNum(order['tips'], fallback: 0);
    num total = _asNum(order['total'], fallback: subtotal + tax + tips);

    bytes.addAll(_arabicRow(g, 'الإجمالي الفرعي', _digits(_money(subtotal))));
    if (tax > 0) {
      bytes.addAll(_arabicRow(g, 'الضريبة', _digits(_money(tax))));
    }
    if (tips > 0) {
      bytes.addAll(_arabicRow(g, 'الإكرامية', _digits(_money(tips))));
    }
    bytes.addAll(g.hr());
    bytes.addAll(_arabicRow(g, 'الإجمالي', _digits(_money(total)),
        styles: PosStyles(bold: true, height: PosTextSize.size2)));
    bytes.addAll(g.hr());

    // ---- Footer ----
    bytes.addAll(
        _arabicText(g, 'شكراً لكم', styles: PosStyles(align: PosAlign.center)));
    bytes.addAll(g.feed(2));
    bytes.addAll(g.cut());

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

    bytes.addAll(_arabicText(g, kitchenName,
        styles: PosStyles(
            bold: true, height: PosTextSize.size2, align: PosAlign.center)));
    bytes.addAll(g.hr());

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final String name = (item['name'] ?? 'صنف').toString();
      final num qty = _asNum(item['quantity'], fallback: 1);
      final String notes = (item['notes'] ?? '').toString();

      bytes.addAll(_arabicText(g, '${_digits(qty.toString())} × $name',
          styles: PosStyles(align: PosAlign.right, height: PosTextSize.size2)));
      if (notes.trim().isNotEmpty) {
        bytes.addAll(_arabicText(g, 'ملاحظات: $notes',
            styles: PosStyles(align: PosAlign.right)));
      }
    }
    bytes.addAll(g.hr());

    final orderNo = (order['orderNumber'] ?? '').toString();
    if (orderNo.isNotEmpty) {
      bytes.addAll(_arabicRow(g, 'رقم الطلب', _digits(orderNo)));
    }
    bytes.addAll(_arabicText(g, _digits(_formatNow()),
        styles: PosStyles(align: PosAlign.center)));
    bytes.addAll(g.feed(1));
    bytes.addAll(g.cut());

    final out = Uint8List.fromList(bytes);
    _d(debug,
        'buildKitchen() ✓ ${out.length} bytes in ${sw.elapsedMilliseconds}ms');
    return out;
  }

  // ---------------------------------------------------------------------------
  // Core Arabic Printing Helpers
  // ---------------------------------------------------------------------------

  /// Selects the Arabic code page, sends the encoded text, and reverts to the default page.
  List<int> _arabicText(Generator generator, String text,
      {PosStyles styles = const PosStyles()}) {
    List<int> bytes = [];
    // Select Arabic code page (PC864)
    bytes += [0x1b, 0x74, 0x16];
    // Set text alignment
    bytes += generator.setStyles(styles.copyWith(align: styles.align));
    // Encode text to Windows-1256 and add to buffer
    bytes += windows1256.encode(text);
    // Add a newline
    bytes += generator.text('');
    // Revert to default code page
    bytes += [0x1b, 0x74, 0x00];
    return bytes;
  }

  /// Prints a two-column row with Arabic text, correctly aligned.
  List<int> _arabicRow(Generator generator, String col1, String col2,
      {PosStyles styles = const PosStyles()}) {
    List<int> bytes = [];
    // Select Arabic code page
    bytes += [0x1b, 0x74, 0x16];
    // Encode texts
    final encCol1 = windows1256.encode(col1);
    final encCol2 = windows1256.encode(col2);
    // Use g.row to handle spacing and alignment.
    // We pass the raw encoded bytes to avoid re-encoding.
    bytes += generator.row([
      PosColumn(
          textEncoded: encCol1,
          width: 6,
          styles: styles.copyWith(align: PosAlign.right)),
      PosColumn(
          textEncoded: encCol2,
          width: 6,
          styles: styles.copyWith(align: PosAlign.left)),
    ]);
    // Revert to default code page
    bytes += [0x1b, 0x74, 0x00];
    return bytes;
  }

  // ---------------------------------------------------------------------------
  // Small helpers
  // ---------------------------------------------------------------------------
  String _money(num v) => '\$${v.toStringAsFixed(2)}';

  num _asNum(dynamic v, {num fallback = 0}) {
    if (v is num) return v;
    if (v is String) {
      final p = num.tryParse(v);
      if (p != null) return p;
    }
    return fallback;
  }

  num _pickPrice(Map<String, dynamic> it) {
    final keys = [
      'unitPrice',
      'price',
      'unit_price',
      'unit_price_amount',
      'amount'
    ];
    for (final k in keys) {
      if (it.containsKey(k)) {
        final v = _asNum(it[k]);
        if (v > 0) return v;
      }
    }
    return 0;
  }

  String _formatNow() {
    final now = DateTime.now();
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
  }

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
    print('[XpP501a][D][$t] $msg');
  }
}
