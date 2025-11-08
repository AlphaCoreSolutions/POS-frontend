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
    try {
      // 1. Print Customer Receipt
      final customerBytes = await builder.buildCustomer(order);
      final customerSuccess =
          await bt.withPrinter(PrinterRole.customer, () async {
        await bt.writeBytes(customerBytes);
      });

      if (!customerSuccess) {
        print('⚠️ Customer receipt failed to print');
      }
      await Future.delayed(const Duration(milliseconds: 300));

      // 2. Print Kitchen Tickets
      final buckets = router.split(order);

      // Falafel Kitchen
      final falafelItems = buckets['falafel']!;
      if (falafelItems.isNotEmpty) {
        final bytes = await builder.buildKitchen(
          order,
          kitchenName: 'مطبخ الفلافل', // Arabic: Falafel Kitchen
          items: falafelItems,
        );
        final success = await bt.withPrinter(PrinterRole.falafel, () async {
          await bt.writeBytes(bytes);
        });

        if (!success) {
          print('⚠️ Falafel kitchen ticket failed to print');
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Shawarma & Snacks Kitchen
      final shsnItems = buckets['shawarmaSnacks']!;
      if (shsnItems.isNotEmpty) {
        final bytes = await builder.buildKitchen(
          order,
          kitchenName:
              'مطبخ الشاورما والوجبات الخفيفة', // Arabic: Shawarma & Snacks Kitchen
          items: shsnItems,
        );
        final success =
            await bt.withPrinter(PrinterRole.shawarmaSnacks, () async {
          await bt.writeBytes(bytes);
        });

        if (!success) {
          print('⚠️ Shawarma & Snacks kitchen ticket failed to print');
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // 3. Reconnect to Customer Printer (ready for next order)
      final customerPrinter = bt.getForRole(PrinterRole.customer);
      if (customerPrinter != null) {
        await Future.delayed(const Duration(
            milliseconds: 500)); // Allow previous printer to fully disconnect
        final reconnected = await bt.connect(customerPrinter.mac);
        if (reconnected) {
          print('✅ Customer printer reconnected and ready');
        } else {
          print('⚠️ Failed to reconnect customer printer');
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error in printAll: $e');
      print('Stack trace: $stackTrace');

      // Always try to reconnect customer printer even if there was an error
      try {
        final customerPrinter = bt.getForRole(PrinterRole.customer);
        if (customerPrinter != null) {
          await Future.delayed(const Duration(milliseconds: 500));
          await bt.connect(customerPrinter.mac);
        }
      } catch (reconnectError) {
        print(
            '⚠️ Failed to reconnect customer printer after error: $reconnectError');
      }

      rethrow;
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
