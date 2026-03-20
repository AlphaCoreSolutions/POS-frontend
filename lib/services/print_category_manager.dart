import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visionpos/models/category_model.dart' as cat_model;

/// Manages dynamic category routing for printing.
/// Allows users to assign which categories print to which kitchen/printer role.
class PrintCategoryManager with ChangeNotifier {
  static const String _falafelKey = 'print_falafel_categories';
  static const String _shawarmaKey = 'print_shawarma_categories';

  Set<int> _falafelCategoryIds = {};
  Set<int> _shawarmaSnacksCategoryIds = {};

  Set<int> get falafelCategoryIds => Set.unmodifiable(_falafelCategoryIds);
  Set<int> get shawarmaSnacksCategoryIds =>
      Set.unmodifiable(_shawarmaSnacksCategoryIds);

  /// Load saved category routing from cache
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load falafel categories
      final falafelJson = prefs.getString(_falafelKey);
      if (falafelJson != null) {
        final list = jsonDecode(falafelJson) as List;
        _falafelCategoryIds = list.map((e) => e as int).toSet();
      }

      // Load shawarma categories
      final shawarmaJson = prefs.getString(_shawarmaKey);
      if (shawarmaJson != null) {
        final list = jsonDecode(shawarmaJson) as List;
        _shawarmaSnacksCategoryIds = list.map((e) => e as int).toSet();
      }

      debugPrint(
          '📋 PrintCategoryManager loaded - Falafel: $_falafelCategoryIds, Shawarma: $_shawarmaSnacksCategoryIds');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading print categories: $e');
    }
  }

  /// Save falafel category routing
  Future<void> setFalafelCategories(Set<int> categoryIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _falafelCategoryIds = categoryIds;
      await prefs.setString(_falafelKey, jsonEncode(categoryIds.toList()));
      debugPrint('✅ Saved falafel categories: $_falafelCategoryIds');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error saving falafel categories: $e');
    }
  }

  /// Save shawarma category routing
  Future<void> setShawarmaSnacksCategories(Set<int> categoryIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _shawarmaSnacksCategoryIds = categoryIds;
      await prefs.setString(_shawarmaKey, jsonEncode(categoryIds.toList()));
      debugPrint('✅ Saved shawarma categories: $_shawarmaSnacksCategoryIds');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error saving shawarma categories: $e');
    }
  }

  /// Set both falafel and shawarma categories at once
  Future<void> setAllCategories({
    required Set<int> falafel,
    required Set<int> shawarma,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _falafelCategoryIds = falafel;
      _shawarmaSnacksCategoryIds = shawarma;

      await prefs.setString(_falafelKey, jsonEncode(falafel.toList()));
      await prefs.setString(_shawarmaKey, jsonEncode(shawarma.toList()));

      debugPrint(
          '✅ Saved all categories - Falafel: $_falafelCategoryIds, Shawarma: $_shawarmaSnacksCategoryIds');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error saving all categories: $e');
    }
  }

  /// Clear all saved categories
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _falafelCategoryIds.clear();
      _shawarmaSnacksCategoryIds.clear();
      await prefs.remove(_falafelKey);
      await prefs.remove(_shawarmaKey);
      debugPrint('✅ Cleared all print categories');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error clearing categories: $e');
    }
  }

  /// Get category name from list of categories
  String? getCategoryName(int categoryId, List<cat_model.Category> allCategories) {
    try {
      return allCategories
          .firstWhere((c) => c.id == categoryId)
          .categoryName;
    } catch (e) {
      return null;
    }
  }

  /// Get all category names for falafel
  List<String> getFalafelCategoryNames(List<cat_model.Category> allCategories) {
    return _falafelCategoryIds
        .map((id) => getCategoryName(id, allCategories))
        .whereType<String>()
        .toList();
  }

  /// Get all category names for shawarma
  List<String> getShawarmaSnacksCategoryNames(List<cat_model.Category> allCategories) {
    return _shawarmaSnacksCategoryIds
        .map((id) => getCategoryName(id, allCategories))
        .whereType<String>()
        .toList();
  }

  /// Check if categories are configured
  bool get isConfigured =>
      _falafelCategoryIds.isNotEmpty || _shawarmaSnacksCategoryIds.isNotEmpty;

  /// Get summary of current configuration
  String getConfigurationSummary(List<cat_model.Category> allCategories) {
    final falafelNames = getFalafelCategoryNames(allCategories);
    final shawarmaNames = getShawarmaSnacksCategoryNames(allCategories);

    final parts = <String>[];
    if (falafelNames.isNotEmpty) {
      parts.add('🍗 Falafel: ${falafelNames.join(", ")}');
    }
    if (shawarmaNames.isNotEmpty) {
      parts.add('🌯 Shawarma: ${shawarmaNames.join(", ")}');
    }

    return parts.isEmpty ? 'Not configured' : parts.join('\n');
  }
}
