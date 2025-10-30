//import 'dart:io';

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, dynamic>?>(
          future:
              apiHandler.fetchOrderDetailsById(orderId), // Fetch order by ID
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
              return Center(child: Text(translation(context).order_not_found));
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
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    title: Text('Order ID: $orderId'),
                    subtitle:
                        Text('Grand Total: ${grandTotal.toStringAsFixed(2)}'),
                    trailing: Column(
                      children: [
                        Text('Tip: ${tip}'),
                        SizedBox(
                          height: 5,
                        ),
                        Text('Payment Method: $paymentMethod'),
                      ],
                    ),
                  ),
                ),
                Divider(),
                ...orderItems.map((item) {
                  return Card(
                    elevation: 4, // Adds shadow for better visibility
                    margin: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16), // Adds spacing around cards
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Rounded edges
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
                          12), // Ensures good spacing inside the card
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          /*
        // Product Image (If you have one)
        if (item['productPicture'] != null)
          ClipRRect(
          borderRadius: BorderRadius.circular(8), // Rounded image corners
          child: (item['productPicture'] != null && item['productPicture'].isNotEmpty)
              ? Image.file( // Only display local file path images
                  File(item['productPicture'].replaceAll('\\', '/')),
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                )
              : Container( // Default placeholder if no image is provided
                  width: 70,
                  height: 70,
                  color: Colors.grey[300],
                  child: Icon(Icons.image, color: Colors.white),
                ),
        ),
        */
                          SizedBox(
                              width: 12), // Adds space between image and text

                          // Product Details (Flexible to prevent overflow)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['productName'] ?? 'Unknown Product',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Quantity: ${item['quantity']}',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[700]),
                                ),
                                SizedBox(height: 5),
                                /*
              Text(
                ' Price: ${item['sellingPrice'].toString() ?? "0.0"} JOD',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              */
                              ],
                            ),
                          ),
                          /*
        // Delete Button
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.delete, color: Colors.red, size: 28),
        ),
        */
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
      ),
    );
  }
}
