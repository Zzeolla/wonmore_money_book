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
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final supabaseUser = Supabase.instance.client.auth.currentUser;
      final userProvider = context.read<UserProvider>();
      final moneyProvider = context.read<MoneyProvider>();
      final todoProvider = context.read<TodoProvider>();

      // 1. 인터넷 체크
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const NoInternetScreen()),
          );
        }
        return;
      }
      // 2. 로그인 id 확인
      if (supabaseUser != null) {
        await userProvider.setUser(supabaseUser);
        final user = userProvider.currentUser;
        final response = await Supabase.instance.client
            .from('users').select().eq('id', user!.id).maybeSingle();

        if (response == null) {
          final email = user.email ?? '';
          final name = email.contains('@') ? email
              .split('@')
              .first : '사용자';
          final profileImageUrl = Supabase.instance.client.storage
              .from('avatars')
              .getPublicUrl('${user.id}/profile.png');

          bool imageExists = false;
          final newUser = UserModel(
            id: user.id,
            email: email,
            name: name,
            groupName: '$name의 그룹',
            lastOwnerId: user.id,
            profileUrl: profileImageUrl,
            isProfile: imageExists
          );

          await Supabase.instance.client.from('users').insert(newUser.toMap());

          await Supabase.instance.client.from('subscriptions').insert({
            'user_id': user.id,
            'plan_name': 'free',
            'start_date': DateTime.now().toIso8601String(),
            'is_active': true,
          });

          final newBudgetId = const Uuid().v4();
          await Supabase.instance.client.from('budgets').insert({
            'id': newBudgetId,
            'owner_id': user.id,
            'name': '주 가계부',
            'updated_by': user.id,
            'is_main': true
          });
          await userProvider.setOwnerId(user.id);
        } else {
          if (userProvider.justSignedIn) {
            await userProvider.setOwnerId(user.id);
          } else {
            final lastOwnerResponse = await Supabase.instance.client
                .from('users')
                .select('last_owner_id')
                .eq('id', user.id)
                .maybeSingle();
            await userProvider.setOwnerId(lastOwnerResponse?['last_owner_id']);
          }
        }

        await userProvider.initializeUserProvider();
        final ownerId = userProvider.ownerId;
        final budgetId = userProvider.budgetId;


        // print('ownerId : ${userProvider.ownerId}');
        // print('budgetId : ${userProvider.budgetId}');



        if (budgetId != null) {
          await moneyProvider.setInitialUserId(user.id, ownerId, budgetId);
        } else {
          final response = await Supabase.instance.client
              .from('budgets')
              .select('*')
              .eq('owner_id', ownerId!)
              .eq('is_main', true)
              .maybeSingle();

          final mainBudgetId = response?['id'] as String?;
          if (mainBudgetId != null) {
            await Future.wait([
              userProvider.setBudgetId(mainBudgetId),
              moneyProvider.setInitialUserId(user.id, ownerId, mainBudgetId),
            ]);
          }
        }
        await todoProvider.setUserId(user.id, ownerId);
      } else {
        await Future.wait([
          userProvider.initializeUserProvider(),
          moneyProvider.setInitialUserId(null, null, null),
          todoProvider.setUserId(null, null),
        ]);
      }
      //
      // print('userId : ${userProvider.userId}');
      // print('ownerId : ${userProvider.ownerId}');
      // print('budgetId : ${userProvider.budgetId}');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('record_limit_count');
      await prefs.remove('record_limit_ad_count');
      // 4. 다음 화면 이동
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}