import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/component/banner_ad_widget.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/dialog/custom_delete_dialog.dart';
import 'package:wonmore_money_book/dialog/favorite_record_input_dialog.dart';
import 'package:wonmore_money_book/dialog/repeat_record_input_dialog.dart';
import 'package:wonmore_money_book/model/period_type.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';
import 'package:wonmore_money_book/provider/money_provider.dart';
import 'package:wonmore_money_book/util/icon_map.dart';

class FavoriteScreen extends StatefulWidget {
  final VoidCallback onClose;

  const FavoriteScreen({
    super.key,
    required this.onClose,
  });

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  bool _isRepeat = false;

  @override
  Widget build(BuildContext context) {
    // final dummyRecords = [
    //   FavoriteRecord(
    //     id: 1,
    //     amount: 50000,
    //     type: TransactionType.expense,
    //     period: PeriodType.none,
    //     sortOrder: 0,
    //     startDate: DateTime(2025, 6, 1),
    //     lastGeneratedDate: DateTime.now(),
    //     categoryId: 1,
    //     assetId: 1,
    //     title: '점심 회식',
    //     memo: '회사 팀 회식',
    //     createdAt: DateTime.now(),
    //     updatedAt: DateTime.now(),
    //     userId: null,
    //     createdBy: null,
    //     updatedBy: null,
    //   ),
    //   FavoriteRecord(
    //     id: 2,
    //     amount: 200000,
    //     type: TransactionType.expense,
    //     period: PeriodType.everyMonth,
    //     sortOrder: 1,
    //     startDate: DateTime(2025, 6, 1),
    //     categoryId: 2,
    //     assetId: 1,
    //     title: '아이 학원비',
    //     memo: '매달 1일 결제',
    //     createdAt: DateTime.now(),
    //     updatedAt: DateTime.now(),
    //     userId: null,
    //     createdBy: null,
    //     updatedBy: null,
    //   ),
    //   FavoriteRecord(
    //     id: 3,
    //     amount: 10000,
    //     type: TransactionType.expense,
    //     period: PeriodType.everyDay,
    //     sortOrder: 2,
    //     startDate: DateTime(2025, 6, 1),
    //     categoryId: 3,
    //     assetId: 2,
    //     title: '커피',
    //     memo: '스타벅스 아메리카노',
    //     createdAt: DateTime.now(),
    //     updatedAt: DateTime.now(),
    //     userId: null,
    //     createdBy: null,
    //     updatedBy: null,
    //   ),
    //   FavoriteRecord(
    //     id: 4,
    //     amount: 3000000,
    //     type: TransactionType.income,
    //     period: PeriodType.everyMonth,
    //     sortOrder: 3,
    //     startDate: DateTime(2025, 6, 25),
    //     categoryId: 4,
    //     assetId: 1,
    //     title: '월급',
    //     memo: '6월 급여',
    //     createdAt: DateTime.now(),
    //     updatedAt: DateTime.now(),
    //     userId: null,
    //     createdBy: null,
    //     updatedBy: null,
    //   ),
    //   FavoriteRecord(
    //     id: 5,
    //     amount: 120000,
    //     type: TransactionType.expense,
    //     period: PeriodType.everyWeek,
    //     sortOrder: 4,
    //     startDate: DateTime(2025, 6, 3),
    //     categoryId: 5,
    //     assetId: 2,
    //     title: '정기 쇼핑',
    //     memo: '홈플러스 장보기',
    //     createdAt: DateTime.now(),
    //     updatedAt: DateTime.now(),
    //     userId: null,
    //     createdBy: null,
    //     updatedBy: null,
    //   ),
    //   FavoriteRecord(
    //     id: 6,
    //     amount: 80000,
    //     type: TransactionType.expense,
    //     period: PeriodType.none,
    //     sortOrder: 5,
    //     startDate: DateTime(2025, 6, 5),
    //     categoryId: 6,
    //     assetId: 3,
    //     title: '아이 병원비',
    //     memo: '소아과 진료',
    //     createdAt: DateTime.now(),
    //     updatedAt: DateTime.now(),
    //     userId: null,
    //     createdBy: null,
    //     updatedBy: null,
    //   ),
    //   FavoriteRecord(
    //     id: 7,
    //     amount: 15000,
    //     type: TransactionType.expense,
    //     period: PeriodType.everyWeek,
    //     sortOrder: 6,
    //     startDate: DateTime(2025, 6, 2),
    //     categoryId: 3,
    //     assetId: 1,
    //     title: '편의점 간식',
    //     memo: '월요일 간식비',
    //     createdAt: DateTime.now(),
    //     updatedAt: DateTime.now(),
    //     userId: null,
    //     createdBy: null,
    //     updatedBy: null,
    //   ),
    //   FavoriteRecord(
    //     id: 8,
    //     amount: 250000,
    //     type: TransactionType.transfer,
    //     period: PeriodType.everyMonth,
    //     sortOrder: 7,
    //     startDate: DateTime(2025, 6, 10),
    //     categoryId: 7,
    //     assetId: 1,
    //     title: '저축 이체',
    //     memo: '적금 통장으로 이체',
    //     createdAt: DateTime.now(),
    //     updatedAt: DateTime.now(),
    //     userId: null,
    //     createdBy: null,
    //     updatedBy: null,
    //   ),
    // ];

    return WillPopScope(
      onWillPop: () {
        widget.onClose();
        return Future.value(false);
      },
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  _typeButton(
                    label: '개별',
                    isSelected: !_isRepeat,
                    onPressed: () {
                      setState(() {
                        _isRepeat = false;
                      });
                    },
                  ),
                  const SizedBox(width: 24),
                  _typeButton(
                    label: '반복',
                    isSelected: _isRepeat,
                    onPressed: () {
                      setState(() {
                        _isRepeat = true;
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
                    final records = provider.favoriteRecords;
                    final filtered = records.where((record) {
                      if (_isRepeat) {
                        // 반복 거래: period가 none이 아닌 것만
                        return record.period != PeriodType.none;
                      } else {
                        // 개별 거래: period가 none인 것만
                        return record.period == PeriodType.none;
                      }
                    }).toList();

                    // final filtered = dummyRecords.where((record) {
                    //   return _isRepeat
                    //       ? record.period != PeriodType.none
                    //       : record.period == PeriodType.none;
                    // }).toList();

                    return _isRepeat
                        ? ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              Category? category;
                              try {
                                category = provider.categories
                                    .firstWhere((c) => c.id == filtered[index].categoryId);
                              } catch (_) {
                                category = null;
                              }
                              Asset? asset;
                              try {
                                asset = provider.assets
                                    .firstWhere((c) => c.id == filtered[index].assetId);
                              } catch (_) {
                                asset = null;
                              }
                              final favoriteRecord = filtered[index];
                              return Card(
                                key: ValueKey(favoriteRecord.id),
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Colors.amberAccent, width: 1),
                                ),
                                child: ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                  leading: SizedBox(
                                    width: 50,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: category != null
                                              ? Color(category.colorValue)
                                              : Colors.grey.shade300,
                                          child: Icon(
                                              category != null
                                                  ? getIconData(category.iconName)
                                                  : Icons.category,
                                              color: Colors.white,
                                              size: 16),
                                        ),
                                        Text(
                                          category?.name ?? '미분류',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: category != null ? Colors.black : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  title: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              favoriteRecord.title ?? '',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            if (asset != null)
                                              Text(
                                                asset.name,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${favoriteRecord.type == TransactionType.income ? '+' : '-'}${_formatAmount(favoriteRecord.amount)}원',
                                        style: TextStyle(
                                          color: favoriteRecord.type == TransactionType.income
                                              ? Colors.blue
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // subtitle: asset != null ? Text(asset.name) : null,
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => RepeatRecordInputDialog(
                                        initialStartDate: favoriteRecord.startDate!,
                                        initialType: favoriteRecord.type,
                                        initialTitle: favoriteRecord.title,
                                        initialAmount: favoriteRecord.amount,
                                        initialCategoryId: favoriteRecord.categoryId,
                                        initialAssetId: favoriteRecord.assetId,
                                        initialMemo: favoriteRecord.memo,
                                        favoriteRecordId: favoriteRecord.id,
                                      ),
                                    ).then((result) {
                                      if (result == true) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('수정되었습니다')),
                                        );
                                      }
                                    });
                                  },
                                  trailing: Text(
                                    periodTypeToKo(favoriteRecord.period) ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            },
                          )
                        : ReorderableListView.builder(
                            itemCount: filtered.length,
                            onReorder: (oldIndex, newIndex) async {
                              if (newIndex > oldIndex) newIndex--;
                              final item = filtered.removeAt(oldIndex);
                              filtered.insert(newIndex, item);

                              final idOrder = filtered.map((r) => r.id).toList();
                              final reordered = provider.favoriteRecords
                                  .where((r) => idOrder.contains(r.id))
                                  .toList()
                                ..sort((a, b) =>
                                    idOrder.indexOf(a.id).compareTo(idOrder.indexOf(b.id)));
                              await context.read<MoneyProvider>().reorderFavoriteRecords(reordered);
                            },
                            itemBuilder: (context, index) {
                              Category? category;
                              try {
                                category = provider.categories
                                    .firstWhere((c) => c.id == filtered[index].categoryId);
                              } catch (_) {
                                category = null;
                              }
                              Asset? asset;
                              try {
                                asset = provider.assets
                                    .firstWhere((a) => a.id == filtered[index].assetId);
                              } catch (_) {
                                asset = null;
                              }
                              final favoriteRecord = filtered[index];
                              return Card(
                                key: ValueKey(favoriteRecord.id),
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Colors.amberAccent, width: 1),
                                ),
                                child: ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                  leading: SizedBox(
                                    width: 50,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: category != null
                                              ? Color(category.colorValue)
                                              : Colors.grey.shade300,
                                          child: Icon(
                                              category != null
                                                  ? getIconData(category.iconName)
                                                  : Icons.category,
                                              color: Colors.white,
                                              size: 16),
                                        ),
                                        Text(
                                          category?.name ?? '미분류',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: category != null ? Colors.black : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  title: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              favoriteRecord.title ?? '',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            if (asset != null)
                                              Text(
                                                asset.name,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${favoriteRecord.type == TransactionType.income ? '+' : '-'}${_formatAmount(favoriteRecord.amount)}원',
                                        style: TextStyle(
                                          color: favoriteRecord.type == TransactionType.income
                                              ? Colors.blue
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // subtitle: asset != null ? Text(asset.name) : null,
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => FavoriteRecordInputDialog(
                                        initialType: favoriteRecord.type,
                                        initialTitle: favoriteRecord.title,
                                        initialAmount: favoriteRecord.amount,
                                        initialCategoryId: favoriteRecord.categoryId,
                                        initialAssetId: favoriteRecord.assetId,
                                        initialMemo: favoriteRecord.memo,
                                        favoriteRecordId: favoriteRecord.id,
                                      ),
                                    ).then((result) {
                                      if (result == true) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('수정되었습니다')),
                                        );
                                      }
                                    });
                                  },
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
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
        bottomNavigationBar: BannerAdWidget(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => _isRepeat
                ? RepeatRecordInputDialog(
                    initialStartDate: DateTime.now(),
                  )
                : const FavoriteRecordInputDialog(),
          ),
          backgroundColor: Color(0xFFA79BFF),
          child: Icon(Icons.add, color: Colors.white, size: 36),
        ),
      ),
    );
  }

  Widget _typeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.amber : Colors.grey.shade300,
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(48),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(label),
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    return amount
        .toString()
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}
