class OrderItemAdditionDto {
  final int domainDetailId;
  final String? additionName; // only for responses
  final double? priceIncrease; // only for responses

  OrderItemAdditionDto({
    required this.domainDetailId,
    this.additionName,
    this.priceIncrease,
  });

  factory OrderItemAdditionDto.fromJson(Map<String, dynamic> json) {
    return OrderItemAdditionDto(
      domainDetailId: json['domainDetailId'] ?? json['DomainDetailId'] ?? 0,
      additionName: json['additionName'] ?? json['AdditionName'],
      priceIncrease:
          (json['priceIncrease'] ?? json['PriceIncrease'] ?? 0).toDouble(),
    );
  }

  /// For POST /api/orders we only need the ID.
  Map<String, dynamic> toJson() {
    return {
      'domainDetailId': domainDetailId,
    };
  }
}
