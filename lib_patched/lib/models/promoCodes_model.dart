class Promocodes {
  final int id;
  final String PromoCode;
  final double Percentage;
  final int OrganizationId;

  Promocodes({
    required this.id,
    required this.PromoCode,
    required this.Percentage,
    required this.OrganizationId,
  });

  factory Promocodes.fromJson(Map<String, dynamic> json) {
    return Promocodes(
      id: json['id'] ?? 0,
      PromoCode: json['PromoCode'] ?? '',
      Percentage: (json['Percentage'] ?? 0.0).toDouble(),
      OrganizationId: json['OrganizationId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'PromoCode': PromoCode,
      'Percentage': Percentage,
      'OrganizationId': OrganizationId,
    };
  }
}
