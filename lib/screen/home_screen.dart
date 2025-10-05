import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/component/banner_ad_widget.dart';
import 'package:wonmore_money_book/dialog/budget_chooser_dialog.dart';
import 'package:wonmore_money_book/dialog/monthly_summary_dialog.dart';
import 'package:wonmore_money_book/dialog/record_input_dialog.dart';
import 'package:wonmore_money_book/model/home_screen_tab.dart';
import 'package:wonmore_money_book/model/subscription_model.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';
import 'package:wonmore_money_book/provider/home_screen_tab_provider.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';
import 'package:wonmore_money_book/provider/user_provider.dart';
import 'package:wonmore_money_book/screen/favorite_screen.dart';
import 'package:wonmore_money_book/screen/todo_list_screen.dart';
import 'package:wonmore_money_book/service/interstitial_ad_service.dart';
import 'package:wonmore_money_book/util/record_ad_handler.dart';
import 'package:wonmore_money_book/widget/calendar_widget.dart';
import 'package:wonmore_money_book/widget/common_app_bar.dart';
import 'package:wonmore_money_book/widget/common_drawer.dart';
import 'package:wonmore_money_book/widget/custom_bottom_sheet.dart';
import 'package:wonmore_money_book/widget/year_month_header.dart';

class DrawerTutorialBridge {
  final VoidCallback openDrawer;
  final VoidCallback closeDrawer;
  final GlobalKey groupSyncKey;
  final GlobalKey currentBudgetKey;
  final GlobalKey shareJoinKey;

  DrawerTutorialBridge({
    required this.openDrawer,
    required this.closeDrawer,
    required this.groupSyncKey,
    required this.currentBudgetKey,
    required this.shareJoinKey,
  });
}

class HomeScreen extends StatefulWidget {
  final GlobalKey? starKey;
  final GlobalKey? todoKey;
  final GlobalKey? fabKey;

  final void Function(DrawerTutorialBridge bridge)? registerDrawerTutorialBridge;

  const HomeScreen({
    super.key,
    this.starKey,
    this.todoKey,
    this.fabKey,
    this.registerDrawerTutorialBridge,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // ✅ Drawer 튜토 타겟 키 3개
  final _keyDrawerSync = GlobalKey();       // 그룹 선택(↻)
  final _keyDrawerBudget = GlobalKey();     // 현재 가계부 드롭다운
  final _keyDrawerShare = GlobalKey();      // 그룹 공유/참여

  // 상수 정의
  static const double kAppBarHeight = 56.0;
  static const double kYearMonthBoxHeight = 40.0;
  static const double kSummaryBoxHeight = 60.0;
  static const double kDaysOfWeekHeight = 36.0;
  static const double kBottomNavBarHeight = 56.0;
  static const double kMinAdHeight = 52.0;

  late double _rowHeight;

  @override
  void initState() {
    super.initState();
    InterstitialAdService().loadAd();
    // 앱 시작 시 현재 달의 거래내역만 로드

    // ✅ MainScreen이 Drawer를 열고/닫고, 타겟 키를 쓰게 해주는 브릿지 등록
    widget.registerDrawerTutorialBridge?.call(
      DrawerTutorialBridge(
        openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        closeDrawer: () => Navigator.of(context).maybePop(),
        groupSyncKey: _keyDrawerSync,
        currentBudgetKey: _keyDrawerBudget,
        shareJoinKey: _keyDrawerShare,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MoneyProvider>().changeFocusedDay(DateTime.now());
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
      key: _scaffoldKey,
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
            key: widget.starKey,
            icon: Icon(Icons.star_border_purple500, color: Color(0xFFF2F4F6), size: 30),
            onPressed: () => context.read<HomeScreenTabProvider>().setTab(HomeTab.favorite),
          ),
          IconButton(
            key: widget.todoKey,
            icon: Icon(Icons.checklist, color: Color(0xFFF2F4F6), size: 30),
            onPressed: () => context.read<HomeScreenTabProvider>().setTab(HomeTab.todo),
            // 장보기 목록, 처리해야 할 금융 업무(이체, 납부 등), 기념일 체크
          ),
        ],
      ),
      drawer: CommonDrawer(
        groupSyncKey: _keyDrawerSync,
        currentBudgetKey: _keyDrawerBudget,
        shareJoinKey: _keyDrawerShare,
      ),
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
                      YearMonthHeader(),

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
                                      child: _buildSummaryItem(
                                    '수입',
                                    provider.monthlyIncome,
                                    '\u20A9',
                                    () => _openMonthlyTxModal(TransactionType.income),
                                  )),
                                  Expanded(
                                      child: _buildSummaryItem(
                                    '지출',
                                    provider.monthlyExpense,
                                    '\u20A9',
                                    () => _openMonthlyTxModal(TransactionType.expense),
                                  )),
                                  Expanded(
                                      child: _buildSummaryItem(
                                    '잔액',
                                    provider.monthlyBalance,
                                    '\u20A9',
                                    () => _openMonthlyTxModal(null),
                                  )),
                                ],
                              );
                            },
                          ),
                        ),
                      ),

                      Expanded(
                        child: CalendarWidget(
                          focusedDay: provider.focusedDay,
                          selectedDay: provider.selectedDay,
                          rowHeight: _rowHeight,
                          onDaySelected: (selectedDay, _) {
                            provider.selectDayAndFocus(selectedDay);
                            _showBottomSheet(context, selectedDay, _rowHeight);
                          },
                          onPageChanged: (focusedDay) {
                            provider.changeFocusedDay(focusedDay);
                          },
                          dailySummary: dailySummary,
                        ),
                      ),
                      BannerAdWidget(),
                    ],
                  ),
                  Positioned(
                    right: 16,
                    bottom: kMinAdHeight + 16,
                    child: Row(
                      children: [
                        if (context.read<UserProvider>().isLoggedIn)
                          FloatingActionButton(
                            heroTag: 'fabSwap',
                            onPressed: _onTapChange,
                            backgroundColor: const Color(0xFFA79BFF),
                            child: const Icon(Icons.swap_horiz, color: Colors.white, size: 36),
                          ),
                        const SizedBox(width: 12),
                        FloatingActionButton(
                          heroTag: 'fabAdd',
                          key: widget.fabKey,
                          onPressed: () {
                            final myPlan =
                                context.read<UserProvider>().myPlan ?? SubscriptionModel.free();
                            final adsEnabled = myPlan.adsEnabled ?? true;

                            if (adsEnabled) {
                              RecordAdHandler.tryAddTransaction(context, _openRecordDialog);
                            } else {
                              _openRecordDialog();
                            }
                          },
                          backgroundColor: Color(0xFFA79BFF),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
          }
        },
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    int amount, [
    String prefix = '\\',
    VoidCallback? onTap,
  ]) {
    final formattedAmount = NumberFormat('#,###').format(amount);
    final displayAmount = '$prefix $formattedAmount';
    final Color amountColor = switch (label) {
      '수입' => Colors.blue,
      '지출' => Colors.red,
      _ => Colors.black,
    };

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 2),
        Text(
          label,
          style:
              const TextStyle(fontSize: 18, color: Color(0xFF7C7C7C), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          displayAmount,
          style: TextStyle(fontSize: 16, color: amountColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    // 탭 가능하도록 GestureDetector로 감싸기
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: content,
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

  void _openMonthlyTxModal(TransactionType? type) {
    final base = context.read<MoneyProvider>().focusedDay;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => MonthlySummaryDialog(
        type: type, // null이면 수입+지출 전체
        monthBase: base,
      ),
    );
  }

  void _openRecordDialog() {
    showDialog(
      context: context,
      builder: (context) => RecordInputDialog(initialDate: DateTime.now()),
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장되었습니다!')),
        );
      }
    });
  }

  void _onTapChange() async {
    await showBudgetChooserDialog(context);
  }
}
