import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wonmore_money_book/model/user_model.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';
import 'package:wonmore_money_book/provider/todo_provider.dart';
import 'package:wonmore_money_book/provider/user_provider.dart';
import 'package:wonmore_money_book/screen/no_internet_screen.dart';

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
  static const _maxRetries = 3;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _guardedInit();
    });

    // 온라인 전환되면 자동 재시도
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      // 하나라도 none이 아니면 온라인으로 간주
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

  Future<T> _withTimeout<T>(Future<T> future, {Duration timeout = const Duration(seconds: 8)}) {
    return future.timeout(timeout, onTimeout: () {
      throw TimeoutException('Splash init timed out');
    });
    // 필요하면 여기서 재시도 래핑도 가능
  }

  Future<void> _guardedInit() async {
    if (_initializing || _navigated) return;
    setState(() {
      _initializing = true;
      _error = false;
    });

    try {
      // 1) 네트워크 체크 (타임아웃)
      final connectivity = await _withTimeout(Connectivity().checkConnectivity(), timeout: const Duration(seconds: 5));
      if (connectivity == ConnectivityResult.none) {
        throw Exception('No internet');
      }

      // 2) 메인 초기화 (기존 로직을 함수로 분리)
      await _withTimeout(_initAppCore());

      // 3) 성공 시 단 1회만 이동
      if (mounted && !_navigated) {
        _navigated = true;
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      // 실패 시 에러 UI 노출 + 수동 재시도 허용
      if (!mounted) return;
      setState(() {
        _error = true;
      });

      // 자동 재시도(선택): 적당히 1~2회 백오프 후 시도
      if (_retryCount < _maxRetries) {
        _retryCount++;
        await Future.delayed(Duration(seconds: 2 * _retryCount));
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

  // 🔧 기존 init 로직을 그대로 옮겨와 try/catch + timeout 하에서 실행
  Future<void> _initAppCore() async {
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    final userProvider = context.read<UserProvider>();
    final moneyProvider = context.read<MoneyProvider>();
    final todoProvider = context.read<TodoProvider>();

    if (supabaseUser != null) {
      await userProvider.setUser(supabaseUser);

      // users 레코드 확인/생성 (타임아웃 보호)
      final userRow = await _withTimeout(
        Supabase.instance.client
            .from('users')
            .select()
            .eq('id', supabaseUser.id)
            .maybeSingle(),
        timeout: const Duration(seconds: 8),
      );

      if (userRow == null) {
        final email = supabaseUser.email ?? '';
        final name = email.contains('@') ? email.split('@').first : '사용자';
        final profileImageUrl = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl('${supabaseUser.id}/profile.png');

        await _withTimeout(
          Supabase.instance.client.from('users').insert({
            'id': supabaseUser.id,
            'email': email,
            'name': name,
            'group_name': '$name의 그룹',
            'last_owner_id': supabaseUser.id,
            'profile_url': profileImageUrl,
            'is_profile': false,
          }),
          timeout: const Duration(seconds: 8),
        );

        await _withTimeout(
          Supabase.instance.client.from('subscriptions').insert({
            'user_id': supabaseUser.id,
            'plan_name': 'free',
            'start_date': DateTime.now().toIso8601String(),
            'is_active': true,
          }),
          timeout: const Duration(seconds: 8),
        );

        final newBudgetId = const Uuid().v4();
        await _withTimeout(
          Supabase.instance.client.from('budgets').insert({
            'id': newBudgetId,
            'owner_id': supabaseUser.id,
            'name': '주 가계부',
            'updated_by': supabaseUser.id,
            'is_main': true,
          }),
          timeout: const Duration(seconds: 8),
        );
      }

      // Provider 초기화
      await _withTimeout(userProvider.initializeUserProvider(), timeout: const Duration(seconds: 8));

      final ownerId = userProvider.ownerId;
      final budgetId = userProvider.budgetId;

      if (budgetId != null && ownerId != null) {
        await _withTimeout(
          moneyProvider.setInitialUserId(supabaseUser.id, ownerId, budgetId),
          timeout: const Duration(seconds: 8),
        );
      } else {
        final response = await _withTimeout(
          Supabase.instance.client
              .from('budgets')
              .select('id')
              .eq('owner_id', ownerId ?? supabaseUser.id)
              .eq('is_main', true)
              .maybeSingle(),
          timeout: const Duration(seconds: 8),
        );

        final mainBudgetId = response?['id'] as String?;
        if (mainBudgetId != null) {
          await Future.wait([
            _withTimeout(userProvider.setBudgetId(mainBudgetId), timeout: const Duration(seconds: 8)),
            _withTimeout(moneyProvider.setInitialUserId(supabaseUser.id, ownerId ?? supabaseUser.id, mainBudgetId),
                timeout: const Duration(seconds: 8)),
          ]);
        }
      }

      await _withTimeout(
        todoProvider.setUserId(supabaseUser.id, ownerId ?? supabaseUser.id),
        timeout: const Duration(seconds: 8),
      );
    } else {
      await _withTimeout(
        Future.wait([
          userProvider.initializeUserProvider(),
          moneyProvider.setInitialUserId(null, null, null),
          todoProvider.setUserId(null, null),
        ]),
        timeout: const Duration(seconds: 8),
      );
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

    // 기본 로딩
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}