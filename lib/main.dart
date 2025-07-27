import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/provider/home_screen_tab_provider.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';
import 'package:wonmore_money_book/provider/todo_provider.dart';
import 'package:wonmore_money_book/provider/user_provider.dart';
import 'package:wonmore_money_book/screen/budget_list_screen.dart';
import 'package:wonmore_money_book/screen/home_screen.dart';
import 'package:wonmore_money_book/screen/assets_screen.dart';
import 'package:wonmore_money_book/screen/analysis_screen.dart';
import 'package:wonmore_money_book/screen/join_group_screen.dart';
import 'package:wonmore_money_book/screen/login_screen.dart';
import 'package:wonmore_money_book/screen/main_screen.dart';
import 'package:wonmore_money_book/screen/more_screen.dart';
import 'package:wonmore_money_book/screen/my_profile_screen.dart';
import 'package:wonmore_money_book/screen/splash_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wonmore_money_book/screen/user_list_screen.dart';

Future<void> deleteLocalDb() async {
  final dir = await getApplicationDocumentsDirectory();
  final dbFile = File('${dir.path}/db.sqlite'); // Drift 기본 파일명
  if (await dbFile.exists()) {
    await dbFile.delete();
    print('✅ DB 파일 삭제됨');
  } else {
    print('ℹ️ DB 파일 없음');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // 광고 기능 초기화
  await MobileAds.instance.initialize();

  // 날짜 포맷 초기화
  await initializeDateFormatting('ko_KR', null);

  // 데이터베이스 초기화
  final database = AppDatabase();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MoneyProvider(database)),
        ChangeNotifierProvider(create: (_) => HomeScreenTabProvider()),
        ChangeNotifierProvider(create: (_) => TodoProvider(database)),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '원모아 가계부',
      debugShowCheckedModeBanner: false,

      // 로컬라이제이션 설정
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 테마 설정
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'NotoSansKR',

        // 카드 테마
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        // 버튼 테마
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // 입력 필드 테마
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        // 페이지 전환 애니메이션
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),

      // 라우팅 설정
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/main': (context) => const MainScreen(),
        '/home': (context) => const HomeScreen(),
        '/assets': (context) => AssetsScreen(),
        '/analysis': (context) => const AnalysisScreen(),
        '/more': (context) => const MoreScreen(),
        '/more/my-info': (context) => const MyInfoScreen(),
        '/more/join-group': (context) => const JoinGroupScreen(),
        '/more/edit-budget': (context) => const BudgetListScreen(),
        '/more/edit-user': (context) => const UserListScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
