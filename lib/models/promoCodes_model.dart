class Promocodes {
  final int? id;
  final int OrganizationId;
  final String PromoCode;
  final double Percentage;

  const Promocodes(
      {this.id,
      required this.PromoCode,
      required this.Percentage,
      required this.OrganizationId});

  factory Promocodes.fromJson(Map<String, dynamic> json) => Promocodes(
      id: json['id'],
      PromoCode: json["name"] ?? "No Promo Code",
      Percentage: json["percentage"] ?? 0.0,
      OrganizationId: json["OrganizationId"] ?? 0);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': PromoCode,
        'percentage': Percentage,
        'OrganizationId': OrganizationId
      };
}
