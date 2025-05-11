import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/dialog/record_input_dialog.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';
import 'package:wonmore_money_book/util/icon_map.dart';
import 'package:wonmore_money_book/provider/money_provider.dart';

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
  // 더미 카테고리 데이터
  final List<Category> dummyCategories = [
    Category(
      id: 1,
      name: '식비',
      type: TransactionType.expense,
      isDefault: true,
      iconName: 'restaurant',
      colorValue: 0xFFFFC107, // amber
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: null,
      createdBy: null,
      updatedBy: null,
    ),
    Category(
      id: 2,
      name: '쇼핑',
      type: TransactionType.expense,
      isDefault: true,
      iconName: 'shopping_bag',
      colorValue: 0xFFE91E63, // pink
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: null,
      createdBy: null,
      updatedBy: null,
    ),
    Category(
      id: 3,
      name: '월급',
      type: TransactionType.income,
      isDefault: true,
      iconName: 'attach_money',
      colorValue: 0xFF4CAF50, // green
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: null,
      createdBy: null,
      updatedBy: null,
    ),
    Category(
      id: 4,
      name: '문화생활',
      type: TransactionType.expense,
      isDefault: true,
      iconName: 'movie',
      colorValue: 0xFF9C27B0, // purple
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: null,
      createdBy: null,
      updatedBy: null,
    ),
  ];

  // 더미 자산 데이터
  final List<Asset> dummyAssets = [
    Asset(
      id: 1,
      name: '카카오뱅크',
      balance: 1500000,
      type: '현금',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: null,
      createdBy: null,
      updatedBy: null,
    ),
    Asset(
      id: 2,
      name: '토스뱅크',
      balance: 2500000,
      type: '현금',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: null,
      createdBy: null,
      updatedBy: null,
    ),
    Asset(
      id: 3,
      name: '신한은행',
      balance: 5000000,
      type: '현금',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: null,
      createdBy: null,
      updatedBy: null,
    ),
  ];

  // 더미 거래 데이터
  late final List<Transaction> dummyTransactions = [
    Transaction(
      id: 1,
      date: DateTime.now().subtract(const Duration(hours: 2)),
      amount: 12000,
      type: TransactionType.expense,
      categoryId: 1,
      assetId: 1,
      title: '점심 식사',
      memo: '카카오뱅크',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: null,
      createdBy: null,
      updatedBy: null,
    ),
    Transaction(
      id: 2,
      date: DateTime.now().subtract(const Duration(hours: 5)),
      amount: 35000,
      type: TransactionType.expense,
      categoryId: 2,
      assetId: 2,
      title: '티셔츠 구매',
      memo: '토스뱅크',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: null,
      createdBy: null,
      updatedBy: null,
    ),
    Transaction(
      id: 3,
      date: DateTime.now().subtract(const Duration(hours: 6)),
      amount: 3000000,
      type: TransactionType.income,
      categoryId: 3,
      assetId: 3,
      title: '월급',
      memo: '신한은행',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: null,
      createdBy: null,
      updatedBy: null,
    ),
    Transaction(
      id: 4,
      date: DateTime.now().subtract(const Duration(hours: 8)),
      amount: 3000000,
      type: TransactionType.income,
      categoryId: 3,
      assetId: 3,
      title: null,
      memo: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: null,
      createdBy: null,
      updatedBy: null,
    ),
    Transaction(
      id: 5,
      date: DateTime.now().subtract(const Duration(hours: 6)),
      amount: 3000000,
      type: TransactionType.expense,
      categoryId: 4,
      assetId: 3,
      title: '영화 관람',
      memo: '신한은행',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: null,
      createdBy: null,
      updatedBy: null,
    ),
  ];

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
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoneyProvider>();
    // 현재 보여지는 날짜 계산
    final currentDate = _baseDay.add(Duration(days: _currentPageIndex - initialPage));
    // 해당 날짜의 거래만 필터링
    List<Transaction> txList = provider.currentMonthTransactions.where((tx) =>
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

    final screenHeight = MediaQuery.of(context).size.height;
    final paddingTop = MediaQuery.of(context).padding.top;

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
          List<Transaction> txList = provider.currentMonthTransactions.where((tx) =>
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
                Category? category;
                try {
                  category = provider.categories.firstWhere((c) => c.id == txList[index].categoryId);
                } catch (_) {
                  category = null;
                }
                Asset? asset;
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
                    leading: Column(
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
                          style: TextStyle(
                            fontSize: 12,
                            color: category != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    title: Text(tx.title ?? ''),
                    subtitle: asset != null ? Text(asset.name) : null,
                    trailing: Text(
                      '${tx.type == TransactionType.income ? '+' : '-'}${_formatAmount(tx.amount)}원',
                      style: TextStyle(
                        color: tx.type == TransactionType.income ? Colors.blue : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    onLongPress: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('삭제하시겠습니까?'),
                          content: Text('이 내역을 삭제하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('취소'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text('확인', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (result == true) {
                        // 삭제 실행
                        await context.read<MoneyProvider>().deleteTransaction(tx.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('삭제되었습니다.')),
                        );
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

    // 광고 영역
    Widget adArea = Container(
      height: 50,
      width: double.infinity,
      color: Colors.grey.shade300,
      child: const Center(
        child: Text('광고 자리', style: TextStyle(color: Colors.black54)),
      ),
    );

    // 플로팅 버튼
    Widget fab = Positioned(
      right: 16,
      bottom: 50 + 16,
      child: FloatingActionButton(
        onPressed: () {
          final provider = context.read<MoneyProvider>();
          final now = DateTime.now();
          final selected = _baseDay;
          final date = DateTime(selected.year, selected.month, selected.day, now.hour, now.minute);
          showDialog(
            context: context,
            builder: (context) => RecordInputDialog(
              initialDate: date,
              categories: provider.categories,
              assetList: provider.assets.map((a) => a.name).toList(),
            ),
          ).then((result) {
            if (result == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('저장되었습니다!')),
              );
            }
          });
        },
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
          height: (screenHeight - paddingTop) / 2 + widget.rowHeight ,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F1FD),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              dateHeader,
              Divider(height: 1, thickness: 1, color: Colors.grey.shade400),
              recordList,
              adArea,
            ],
          ),
        ),
        fab,
      ],
    );
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
