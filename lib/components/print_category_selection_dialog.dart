import 'package:flutter/material.dart';
import 'package:visionpos/models/category_model.dart';
import 'package:visionpos/services/print_category_manager.dart';

/// Dialog for selecting which categories route to which kitchen/printer
class PrintCategorySelectionDialog extends StatefulWidget {
  final List<Category> allCategories;
  final PrintCategoryManager categoryManager;

  const PrintCategorySelectionDialog({
    super.key,
    required this.allCategories,
    required this.categoryManager,
  });

  @override
  State<PrintCategorySelectionDialog> createState() =>
      _PrintCategorySelectionDialogState();
}

class _PrintCategorySelectionDialogState
    extends State<PrintCategorySelectionDialog> {
  late Set<int> _selectedFalafel;
  late Set<int> _selectedShawarma;
  final Set<int> _unassigned = {};

  @override
  void initState() {
    super.initState();
    _selectedFalafel =
        Set.from(widget.categoryManager.falafelCategoryIds);
    _selectedShawarma =
        Set.from(widget.categoryManager.shawarmaSnacksCategoryIds);
    _updateUnassigned();
  }

  void _updateUnassigned() {
    _unassigned.clear();
    for (final cat in widget.allCategories) {
      if (!_selectedFalafel.contains(cat.id) &&
          !_selectedShawarma.contains(cat.id)) {
        _unassigned.add(cat.id);
      }
    }
  }

  void _toggleFalafelCategory(int categoryId) {
    setState(() {
      if (_selectedFalafel.contains(categoryId)) {
        _selectedFalafel.remove(categoryId);
      } else {
        _selectedFalafel.add(categoryId);
        _selectedShawarma.remove(categoryId);
      }
      _updateUnassigned();
    });
  }

  void _toggleShawarmaCategory(int categoryId) {
    setState(() {
      if (_selectedShawarma.contains(categoryId)) {
        _selectedShawarma.remove(categoryId);
      } else {
        _selectedShawarma.add(categoryId);
        _selectedFalafel.remove(categoryId);
      }
      _updateUnassigned();
    });
  }

  void _toggleUnassignedCategory(int categoryId) {
    setState(() {
      _unassigned.remove(categoryId);
      _selectedFalafel.remove(categoryId);
      _selectedShawarma.remove(categoryId);
    });
  }

  void _save() async {
    await widget.categoryManager.setAllCategories(
      falafel: _selectedFalafel,
      shawarma: _selectedShawarma,
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Print category routing saved'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _getCategoryName(int categoryId) {
    try {
      return widget.allCategories
          .firstWhere((c) => c.id == categoryId)
          .categoryName;
    } catch (e) {
      return 'Category $categoryId';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Get leaf categories (categories without children)
    final leafCategories = _getLeafCategories();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: screenWidth * 0.7,
        height: screenHeight * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Text(
              'Configure Print Categories',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Assign categories to different kitchen printers',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Category assignments
            Expanded(
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Falafel Kitchen
                    Expanded(
                      child: _buildKitchenSection(
                        title: '🍗 Falafel Kitchen',
                        color: Colors.orange,
                        selectedIds: _selectedFalafel,
                        leafCategories: leafCategories,
                        onToggle: _toggleFalafelCategory,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Shawarma & Snacks Kitchen
                    Expanded(
                      child: _buildKitchenSection(
                        title: '🌯 Shawarma & Snacks',
                        color: Colors.deepOrange,
                        selectedIds: _selectedShawarma,
                        leafCategories: leafCategories,
                        onToggle: _toggleShawarmaCategory,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Unassigned
                    Expanded(
                      child: _buildKitchenSection(
                        title: '❌ Unassigned',
                        color: Colors.grey,
                        selectedIds: _unassigned,
                        leafCategories: leafCategories,
                        onToggle: _toggleUnassignedCategory,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB87333),
                  ),
                  child: const Text(
                    'Save Configuration',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKitchenSection({
    required String title,
    required Color color,
    required Set<int> selectedIds,
    required List<Category> leafCategories,
    required Function(int) onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          if (selectedIds.isEmpty)
            Text(
              'No categories assigned',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedIds.map((id) {
                return Chip(
                  label: Text(_getCategoryName(id)),
                  onDeleted: () => onToggle(id),
                  deleteIcon: const Icon(Icons.close, size: 16),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Click to assign:',
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: leafCategories.map((cat) {
              final isSelected = selectedIds.contains(cat.id);
              return GestureDetector(
                onTap: () => onToggle(cat.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    cat.categoryName,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<Category> _getLeafCategories() {
    // Get categories that don't have children
    final parentIds = {
      for (var c in widget.allCategories
          .where((c) => c.mainCategoryId != null))
        c.mainCategoryId
    };

    return widget.allCategories
        .where((c) => !parentIds.contains(c.id))
        .toList();
  }
}
