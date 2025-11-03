class User {
  final int id;
  final int organizationId;
  final String fullName;
  final String userName;
  final String email;
  final String password;
  final String phoneNumber;
  final String role;
  final bool isActive;

  const User({
    required this.id,
    required this.organizationId,
    required this.fullName,
    required this.userName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.role,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
      id: json['id'] ?? 0,
      fullName: json["fullName"] ?? '',
      userName: json["userName"] ?? '',
      email: json["email"] ?? '',
      password: json["password"] ?? '',
      phoneNumber: json["phoneNumber"] ?? '',
      role: json["role"] ?? '',
      organizationId: json["organizationId"] ?? 0,
      isActive: json["isActive"] ?? true);

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'userName': userName,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'role': role,
        'organizationId': organizationId,
        'isActive': isActive
      };

  @override
  String toString() {
    return 'User{id: $id, fullName: $fullName, userName: $userName, email: $email, phone: $phoneNumber, role: $role, orgId: $organizationId, isActive: $isActive}';
  }
}
