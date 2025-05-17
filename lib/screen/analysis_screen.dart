import 'package:flutter/material.dart';
import 'package:wonmore_money_book/widget/common_app_bar.dart';
import 'package:wonmore_money_book/widget/common_drawer.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // todo: 분석 기능 만들기 최대한 간단하게
      appBar: CommonAppBar(),
      drawer: CommonDrawer(),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '분석 기능은 추후 업데이트 예정입니다.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 