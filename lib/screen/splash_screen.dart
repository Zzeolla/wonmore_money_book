import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration(milliseconds: 500),
      () {
        /// 0.5초 뒤 실행될 로직 구현
        Navigator.popAndPushNamed(context, '/main');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
