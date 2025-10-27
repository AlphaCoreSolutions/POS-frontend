import 'dart:convert';

import 'package:fixed_pos/models/category_model.dart';
import 'package:fixed_pos/pages/essential_pages/api_handler.dart';
import 'package:fixed_pos/utils/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class AddCategory extends StatefulWidget {
  final int? initialOrgId;
  const AddCategory({super.key, this.initialOrgId});
  @override
  State<AddCategory> createState() => _AddCategoryState();
}

class _AddCategoryState extends State<AddCategory> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _api = ApiHandler();

  bool _loading = true; // loading orgId + categories
  bool _saving = false; // posting
  String? _loadError;

  int? _orgId;
  List<Category> _all = [];
  Category? _parent;

  // theme colors you used
  final copper = const Color(0xFFB87333);
  final charcoal = const Color(0xFF36454F);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _orgId = widget.initialOrgId ?? await SessionManager.getOrganizationId();
    debugPrint('🔎 Loaded orgId: $_orgId');
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      // 1) read orgId from session (supports null)
      _orgId = await SessionManager.getOrganizationId();
      debugPrint('🔎 Loaded orgId from session: $_orgId');

      // 2) fetch all categories once; filter locally if orgId > 0
      final all = await _api.getCategoryData();
      _all = (_orgId ?? 0) > 0
          ? all.where((c) => c.organizationId == _orgId).toList()
          : all;
    } catch (e) {
      _loadError = 'Failed to load data: $e';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  int _validOrgIdOrZero(int? id) => (id ?? 0) > 0 ? id! : 0;

  Future<void> _add() async {
    if (_loading || _saving) return;

    // Validate form fields
    if (!_formKey.currentState!.saveAndValidate()) return;

    // Validate org
    final orgId = _validOrgIdOrZero(_orgId);
    if (orgId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Organization is missing. Please sign in/select org first.'),
        ),
      );
      return;
    }

    final v = _formKey.currentState!.value;

    final cat = Category(
      id: 0,
      mainCategoryId: _parent?.id, // null => top-level
      organizationId: orgId,
      categoryName: v['categoryName'],
    );

    // Pre-flight log
    debugPrint('🟠 About to POST Category: ${jsonEncode(cat.toJson())}');

    setState(() => _saving = true);
    try {
      final resp = await _api.AddCategory(category: cat);
      debugPrint('🟢 POST /Category status: ${resp.statusCode}');
      debugPrint('🟢 body: ${resp.body}');

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        // API returns created entity; pass it back
        final created = Category.fromJson(json.decode(resp.body));
        Navigator.pop(context, created);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${resp.statusCode} - ${resp.body}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(primary: copper),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: copper),
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        fillColor: Colors.white,
        filled: true,
      ),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFB87333)),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title:
              const Text('Add Category', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: _saving
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const Icon(Icons.check, color: Colors.white),
              onPressed: (_loading || _saving) ? null : _add,
              tooltip: 'Save',
            ),
          ],
        ),
        backgroundColor: Colors.grey[100],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_loadError != null)
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _loadError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: FormBuilder(
                          key: _formKey,
                          child: Column(
                            children: [
                              FormBuilderTextField(
                                name: 'categoryName',
                                decoration: const InputDecoration(
                                  labelText: 'Category name',
                                  prefixIcon: Icon(Icons.category_outlined),
                                ),
                                validator: FormBuilderValidators.compose(
                                  [FormBuilderValidators.required()],
                                ),
                                textInputAction: TextInputAction.done,
                              ),
                              const SizedBox(height: 16),
                              // Parent chooser (optional)
                              FormBuilderDropdown<Category?>(
                                name: 'parent',
                                decoration: const InputDecoration(
                                  labelText: 'Parent (optional)',
                                  prefixIcon: Icon(Icons.account_tree_outlined),
                                ),
                                items: [
                                  const DropdownMenuItem<Category?>(
                                    value: null,
                                    child: Text('None (Top-level)'),
                                  ),
                                  ..._all.map(
                                    (c) => DropdownMenuItem<Category?>(
                                      value: c,
                                      child: Text(c.categoryName),
                                    ),
                                  ),
                                ],
                                onChanged: (c) => _parent = c,
                              ),
                              const SizedBox(height: 8),
                              if ((_orgId ?? 0) <= 0) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'No organization selected. You can still browse parents, but saving requires a valid organization.',
                                  style: TextStyle(color: Colors.orange),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
