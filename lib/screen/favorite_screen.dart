import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/component/banner_ad_widget.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/dialog/custom_delete_dialog.dart';
import 'package:wonmore_money_book/dialog/favorite_record_input_dialog.dart';
import 'package:wonmore_money_book/dialog/repeat_record_input_dialog.dart';
import 'package:wonmore_money_book/model/asset_model.dart';
import 'package:wonmore_money_book/model/category_model.dart';
import 'package:wonmore_money_book/model/period_type.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';
import 'package:wonmore_money_book/service/rewarded_interstitial_ad_service.dart';
import 'package:wonmore_money_book/util/icon_map.dart';
import 'package:wonmore_money_book/util/record_ad_handler.dart';

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
  void initState() {
    super.initState();
    RewardedInterstitialAdService().loadAd();
  }

  @override
  Widget build(BuildContext context) {
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

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        CategoryModel? category;
                        try {
                          category = provider.categories
                              .firstWhere((c) => c.id == filtered[index].categoryId);
                        } catch (_) {
                          category = null;
                        }
                        AssetModel? asset;
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
                                builder: _isRepeat ? (_) => RepeatRecordInputDialog(
                                  initialStartDate: favoriteRecord.startDate!,
                                  initialType: favoriteRecord.type,
                                  initialTitle: favoriteRecord.title,
                                  initialAmount: favoriteRecord.amount,
                                  initialCategoryId: favoriteRecord.categoryId,
                                  initialAssetId: favoriteRecord.assetId,
                                  initialMemo: favoriteRecord.memo,
                                  favoriteRecordId: favoriteRecord.id,
                                ) : (_) => FavoriteRecordInputDialog(
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
                            trailing: _isRepeat ? Text(
                              periodTypeToKo(favoriteRecord.period) ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ) : null
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
          onPressed: () => RecordAdHandler.tryAddTransaction(context, _openRecordDialog),
          backgroundColor: Color(0xFFA79BFF),
          child: Icon(Icons.add, color: Colors.white, size: 36),
        ),
      ),
    );
  }

  void _openRecordDialog() {
    showDialog(
      context: context,
      builder: (_) => _isRepeat
          ? RepeatRecordInputDialog(
        initialStartDate: DateTime.now(),
      )
          : const FavoriteRecordInputDialog(),
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
