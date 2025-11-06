class Customer {
  final int customerId;
  final int organizationId;
  final String name;
  final String phone;
  final String? email;
  final String? address;

  Customer({
    required this.customerId,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    required this.organizationId,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        customerId: json["customerId"] ?? 0,
        organizationId: json["organizationId"] ?? 0,
        name: json["name"] ?? '',
        email: json["email"],
        address: json["address"],
        phone: json["phone"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'name': name,
        'email': email,
        'address': address,
        'phone': phone,
        'organizationId': organizationId
      };
}
