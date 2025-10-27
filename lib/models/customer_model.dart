class Customer {
  final int CustomerId;
  final int OrganizationId;
  final String Name;
  final String Phone;
  final String Email;
  final String Address;

  Customer(
      {required this.CustomerId,
      required this.Name,
      required this.Phone,
      required this.Email,
      required this.Address,
      required this.OrganizationId});

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        CustomerId: json["customerId"],
        OrganizationId: json["OrganizationId"] ?? 0,
        Name: json["name"],
        Email: json["email"] ?? "example@provider.com",
        Address: json["address"] ?? 'the Address',
        Phone: json["phone"] ?? '+962712345678',
      );

  Map<String, dynamic> toJson() => {
        'customerId': CustomerId,
        'name': Name,
        'email': Email,
        'address': Address,
        'phone': Phone,
        'OrganizationId': OrganizationId
      };
}
