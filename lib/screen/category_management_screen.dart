import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';
import 'package:wonmore_money_book/provider/money_provider.dart';
import 'package:wonmore_money_book/util/icon_map.dart';
import 'package:wonmore_money_book/widget/common_app_bar.dart';
import 'package:wonmore_money_book/widget/transaction_type_button.dart';

class CategoryManagementScreen extends StatefulWidget {
  final TransactionType selectedType;

  const CategoryManagementScreen({
    super.key,
    required this.selectedType,
  });

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  late TransactionType _selectedType;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncCategories();
    });
  }

  void _syncCategories() {
    final all = context.read<MoneyProvider>().categories;
    setState(() {
      _categories = all.where((c) => c.type == _selectedType).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(isMainScreen: false),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                TransactionTypeButton(
                  label: '수입',
                  type: TransactionType.income,
                  selectedType: _selectedType,
                  onSelected: (type) {
                    setState(() {
                      _selectedType = type;
                    });
                    _syncCategories();
                  },
                ),
                const SizedBox(width: 24),
                TransactionTypeButton(
                  label: '지출',
                  type: TransactionType.expense,
                  selectedType: _selectedType,
                  onSelected: (type) {
                    setState(() {
                      _selectedType = type;
                    });
                    _syncCategories();
                  },
                ),
              ],
            ),
          ),
          const Divider(thickness: 1, height: 1, color: Colors.grey),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ReorderableListView.builder(
                itemCount: _categories.length,
                onReorder: (oldIndex, newIndex) async {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _categories.removeAt(oldIndex);
                    _categories.insert(newIndex, item);
                  });

                  await context.read<MoneyProvider>().reorderCategories(_categories);
                  _syncCategories(); // 최신 정렬 반영
                },
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Card(
                    key: ValueKey(category.id),
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.amberAccent, width: 1),
                    ),
                    child: ListTile(
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(category.colorValue),
                        child: Icon(
                          getIconData(category.iconName),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        category.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey),
                            onPressed: () {
                              // TODO: 수정 기능
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () async {
                              final result = await context
                                  .read<MoneyProvider>()
                                  .deleteCategory(category.id);
                              if (!result && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('기본 카테고리는 삭제할 수 없습니다.')),
                                );
                              } else {
                                _syncCategories(); // 삭제 후 목록 반영
                              }
                            },
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
