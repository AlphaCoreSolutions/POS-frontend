import 'package:flutter/material.dart';

class PaymentSection extends StatelessWidget {
  final String paymentMethod;
  final bool isCash;
  final Function(bool) onTogglePaymentMethod;

  const PaymentSection({
    super.key,
    required this.paymentMethod,
    required this.isCash,
    required this.onTogglePaymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.001,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Payment Method',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: MediaQuery.of(context).size.width * 0.0115,
            ),
          ),
          Row(
            children: [
              Text(
                paymentMethod,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.width * 0.0115,
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isCash,
                  onChanged: onTogglePaymentMethod,
                  activeThumbColor: Colors.green,
                  inactiveThumbColor: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
