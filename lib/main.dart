import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/provider/home_screen_tab_provider.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';
import 'package:wonmore_money_book/provider/todo_provider.dart';
import 'package:wonmore_money_book/provider/user_provider.dart';
import 'package:wonmore_money_book/screen/home_screen.dart';
import 'package:wonmore_money_book/screen/assets_screen.dart';
import 'package:wonmore_money_book/screen/analysis_screen.dart';
import 'package:wonmore_money_book/screen/login_screen.dart';
import 'package:wonmore_money_book/screen/main_screen.dart';
import 'package:wonmore_money_book/screen/more_screen.dart';
import 'package:wonmore_money_book/screen/splash_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 광고 기능 초기화
  await MobileAds.instance.initialize();

  // 날짜 포맷 초기화
  await initializeDateFormatting('ko_KR', null);

  // 데이터베이스 초기화
  final database = AppDatabase();

  await Supabase.initialize(
    url: 'https://rzauhdeimiizczhnclpw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ6YXVoZGVpbWlpemN6aG5jbHB3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAxNTUxNTksImV4cCI6MjA2NTczMTE1OX0.iZdWkSNqrjKj8E1nFK10kNtwaWY7o-7wPi7lSXSFDWw'
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
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
