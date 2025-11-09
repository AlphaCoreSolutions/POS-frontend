import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Print Preview Dialog - Shows receipt preview before printing
class PrintPreviewDialog extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback onPrint;

  const PrintPreviewDialog({
    Key? key,
    required this.orderData,
    required this.onPrint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: screenWidth * 0.5,
        height: screenHeight * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'معاينة الطباعة',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Preview Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: _buildReceiptPreview(context),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Cancel Button
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.cancel, size: 24),
                  label: Text(
                    'إلغاء',
                    style: TextStyle(fontSize: 20),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // Print Button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onPrint();
                  },
                  icon: Icon(Icons.print, size: 24),
                  label: Text(
                    'طباعة',
                    style: TextStyle(fontSize: 20),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB87333),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptPreview(BuildContext context) {
    final items =
        (orderData['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final orderNumber =
        orderData['data']?['orderNumber'] ?? orderData['orderNumber'] ?? '';
    final paymentMethod =
        orderData['data']?['paymentMethod'] ?? orderData['paymentMethod'] ?? '';

    final apiData = orderData['data'] ?? orderData;
    final num subtotal = _asNum(
        apiData['totalAfterDiscount'] ?? apiData['grandTotal'],
        fallback: 0);
    final num discount = _asNum(apiData['discountTotal'], fallback: 0);
    final num tax = _asNum(apiData['taxTotal'], fallback: 0);
    final num tips = _asNum(apiData['tips'], fallback: 0);
    final num total = _asNum(apiData['totalAfterTax'] ?? apiData['grandTotal'],
        fallback: subtotal);

    return Container(
      constraints: BoxConstraints(maxWidth: 480), // Increased for 80mm
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Store Name
          Text(
            orderData['storeName']?.toString() ?? 'POS System',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Receipt Title
          Text(
            'فاتورة البيع',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Order Number
          Text(
            'رقم الطلب: $orderNumber',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Payment Method
          if (paymentMethod.isNotEmpty)
            Text(
              'طريقة الدفع: ${_paymentMethodArabic(paymentMethod)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

          const Divider(thickness: 2, height: 32),

          // Items Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black, width: 2),
                bottom: BorderSide(color: Colors.black, width: 2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 45,
                  child: Text(
                    'الصنف',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 20,
                  child: Text(
                    'الكمية',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 35,
                  child: Text(
                    'المجموع',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),

          // Items
          ...items.map((item) {
            final name =
                (item['productName'] ?? item['name'] ?? 'صنف').toString();
            final qty = _asNum(item['quantity'], fallback: 1);
            final lineTotal =
                _asNum(item['totalAfterTax'] ?? item['total'], fallback: 0);

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 45,
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 20,
                    child: Text(
                      qty.toString(),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 35,
                    child: Text(
                      '\$${lineTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          const Divider(thickness: 2, height: 32),

          // Totals Section - Centered and Larger
          const SizedBox(height: 16),

          if (discount > 0 || tax > 0)
            _buildTotalLine('الإجمالي الفرعي', subtotal - discount),

          if (discount > 0) _buildTotalLine('الخصم', -discount),

          if (tax > 0) _buildTotalLine('الضريبة', tax),

          if (tips > 0) _buildTotalLine('الإكرامية', tips),

          const Divider(thickness: 2, height: 32),

          // Grand Total - Centered
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'الإجمالي: ',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          const Divider(thickness: 2, height: 32),

          // Footer - Centered
          const SizedBox(height: 16),
          Text(
            'شكراً لزيارتكم',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            DateFormat('yyyy/MM/dd - hh:mm a').format(DateTime.now()),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalLine(String label, num value) {
    final displayValue = value < 0
        ? '- \$${(-value).toStringAsFixed(2)}'
        : '\$${value.toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  num _asNum(dynamic v, {num fallback = 0}) {
    if (v is num) return v;
    if (v is String) {
      final p = num.tryParse(v);
      if (p != null) return p;
    }
    return fallback;
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
}
