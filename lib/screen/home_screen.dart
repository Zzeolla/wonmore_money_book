import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/component/banner_ad_widget.dart';
import 'package:wonmore_money_book/dialog/record_input_dialog.dart';
import 'package:wonmore_money_book/model/home_screen_tab.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';
import 'package:wonmore_money_book/provider/home_screen_tab_provider.dart';
import 'package:wonmore_money_book/provider/money_provider.dart';
import 'package:wonmore_money_book/screen/favorite_screen.dart';
import 'package:wonmore_money_book/screen/todo_list_screen.dart';
import 'package:wonmore_money_book/widget/calendar_widget.dart';
import 'package:wonmore_money_book/widget/common_app_bar.dart';
import 'package:wonmore_money_book/widget/custom_bottom_sheet.dart';
import 'package:wonmore_money_book/widget/common_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 상수 정의
  static const double kAppBarHeight = 56.0;
  static const double kYearMonthBoxHeight = 48.0;
  static const double kSummaryBoxHeight = 80.0;
  static const double kDaysOfWeekHeight = 36.0;
  static const double kBottomNavBarHeight = 56.0;
  static const double kMinAdHeight = 52.0;

  late double _rowHeight;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  String get _yearMonthText {
    return '${_focusedDay.year}.${_focusedDay.month}월';
  }

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 현재 달의 거래내역만 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MoneyProvider>().changeMonth(_focusedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final paddingTop = MediaQuery.of(context).padding.top;
    final paddingBottom = MediaQuery.of(context).padding.bottom;

    final usedHeight = paddingTop +
        paddingBottom +
        kAppBarHeight +
        kYearMonthBoxHeight +
        kSummaryBoxHeight +
        kBottomNavBarHeight +
        kDaysOfWeekHeight;

    final remainingHeight = screenHeight - usedHeight;

    _rowHeight = ((remainingHeight - kMinAdHeight) / 7).floorToDouble();

    final provider = context.watch<MoneyProvider>();
    final dailySummary = provider.dailySummaryMap;
    final tab = context.watch<HomeScreenTabProvider>().currentTab;
    final isMainScreen = context.watch<HomeScreenTabProvider>().isMainScreen;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CommonAppBar(
        isMainScreen: isMainScreen,
        actions: [
          // IconButton(
          //   icon: Icon(Icons.search, color: Color(0xFFF2F4F6), size: 36),
          //   onPressed: () {
          //     // TODO: 검색기능(구현할지 말지 고민해보자)
          //   },
          // ),
          IconButton(
            icon: Icon(Icons.star_border_purple500, color: Color(0xFFF2F4F6), size: 36),
            onPressed: () =>
                context.read<HomeScreenTabProvider>().setTab(HomeTab.favorite), // TODO: 즐겨찾기 팝업
          ),
          IconButton(
            icon: Icon(Icons.checklist, color: Color(0xFFF2F4F6), size: 36),
            onPressed: () => context.read<HomeScreenTabProvider>().setTab(HomeTab.todo),
            // TODO: 투두 화면 이동 또는 팝업 열기
            // 장보기 목록, 처리해야 할 금융 업무(이체, 납부 등), 기념일 체크
          ),
        ],
      ),
      drawer: CommonDrawer(),
      body: Builder(
        builder: (context) {
          switch (tab) {
            case HomeTab.favorite:
              return FavoriteScreen(
                  onClose: () => context.read<HomeScreenTabProvider>().resetToHome());
            case HomeTab.todo:
              return TodoListScreen(
                  onClose: () => context.read<HomeScreenTabProvider>().resetToHome());
            case HomeTab.home:
              return Stack(
                children: [
                  Column(
                    children: [
                      /// 연도.월 + 화살표 구현
                      Container(
                        color: Color(0xFFF1F1FD),
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          height: kYearMonthBoxHeight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: _onLeftArrow,
                                icon: Icon(Icons.chevron_left),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // TODO: 월 선택 다이얼로그 구현
                                },
                                child: Text(
                                  _yearMonthText,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                onPressed: _onRightArrow,
                                icon: Icon(Icons.chevron_right),
                              )
                            ],
                          ),
                        ),
                      ),

                      /// 수입/지출/잔액 정보
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: kSummaryBoxHeight,
                          child: Consumer<MoneyProvider>(
                            builder: (context, provider, child) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                      child: _buildSummaryItem('수입', provider.monthlyIncome, '+')),
                                  Expanded(
                                      child: _buildSummaryItem('지출', provider.monthlyExpense, '-')),
                                  Expanded(
                                      child: _buildSummaryItem(
                                          '잔액', provider.monthlyBalance, '\u20A9')),
                                ],
                              );
                            },
                          ),
                        ),
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          child: CalendarWidget(
                            focusedDay: _focusedDay,
                            selectedDay: _selectedDay,
                            rowHeight: _rowHeight,
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = selectedDay;
                              });
                              _showBottomSheet(context, _selectedDay, _rowHeight);
                            },
                            onPageChanged: (focusedDay) {
                              setState(() {
                                _focusedDay = focusedDay;
                              });
                              context.read<MoneyProvider>().changeMonth(_focusedDay);
                            },
                            dailySummary: dailySummary,
                          ),
                        ),
                      ),
                      BannerAdWidget(),
                    ],
                  ),
                  Positioned(
                    right: 16,
                    bottom: kMinAdHeight + 16,
                    child: FloatingActionButton(
                      onPressed: () {
                        final provider = context.read<MoneyProvider>();
                        showDialog(
                          context: context,
                          builder: (context) => RecordInputDialog(
                            initialDate: DateTime.now(),
                            categories: provider.categories,
                            assetList: provider.assets.map((a) => a.name).toList(),
                          ),
                        ).then(
                          (result) {
                            if (result == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('저장되었습니다!')),
                              );
                            }
                          },
                        );
                      },
                      backgroundColor: Color(0xFFA79BFF),
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ],
              );
          }
        },
      ),
    );
  }

  void _onLeftArrow() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
    });
    context.read<MoneyProvider>().changeMonth(_focusedDay);
  }

  void _onRightArrow() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
    });
    context.read<MoneyProvider>().changeMonth(_focusedDay);
  }

  Widget _buildSummaryItem(String label, int amount, [String prefix = '\\']) {
    final formattedAmount = NumberFormat('#,###').format(amount);
    final displayAmount = '$prefix $formattedAmount';
    final Color amountColor = switch (prefix) {
      '+' => Colors.blue,
      '-' => Colors.red,
      _ => Colors.black,
    };
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 20, // 폰트 크기 축소
              color: Color(0xFF7C7C7C),
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4), // 간격 축소
        Text(
          displayAmount,
          style: TextStyle(
            fontSize: 16, // 폰트 크기 축소
            color: amountColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showBottomSheet(BuildContext context, DateTime selectedDay, double rowHeight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return CustomBottomSheet(selectedDay: selectedDay, rowHeight: rowHeight);
      },
    );
  }
}
