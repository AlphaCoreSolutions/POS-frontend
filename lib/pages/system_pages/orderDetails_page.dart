import 'dart:io';

import 'package:visionpos/language_changing/constants.dart';
import 'package:visionpos/pages/essential_pages/api_handler.dart';
import 'package:flutter/material.dart';

class OrdersPage extends StatelessWidget {
  final ApiHandler apiHandler = ApiHandler();

  @override
  Widget build(BuildContext context) {
    final int? orderId = ModalRoute.of(context)?.settings.arguments as int?;

    if (orderId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(translation(context).order_details),
        ),
        body: Center(child: Text("Invalid Order ID")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(translation(context).order_details),
        backgroundColor: Color(0xFF36454F),
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final horizontalPadding = isMobile ? 16.0 : 32.0;
          final verticalMargin = isMobile ? 10.0 : 20.0;
          final imageSize = isMobile ? 60.0 : 80.0;
          final titleFontSize = isMobile ? 16.0 : 18.0;
          final subtitleFontSize = isMobile ? 14.0 : 16.0;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: FutureBuilder<Map<String, dynamic>?>(
              future: apiHandler
                  .fetchOrderDetailsById(orderId), // Fetch order by ID
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(
                    color: Color(0xFFB87333),
                  ));
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text("Error loading order: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return Center(
                      child: Text(translation(context).order_not_found));
                }

                Map<String, dynamic> orderData = snapshot.data!;
                double grandTotal = orderData['grandTotal'] ?? 0.0;
                double tip = orderData['tips'] ?? 0.0;
                String paymentMethod =
                    orderData['paymentMethod'] ?? 'not specified';
                List<dynamic> orderItems = orderData['orderItems'] ?? [];

                return ListView(
                  children: [
                    Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: verticalMargin),
                      child: ListTile(
                        title: Text('Order ID: $orderId'),
                        subtitle: Text(
                            'Grand Total: ${grandTotal.toStringAsFixed(2)}'),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Tip: ${tip}'),
                            SizedBox(height: 5),
                            Text('Payment Method: $paymentMethod'),
                          ],
                        ),
                      ),
                    ),
                    Divider(),
                    ...orderItems.map((item) {
                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: verticalMargin),
                        child: ListTile(
                          leading: item['productPicture'] != null &&
                                  item['productPicture'].isNotEmpty
                              ? Image.file(
                                  File(item['productPicture']
                                      .replaceAll('\\', '/')),
                                  width: imageSize,
                                  height: imageSize,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: imageSize,
                                  height: imageSize,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.image, color: Colors.white),
                                ),
                          title: Text(
                            item['productName'] ?? 'Unknown Product',
                            style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Quantity: ${item['quantity']}',
                            style: TextStyle(
                                fontSize: subtitleFontSize,
                                color: Colors.grey[700]),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
