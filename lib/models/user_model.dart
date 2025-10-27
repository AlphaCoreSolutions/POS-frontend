class User {
  final int id;
  final int OrganizationId;
  final String FullName;
  final String UserName;
  final String Email;
  final String Password;
  final String PhoneNumber;
  final String Role;

  const User({
    required this.id,
    required this.OrganizationId,
    required this.FullName,
    required this.UserName,
    required this.Email,
    required this.Password,
    required this.PhoneNumber,
    required this.Role,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
      id: json['id'] ?? 0, // Default 0 if null
      FullName: json["fullName"] ?? '', // Ensure matching API response casing
      UserName: json["userName"] ?? '',
      Email: json["email"] ?? '',
      Password: json["password"] ?? '',
      PhoneNumber: json["phoneNumber"] ?? '',
      Role: json["role"] ?? '',
      OrganizationId: json["organizationId"] ?? 0);

  Map<String, dynamic> toJson() => {
        // Corrected function name
        'id': id,
        'fullName': FullName, // Ensure it matches API expectation
        'userName': UserName,
        'email': Email,
        'password': Password,
        'phoneNumber': PhoneNumber,
        'role': Role,
        'OrganizationId': OrganizationId
      };

  @override
  String toString() {
    return 'User{id: $id, fullName: $FullName, userName: $UserName, email: $Email, phone: $PhoneNumber, role: $Role, orgId: $OrganizationId}';
  }
}
