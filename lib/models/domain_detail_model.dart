class DomainDetail {
  final int domainDetailId;
  final int? domainId;
  final String name;
  final double priceIncrease;
  final bool? isActive;

  DomainDetail({
    required this.domainDetailId,
    this.domainId,
    required this.name,
    this.priceIncrease = 0.0,
    this.isActive,
  });

  factory DomainDetail.fromJson(Map<String, dynamic> json) {
    return DomainDetail(
      domainDetailId: json['domainDetailId'] ?? json['DomainDetailId'] ?? 0,
      domainId: json['domainId'] ?? json['DomainId'],
      name: json['name'] ?? json['Name'] ?? '',
      priceIncrease:
          (json['priceIncrease'] ?? json['PriceIncrease'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? json['IsActive'],
    );
  }

  /// For POST /api/orders additions we only need the ID.
  Map<String, dynamic> toJson() {
    return {
      'domainDetailId': domainDetailId,
    };
  }
}
