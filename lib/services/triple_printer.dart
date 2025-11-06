import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:visionpos/services/arabic_font_loader.dart';
import 'package:visionpos/services/arabic_raster_receipt.dart';
import 'package:visionpos/services/bluetooth_printing_service.dart';
import 'package:visionpos/services/kitchen_router.dart';

import 'receipt_builder.dart';

/// Facade to print customer and kitchen tickets in one go.
class TriplePrinter {
  final BluetoothPrinterManager bt;
  final ReceiptBuilder builder;
  final KitchenRouter router;

  TriplePrinter(
      {required this.bt, required this.builder, required this.router});

  /// order must have:
  ///  - items: [{name, quantity, price, categoryId, notes?}, ...]
  ///  - subtotal, tax, tips, total, paymentMethod, orderNumber
  Future<void> printAll(Map<String, dynamic> order) async {
    // Customer
    final customerBytes = await builder.buildCustomer(order);
    await bt.withPrinter(PrinterRole.customer, () async {
      await bt.writeBytes(customerBytes);
    });
    await Future.delayed(const Duration(milliseconds: 250));

    // Falafel
    final buckets = router.split(order);
    final falafelItems = buckets['falafel']!;
    if (falafelItems.isNotEmpty) {
      final bytes = await builder.buildKitchen(
        order,
        kitchenName: 'Falafel',
        items: falafelItems,
      );
      await bt.withPrinter(PrinterRole.falafel, () async {
        await bt.writeBytes(bytes);
      });
      await Future.delayed(const Duration(milliseconds: 250));
    }

    // Shawarma & Snacks
    final shsnItems = buckets['shawarmaSnacks']!;
    if (shsnItems.isNotEmpty) {
      final bytes = await builder.buildKitchen(
        order,
        kitchenName: 'Shawarma & Snacks',
        items: shsnItems,
      );
      await bt.withPrinter(PrinterRole.shawarmaSnacks, () async {
        await bt.writeBytes(bytes);
      });
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<ArabicRasterReceipt> makeArabicBuilder58() async {
    await ArabicFontLoader.ensureLoaded(
      family: 'NotoNaskhArabic',
      assetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
    );
    final profile = await CapabilityProfile.load();
    return ArabicRasterReceipt(
      paper: PaperSize.mm58,
      profile: profile,
      widthPx: 384, // 58mm typical
      fontFamily: 'NotoNaskhArabic',
    );
  }

  Future<ArabicRasterReceipt> makeArabicBuilder80() async {
    await ArabicFontLoader.ensureLoaded(
      family: 'NotoNaskhArabic',
      assetPath: 'lib/assets/fonts/NotoNaskhArabic-Regular.ttf',
    );
    final profile = await CapabilityProfile.load();
    return ArabicRasterReceipt(
      paper: PaperSize.mm80,
      profile: profile,
      widthPx: 576, // 80mm typical
      fontFamily: 'NotoNaskhArabic',
    );
  }
}
