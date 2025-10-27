class Organization {
  final int id;
  final String nameAR;
  final String nameEN;
  final int vat;
  final int crNumber;
  final String logo;
  final String fullAddress;

  Organization({
    required this.id,
    required this.nameAR,
    required this.nameEN,
    required this.vat,
    required this.crNumber,
    required this.logo,
    required this.fullAddress,
  });

  /// Create an Organization from a JSON map
  factory Organization.fromJson(Map<String, dynamic> json) => Organization(
        id: json['id'] as int,
        nameAR: json['nameAR'] as String,
        nameEN: json['nameEN'] as String,
        vat: json['vat'] as int,
        crNumber: json['crNumber'] as int,
        logo: json['logo'] as String,
        fullAddress: json['fullAddress'] as String,
      );

  /// Convert this Organization into a JSON map
  Map<String, dynamic> toJson() => {
        'id': id,
        'nameAR': nameAR,
        'nameEN': nameEN,
        'vat': vat,
        'crNumber': crNumber,
        'logo': logo,
        'fullAddress': fullAddress,
      };
}
