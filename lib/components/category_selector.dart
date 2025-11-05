import 'package:flutter/material.dart';
import 'package:visionpos/models/category_model.dart';

class CategorySelector extends StatefulWidget {
  final List<Category> allCategories;
  final Category? selectedCategory;
  final int? selectedSubId;
  final Function(Category?) onRootTap;
  final Function(Category) onSubTap;

  const CategorySelector({
    super.key,
    required this.allCategories,
    this.selectedCategory,
    this.selectedSubId,
    required this.onRootTap,
    required this.onSubTap,
  });

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  int? expandedCategoryId;

  List<Category> get rootCategories =>
      widget.allCategories.where((cat) => cat.mainCategoryId == null).toList();

  List<Category> getSubCategories(int parentId) => widget.allCategories
      .where((cat) => cat.mainCategoryId == parentId)
      .toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rootCategories.map((cat) {
          final isExpanded = expandedCategoryId == cat.id;
          final subCats = getSubCategories(cat.id);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (expandedCategoryId == cat.id) {
                      expandedCategoryId = null;
                      widget.onRootTap(null);
                    } else {
                      expandedCategoryId = cat.id;
                      widget.onRootTap(cat);
                    }
                  });
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    cat.categoryName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child: isExpanded && subCats.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: subCats.map((subCat) {
                            return GestureDetector(
                              onTap: () => widget.onSubTap(subCat),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  subCat.categoryName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
