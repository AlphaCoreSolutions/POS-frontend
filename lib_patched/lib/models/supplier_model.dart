class Supplier {
  final int SupplierId;
  final int OrganizationId;
  final String Name;
  final String CompanyName;
  final String Phone;
  final String Email;
  final String Address;

  Supplier(
      {required this.SupplierId,
      required this.Name,
      required this.CompanyName,
      required this.Phone,
      required this.Email,
      required this.Address,
      required this.OrganizationId});
  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
      SupplierId: json["supplierId"],
      Name: json["name"],
      CompanyName: json["companyName"] ?? 'Company Name',
      Email: json["email"] ?? "example@provider.com",
      Address: json["address"] ?? 'the Address',
      Phone: json["phone"] ?? '+962712345678',
      OrganizationId: json["OrganizationId"] ?? 0);

  Map<String, dynamic> toJson() => {
        'supplierId': SupplierId,
        'name': Name,
        'companyName': CompanyName,
        'email': Email,
        'address': Address,
        'phone': Phone,
        'OrganizationId': OrganizationId
      };
}
