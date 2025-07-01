import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/model/home_screen_tab.dart';
import 'package:wonmore_money_book/provider/home_screen_tab_provider.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';
import 'package:wonmore_money_book/provider/todo_provider.dart';
import 'package:wonmore_money_book/provider/user_provider.dart';
import 'package:wonmore_money_book/screen/analysis_screen.dart';
import 'package:wonmore_money_book/screen/assets_screen.dart';
import 'package:wonmore_money_book/screen/home_screen.dart';
import 'package:wonmore_money_book/screen/more_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    AssetsScreen(),
    const AnalysisScreen(),
    const MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = context.read<UserProvider>();
      final moneyProvider = context.read<MoneyProvider>();
      final todoProvider = context.read<TodoProvider>();

      if (userProvider.justSignedIn && userProvider.userId != null) {
        userProvider.justSignedIn = false; // 이후 재호출 방지
        _showSyncDialog();
        await todoProvider.syncTodoLocalDataToSupabase();
        await moneyProvider.syncAllLocalDataToSupabase();

        // final hasLocalRecords = await moneyProvider.hasAnyTransactions();
        // if (hasLocalRecords && context.mounted) {
        //   _showSyncDialog();
        // }
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
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      final homeScreenTabProvider = context.read<HomeScreenTabProvider>();
      homeScreenTabProvider.resetToHome();
    });
  }

  void _showSyncDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("기록 동기화"),
        content: const Text("기존 로컬 기록을 업로드 중입니다.\n데이터양에 따라 시간이 걸릴 수 있습니다."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }
}