import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:wonmore_money_book/provider/home_screen_tab_provider.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';
import 'package:wonmore_money_book/provider/todo_provider.dart';
import 'package:wonmore_money_book/provider/user_provider.dart';
import 'package:wonmore_money_book/screen/analysis_screen.dart';
import 'package:wonmore_money_book/screen/assets_screen.dart';
import 'package:wonmore_money_book/screen/home_screen.dart';
import 'package:wonmore_money_book/screen/more_screen.dart';
import 'package:wonmore_money_book/service/repeat_transaction_service.dart';
import 'package:wonmore_money_book/service/tutorial_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

// Drawer 튜토리얼용 추가 필드
  DrawerTutorialBridge? _drawerBridge;        // HomeScreen에서 넘겨주는 브릿지
  TutorialCoachMark? _drawerTutorial;         // Drawer용 코치마크
  late List<TargetFocus> _drawerTargets;      // Drawer 타깃들

  // 하단 네비 4개
  final keyTabBudget = GlobalKey(); // 왼쪽 아래: 가계부(달력)
  final keyTabAsset = GlobalKey(); // 자산
  final keyTabAnalysis = GlobalKey(); // 분석
  final keyTabMore = GlobalKey(); // 더보기

// 상단 AppBar
  final keyStar = GlobalKey(); // 즐겨찾기
  final keyTodo = GlobalKey(); // Todo 리스트
// (원하면) 추가 버튼
  final keyFabAdd = GlobalKey(); // 우하단 + (선택)

  int _selectedIndex = 0;

  late final List<Widget> _screens;

  TutorialCoachMark? _tutorial;
  late List<TargetFocus> _targets;

  // final List<Widget> _screens = [
  //   const HomeScreen(),
  //   AssetsScreen(),
  //   const AnalysisScreen(),
  //   const MoreScreen(),
  // ];

  @override
  void initState() {
    super.initState();

    _screens = [
      HomeScreen(
        starKey: keyStar,
        todoKey: keyTodo,
        fabKey: keyFabAdd,
        registerDrawerTutorialBridge: (bridge) {
          _drawerBridge = bridge;
        },
      ),
      AssetsScreen(),
      const AnalysisScreen(),
      MoreScreen(onRestartTutorial: _restartMainTutorial),
    ];

    Future.microtask(() async {
      final moneyProvider = context.read<MoneyProvider>();
      final repeatService = RepeatTransactionService(moneyProvider);
      await repeatService.generateTodayRepeatedTransactions();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = context.read<UserProvider>();
      final moneyProvider = context.read<MoneyProvider>();
      final todoProvider = context.read<TodoProvider>();

      if (userProvider.justSignedIn && userProvider.userId != null) {
        userProvider.justSignedIn = false; // 이후 재호출 방지
        await Future.delayed(const Duration(milliseconds: 250));
        if (mounted) {
          await _startDrawerTutorial();
        }

        if (!mounted) return;
        _showSyncDialog();
        await todoProvider.syncTodoLocalDataToSupabase();
        await moneyProvider.syncAllLocalDataToSupabase();

        // final hasLocalRecords = await moneyProvider.hasAnyTransactions();
        // if (hasLocalRecords && context.mounted) {
        //   _showSyncDialog();
        // }
      }
      final done = await TutorialService.isMainTutorialDone();
      if (!done && _selectedIndex == 0 && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        _startMainTutorial();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Color(0xFFF1F1FD),
        selectedItemColor: Color(0xFF6A50FF),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        iconSize: 36,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month, key: keyTabBudget),
            label: '',
            tooltip: '가계부',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list, key: keyTabAsset),
            label: '',
            tooltip: '자산',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart, key: keyTabAnalysis),
            label: '',
            tooltip: '분석',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, key: keyTabMore),
            label: '',
            tooltip: '더보기',
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      context.read<HomeScreenTabProvider>().resetToHome();
    });
  }

  void _showSyncDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("기록 동기화"),
        content: const Text("기존 로컬 기록을 주 가계부에 업로드 중입니다.\n데이터양에 따라 시간이 걸릴 수 있습니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  // =========================
  // 튜토리얼 (코치마크) 시나리오
  // =========================
  void _buildTargets() {
    _targets = [
      // 하단 네비 4개
      TargetFocus(
        keyTarget: keyTabBudget,
        identify: "tab_budget",
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _coachText(
              title: "가계부(달력)",
              body: "현재 선택된 가계부를 달력으로 볼 수 있어요.\n날짜를 눌러 내역을 추가/확인하세요.",
            ),
          ),
        ],
      ),
      TargetFocus(
        keyTarget: keyTabAsset,
        identify: "tab_asset",
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _coachText(
              title: "자산",
              body: "통장/카드 등 자산을 등록하고 수정할 수 있어요.",
            ),
          ),
        ],
      ),
      TargetFocus(
        keyTarget: keyTabAnalysis,
        identify: "tab_analysis",
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _coachText(
              title: "분석",
              body: "기간별 통계로 지출 패턴을 분석해요.\n카테고리별 합계와 추이를 확인해보세요.",
            ),
          ),
        ],
      ),
      TargetFocus(
        keyTarget: keyTabMore,
        identify: "tab_more",
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _coachText(
              title: "더보기",
              body: "내 정보/가계부/카테고리를 관리하고\n‘튜토리얼 다시보기’도 여기서 할 수 있어요.",
            ),
          ),
        ],
      ),

      // 상단 AppBar(홈 탭에서만 표시됨)
      TargetFocus(
        keyTarget: keyStar,
        identify: "star",
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _coachText(
              title: "즐겨찾기",
              body: "자주 쓰는 내역을 모아두고,\n반복 수입/지출도 추가할 수 있어요.",
            ),
          ),
        ],
      ),
      TargetFocus(
        keyTarget: keyTodo,
        identify: "todo",
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _coachText(
              title: "할 일",
              body: "장보기 목록, 금융 업무, 기념일 등\n해야 할 일을 체크하세요.",
            ),
          ),
        ],
      ),

      // FAB
      TargetFocus(
        keyTarget: keyFabAdd,
        identify: "fab_add",
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _coachText(
              title: "내역 추가",
              body: "수입/지출/이체 내역을 추가합니다.",
            ),
          ),
        ],
      ),

      // 1) 로그인/공유 안내
      TargetFocus(
        keyTarget: keyTabMore,                 // 더보기 탭을 강조
        identify: "share_login",
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _coachText(
              title: "함께 쓰는 가계부",
              body: "로그인하여 다른 사용자를 추가하면\n가족/지인과 같은 가계부를 함께 관리할 수 있어요.",
            ),
          ),
        ],
      ),

      // 2) Pro 업그레이드 안내
      TargetFocus(
        keyTarget: keyTabMore,                 // 같은 더보기 탭에 연속 안내
        identify: "pro_upgrade",
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _coachText(
              title: "Pro로 업그레이드",
              body: "광고 제거, 2단 가계부 확장까지 가능합니다.",
            ),
          ),
        ],
      ),
    ];
  }

  Widget _coachText({required String title, required String body}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.black87),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Future<void> _startMainTutorial({VoidCallback? onFinish}) async {
    _buildTargets();
    _tutorial = TutorialCoachMark(
      targets: _targets,
      pulseEnable: false,
      colorShadow: Colors.black.withOpacity(0.5),
      opacityShadow: 0.55, // 지원 버전에 따라 있으면 함께 사용
      focusAnimationDuration: Duration.zero,   // ✅ 포커스 인
      unFocusAnimationDuration: Duration.zero, // ✅ 포커스 아웃
      // 스킵 UI
      hideSkip: false,
      textSkip: "건너뛰기",
      onFinish: () {
        TutorialService.setMainTutorialDone(true);
        onFinish?.call();
      },
      onSkip: () {
        TutorialService.setMainTutorialDone(true);
        return true;
      },
    );
    _tutorial!.show(context: context);
  }

  /// 더보기에서 “튜토리얼 다시보기” 눌렀을 때
  Future<void> _restartMainTutorial() async {
    await TutorialService.resetMainTutorial();
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
      // 홈 화면으로 전환된 뒤 실행
      await Future.delayed(const Duration(milliseconds: 350));
    }
    _startMainTutorial(
      onFinish: () {
        // ✅ 메인 튜토 끝난 후 → 로그인 상태면 Drawer 튜토 실행
        final uid = context.read<UserProvider>().userId;
        if (uid != null) {
          _startDrawerTutorial();
        }
      },
    );
  }

  void _buildDrawerTargets() {
    if (_drawerBridge == null) return;

    _drawerTargets = [
      TargetFocus(
        keyTarget: _drawerBridge!.groupSyncKey,
        identify: "drawer_group_sync",
        shape: ShapeLightFocus.Circle,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _coachText(
              title: "그룹 선택",
              body: "이 버튼을 눌러 공유받은 가족/지인의 가계부 그룹으로 전환할 수 있어요.",
            ),
          ),
        ],
      ),
      TargetFocus(
        keyTarget: _drawerBridge!.currentBudgetKey,
        identify: "drawer_current_budget",
        shape: ShapeLightFocus.RRect,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _coachText(
              title: "현재 가계부",
              body: "여기에서 작성 가능한 가계부를 바꿀 수 있어요.",
            ),
          ),
        ],
      ),
      TargetFocus(
        keyTarget: _drawerBridge!.shareJoinKey,
        identify: "drawer_share_join",
        shape: ShapeLightFocus.RRect,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _coachText(
              title: "가계부 그룹 공유/참여",
              body: "초대 코드로 참여하거나 내 그룹을 공유하려면 여기를 눌러요.",
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _startDrawerTutorial() async {
    if (_drawerBridge == null) return;

    final completer = Completer<void>();

    // Drawer 열기
    _drawerBridge!.openDrawer();
    // 레이아웃 안정화 기다림
    await Future.delayed(const Duration(milliseconds: 250));

    _buildDrawerTargets();
    if (_drawerTargets.isEmpty) return;

    _drawerTutorial = TutorialCoachMark(
      targets: _drawerTargets,
      pulseEnable: false,
      colorShadow: Colors.black.withOpacity(0.5),
      opacityShadow: 0.55,
      focusAnimationDuration: Duration.zero,
      unFocusAnimationDuration: Duration.zero,
      hideSkip: false,
      textSkip: "건너뛰기",
      onFinish: () {
        _drawerBridge?.closeDrawer();
        if (!completer.isCompleted) completer.complete();
      },
      onSkip: () {
        _drawerBridge?.closeDrawer();
        if (!completer.isCompleted) completer.complete();
        return true;
      },
    );

    _drawerTutorial!.show(context: context);
    await completer.future;
  }
}