class OrderItemAdditionDto {
  final int domainDetailId;
  final String? additionName;
  final double? priceIncrease;

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

  Map<String, dynamic> toJson() {
    return {
      'domainDetailId': domainDetailId,
    };
  }
}
