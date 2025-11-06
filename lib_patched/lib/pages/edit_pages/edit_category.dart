import 'package:visionpos/models/category_model.dart';
import 'package:visionpos/pages/add_pages/add_category.dart';
import 'package:visionpos/pages/essential_pages/api_handler.dart';
import 'package:visionpos/utils/session_manager.dart';
import 'package:flutter/material.dart';

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});
  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  final api = ApiHandler();
  List<Category> _all = [];
  int? _orgId;
  final copper = const Color(0xFFB87333);
  final charcoal = const Color(0xFF36454F);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _orgId = await SessionManager.getOrganizationId();
    _all = await api.getCategoriesForOrg(_orgId ?? 0);
    if (mounted) setState(() {});
  }

  Future<void> _addSub(Category parent) async {
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add subcategory'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: copper),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      await api.AddCategory(
        category: Category(
          id: 0,
          mainCategoryId: parent.id,
          organizationId: _orgId ?? 0,
          categoryName: nameCtrl.text.trim(),
        ),
      );
      await _load();
    }
  }

  Future<void> _rename(Category c) async {
    final ctrl = TextEditingController(text: c.categoryName);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename category'),
        content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: copper),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await api.updateCategory(
        category: Category(
          id: c.id,
          mainCategoryId: c.mainCategoryId,
          organizationId: c.organizationId,
          categoryName: ctrl.text.trim(),
        ),
      );
      await _load();
    }
  }

  Future<void> _delete(Category c) async {
    await api.deleteCategory(categoryID: c.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final roots = api.rootsOf(_all);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: copper,
        title: const Text('Manage Categories',
            style: TextStyle(color: Colors.white)),
      ),
      backgroundColor: Colors.grey[100],
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: roots.length,
        itemBuilder: (_, i) {
          final parent = roots[i];
          final subs = api.childrenOf(parent.id, _all);
          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              title: Text(parent.categoryName,
                  style:
                      TextStyle(color: charcoal, fontWeight: FontWeight.bold)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    onPressed: () => _rename(parent),
                    icon: const Icon(Icons.edit, color: Colors.black54)),
                IconButton(
                    onPressed: () => _delete(parent),
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent)),
              ]),
              children: [
                ...subs.map((s) => ListTile(
                      title: Text(s.categoryName),
                      leading: const Icon(Icons.subdirectory_arrow_right),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                            onPressed: () => _rename(s),
                            icon:
                                const Icon(Icons.edit, color: Colors.black54)),
                        IconButton(
                            onPressed: () => _delete(s),
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent)),
                      ]),
                    )),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 12),
                    child: ElevatedButton.icon(
                      onPressed: () => _addSub(parent),
                      icon: const Icon(Icons.add),
                      label: const Text('Add subcategory'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: copper,
                          foregroundColor: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: copper,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const AddCategory()))
            .then((_) => _load()),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
    );
  }
}
