import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/dialog/installment_input_dialog.dart';
import 'package:wonmore_money_book/dialog/record_input_dialog.dart';
import 'package:wonmore_money_book/model/asset_model.dart';
import 'package:wonmore_money_book/model/category_model.dart';
import 'package:wonmore_money_book/model/transaction_model.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';
import 'package:wonmore_money_book/util/icon_map.dart';

/// type == null 이면 전체(수입+지출)를 보여준다.
/// 오름차순 정렬(예: 8.1 → 8.31).
class MonthlySummaryDialog extends StatelessWidget {
  final TransactionType? type; // null: 전체
  final DateTime monthBase;

  const MonthlySummaryDialog({
    super.key,
    required this.type,
    required this.monthBase,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoneyProvider>();
    final year = monthBase.year;
    final month = monthBase.month;

    // 해당 달 + (type 필터: null이면 전체)
    final List<TransactionModel> items = provider.monthlyTransactions
        .where((tx) =>
    tx.date.year == year &&
        tx.date.month == month &&
        (type == null || tx.type == type))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date)); // 오름차순

    // 월간 수입/지출 합계 (잔액 표시용)
    final incomeTotal = provider.monthlyTransactions
        .where((tx) =>
    tx.date.year == year &&
        tx.date.month == month &&
        tx.type == TransactionType.income)
        .fold<int>(0, (s, e) => s + e.amount);

    final expenseTotal = provider.monthlyTransactions
        .where((tx) =>
    tx.date.year == year &&
        tx.date.month == month &&
        tx.type == TransactionType.expense)
        .fold<int>(0, (s, e) => s + e.amount);

    final selectedTotal = items.fold<int>(0, (s, e) => s + e.amount);
    final balance = incomeTotal - expenseTotal;
    final nf = NumberFormat('#,###');

    final title = switch (type) {
      TransactionType.income => '수입 내역',
      TransactionType.expense => '지출 내역',
      _ => '전체 내역',
    };

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: const Color(0xFFF1F1FD),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  // YYYY.MM 박스
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amberAccent, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Text(
                      '${year}.${month.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (type == null) ...[
                    Text(
                      '₩${nf.format(balance)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    // 전체: 잔액 + 수입/지출 요약
                  ] else ...[
                    // 수입/지출 전용 합계
                    Text(
                      '${type == TransactionType.income ? '+' : '-'}₩${nf.format(selectedTotal)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: type == TransactionType.income ? Colors.blue : Colors.red,
                      ),
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Divider(height: 1, thickness: 1, color: Colors.grey.shade400),

            // 리스트
            Expanded(
              child: items.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    switch (type) {
                      TransactionType.income => '이 달의 수입 내역이 없어요.',
                      TransactionType.expense => '이 달의 지출 내역이 없어요.',
                      _ => '이 달의 내역이 없어요.',
                    },
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final tx = items[index];
                  final category = _findCategory(context, tx.categoryId);
                  final asset = _findAsset(context, tx.assetId);

                  return _TxCard(
                    tx: tx,
                    category: category,
                    asset: asset,
                    onTap: () async {
                      if (tx.installmentId != null) {
                        final ins = await context
                            .read<MoneyProvider>()
                            .database
                            .getInstallmentById(tx.installmentId!);
                        if (ins == null) return;
                        showDialog(
                          context: context,
                          builder: (_) => InstallmentInputDialog(
                            initialDate: ins.date,
                            initialTotalAmount: ins.totalAmount,
                            initialTitle: ins.title,
                            initialMonths: ins.months,
                            initialCategoryId: ins.categoryId,
                            initialAssetId: ins.assetId,
                            initialMemo: ins.memo,
                            installmentId: ins.id,
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (_) => RecordInputDialog(
                            initialDate: tx.date,
                            initialTitle: tx.title,
                            initialAmount: tx.amount,
                            initialType: tx.type,
                            initialCategoryId: tx.categoryId,
                            initialAssetId: tx.assetId,
                            initialMemo: tx.memo,
                            transactionId: tx.id,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  CategoryModel? _findCategory(BuildContext context, String? id) {
    if (id == null) return null;
    final p = context.read<MoneyProvider>();
    try {
      return p.categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  AssetModel? _findAsset(BuildContext context, String? id) {
    if (id == null) return null;
    final p = context.read<MoneyProvider>();
    try {
      return p.assets.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

class _TxCard extends StatelessWidget {
  final TransactionModel tx;
  final CategoryModel? category;
  final AssetModel? asset;
  final VoidCallback onTap;

  const _TxCard({
    required this.tx,
    required this.category,
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###');
    final isIncome = tx.type == TransactionType.income;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.amberAccent, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: SizedBox(
          width: 50,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: category != null
                    ? Color(category!.colorValue)
                    : Colors.grey.shade300,
                child: Icon(
                  category != null ? getIconData(category!.iconName) : Icons.category,
                  color: Colors.white,
                  size: 16,
                ),
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
        title: Text(
          tx.title ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_yyyyMMdd(tx.date)}     ${asset?.name ?? ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'}${nf.format(tx.amount)}원',
          style: TextStyle(
            color: isIncome ? Colors.blue : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  static String _yyyyMMdd(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}
