import 'dart:async';
import 'dart:convert';
import 'dart:typed_data'; // For Uint8List
import 'dart:ui' as ui;
import 'package:image/image.dart' as img; // for image raster
import 'package:esc_pos_utils/esc_pos_utils.dart'; // you already use it

import 'package:visionpos/L10n/app_localizations.dart';
import 'package:visionpos/components/printer_setup_dialog.dart';
import 'package:visionpos/language_changing/constants.dart';
import 'package:visionpos/models/order_dto.dart';
import 'package:visionpos/models/order_item_addition_dto.dart';
import 'package:visionpos/models/order_item_dto.dart';
import 'package:visionpos/models/promocodes_model.dart';
import 'package:visionpos/models/taxes_model.dart';
import 'package:visionpos/pages/add_pages/add_category.dart';
import 'package:visionpos/pages/essential_pages/api_handler.dart';
import 'package:visionpos/models/category_model.dart';
import 'package:visionpos/models/product_model.dart';
import 'package:visionpos/services/arabic_font_loader.dart';
import 'package:visionpos/utils/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:visionpos/services/bluetooth_printing_service.dart';
import 'package:visionpos/services/receipt_builder.dart';
import 'package:visionpos/services/kitchen_router.dart';
import 'package:visionpos/services/triple_printer.dart';
import 'package:flutter/foundation.dart' show setEquals, listEquals;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  final _barcodeController = TextEditingController();
  final _barcodeFocus = FocusNode();
  String _barcodeBuffer = '';
  late List<dynamic> data = [];
  Product? selectedProduct;
  List<Product> products = [];
  bool isLoading = false;
  List<Product> searchResults = [];
  Product? productSearch;
  OverlayEntry? overlayEntry;
  int userId = 1;
  int ordeId = 0;
  int? _orgId;
  // ignore: unused_field
  List<Category> _categories = [];

  // One-shot print guard
  late final TriplePrinter printer;

  Future<void> _loadOrganizationId() async {
    final orgId = await SessionManager.getOrganizationId();
    setState(() => _orgId = orgId);
  }

  Future<void> _loadCategories() async {
    final org = await SessionManager.getOrganizationId();
    final cats = await ApiHandler().getCategoriesForOrg(org ?? 0);
    setState(() => _categories = cats);
  }

  //---------------------------------------------------------------
  Category? selectedCategory;
  List<Category> _all = [];
  List<Category> _rootCategories = [];
  List<Category> _activeSubs = [];
  // ignore: unused_field
  Category? _selectedRoot;
  int? _selectedSubId;
  late final ScrollController _subsCtrl;
  Map<int, String> get _catNameById => {
        for (final c in _all) c.id: c.categoryName,
      }; // _all: List<Category>

  //--------------------------------------------------------------
  ApiHandler apiHandler = ApiHandler();
  TextEditingController searchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  //---------------------------------------------------------------
  List<OrderItemDto> selectedItems = [];
  double subtotal = 0.0;
  double taxes = 0.0;
  double total = 0.0;
  Map<int, double> productPrices = {};
  double tips = 0.0;
  //String orderStatus = '';
  int paymentMethod = 1; // 1 for Cash, 2 for Visa
  bool isCash = true; // Initially set to 'Cash'
  double switchScale = 0.8;
  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  int? get selectedRootId => selectedCategory?.id;
  int? get selectedSubId => _selectedSubId;
  //---------------------------------------------------------------
  final TextEditingController promoCodeController = TextEditingController();
  final TextEditingController _tipController = TextEditingController();
  OverlayEntry? overlayEntrypromo;
  final LayerLink _layerLinkpromo = LayerLink();
  List<Promocodes> searchResultspromo = [];
  Promocodes? selectedPromoCode;
  double discount = 0.0;
  double discountPercentage = 0.0;
  int orderCount = 0;
  //---------------------------------------------------------------
  Taxes? currentTaxes;
  String selectedTaxType = 'In-House'; // Default is In-House
  //---------------------------------------------------------------
  double xOffset = 0;
  double yOffset = 0;
  bool isDrawerOpen = false;
  //---------------------------------------------------------------
  // ignore: unused_field
  String _info = "";
  // ignore: unused_field
  String _msj = '';
  bool connected = false;
  List<BluetoothDevice> items = [];
  String optionprinttype = "58 mm";
  List<String> options = ["58 mm", "80 mm"];
  // ignore: unused_field
  final TextEditingController _txtText = TextEditingController(
    text: "Hello developer",
  );
  // ignore: unused_field
  bool _progress = false;
  // ignore: unused_field
  String _msjprogress = "";
  // ignore: unused_field
  final String _selectSize = "2";
  String formattedTime = DateFormat('hh:mm a').format(DateTime.now());

  List<Category> _allCategories = [];

  // ignore: unused_element
  Future<void> _loadCats() async {
    final org = await SessionManager.getOrganizationId();
    _allCategories = await ApiHandler().getCategoriesForOrg(org ?? 0);
    _rootCategories = ApiHandler().rootsOf(_allCategories);
    _buildCategoryIndices(_allCategories);
    setState(() {});
  }

  void _buildCategoryIndices(List<Category> all) {
    _catById.clear();
    _subIdsByRoot.clear();

    for (final c in all) {
      _catById[c.id] = c;
      final parent = c.id;
      // ignore: unnecessary_null_comparison
      if (parent != null) {
        (_subIdsByRoot[parent] ??= <int>[]).add(c.id);
      }
    }
  }

  final Map<int, Category> _catById = {};
  final Map<int, List<int>> _subIdsByRoot = {};

  void _onRootTap(Category? cat) {
    setState(() {
      selectedCategory = cat; // null => All
      _selectedSubId = null; // reset any sub
      if (cat == null) {
        _activeSubs = const [];
      } else {
        final rootId = _toInt(cat.mainCategoryId);
        _activeSubs = _allCategories
            .where(
              (c) => _toInt(c.mainCategoryId) == rootId,
            ) // children of this root
            .toList();
      }
    });
  }

  void _onSubTap(Category sub) {
    setState(() => _selectedSubId = sub.id);
  }

  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.storage,
    ].request();

    statuses.forEach((permission, status) {
      if (status.isDenied) {
        print('$permission is denied');
      } else if (status.isPermanentlyDenied) {
        print('$permission is permanently denied. Open app settings.');
      } else {
        print('$permission granted');
      }
    });
  }

  Future<void> initPlatformState() async {
    String platformVersion;

    try {
      // blue_thermal_printer doesn't provide platform version or battery level
      platformVersion = 'BlueThermal v1.2.3';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    final bool? result = await _bluetooth.isAvailable;
    _msj = (result == true)
        ? "Bluetooth enabled, please search and connect"
        : "Bluetooth not enabled";

    setState(() {
      _info = platformVersion;
    });
  }

  Future<void> getBluetoothDevices() async {
    setState(() {
      _progress = true;
      _msjprogress = "Wait";
      items = [];
    });

    final List<BluetoothDevice> listResult =
        await _bluetooth.getBondedDevices();

    setState(() {
      _progress = false;
      items = listResult;
    });
  }

  Future<void> connectToPrinter(String macAddress) async {
    setState(() {
      _progress = true;
      _msjprogress = "Connecting...";
      connected = false;
    });

    try {
      // Find device by MAC address
      final devices = await _bluetooth.getBondedDevices();
      final device = devices.firstWhere(
        (d) => d.address == macAddress,
        orElse: () => throw Exception('Device not found'),
      );

      // Connect with timeout
      await _bluetooth.connect(device).timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Connection timeout'),
          );

      setState(() {
        connected = true;
      });
    } catch (e) {
      debugPrint('Connection error: $e');
      setState(() {
        connected = false;
      });
    }

    setState(() {
      _progress = false;
    });
  }

  Future<void> disconnectPrinter() async {
    try {
      await _bluetooth.disconnect();
    } catch (e) {
      debugPrint('Disconnect error: $e');
    }
    setState(() {
      connected = false;
    });
  }

  Future<void> _printReceipt() async {
    try {
      if (selectedItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.shopping_cart_outlined, color: Colors.white),
                  SizedBox(width: 8),
                  Text('لا توجد عناصر للطباعة'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final btConnected = await _bluetooth.isConnected;
      if (!(connected == true && btConnected == true)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.bluetooth_disabled, color: Colors.white),
                  SizedBox(width: 8),
                  Text('الطابعة غير متصلة، الرجاء الاتصال أولاً'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('جاري طباعة الفاتورة...'),
              ],
            ),
            duration: Duration(milliseconds: 800),
          ),
        );
      }

      // 1️⃣ Build enriched items (additions + notes) for ReceiptBuilder
      //    We go through the in-memory products once and index them by id.
      final productsById = {
        for (final p in products) p.productId: p,
      };

      final List<Map<String, dynamic>> items = selectedItems.map((it) {
        final prod = productsById[it.productId];

        // base unit price: prefer item.price if user entered it,
        // otherwise fall back to product.sellingPrice
        final double basePrice =
            (it.price != 0.0 ? it.price : (prod?.sellingPrice ?? 0.0));

        double additionsTotal = 0.0;
        final List<Map<String, dynamic>> additions = it.additions.map((a) {
          // ignore: unused_local_variable
          dynamic dd;
          try {
            dd = prod?.additions
                .firstWhere((d) => d.domainDetailId == a.domainDetailId);
          } catch (_) {
            dd = null;
          }

          return {
            'domainDetailId': a.domainDetailId,
          };
        }).toList();

        final double lineTotal =
            (basePrice! + additionsTotal) * it.quantity.toDouble();

        return {
          'productId': it.productId,
          'productName': (prod?.productName ?? '').toString().trim(),
          'quantity': it.quantity,
          'unitPrice': basePrice,
          'price': basePrice,
          'totalAfterTax': lineTotal, // 👈 used by ReceiptBuilder row total
          'additions': additions, // 👈 used by ReceiptBuilder to print lines
          'notes': it.notes ?? '', // 👈 real notes
          'categoryId': prod?.categoryId,
        };
      }).toList();

      // 2️⃣ Create ReceiptBuilder (customer)
      final builder = await ReceiptBuilder.create(
        paper: PaperSize.mm80,
        widthPxOverride: 512,
        arabicFontFamily: 'NotoNaskhArabic',
        arabicFontAssetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
        useArabicIndicDigits: true,
      );

      // 3️⃣ Totals (you can later adjust _calculateSubtotal/_calculateTaxes
      //    to include additions if you want the printed totals to include them)
      final double sub = _calculateSubtotal(selectedItems);
      final double tax = _calculateTaxes(selectedItems);
      final double tip = tips;
      final double grand = _calculateTotal(selectedItems);

      final int pm = paymentMethod;
      final String orderNo =
          (orderCount).clamp(1, 999999).toString().padLeft(4, '0');

      // 4️⃣ Order map in the format ReceiptBuilder expects
      final Map<String, dynamic> orderMap = {
        'data': {
          'orderNumber': orderNo,
          'paymentMethod': pm,
          'orderItems': items,
          'totalAfterDiscount': sub,
          'discountTotal': 0.0,
          'taxTotal': tax,
          'tips': tip,
          'totalAfterTax': grand,
          'grandTotal': grand,
        },
        // Also expose items at top level so _extractItems() can see them first
        'items': items,
      };

      final sw = Stopwatch()..start();
      final List<int> bytes = await builder.printCustomer(
        orderMap,
        items: items,
        orderNumber: orderNo,
        storeName: 'متجر رؤية',
        resolve: (int id) => _getProductById(id),
      );
      sw.stop();
      debugPrint(
          'Receipt generated: ${bytes.length} bytes in ${sw.elapsedMilliseconds}ms');

      // 5️⃣ Try to send to printer with retries
      bool printSuccess = false;
      int retry = 0;
      const maxRetries = 2;

      while (!printSuccess && retry <= maxRetries) {
        try {
          await _bluetooth.writeBytes(Uint8List.fromList(bytes));
          printSuccess = true;
          debugPrint('Print successful on attempt ${retry + 1}');
        } catch (err) {
          debugPrint('Print attempt ${retry + 1} error: $err');
          if (retry < maxRetries) {
            await Future.delayed(const Duration(seconds: 1));
            retry++;
          } else {
            break;
          }
        }
      }

      if (mounted) {
        if (printSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('✅ تم إرسال الفاتورة للطابعة بنجاح'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('❌ فشل في الطباعة بعد عدة محاولات')),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'إعادة المحاولة',
                textColor: Colors.white,
                onPressed: _printReceipt,
              ),
            ),
          );
        }
      }
    } catch (e, st) {
      debugPrint('Print error: $e');
      debugPrint('Stack trace: $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'خطأ في الطباعة: ${e.toString().substring(0, e.toString().length > 50 ? 50 : e.toString().length)}...',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'تفاصيل',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تفاصيل الخطأ'),
                    content: SingleChildScrollView(child: Text(e.toString())),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إغلاق'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> printArabicSmokeTest() async {
    // Must be connected already
    final connectedNow = await _bluetooth.isConnected;
    if (connectedNow != true) {
      // ignore: avoid_print
      print('SmokeTest: printer not connected');
      return;
    }

    // Load font
    await ArabicFontLoader.ensureLoaded(
      family: 'NotoNaskhArabic',
      assetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
    );

    // Build a single raster line
    final profile = await CapabilityProfile.load();
    final paper = PaperSize.mm80; // change to mm58 if needed
    final widthPx = 576; // 80mm ~576, 58mm ~384
    final gen = Generator(paper, profile);
    final bytes = <int>[];

    Future<img.Image?> render(String text) async {
      final style = ui.TextStyle(
        fontFamily: 'NotoNaskhArabic',
        color: const ui.Color(0xFF000000),
        fontSize: 28,
        fontWeight: ui.FontWeight.w600,
      );
      final pStyle = ui.ParagraphStyle(
        textDirection: ui.TextDirection.rtl,
        textAlign: ui.TextAlign.center,
        maxLines: null,
      );
      final b = ui.ParagraphBuilder(pStyle)
        ..pushStyle(style)
        ..addText(text);
      final p = b.build()
        ..layout(ui.ParagraphConstraints(width: widthPx.toDouble()));
      final h = p.height.ceil();
      final rec = ui.PictureRecorder();
      final c = ui.Canvas(rec);
      c.drawRect(ui.Rect.fromLTWH(0, 0, widthPx.toDouble(), h.toDouble()),
          ui.Paint()..color = const ui.Color(0xFFFFFFFF));
      c.drawParagraph(p, const ui.Offset(0, 0));
      final pic = rec.endRecording();
      final imgUi = await pic.toImage(widthPx, h);
      final bd = await imgUi.toByteData(format: ui.ImageByteFormat.png);
      if (bd == null) return null;
      return img.decodePng(bd.buffer.asUint8List());
    }

    final im = await render('مرحبا بالعالم — اختبار العربية');
    if (im == null) {
      // ignore: avoid_print
      print('SmokeTest: failed to render image');
      return;
    }

    // Try imageRaster, then fallback to image
    try {
      bytes.addAll(gen.imageRaster(im, align: PosAlign.center));
    } catch (_) {
      // ignore: avoid_print
      print('SmokeTest: imageRaster failed, trying image()');
      bytes.addAll(gen.image(im, align: PosAlign.center));
    }
    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.cut());

    await _bluetooth.writeBytes(Uint8List.fromList(bytes));
  }

  /*
  Future<void> printTestReceipt() async {
    bool connectionStatus = await PrintBluetoothThermal.connectionStatus;

    if (connectionStatus) {
      bool result;
      if (Platform.isWindows) {
        List<int> ticket = await generateWindowsTicket();
        result = await PrintBluetoothThermalWindows.writeBytes(bytes: ticket);
      } else {
        List<int> ticket = await generatePrintTicket();
        result = await PrintBluetoothThermal.writeBytes(ticket);
      }
      print("Print test result: $result");
    } else {
      disconnectPrinter();
    }
  }
*/

  Future<List<int>> generateWindowsTicket(
    OrderDto order,
    List<Product> products,
  ) async {
    // ----- Adjust these to your printer -----
// set true if your printer is 80mm
    final paper = PaperSize.mm58;
    final int widthPx = 384; // 58mm ≈ 384 px, 80mm ≈ 576 px

    // Arabic font must exist in pubspec with same family name
    const String arabicFontFamily = 'NotoNaskhArabic';

    // 1) Load the font (very important)
    await ArabicFontLoader.ensureLoaded(
      family: arabicFontFamily,
      assetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
    );

    // 2) ESC/POS generator
    final profile = await CapabilityProfile.load();
    final gen = Generator(paper, profile);
    final bytes = <int>[];

    // 3) Join items with products by productId
    final byId = <int, Product>{for (final p in products) p.productId: p};

    // ---------- helpers ----------
    PosAlign pos(TextAlign a) => a == TextAlign.center
        ? PosAlign.center
        : a == TextAlign.right
            ? PosAlign.right
            : PosAlign.left;

    // Render one line with Flutter text engine
    Future<img.Image?> renderLine({
      required String text,
      required bool rtl,
      required TextAlign align,
      double fontSize = 30, // bigger = cleaner
      bool bold = true, // slightly heavier strokes
    }) async {
      final style = ui.TextStyle(
        fontFamily: arabicFontFamily,
        color: const ui.Color(0xFF000000),
        fontSize: fontSize,
        fontWeight: bold ? ui.FontWeight.w600 : ui.FontWeight.w400,
      );

      final pStyle = ui.ParagraphStyle(
        textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        textAlign: align == TextAlign.center
            ? ui.TextAlign.center
            : align == TextAlign.right
                ? ui.TextAlign.right
                : ui.TextAlign.left,
        maxLines: null,
      );

      final builder = ui.ParagraphBuilder(pStyle)
        ..pushStyle(style)
        ..addText(text);
      final paragraph = builder.build()
        ..layout(ui.ParagraphConstraints(width: widthPx.toDouble()));

      final h = paragraph.height.ceil();
      if (h <= 0) return null;

      final rec = ui.PictureRecorder();
      final canvas = ui.Canvas(rec);
      // solid white background (avoid dither noise)
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, widthPx.toDouble(), h.toDouble()),
        ui.Paint()..color = const ui.Color(0xFFFFFFFF),
      );
      canvas.drawParagraph(paragraph, const ui.Offset(0, 0));
      final pic = rec.endRecording();
      final uiImg = await pic.toImage(widthPx, h);
      final bd = await uiImg.toByteData(format: ui.ImageByteFormat.png);
      if (bd == null) return null;
      return img.decodePng(bd.buffer.asUint8List());
    }

    // Convert to pure black/white with a threshold (no error-diffusion dithering)
    img.Image toBW(img.Image src, {int threshold = 200}) {
      final out = img.Image.from(src);
      for (int y = 0; y < out.height; y++) {
        for (int x = 0; x < out.width; x++) {
          final c = out.getPixel(x, y);
          final r = img.getRed(c);
          final g = img.getGreen(c);
          final b = img.getBlue(c);
          // simple luma
          final l = (0.299 * r + 0.587 * g + 0.114 * b).round();
          final v = (l < threshold) ? 0 : 255;
          out.setPixelRgba(x, y, v, v, v, 255);
        }
      }
      return out;
    }

    Future<void> line({
      required String text,
      bool rtl = false,
      TextAlign align = TextAlign.left,
      double size = 30, // larger default
      bool bold = true,
    }) async {
      final im = await renderLine(
          text: text, rtl: rtl, align: align, fontSize: size, bold: bold);
      if (im == null) return;

      // Ensure exact width & binarize
      final resized =
          im.width == widthPx ? im : img.copyResize(im, width: widthPx);
      final bw = toBW(resized, threshold: 200); // tweak 180..220 if needed

      // Some printers hate GS v 0; try raster first, then legacy
      try {
        bytes.addAll(gen.imageRaster(bw, align: pos(align)));
      } catch (_) {
        bytes.addAll(gen.image(bw, align: pos(align)));
      }
    }

    String fmtQty(double q) => (q.truncateToDouble() == q)
        ? q.toStringAsFixed(0)
        : q.toStringAsFixed(2);

    // ---------- header ----------
    await line(
        text: 'أبو كاف',
        rtl: true,
        align: TextAlign.center,
        size: 34,
        bold: true);
    await line(text: '', size: 12, bold: false);

    // ---------- items ----------
    for (final it in order.orderItems) {
      final p = byId[it.productId];
      final name = p?.productName ?? 'غير معروف';
      final unit = p?.sellingPrice ?? 0.0;
      final qty = it.quantity;
      final disc = it.discount;
      final lineTotal = (unit * qty) - disc;

      await line(
        text: '$name ×${fmtQty(qty)}  —  ${lineTotal.toStringAsFixed(2)}',
        rtl: true,
        align: TextAlign.left,
        size: 28,
        bold: false,
      );

      if (disc > 0) {
        await line(
          text: 'خصم: ${disc.toStringAsFixed(2)}',
          rtl: true,
          align: TextAlign.right,
          size: 24,
          bold: false,
        );
      }
    }

    await line(
        text: '——————————————', align: TextAlign.center, size: 22, bold: false);

    // ---------- totals ----------
    final grand = order.grandTotal.toDouble();
    final tip = (order.tips != 0.0 ? order.tips : order.tips).toDouble();
    final pm = order.paymentMethod;

    await line(
      text: 'الإجمالي: ${grand.toStringAsFixed(2)}',
      rtl: true,
      align: TextAlign.right,
      size: 30,
      bold: true,
    );

    if (tip > 0) {
      await line(
        text: 'البقشيش: ${tip.toStringAsFixed(2)}',
        rtl: true,
        align: TextAlign.right,
        size: 26,
        bold: false,
      );
    }

    await line(
      text: 'طريقة الدفع: $pm',
      rtl: true,
      align: TextAlign.right,
      size: 26,
      bold: false,
    );

    await line(text: '', size: 12, bold: false);
    await line(
        text: 'شكرًا لزيارتكم',
        rtl: true,
        align: TextAlign.center,
        size: 28,
        bold: true);

    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.cut());
    return bytes;
  }

  Future<List<int>> generatePrintTicket() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    List<int> bytes = [];
    bytes += generator.text("Test Print");
    bytes += generator.cut();

    return bytes;
  }

  void _showPrinterDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Select Printer',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: const Color(0xFFB87333), // dark orange
                    ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5C42), // brown
                  ),
                ), dialogTheme: DialogThemeData(backgroundColor: Colors.grey[100]),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select a Printer',
                        style: TextStyle(
                          color: const Color(0xFF36454F),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: items.isNotEmpty
                            ? ListView.separated(
                                itemCount: items.length,
                                separatorBuilder: (_, __) => Divider(
                                  color: Colors.grey.shade300,
                                  height: 1,
                                ),
                                itemBuilder: (ctx, i) {
                                  final device = items[i];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        Navigator.pop(context);
                                        connectToPrinter(device.address ?? '');
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(
                                            device.name ?? 'Unknown',
                                            style: TextStyle(
                                              color: Color(0xFF36454F),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            device.address ?? '',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          trailing: Icon(
                                            Icons.bluetooth,
                                            color: const Color(0xFFB87333),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Text(
                                  'No paired Bluetooth printers found.',
                                  style: TextStyle(color: Colors.grey[700]),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                      ),
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
    );
  }

  void _togglePaymentMethod(bool value) {
    setState(() {
      isCash = value;
      paymentMethod = isCash ? 1 : 2;
      //isCash ? 'Cash' : 'Visa'; // Toggle between 'Cash' and 'Visa'
    });
  }

  Future<void> _fetchTaxes() async {
    try {
      final taxes = await apiHandler.getTaxes();
      setState(() {
        currentTaxes = taxes;
      });
    } catch (e) {
      print('Error fetching taxes: $e');
    }
  }

  void _removeOverlaypromo() {
    overlayEntrypromo?.remove();
    overlayEntrypromo = null;
  }

  void _showOverlaypromo(BuildContext context) {
    _removeOverlaypromo(); // Remove previous overlay if any

    final overlay = Overlay.of(context);
    if (searchResultspromo.isEmpty) return;

    overlayEntrypromo = OverlayEntry(
      builder: (context) => Positioned(
        width:
            MediaQuery.of(context).size.width * 0.42, // Adjust width if needed
        child: CompositedTransformFollower(
          link: _layerLinkpromo,
          showWhenUnlinked: false,
          offset: const Offset(0, 50), // Adjust dropdown position
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: searchResultspromo.map((promo) {
                  return ListTile(
                    title: Text(promo.PromoCode),
                    onTap: () {
                      selectedPromoCode = promo; // Set the selected promo code
                      promoCodeController.text =
                          promo.PromoCode; // Update TextField
                      discount = promo.Percentage;
                      searchResultspromo = []; // Clear search results
                      _removeOverlaypromo(); // Hide dropdown
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntrypromo!); // Insert overlay into the widget tree
  }

  void findPromoCode(String query) async {
    if (query.isEmpty) {
      _removeOverlaypromo(); // Hide overlay if search is empty
      return;
    }

    List<Promocodes> allPromoCodes =
        await apiHandler.fetchPromoCodes(); // Use instance

    List<Promocodes> filteredPromoCodes = allPromoCodes
        .where(
          (promo) =>
              promo.PromoCode.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    if (filteredPromoCodes.isEmpty) {
      _removeOverlaypromo(); // Hide dropdown if no results
      return;
    }

    searchResultspromo = filteredPromoCodes; // Update search results
    _showOverlaypromo(context); // Show the dropdown above the TextField
  }

  void _removeProductFromOrder(int index) {
    if (index < 0 || index >= selectedItems.length) {
      print("Invalid index");
      return;
    }

    setState(() {
      int productId = selectedItems[index].productId;

      // Get the product using the function
      //var product = _getProductById(productId);
      /*
    // Restore the product quantity
    if (product.productId != 0) {
      if(product.productInventory != 0){
        product.productInventory += 1;  // Increase quantity back
      }
    }
    */

      selectedItems[index] = selectedItems[index].updateQuantity(
        selectedItems[index].quantity - 1,
      );

      if (selectedItems[index].quantity == 0) {
        productPrices.remove(productId); // Remove price from map
        selectedItems.removeAt(index);
      }
    });
  }

  void _addQuantity(int index) {
    if (index < 0 || index >= selectedItems.length) {
      print("Invalid index");
    }
    setState(() {
      selectedItems[index] = selectedItems[index].updateQuantity(
        selectedItems[index].quantity + 1,
      );
    });
  }

  double _getProductPrice(int productId) {
    return productPrices[productId] ?? 0.0;
  }

  Future<void> addToOrder(Product product) async {
    AdditionsSelectionResult? selection;

    // 1️⃣ Show dialog if product has additions
    if (product.additions.isNotEmpty) {
      selection = await showAdditionsDialog(context, product);
      if (selection == null) {
        // user cancelled
        return;
      }
    }

    setState(() {
      final String? newNotes = selection?.notes;
      final newAdditions =
          selection?.additions ?? const <OrderItemAdditionDto>[]; // 👈 here

      // 2️⃣ Find an existing line with SAME product + SAME notes + SAME additions
      final int index = selectedItems.indexWhere((item) {
        if (item.productId != product.productId) return false;

        final existingNotes = (item.notes ?? '').trim();
        final targetNotes = (newNotes ?? '').trim();
        if (existingNotes != targetNotes) return false;

        final existingAddIds =
            item.additions.map((a) => a.domainDetailId).toSet();
        final targetAddIds = newAdditions.map((a) => a.domainDetailId).toSet();

        return setEquals(existingAddIds, targetAddIds);
      });

      if (index != -1) {
        // 3️⃣ Same config → just bump quantity
        final current = selectedItems[index];
        selectedItems[index] = current.updateQuantity(current.quantity + 1);
      } else {
        // 4️⃣ New config → create new row WITH additions + notes
        selectedItems.add(
          OrderItemDto(
            productId: product.productId,
            quantity: 1,
            discount: 0.0,
            price: (() {
              final p = product.sellingPrice;
              if (p != 0.0) return p;

              // If selling price is 0, schedule a dialog after this frame to ask user for a price.
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                final priceCtrl = TextEditingController();
                final double? entered = await showDialog<double?>(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) {
                    return AlertDialog(
                      title: Text('Enter price for "${product.productName}"'),
                      content: TextField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(hintText: '0.00'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(null),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final v = double.tryParse(priceCtrl.text);
                            Navigator.of(ctx).pop(v);
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );

                if (!mounted) return;

                if (entered != null) {
                  setState(() {
                    // Find the last added matching item (just added above with price 0)
                    final idx = selectedItems.lastIndexWhere((it) =>
                        it.productId == product.productId &&
                        (it.notes ?? '') == (newNotes ?? '') &&
                        listEquals(
                            it.additions.map((a) => a.domainDetailId).toList(),
                            newAdditions
                                .map((a) => a.domainDetailId)
                                .toList()));

                    if (idx != -1) {
                      final old = selectedItems[idx];
                      selectedItems[idx] = OrderItemDto(
                        productId: old.productId,
                        quantity: old.quantity,
                        discount: old.discount,
                        price: entered,
                        notes: old.notes,
                        additions: old.additions,
                      );
                      productPrices[product.productId] = entered;
                    }
                  });
                } else {
                  // User cancelled: remove the placeholder item we added with price 0
                  setState(() {
                    final idx = selectedItems.lastIndexWhere((it) =>
                        it.productId == product.productId &&
                        it.price == 0.0 &&
                        (it.notes ?? '') == (newNotes ?? '') &&
                        listEquals(
                            it.additions.map((a) => a.domainDetailId).toList(),
                            newAdditions
                                .map((a) => a.domainDetailId)
                                .toList()));
                    if (idx != -1) selectedItems.removeAt(idx);
                  });
                }
              });

              // Temporarily return 0.0 as the price (will be updated by dialog result)
              return 0.0;
            })(),
            notes: newNotes, // ✅ notes stored here
            additions: newAdditions, // ✅ additions stored here
          ),
        );
      }

      productPrices[product.productId] = product.sellingPrice;
    });
  }

  Future<AdditionsSelectionResult?> showAdditionsDialog(
    BuildContext context,
    Product product,
  ) {
    final additions = product.additions;
    final selected = <int>{};
    final notesController = TextEditingController();

    // Your custom palette
    const Color bgColor = ui.Color.fromARGB(255, 255, 255, 255);
    const Color accentColor = Color(0xFFB87333);
    const Color textColor = ui.Color.fromARGB(255, 0, 0, 0);

    return showDialog<AdditionsSelectionResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              backgroundColor: bgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                product.productName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (additions.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: additions.map((d) {
                          final checked = selected.contains(d.domainDetailId);
                          return CheckboxListTile(
                            value: checked,
                            activeColor: accentColor,
                            checkColor: textColor,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              '${d.name} (+${d.priceIncrease.toStringAsFixed(2)})',
                              style: const TextStyle(
                                color: textColor,
                                fontSize: 14,
                              ),
                            ),
                            onChanged: (value) {
                              setStateDialog(() {
                                if (value == true) {
                                  selected.add(d.domainDetailId);
                                } else {
                                  selected.remove(d.domainDetailId);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        labelStyle: const TextStyle(
                          color: accentColor,
                          fontSize: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.black,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: accentColor,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: bgColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  style: TextButton.styleFrom(
                    foregroundColor: textColor,
                  ),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final additionsDtos = selected.map((id) {
                      final dd = additions.firstWhere(
                        (d) => d.domainDetailId == id,
                      );

                      return OrderItemAdditionDto(
                        domainDetailId: dd.domainDetailId,
                      );
                    }).toList();

                    Navigator.of(dialogContext).pop(
                      AdditionsSelectionResult(
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                        additions: additionsDtos,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: textColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'تأكيد',
                    style: TextStyle(color: bgColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  double _calculateItemTotal(OrderItemDto item) {
    // 1. Base price: prefer the item's own price, fall back to product price
    final double basePrice =
        (item.price != 0.0) ? item.price : _getProductPrice(item.productId);

    // 2. Additions unit price
    double additionsUnitPrice = 0.0;

    // Get the product to inspect its additions list
    final product = _getProductById(item.productId);

    // Be defensive in case product/additions is null
    final productAdditions = product.additions;

    for (final add in item.additions) {
      // Find matching domainDetail in the product's additions
      final matches =
          productAdditions.where((d) => d.domainDetailId == add.domainDetailId);

      if (matches.isNotEmpty) {
        additionsUnitPrice += matches.first.priceIncrease;
      }
    }

    // 3. Line total = (base + additions) * quantity
    return (basePrice! + additionsUnitPrice) * item.quantity;
  }

  double _calculateGrandTotal(List<OrderItemDto> orderItems) {
    double subtotal = _calculateSubtotal(orderItems);
    double taxes = _calculateTaxes(orderItems);
    return subtotal + taxes;
  }

  void submitOrder() async {
    // Ensure we have a valid org id (non-null, non-zero) before proceeding
    if (_orgId == null || _orgId == 0) {
      final id = await SessionManager.getOrganizationId();
      if (id == null || id == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  '⚠️ Organization is not set. Please re-login or select an organization.')),
        );
        return;
      }
      setState(() => _orgId = id);
    }

    // Now safe to compute totals and build the order
    final double grandTotal = _calculateGrandTotal(selectedItems);

    final order = OrderDto(
      id: 0,
      organizationId: _orgId!, // guaranteed valid here
      orderItems: selectedItems,
      grandTotal: grandTotal,
      paymentMethod: paymentMethod,
      tips: tips,
    );

    final success = await ApiHandler().postOrder(order);

    if (success) {
      // === UNIFIED PRINTING: Customer + Kitchen (Arabic & Android Compatible) ===
      try {
        // Calculate totals
        final double subtotal = _calculateSubtotal(selectedItems);
        final double tax = _calculateTaxes(selectedItems);
        final double total = subtotal + tax + tips;

        // Call unified print function - handles everything!
        final printSuccess = await _printReceipts(
          orderNumber: order.id.toString(),
          paymentMethod: paymentMethod == 1 ? 'CASH' : 'VISA',
          items: selectedItems,
          subtotal: subtotal,
          tax: tax,
          tips: tips,
          total: total,
        );

        if (!printSuccess) {
          debugPrint('⚠️ Printing completed with errors (check logs)');
        }
      } catch (e) {
        // Swallow printing errors to avoid blocking the POS
        debugPrint('❌ Printing error: $e');
      }
      // === End Unified Printing ===

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Order submitted successfully!')),
      );
      setState(() => selectedItems.clear());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to submit order')),
      );
    }
  }

  double _calculateSubtotal(List<OrderItemDto> orderItems) {
    // Sum all lines with additions included
    double subtotal = orderItems.fold(0.0, (sum, item) {
      return sum + _calculateItemTotal(item);
    });

    // Apply percentage discount if any
    if (discount != 0.0) {
      subtotal -= (discount / 100 * subtotal);
    }

    return subtotal;
  }

  double _calculateTaxes(List<OrderItemDto> orderItems) {
    double taxRate = 0.0;

    // Ensure that taxes are fetched and available
    if (currentTaxes != null) {
      if (selectedTaxType == 'In-House') {
        taxRate = currentTaxes!.inHouse;
      } else if (selectedTaxType == 'Takeout') {
        taxRate = currentTaxes!.takeOut;
      }
    }
    return _calculateSubtotal(orderItems) * (taxRate / 100);
  }

  double _calculateTotal(List<OrderItemDto> orderItems) {
    return _calculateSubtotal(orderItems) + _calculateTaxes(orderItems) + tips;
  }

  void _removeOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay(); // Remove previous overlay if any

    final overlay = Overlay.of(context);
    if (searchResults.isEmpty) return;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width:
            MediaQuery.of(context).size.width * 0.42, // Adjust width if needed
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 50), // Adjust the dropdown’s position
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: searchResults.map((Product) {
                  return ListTile(
                    title: Text(Product.productName),
                    onTap: () {
                      setState(() {
                        productSearch =
                            Product; // Set the selected product for search
                        searchController.text =
                            Product.productName; // Update the search bar text
                        searchResults = []; // Clear the search results
                        addToOrder(Product);
                      });
                      _removeOverlay(); // Hide the dropdown after selection
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry!); // Insert the overlay into the widget tree
  }

  void findProduct(String query) async {
    if (query.isEmpty) {
      _removeOverlay(); // Remove overlay when the search is empty
      return;
    }

    // Fetch all products (or use a cached list if available)
    List<Product> allProducts = await apiHandler.searchProductByName(
      productName: query,
    );

    // Filter products locally based on the query
    List<Product> filteredProducts = allProducts
        .where(
          (product) =>
              product.productName.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    if (filteredProducts.isEmpty) {
      _removeOverlay(); // Hide dropdown if no results
      return;
    }

    setState(() {
      searchResults = filteredProducts; // Update search results
    });

    _showOverlay(); // Show the dropdown above the TextField
  }

  void getData() async {
    data = await apiHandler.getProductData();
    setState(() {
      if (data.isEmpty) {
        print("data not here");
      }
    });
  }

  Future<void> categoryData() async {
    final org = await SessionManager.getOrganizationId();
    final result = await apiHandler.getCategoriesForOrg(org ?? 0);
    if (!mounted) return;

    // derive roots & clear subs
    final roots = result.where((c) => c.mainCategoryId == null).toList();

    setState(() {
      _all = result;
      _rootCategories = roots;
      _selectedRoot = null;
      _activeSubs = []; // collapsed initially
    });

    debugPrint('Roots: ${_rootCategories.length}');
    for (final r in _rootCategories) {
      debugPrint(
        ' root -> id=${r.id}, name=${r.categoryName}, main=${r.mainCategoryId}',
      );
    }
  }

  // tap handlers used by your UI

  /*
  late List categoryIcons = [
    Icons.category,
    Icons.category,
    Icons.category,
    Icons.category,
    Icons.category,
    Icons.category,
    Icons.category,
    Icons.category,
    Icons.category,
    Icons.category,
    Icons.category,
    Icons.category,
  ];
*/

  @override
  void initState() {
    getData();
    categoryData();
    _subsCtrl = ScrollController();
    _loadOrganizationId();
    _loadCategories();
    super.initState();
    requestPermissions();
    apiHandler.fetchPromoCodes();
    _fetchTaxes();
    getBluetoothDevices().then((_) {
      if (items.isNotEmpty) {
        Future.delayed(Duration.zero, () {
          _showPrinterDialog();
        });
      }
    });

    // after first frame, give focus to our hidden field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_barcodeFocus);
    });
  }

  void _onBarcodeSubmitted(String code) {
    _barcodeController.clear();
    _processScannedBarcode(code.trim());
  }

  Future<void> _processScannedBarcode(String code) async {
    final api = ApiHandler();
    final filter = "Barcode LIKE N'%$code%'";

    // 1) Fetch matching products
    final products = await api.advanceSearchProducts(filter);

    if (products.isNotEmpty) {
      final prod = products.first;
      setState(() {
        // 2) Find index of an existing OrderItemDto with same productId
        final idx = selectedItems.indexWhere(
          (item) => item.productId == prod.productId,
        );

        if (idx >= 0) {
          // 3a) If found, increment its quantity
          selectedItems[idx] = selectedItems[idx]
              .updateQuantity(selectedItems[idx].quantity + 1);
        } else {
          // 3b) Otherwise add a brand‐new line
          selectedItems
              .add(OrderItemDto(productId: prod.productId, quantity: 1));
        }
      });
    } else {
      // 4) Not found → prompt to create
      final newProd = await showDialog<Product>(
        context: context,
        builder: (_) => AddProductDialog(barcode: code),
      );
      if (newProd != null) {
        setState(() {
          selectedItems
              .add(OrderItemDto(productId: newProd.productId, quantity: 1));
        });
      }
    }

    // 5) Re‑focus so the scanner keeps feeding here
    FocusScope.of(context).requestFocus(_barcodeFocus);
  }

  @override
  void dispose() {
    _tipController.dispose();
    _subsCtrl.dispose();
    super.dispose();
  }

  void toggleMenu() {
    setState(() {
      if (isDrawerOpen) {
        xOffset = 0;
        yOffset = 0;
        isDrawerOpen = false;
      } else {
        xOffset = 290;
        yOffset = 80;
        isDrawerOpen = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double screenHeight = constraints.maxHeight;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          transform: Matrix4.translationValues(xOffset, yOffset, 0)
            ..scale(isDrawerOpen ? 0.85 : 1.0),
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                AppLocalizations.of(context)!.welcomeMessage,
                style: TextStyle(fontSize: screenWidth * 0.017),
              ),
              centerTitle: true,
              backgroundColor: Color(0xFF36454F),
              foregroundColor: Colors.white,
              leading: GestureDetector(
                onTap: toggleMenu,
                child: Icon(isDrawerOpen ? Icons.arrow_back_ios : Icons.menu),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.print),
                  onPressed: () => showPrinterSetupDialog(context),
                ),
                ElevatedButton(
                  onPressed: _showPrinterDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.all(8), // Adjust button padding
                    minimumSize: Size(24, 24), // Set minimum button size
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        20,
                      ), // Rounded corners
                    ),
                  ),
                  child: Icon(
                    Icons.print,
                    size: 15, // Adjust icon size
                    color: Color(0xFFB87333),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  connected ? "Printer Connected" : "Printer Not Connected",
                  style: TextStyle(
                    color: connected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 10),
                SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () {
                    getData();
                    categoryData();
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: SizedBox(
                height: screenHeight * 1.1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Left Section - Main content (Products and Categories)
                      Expanded(
                        flex:
                            3, // You can adjust this flex value based on the layout
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search Bar
                            CompositedTransformTarget(
                              link:
                                  _layerLink, // This should be defined as LayerLink _layerLink = LayerLink();
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: screenWidth * 0.13,
                                ),
                                child: TextField(
                                  controller: searchController,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal:
                                          MediaQuery.of(context).size.width *
                                              0.02, // Horizontal padding
                                      vertical:
                                          MediaQuery.of(context).size.height *
                                              0.01, // Vertical padding
                                    ),
                                    labelText: translation(context).search,
                                    labelStyle: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.02,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        width: 1.0,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      size: MediaQuery.of(context).size.height *
                                          0.035,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context)
                                            .size
                                            .width *
                                        0.02, // Set text size to 3.5% of screen width
                                  ),
                                  onChanged: (query) {
                                    findProduct(query);
                                  },
                                ),
                              ),
                            ),
                            SizedBox(
                              height: screenHeight * 0.01,
                            ), // Space between the search bar and the grid view
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.categories,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.022,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(197, 0, 0, 0),
                                  ),
                                ),
                              ],
                            ),

                            // Category Grid View
                            // Main category row (horizontal)
                            SizedBox(
                              height: screenHeight * 0.18,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _rootCategories.length + 1,
                                itemBuilder: (context, index) {
                                  final isAll = index == 0;
                                  final cat =
                                      isAll ? null : _rootCategories[index - 1];
                                  final name =
                                      isAll ? 'All' : cat!.categoryName;

                                  return GestureDetector(
                                    onTap: () => _onRootTap(cat),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      width: screenWidth * 0.13,
                                      child: Card(
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            name,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.016,
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromARGB(
                                                166,
                                                0,
                                                0,
                                                0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Animated subcategory rail (vertical, compact)
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              key: ValueKey(_activeSubs.length),
                              curve: Curves.easeOut,
                              child: _activeSubs.isEmpty
                                  ? const SizedBox.shrink()
                                  : SizedBox(
                                      height: screenHeight * 0.16,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: screenWidth * 0.12,
                                            margin: const EdgeInsets.only(
                                              left: 4,
                                              right: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: Colors.grey.shade200,
                                              ),
                                            ),
                                            child: Scrollbar(
                                              controller: _subsCtrl,
                                              thumbVisibility: true,
                                              interactive: true,
                                              child: ListView.separated(
                                                controller: _subsCtrl,
                                                primary: false,
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                itemCount: _activeSubs.length,
                                                separatorBuilder: (_, __) =>
                                                    const SizedBox(height: 8),
                                                itemBuilder: (context, i) {
                                                  final sub = _activeSubs[i];
                                                  final selected =
                                                      sub.id == _selectedSubId;
                                                  final cs = Theme.of(
                                                    context,
                                                  ).colorScheme;

                                                  return Material(
                                                    color: selected
                                                        ? cs.primary
                                                            .withOpacity(0.08)
                                                        : Colors.white,
                                                    elevation: selected ? 2 : 0,
                                                    shadowColor: cs.primary
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      12,
                                                    ),
                                                    child: InkWell(
                                                      onTap: () {
                                                        setState(
                                                          () => _selectedSubId =
                                                              sub.id,
                                                        );
                                                        _onSubTap(sub);
                                                      },
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        12,
                                                      ),
                                                      child: AnimatedContainer(
                                                        duration:
                                                            const Duration(
                                                          milliseconds: 160,
                                                        ),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          vertical: 10,
                                                          horizontal: 12,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            12,
                                                          ),
                                                          border: Border.all(
                                                            color: selected
                                                                ? cs.primary
                                                                : Colors.grey
                                                                    .withOpacity(
                                                                    0.22,
                                                                  ),
                                                            width: selected
                                                                ? 1.25
                                                                : 1,
                                                          ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            // circular icon chip
                                                            AnimatedContainer(
                                                              color: selected
                                                                  ? cs.primary
                                                                  : Colors.grey
                                                                      .withOpacity(
                                                                      0.18,
                                                                    ),
                                                              duration:
                                                                  const Duration(
                                                                milliseconds:
                                                                    160,
                                                              ),
                                                              width: 28,
                                                              height: 28,
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              decoration:
                                                                  BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                color: selected
                                                                    ? cs.primary
                                                                        .withOpacity(
                                                                        0.18,
                                                                      )
                                                                    : Colors
                                                                        .grey
                                                                        .shade200,
                                                              ),
                                                              child: Icon(
                                                                Icons
                                                                    .label_rounded,
                                                                size: 16,
                                                                color: selected
                                                                    ? cs.primary
                                                                    : Colors
                                                                        .grey
                                                                        .shade700,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 10,
                                                            ),
                                                            // name
                                                            Expanded(
                                                              child: Text(
                                                                sub.categoryName,
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style:
                                                                    TextStyle(
                                                                  color:
                                                                      const Color(
                                                                    0xFF36454F,
                                                                  ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize:
                                                                      screenWidth *
                                                                          0.011,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                            // chevron
                                                            Icon(
                                                              Icons
                                                                  .chevron_right_rounded,
                                                              size: 18,
                                                              color: selected
                                                                  ? cs.primary
                                                                  : Colors.grey
                                                                      .shade600,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),

                            SizedBox(height: screenHeight * 0.01),
                            Padding(
                              padding: EdgeInsets.only(
                                left: 8.0,
                                right: 50.0,
                                bottom: screenHeight * 0.005,
                                top: 8.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.products,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.022,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(197, 0, 0, 0),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Product Grid View
                            Expanded(
                              child: data.isEmpty
                                  ? Center(
                                      child: Text(
                                        translation(
                                          context,
                                        ).no_available_products,
                                      ),
                                    )
                                  : Builder(
                                      builder: (context) {
                                        final int? selectedSubId =
                                            _selectedSubId; // if you use subs
                                        // filter by ID, not by name
                                        final rootSubIds = (selectedRootId ==
                                                null)
                                            ? const <int>[]
                                            : _allCategories
                                                .where(
                                                  (c) =>
                                                      _toInt(c.id) ==
                                                      _toInt(selectedRootId),
                                                )
                                                .map(
                                                  (c) => _toInt(
                                                    c.mainCategoryId,
                                                  )!,
                                                )
                                                .toList();

                                        final filteredProducts = data.where((
                                          p,
                                        ) {
                                          final int? pCatId = _toInt(
                                            p.categoryId,
                                          );
                                          if (pCatId == null) return false;

                                          final bool matchesRoot =
                                              (selectedRootId == null) ||
                                                  pCatId ==
                                                      _toInt(selectedRootId) ||
                                                  rootSubIds.contains(pCatId);

                                          final bool matchesSub =
                                              (selectedSubId == null) ||
                                                  (pCatId ==
                                                      _toInt(selectedSubId));

                                          return matchesRoot && matchesSub;
                                        }).toList();

                                        return GridView.builder(
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 4,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                            childAspectRatio: 1.2,
                                          ),
                                          itemCount: filteredProducts
                                              .length, // use filtered length
                                          itemBuilder: (context, index) {
                                            final product =
                                                filteredProducts[index];

                                            // look up the category name from its id
                                            final categoryName = _catNameById[
                                                    product.categoryId] ??
                                                'Uncategorized';

                                            return GestureDetector(
                                              onTap: () async {
                                                await addToOrder(product);
                                              },
                                              child: Card(
                                                elevation: 3,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    // Product Name
                                                    Text(
                                                      product.productName,
                                                      style: TextStyle(
                                                        fontSize:
                                                            screenWidth * 0.014,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    // Category Name
                                                    Text(
                                                      categoryName,
                                                      style: TextStyle(
                                                        fontSize:
                                                            screenWidth * 0.011,
                                                        color: Colors.grey,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    // Price
                                                    Text(
                                                      '${product.sellingPrice.toStringAsFixed(2)} JOD',
                                                      style: TextStyle(
                                                        fontSize:
                                                            screenWidth * 0.012,
                                                        color: Colors.green,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),

                      // Right Section - Order Details
                      SingleChildScrollView(
                        child: SizedBox(
                          height: screenHeight * 1,
                          child: Container(
                            height: screenHeight * 2.3,
                            width: screenWidth *
                                0.35, // Set a fixed width for the right section
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  spreadRadius: 4,
                                ),
                              ],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.orders,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.022,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(197, 0, 0, 0),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.01),

                                // Display selected products
                                if (selectedItems.isNotEmpty)
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: selectedItems.length,
                                      itemBuilder: (context, index) {
                                        final selected = selectedItems[index];
                                        // Cast data to List<Product> and fetch the product details
                                        final product = _getProductById(
                                          selected.productId,
                                        );
                                        return Card(
                                          elevation: 4,
                                          margin: EdgeInsets.only(
                                            bottom: screenHeight * 0.02,
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(
                                              screenWidth * 0.0008,
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: screenWidth * 0.001,
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      ListTile(
                                                        title: Text(
                                                          product.productName,
                                                          style: TextStyle(
                                                            fontSize:
                                                                screenWidth *
                                                                    0.013,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        // 🔥 quantity + additions + notes
                                                        subtitle: Builder(
                                                          builder: (_) {
                                                            // Build additions display (names from product.additions)
                                                            final List<Widget>
                                                                additionWidgets =
                                                                [];

                                                            if (selected
                                                                .additions
                                                                .isNotEmpty) {
                                                              for (final add
                                                                  in selected
                                                                      .additions) {
                                                                // Find matching DomainDetail on the product
                                                                String label =
                                                                    '';
                                                                for (final d
                                                                    in product
                                                                        .additions) {
                                                                  if (d.domainDetailId ==
                                                                      add.domainDetailId) {
                                                                    final pricePart =
                                                                        d.priceIncrease >
                                                                                0
                                                                            ? ' (+${d.priceIncrease.toStringAsFixed(2)})'
                                                                            : '';
                                                                    label =
                                                                        '${d.name}$pricePart';
                                                                    break;
                                                                  }
                                                                }

                                                                if (label
                                                                    .isEmpty) {
                                                                  label =
                                                                      'إضافة (${add.domainDetailId})';
                                                                }

                                                                additionWidgets
                                                                    .add(
                                                                  Text(
                                                                    '• $label',
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          screenWidth *
                                                                              0.0115,
                                                                      color: Colors
                                                                              .grey[
                                                                          800],
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                            }

                                                            final hasNotes =
                                                                (selected.notes !=
                                                                        null &&
                                                                    selected
                                                                        .notes!
                                                                        .trim()
                                                                        .isNotEmpty);

                                                            return Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  'Quantity: ${selected.quantity}',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        screenWidth *
                                                                            0.013,
                                                                  ),
                                                                ),
                                                                if (additionWidgets
                                                                    .isNotEmpty) ...[
                                                                  const SizedBox(
                                                                      height:
                                                                          4),
                                                                  ...additionWidgets,
                                                                ],
                                                                if (hasNotes) ...[
                                                                  const SizedBox(
                                                                      height:
                                                                          4),
                                                                  Text(
                                                                    'ملاحظة: ${selected.notes}',
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          screenWidth *
                                                                              0.0115,
                                                                      color: Colors
                                                                              .brown[
                                                                          700],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ],
                                                            );
                                                          },
                                                        ),
                                                        trailing: Text(
                                                          '${product.sellingPrice.toStringAsFixed(2)} JOD',
                                                          style: TextStyle(
                                                            fontSize:
                                                                screenWidth *
                                                                    0.015,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.green,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.remove_circle,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed: () =>
                                                          _removeProductFromOrder(
                                                              index),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.add_circle,
                                                        color: Colors.green,
                                                      ),
                                                      onPressed: () =>
                                                          _addQuantity(index),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                // Divider line
                                Divider(height: 7, color: Colors.black45),
                                // Promo Code Section
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.01,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: CompositedTransformTarget(
                                          link: _layerLinkpromo,
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              double textFieldWidth = constraints
                                                      .maxWidth *
                                                  0.8; // Adjust width dynamically
                                              double textSize = screenWidth *
                                                  0.013; // Adjust font size dynamically
                                              double paddingHorizontal =
                                                  screenWidth *
                                                      0.02; // Adjust padding dynamically
                                              double paddingVertical =
                                                  screenHeight * 0.015;

                                              return SizedBox(
                                                width:
                                                    textFieldWidth, // Ensure it scales dynamically
                                                child: TextField(
                                                  controller:
                                                      promoCodeController,
                                                  style: TextStyle(
                                                    fontSize: textSize,
                                                  ),
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        AppLocalizations.of(
                                                      context,
                                                    )!
                                                            .discount,
                                                    labelStyle: TextStyle(
                                                      fontSize: textSize,
                                                    ),
                                                    border:
                                                        OutlineInputBorder(),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                      horizontal:
                                                          paddingHorizontal,
                                                      vertical: paddingVertical,
                                                    ),
                                                  ),
                                                  onChanged: findPromoCode,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.01),
                                      ElevatedButton(
                                        onPressed: () {
                                          // Handle promo code validation here

                                          if (selectedPromoCode != null) {
                                            setState(() {
                                              // Here you can add your validation logic
                                              // If valid, update the selectedPromoCode text
                                              // If not valid, you can show an error or reset the value
                                            });
                                          } else {
                                            // If no promo code selected, you can show an error or message
                                            setState(() {
                                              // Optionally show an error if no promo code is selected
                                              selectedPromoCode =
                                                  null; // Reset or handle the case where no promo code is selected
                                            });
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFFB87333),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                            horizontal: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          AppLocalizations.of(context)!.ok,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                //tips section
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.001,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          width: screenWidth *
                                              0.2, // Adjust width as needed
                                          height: screenHeight *
                                              0.08, // Adjust height as needed
                                          child: TextField(
                                            controller: _tipController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              hintText: 'Enter tip amount',
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                tips = double.tryParse(value) ??
                                                    0.0;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Divider line (for discount section)
                                Divider(
                                  height: screenHeight * 0.02,
                                  color: Colors.black45,
                                ),
                                /*
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          selectedTaxType =
                                              'In-House'; // Switch to In-House tax
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFB87333),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 12), // Reduce padding
                                        minimumSize:
                                            Size(100, 45), // Adjust button size
                                        textStyle: TextStyle(
                                            fontSize: 14), // Make text smaller
                                      ),
                                      child: Text('In-House Tax'),
                                    ),
                                    SizedBox(
                                        height:
                                            8), // Reduce spacing between buttons
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          selectedTaxType =
                                              'Takeout'; // Switch to Takeout tax
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFB87333),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 12),
                                        minimumSize: Size(100, 45),
                                        textStyle: TextStyle(fontSize: 14),
                                      ),
                                      child: Text('Takeout Tax'),
                                    ),
                                  ],
                                ),

                            */
                                // Discount Section
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.01,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.discount,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenWidth * 0.0115,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            selectedPromoCode != null
                                                ? '${selectedPromoCode!.PromoCode} (%${selectedPromoCode!.Percentage})' // Safe to access since we checked for null
                                                : 'No Promo Code', // Default text if no promo code is selected
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                              fontSize: screenWidth * 0.013,
                                            ),
                                          ),
                                          // Add the circular "X" button
                                          if (selectedPromoCode != null)
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  // Reset discount and selectedPromoCode when the "X" is tapped
                                                  discount = 0.0;
                                                  selectedPromoCode = null;
                                                });
                                              },
                                              child: Container(
                                                margin: EdgeInsets.only(
                                                  left: 8.0,
                                                ),
                                                width:
                                                    24.0, // Set the size of the circle
                                                height:
                                                    24.0, // Set the size of the circle
                                                decoration: BoxDecoration(
                                                  color: Colors
                                                      .red, // Circle color
                                                  shape: BoxShape
                                                      .circle, // Make the container circular
                                                ),
                                                child: Icon(
                                                  Icons.close, // The "X" icon
                                                  color: Colors
                                                      .white, // Icon color
                                                  size: 16.0, // Icon size
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.001,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Payment Method', // You can change this to any localized text
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenWidth *
                                              0.0115, // Adjust text size based on screen width
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            paymentMethod == 1
                                                ? 'Cash'
                                                : 'Visa', // Show the current payment method
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: screenWidth *
                                                  0.0115, // Adjust text size based on screen width
                                            ),
                                          ),
                                          Transform.scale(
                                            scale:
                                                switchScale, // Adjust the scale to change the switch size
                                            child: Switch(
                                              value: isCash, // Toggle value
                                              onChanged:
                                                  _togglePaymentMethod, // Update payment method on change
                                              activeThumbColor: Colors
                                                  .green, // Color when 'Visa' is selected
                                              inactiveThumbColor: Colors
                                                  .blue, // Color when 'Cash' is selected
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Subtotal
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.01,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.total,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenWidth * 0.0115,
                                        ),
                                      ),
                                      Text(
                                        '${_calculateSubtotal(selectedItems).toStringAsFixed(2)} JOD',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Taxes
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.01,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${AppLocalizations.of(context)!.tax} (${selectedTaxType == "In-House" ? currentTaxes?.inHouse ?? 0 : currentTaxes?.takeOut ?? 0}%)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenWidth * 0.0115,
                                        ),
                                      ),
                                      Text(
                                        _calculateTaxes(selectedItems).toStringAsFixed(2),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Total
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.01,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${AppLocalizations.of(context)!.grandTotal} - %${discount.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.015,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${_calculateTotal(selectedItems).toStringAsFixed(2)} JOD',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.016,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Checkout Button
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () async {
                                        submitOrder(); // First, submit the order
                                        // Then, print the receipt
                                        _printReceipt();
                                        orderCount++;
                                        setState(() {
                                          tips = 0.0;
                                          _tipController.clear();
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFB87333),
                                        foregroundColor: Colors.white,
                                        minimumSize: Size(
                                          MediaQuery.of(context).size.width *
                                              0.01,
                                          40,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 32,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)!.checkout,
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.015,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF8B5C42),
                                        foregroundColor: Colors.white,
                                        minimumSize: Size(
                                          MediaQuery.of(context).size.width *
                                              0.01,
                                          40,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 30,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!
                                            .printReceipt,
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.011,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                /*
                                      // Charge button
                                      SizedBox(height: screenHeight * 0.03),
                                      Center(
                                      child: ElevatedButton(
                                        onPressed:_chargeOrder,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          minimumSize: Size(MediaQuery.of(context).size.width * 0.1, 50),
                                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 70),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        child: selectedItems.isNotEmpty
                                            ? Text('Charge \$${_calculateTotal(selectedItems).toStringAsFixed(2)}', style: TextStyle(fontSize: screenWidth * 0.0165))
                                            : Text(AppLocalizations.of(context)!.noData,textAlign: TextAlign.center ,style: TextStyle(fontSize: screenWidth * 0.0165, color: Colors.white,)),
                                      ),
                                    ),
                                    */
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 1) Put this in your widget tree—e.g. at the end of your Stack:
                      Focus(
                        focusNode: _barcodeFocus,
                        autofocus: true,
                        onKey: (FocusNode node, RawKeyEvent event) {
                          // 1) When keys come down, accumulate their characters
                          if (event is RawKeyDownEvent &&
                              event.character != null &&
                              event.character!.isNotEmpty) {
                            _barcodeBuffer += event.character!;
                            return KeyEventResult.handled;
                          }
                          // 2) On key-up of ENTER, submit the whole buffer once
                          if (event.logicalKey == LogicalKeyboardKey.enter &&
                              event is RawKeyUpEvent) {
                            _onBarcodeSubmitted(_barcodeBuffer);
                            _barcodeBuffer = '';
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child:
                            const SizedBox.shrink(), // zero footprint, no IME
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  /*  
void _chargeOrder() async {
  if (selectedItems.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(translation(context).no_products_selected)),
    );
    return;
  }

  // Update product inventory
  for (var item in selectedItems) {
    Product product = _getProductById(item.productId);
    if (product.productId != 0) {
      // Subtract the quantity ordered from the product inventory
      product.productInventory -= item.quantity;
      print("Updated inventory for ${product.productName}: ${product.productInventory}");
      
      // Update the product inventory in the database (optional)
      await apiHandler.updateProductInventoryInDatabase(product);
    }
  }

  // Now post the order
  OrderDto order = OrderDto(id: 0, orderItems: selectedItems, GrandTotal: _calculateGrandTotal(selectedItems));
  bool success = await ApiHandler().postOrder(order);
  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translation(context).order_success)));
    setState(() {
      selectedItems.clear();  // Clear the list
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translation(context).failed_order_submission)));
  }
}
*/

  Product _getProductById(int productId) {
    print("Looking up product with ID: $productId");

    // Cast the data list to a List<Product> and search for the product by its ID
    var product = (data as List<Product>).firstWhere(
      (product) => product.productId == productId,
      orElse: () {
        // If product isn't found, fetch it from the API (or return a default)
        print(
          "Product with ID $productId not found in cache, fetching from API...",
        );
        return Product(
          productId: 0,
          organizationId: _orgId ?? 0,
          categoryId: 0,
          productName: 'Unknown Product',
          productDescription: 'No description available',
          purchasePrice: 0.0,
          sellingPrice: 0.0,
          productInventory: 0.0,
          barcode: '',
        );
      },
    );

    if (product.productId == 0) {
      // If the product is still the default (not found), make an API call to fetch the product by ID
      print("Fetching product from API...");
      // Optionally make an API call to fetch a single product by its ID and return that.
    }

    print("Found product: ${product.productName}, ID: ${product.productId}");
    return product;
  }

  // ===========================================================================
  // UNIFIED PRINTING FUNCTION - Arabic & Android Compatible
  // ===========================================================================

  /// Unified printing function for customer and kitchen receipts.
  ///
  /// Features:
  /// - ✅ 100% Arabic support (automatic raster rendering)
  /// - ✅ 100% Android compatible (List<int> format)
  /// - ✅ Automatic kitchen routing (Falafel, Shawarma, etc.)
  /// - ✅ Auto-reconnect customer printer after kitchen printing
  /// - ✅ Comprehensive error handling and logging
  /// - ✅ Product name Arabic validation
  ///
  /// Usage:
  /// ```dart
  /// await _printReceipts(
  ///   orderNumber: order.id.toString(),
  ///   paymentMethod: 'CASH', // or 'VISA', 'CARD', etc.
  ///   items: selectedItems,
  ///   subtotal: subtotal,
  ///   tax: tax,
  ///   tips: tips,
  ///   total: total,
  /// );
  /// ```
  Future<bool> _printReceipts({
    required String orderNumber,
    required String paymentMethod,
    required List<OrderItemDto> items,
    required double subtotal,
    required double tax,
    required double tips,
    required double total,
  }) async {
    try {
      debugPrint('🖨️ ============================================');
      debugPrint('🖨️ Starting Unified Print Function');
      debugPrint('🖨️ Order: $orderNumber | Total: $total');
      debugPrint('🖨️ ============================================');

      // 1️⃣ Build enriched items for print (WITH additions + notes)
      final List<Map<String, dynamic>> itemsForPrint = items.map((it) {
        final product = _getProductById(it.productId);

        final double basePrice =
            (it.price != 0.0) ? it.price : (product.sellingPrice);

        double additionsTotal = 0.0;
        final additionsList = <Map<String, dynamic>>[];

        for (final add in it.additions) {
          // ignore: unused_local_variable
          dynamic dd;
          try {
            dd = product.additions
                .firstWhere((d) => d.domainDetailId == add.domainDetailId);
          } catch (_) {
            dd = null;
          }

          additionsList.add({
            'domainDetailId': add.domainDetailId,
          });
        }

        final double unitWithAdds = basePrice! + additionsTotal;
        final double lineTotal = unitWithAdds * it.quantity;

        return {
          // keys used by ReceiptBuilder
          'productId': it.productId,
          'productName': product.productName,
          'quantity': it.quantity,
          'unitPrice': basePrice,
          'totalAfterTax': lineTotal, // 👈 includes additions
          'price': basePrice,
          'additions': additionsList, // 👈 used in both kitchen & customer
          'notes': it.notes ?? '', // 👈 used in both kitchen & customer

          // optional metadata for router / kitchen
          'categoryId': product.categoryId,
        };
      }).toList();

      debugPrint('🖨️ Total items: ${itemsForPrint.length}');
      for (final m in itemsForPrint) {
        debugPrint(
            '🖨️ ITEM -> name=${m['productName']}, qty=${m['quantity']}, adds=${m['additions']}, notes=${m['notes']}');
      }

      // 2️⃣ Prepare order data expected by ReceiptBuilder
      final orderData = <String, dynamic>{
        'orderNumber': orderNumber,
        'paymentMethod': paymentMethod,
        'items': itemsForPrint,

        // Totals for _extractTotals()
        'grandTotal': total,
        'totalAfterTax': total,
        'discountTotal': 0.0, // or your real discount value
        'taxTotal': tax,
        'tips': tips,
        'totalAfterDiscount': subtotal,
      };

      // 3️⃣ Initialize Bluetooth printer manager
      debugPrint('🖨️ Initializing Bluetooth printers...');
      final bt = BluetoothPrinterManager();
      await bt.load();
      debugPrint('🖨️ ✅ Bluetooth manager ready');

      // 4️⃣ Setup kitchen router
      final router = KitchenRouter(
        falafelCategoryIds: {2}, // tweak to your real ids
        shawarmaSnacksCategoryIds: {3, 6, 7, 8, 9},
      );
      debugPrint('🖨️ ✅ Kitchen router configured');

      // 5️⃣ Create triple printer
      final printer = TriplePrinter(
        btManager: bt,
        router: router,
      );
      debugPrint(
          '🖨️ ✅ Triple printer initialized (will create fresh builders per printer)');

      // 6️⃣ Print all receipts (customer + kitchens)
      debugPrint('🖨️ ============================================');
      debugPrint('🖨️ Starting print sequence...');
      debugPrint('🖨️ ============================================');

      await Future.delayed(const Duration(milliseconds: 1500));

      await printer.printAll(orderData);

      debugPrint('🖨️ ============================================');
      debugPrint('🖨️ ✅ Print sequence completed successfully!');
      debugPrint('🖨️ ============================================');

      return true;
    } catch (e, stackTrace) {
      debugPrint('🖨️ ============================================');
      debugPrint('🖨️ ❌ PRINT ERROR: $e');
      debugPrint('🖨️ Stack trace: $stackTrace');
      debugPrint('🖨️ ============================================');
      return false;
    }
  }
}

class AddProductDialog extends StatefulWidget {
  final String barcode;
  const AddProductDialog({super.key, required this.barcode});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog>
    with SingleTickerProviderStateMixin {
  // Animation
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;

  // Form fields
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _purPriceCtrl = TextEditingController();
  final _inventoryCtrl = TextEditingController();

  // Data
  List<Category> _categories = [];
  Category? _chosenCategory;
  int? _orgId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Setup animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();

    // Load async data
    _loadOrganizationId();
    _loadCategories();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _inventoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizationId() async {
    final id = await SessionManager.getOrganizationId();
    setState(() => _orgId = id);
  }

  Future<void> _loadCategories() async {
    final cats = await ApiHandler().getCategoryData();
    setState(() => _categories = cats);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _chosenCategory == null) return;
    setState(() => _isSubmitting = true);

    final newProd = Product(
      productId: 0,
      organizationId: _orgId ?? 0,
      categoryId: _chosenCategory!.id,
      productName: _nameCtrl.text.trim(),
      productDescription: _descCtrl.text.trim(),
      sellingPrice: double.parse(_priceCtrl.text),
      purchasePrice: double.parse(_purPriceCtrl.text),
      productInventory: double.parse(_inventoryCtrl.text),
      barcode: widget.barcode,
    );

    final resp = await ApiHandler().AddProducts(product: newProd);
    setState(() => _isSubmitting = false);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final created = Product.fromJson(json.decode(resp.body));
      Navigator.of(context).pop(created);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error creating product')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: const Color(0xFFB87333), // Dark orange focus
              ),
          inputDecorationTheme: InputDecorationTheme(
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFB87333)),
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        child: AlertDialog(
          backgroundColor: Colors.grey[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Add New Product',
            style: const TextStyle(
              color: Color(0xFF36454F),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 350,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 20),
                    // Barcode
                    TextFormField(
                      initialValue: widget.barcode,
                      decoration: const InputDecoration(labelText: 'Barcode'),
                      readOnly: true,
                      style: const TextStyle(color: Color(0xFF36454F)),
                    ),
                    const SizedBox(height: 12),

                    // Name
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Price & Inventory
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              fillColor: Colors.white,
                              filled: true,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                double.tryParse(v!) == null ? 'Invalid' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _inventoryCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Inventory',
                              fillColor: Colors.white,
                              filled: true,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                double.tryParse(v!) == null ? 'Invalid' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Category
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<Category>(
                            items: _categories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.categoryName),
                                  ),
                                )
                                .toList(),
                            onChanged: (c) =>
                                setState(() => _chosenCategory = c),
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              fillColor: Colors.white,
                              filled: true,
                            ),
                            validator: (v) => v == null ? 'Pick one' : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Color(0xFFB87333),
                          ),
                          onPressed: () async {
                            final cat = await Navigator.push<Category>(
                              context,
                              MaterialPageRoute(builder: (_) => AddCategory()),
                            );
                            if (cat != null) {
                              setState(() {
                                _categories.add(cat);
                                _chosenCategory = cat;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF8B5C42)),
              ),
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB87333),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 6,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class AdditionsSelectionResult {
  final String? notes;
  final List<OrderItemAdditionDto> additions;

  AdditionsSelectionResult({
    this.notes,
    this.additions = const [],
  });
}
