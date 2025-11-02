import 'package:flutter/material.dart';
import 'package:visionpos/models/category_model.dart';

class CategorySelector extends StatelessWidget {
  final List<Category> rootCategories;
  final List<Category> activeSubs;
  final Category? selectedCategory;
  final int? selectedSubId;
  final Function(Category?) onRootTap;
  final Function(Category) onSubTap;

  const CategorySelector({
    super.key,
    required this.rootCategories,
    required this.activeSubs,
    this.selectedCategory,
    this.selectedSubId,
    required this.onRootTap,
    required this.onSubTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main category row (horizontal)
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.18,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: rootCategories.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final cat = isAll ? null : rootCategories[index - 1];
              final name = isAll ? 'All' : cat!.categoryName;

              return GestureDetector(
                onTap: () => onRootTap(cat),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: MediaQuery.of(context).size.width * 0.13,
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.016,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(166, 0, 0, 0),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Animated subcategory rail (vertical, compact)
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          key: ValueKey(activeSubs.length),
          curve: Curves.easeOut,
          child: activeSubs.isEmpty
              ? const SizedBox.shrink()
              : SizedBox(
                  height: MediaQuery.of(context).size.height * 0.16,
                  child: Row(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.12,
                        margin: const EdgeInsets.only(left: 4, right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Scrollbar(
                          thumbVisibility: true,
                          interactive: true,
                          child: ListView.separated(
                            primary: false,
                            padding: const EdgeInsets.all(10),
                            physics: const BouncingScrollPhysics(),
                            itemCount: activeSubs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final sub = activeSubs[i];
                              final selected = sub.id == selectedSubId;
                              final cs = Theme.of(context).colorScheme;

                              return Material(
                                color: selected
                                    ? cs.primary.withOpacity(0.08)
                                    : Colors.white,
                                elevation: selected ? 2 : 0,
                                shadowColor: cs.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: () => onSubTap(sub),
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected
                                            ? cs.primary
                                            : Colors.grey.withOpacity(0.22),
                                        width: selected ? 1.25 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          color: selected
                                              ? cs.primary
                                              : Colors.grey.withOpacity(0.18),
                                          duration:
                                              const Duration(milliseconds: 160),
                                          width: 28,
                                          height: 28,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: selected
                                                ? cs.primary.withOpacity(0.18)
                                                : Colors.grey.shade200,
                                          ),
                                          child: Icon(
                                            Icons.label_rounded,
                                            size: 16,
                                            color: selected
                                                ? cs.primary
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            sub.categoryName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: const Color(0xFF36454F),
                                              fontWeight: FontWeight.w600,
                                              fontSize: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.011,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          size: 18,
                                          color: selected
                                              ? cs.primary
                                              : Colors.grey.shade600,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
