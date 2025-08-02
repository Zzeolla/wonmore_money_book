import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/component/banner_ad_widget.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/dialog/custom_delete_dialog.dart';
import 'package:wonmore_money_book/dialog/installment_input_dialog.dart';
import 'package:wonmore_money_book/dialog/record_input_dialog.dart';
import 'package:wonmore_money_book/model/asset_model.dart';
import 'package:wonmore_money_book/model/category_model.dart';
import 'package:wonmore_money_book/model/transaction_model.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';
import 'package:wonmore_money_book/service/rewarded_interstitial_ad_service.dart';
import 'package:wonmore_money_book/util/icon_map.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';
import 'package:wonmore_money_book/util/record_ad_handler.dart';

class CustomBottomSheet extends StatefulWidget {
  final DateTime selectedDay;
  final double rowHeight;

  const CustomBottomSheet({
    super.key,
    required this.selectedDay,
    required this.rowHeight,
  });

  @override
  State<CustomBottomSheet> createState() => _CustomBottomSheetState();
}

class _CustomBottomSheetState extends State<CustomBottomSheet> {

  late DateTime _baseDay;
  late int _currentPageIndex;
  final int pageRange = 15;
  final int initialPage = 15;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _baseDay = widget.selectedDay;
    _currentPageIndex = initialPage;
    _pageController = PageController(initialPage: initialPage);
    RewardedInterstitialAdService().loadAd();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoneyProvider>();
    // 현재 보여지는 날짜 계산
    final currentDate = _baseDay.add(Duration(days: _currentPageIndex - initialPage));
    // 해당 날짜의 거래만 필터링
    List<TransactionModel> txList = provider.monthlyTransactions.where((tx) =>
    tx.date.year == currentDate.year &&
        tx.date.month == currentDate.month &&
        tx.date.day == currentDate.day
    ).toList();
    txList.sort((a, b) => a.date.compareTo(b.date));
    // 선택된 날짜의 수입/지출 합계 계산
    final incomeSum = txList
        .where((tx) => tx.type == TransactionType.income)
        .fold(0, (sum, tx) => sum + tx.amount);
    final expenseSum = txList
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0, (sum, tx) => sum + tx.amount);

    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final paddingTop = MediaQuery
        .of(context)
        .padding
        .top;

    // 상단 날짜/요일/월 표시
    Widget dateHeader = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 날짜 박스
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.amberAccent, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              currentDate.day.toString().padLeft(2, '0'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 4),
          // 요일 동그라미
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.amberAccent.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _weekdayString(currentDate.weekday),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 4),
          // 연/월
          Text(
            '${currentDate.year}.${currentDate.month.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 36),
          // 수입/지출 합계 (실제 데이터)
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      '+${_formatAmount(incomeSum)}원',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '-${_formatAmount(expenseSum)}원',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // PageView로 날짜 이동 구현
    Widget recordList = Expanded(
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        itemCount: pageRange * 2 + 1,
        itemBuilder: (context, pageIndex) {
          final date = _baseDay.add(Duration(days: pageIndex - initialPage));
          // 해당 날짜의 거래만 필터링
          List<TransactionModel> txList = provider.monthlyTransactions.where((tx) =>
          tx.date.year == date.year &&
              tx.date.month == date.month &&
              tx.date.day == date.day
          ).toList();
          txList.sort((a, b) => a.date.compareTo(b.date));
          return Container(
            color: Colors.white,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              itemCount: txList.length,
              itemBuilder: (context, index) {
                CategoryModel? category;
                try {
                  category =
                      provider.categories.firstWhere((c) => c.id == txList[index].categoryId);
                } catch (_) {
                  category = null;
                }
                AssetModel? asset;
                try {
                  asset = provider.assets.firstWhere((a) => a.id == txList[index].assetId);
                } catch (_) {
                  asset = null;
                }
                final tx = txList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.amberAccent,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
                                size: 16
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
                    title: Text(tx.title ?? ''),
                    subtitle: asset != null ? Text(asset.name) : null,
                    trailing: Text(
                      '${tx.type == TransactionType.income ? '+' : '-'}${_formatAmount(tx
                          .amount)}원',
                      style: TextStyle(
                        color: tx.type == TransactionType.income ? Colors.blue : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () async {
                      if (tx.installmentId != null) {
                        final installment = await provider.database.getInstallmentById(tx.installmentId!);

                        if (installment == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('할부 정보를 찾을 수 없습니다.')),
                          );
                          return;
                        }

                        showDialog(
                          context: context,
                          builder: (context) =>
                            InstallmentInputDialog(
                              initialDate: installment.date,
                              initialTotalAmount: installment.totalAmount,
                              initialTitle: installment.title,
                              initialMonths: installment.months,
                              initialCategoryId: installment.categoryId,
                              initialAssetId: installment.assetId,
                              initialMemo: installment.memo,
                              installmentId: installment.id,
                            ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              RecordInputDialog(
                                initialDate: tx.date,
                                initialTitle: tx.title,
                                initialAmount: tx.amount,
                                initialType: tx.type,
                                initialCategoryId: tx.categoryId,
                                initialAssetId: tx.assetId,
                                initialMemo: tx.memo,
                                transactionId: tx.id,
                              ),
                        ).then((result) {
                          if (result == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('수정되었습니다!')),
                            );
                          }
                        });
                      }
                    },
                    onLongPress: () async {
                      final result = await showCustomDeleteDialog(
                        context,
                        message: '이 내역을 정말 삭제할까요?'
                      );
                      if (result!) {
                        // 삭제 실행
                        if (tx.installmentId != null) {

                        } else {
                          await (tx.installmentId != null
                            ? provider.deleteInstallment(tx.installmentId!)
                            : provider.deleteTransaction(tx.id!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('삭제되었습니다')),
                          );
                        }
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
    // 플로팅 버튼
    Widget fab = Positioned(
      right: 16,
      bottom: 50 + 16,
      child: FloatingActionButton(
        onPressed: () => RecordAdHandler.tryAddTransaction(context, _openRecordDialog),
        backgroundColor: const Color(0xFFA79BFF),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 36),
      ),
    );

    // 전체 레이아웃
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: (screenHeight - paddingTop) / 2 + widget.rowHeight,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F1FD),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              dateHeader,
              Divider(height: 1, thickness: 1, color: Colors.grey.shade400),
              recordList,
              BannerAdWidget(),
            ],
          ),
        ),
        fab,
      ],
    );
  }

  void _openRecordDialog() {
    final now = DateTime.now();
    final selected = _baseDay;
    final date = DateTime(selected.year, selected.month, selected.day, now.hour, now.minute);
    showDialog(
      context: context,
      builder: (context) =>
          RecordInputDialog(
            initialDate: date,
          ),
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장되었습니다!')),
        );
      }
    });
  }

  String _weekdayString(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return '월';
      case DateTime.tuesday:
        return '화';
      case DateTime.wednesday:
        return '수';
      case DateTime.thursday:
        return '목';
      case DateTime.friday:
        return '금';
      case DateTime.saturday:
        return '토';
      case DateTime.sunday:
        return '일';
      default:
        return '';
    }
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }


}
