import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/dialog/category_input_dialog.dart';
import 'package:wonmore_money_book/dialog/custom_delete_dialog.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        isMainScreen: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFF2F4F6), size: 36),
            onPressed: () async {
              final result = await showDialog(
                context: context,
                builder: (context) => CategoryInputDialog(type: _selectedType),
              );
              if (result) {
                // 자동 반영되므로 setState 필요 없음
              }
            },
          ),
        ],
      ),
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
                  },
                ),
              ],
            ),
          ),
          const Divider(thickness: 1, height: 1, color: Colors.grey),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Consumer<MoneyProvider>(
                builder: (context, provider, _) {
                  final filtered = provider.categories
                      .where((c) => c.type == _selectedType)
                      .toList();

                  return ReorderableListView.builder(
                    itemCount: filtered.length,
                    onReorder: (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) newIndex--;
                      final item = filtered.removeAt(oldIndex);
                      filtered.insert(newIndex, item);
                      await context.read<MoneyProvider>().reorderCategories(filtered);
                    },
                    itemBuilder: (context, index) {
                      final category = filtered[index];
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
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.grey),
                                onPressed: () async {
                                  final result = await showDialog(
                                    context: context,
                                    builder: (context) => CategoryInputDialog(
                                      type: _selectedType,
                                      category: category,
                                    ),
                                  );
                                  if (result) {
                                    // 목록은 자동 업데이트됨
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.grey),
                                onPressed: () async {
                                  final result = await showCustomDeleteDialog(
                                    context,
                                    message: '이 카테고리를 정말 삭제할까요?',
                                  );
                                  if (result!) {
                                    await context.read<MoneyProvider>().deleteCategory(category.id!);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('삭제되었습니다.')),
                                    );
                                  }
                                }
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