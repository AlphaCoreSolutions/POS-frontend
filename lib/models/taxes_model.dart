class Taxes {
  int id;
  final int OrganizationId;
  double inHouse;
  double takeOut;

  Taxes(
      {required this.inHouse,
      required this.takeOut,
      required this.id,
      required this.OrganizationId});

  // From JSON
  factory Taxes.fromJson(Map<String, dynamic> json) {
    return Taxes(
        id: json['id'],
        inHouse: json['inHouse']?.toDouble() ?? 0.0,
        takeOut: json['takeout']?.toDouble() ?? 0.0,
        OrganizationId: json["OrganizationId"] ?? 0);
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inHouse': inHouse,
      'takeout': takeOut,
      'OrganizationId': OrganizationId
    };
  }
}
