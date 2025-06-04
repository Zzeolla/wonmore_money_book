import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/provider/money_provider.dart';
import 'package:wonmore_money_book/service/repeat_transaction_service.dart';

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
      final provider = context.read<MoneyProvider>();
      await provider.loadFavoriteRecords();
      final repeatService = RepeatTransactionService(provider);

      // 반복 거래 생성 실행
      await repeatService.generateTodayRepeatedTransactions();
      print('test 확인 필요');
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.popAndPushNamed(context, '/main');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
