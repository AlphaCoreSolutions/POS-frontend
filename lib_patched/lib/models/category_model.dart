class Category {
  final int id;
  final int? mainCategoryId; // null for top-level
  final int organizationId;
  final String categoryName;

  Category({
    required this.id,
    required this.organizationId,
    required this.categoryName,
    this.mainCategoryId,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] ?? json['Id'] ?? 0,
        organizationId: json['organizationId'] ?? json['OrganizationId'] ?? 0,
        categoryName: json['categoryName'] ?? json['CategoryName'] ?? '',
        mainCategoryId: json['mainCategoryId'] ?? json['MainCategoryId'],
      );

  Map<String, dynamic> toJson() => {
        // Either casing works because ASP.NET is case-insensitive,
        // but keep it consistent with your API schema:
        'Id': id,
        'CategoryName': categoryName,
        'OrganizationId': organizationId,
        'MainCategoryId': mainCategoryId, // null if top-level
      };
}
