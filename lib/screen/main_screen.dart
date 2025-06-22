import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/model/home_screen_tab.dart';
import 'package:wonmore_money_book/provider/home_screen_tab_provider.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';
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

      if (userProvider.justSignedIn) {
        userProvider.justSignedIn = false; // 이후 재호출 방지
        final hasLocalRecords = await moneyProvider.hasAnyTransactions();
        if (hasLocalRecords && context.mounted) {
          _showSyncDialog();
        }
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
        content: const Text("기존 로컬 기록이 있습니다.\n서버에 동기화할까요?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("아니오"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<MoneyProvider>();
              // await provider.uploadLocalRecordsToSupabase();  TODO: 추후 추가 필요
              // await provider.clearLocalTransactions(); TODO: 추후 추가 필요
            },
            child: const Text("동기화"),
          ),
        ],
      ),
    );
  }
}


