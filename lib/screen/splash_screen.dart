import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';
import 'package:wonmore_money_book/provider/todo_provider.dart';
import 'package:wonmore_money_book/provider/user_provider.dart';
import 'package:wonmore_money_book/service/fcm_token_service.dart';
import 'package:wonmore_money_book/service/iap_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _initializing = false;
  bool _navigated = false;
  bool _error = false;
  int _retryCount = 0;
  static const _maxRetries = 1;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initATT();
      _guardedInit();
    });

    // 네트워크 전환 감지 → 다시 시도
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online && !_initializing && !_navigated && mounted) {
        _guardedInit();
      }
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  Future<T> _withTimeout<T>(Future<T> future,
      {Duration timeout = const Duration(seconds: 8)}) {
    return future.timeout(timeout, onTimeout: () {
      throw TimeoutException('Splash init timed out');
    });
  }

  Future<void> _initATT() async {
    if (!Platform.isIOS) return; // Android/기타 무시
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // 초기 렌더 직후 약간의 딜레이가 더 안정적 (iOS17+)
        await Future.delayed(const Duration(milliseconds: 400));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (e) {
      debugPrint('ATT request failed: $e'); // 실패해도 앱 흐름은 계속
    }
  }


  Future<void> _guardedInit() async {
    if (_initializing || _navigated) return;
    setState(() {
      _initializing = true;
      _error = false;
    });

    try {
      // 1) 네트워크 체크
      final connectivity = await _withTimeout(
        Connectivity().checkConnectivity(),
        timeout: const Duration(seconds: 4),
      );
      if (connectivity == ConnectivityResult.none) {
        throw Exception('No internet');
      }

      // 2) 앱 핵심 초기화
      await _withTimeout(_initAppCore(),
          timeout: const Duration(seconds: 10)); // 전체 타임아웃

      // 3) 성공 시 단 1회만 이동
      if (mounted && !_navigated) {
        _navigated = true;
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = true;
      });

      // 자동 재시도 (1회만)
      if (_retryCount < _maxRetries) {
        _retryCount++;
        await Future.delayed(Duration(seconds: 3 * _retryCount));
        if (mounted && !_navigated) {
          _error = false;
          _initializing = false;
          _guardedInit();
          return;
        }
      }
    } finally {
      if (mounted) {
        _initializing = false;
      }
    }
  }

  Future<void> _initAppCore() async {
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    final userProvider = context.read<UserProvider>();
    final moneyProvider = context.read<MoneyProvider>();
    final todoProvider = context.read<TodoProvider>();

    if (supabaseUser != null) {
      await userProvider.setUser(supabaseUser);

      // --- 🔑 users row는 필수 ---
      final userRow = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', supabaseUser.id)
          .maybeSingle();

      if (userRow == null) {
        final email = supabaseUser.email ?? '';
        final name =
        email.contains('@') ? email.split('@').first : '사용자';
        final profileImageUrl = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl('${supabaseUser.id}/profile.jpg');

        // users
        await Supabase.instance.client.from('users').insert({
          'id': supabaseUser.id,
          'email': email,
          'name': name,
          'group_name': '$name의 그룹',
          'last_owner_id': supabaseUser.id,
          'profile_url': profileImageUrl,
          'is_profile': false,
        });

        // budgets
        final newBudgetId = const Uuid().v4();
        await Supabase.instance.client.from('budgets').insert({
          'id': newBudgetId,
          'owner_id': supabaseUser.id,
          'name': '주 가계부',
          'updated_by': supabaseUser.id,
          'is_main': true,
        });

        await userProvider.setBudgetId(newBudgetId);
      }

      // --- UserProvider 초기화 ---
      await userProvider.initializeUserProvider();

      // --- budgetId 확정 ---
      final ownerId = userProvider.ownerId ?? supabaseUser.id;
      var budgetId = userProvider.budgetId;

      if (budgetId == null) {
        final response = await Supabase.instance.client
            .from('budgets')
            .select('id')
            .eq('owner_id', ownerId)
            .eq('is_main', true)
            .maybeSingle();
        budgetId = response?['id'] as String?;
        if (budgetId != null) {
          await userProvider.setBudgetId(budgetId);
        }
      }

      // --- Money/t odo Provider 초기화 ---
      await Future.wait([
        moneyProvider.setInitialUserId(supabaseUser.id, ownerId, budgetId),
        todoProvider.setUserId(supabaseUser.id, ownerId),
      ]);

      await IapService().verifyNow();
      await userProvider.loadUserSubscription();

      unawaited(IapService().startListener());

      final fcm = FcmTokenService(Supabase.instance.client);
      unawaited(() async {
        try {
          await fcm.register(supabaseUser.id);
          fcm.listenRefresh(supabaseUser.id);
        } catch (e) {
          debugPrint('FCM register failed: $e');
        }
      }());
    } else {
      // --- 게스트 모드 ---
      await Future.wait([
        userProvider.initializeUserProvider(),
        moneyProvider.setInitialUserId(null, null, null),
        todoProvider.setUserId(null, null),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('네트워크 또는 초기화에 실패했어요.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _guardedInit,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

}
