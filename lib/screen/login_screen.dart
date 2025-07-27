import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:io' show Platform;

import 'package:wonmore_money_book/provider/user_provider.dart';
import 'package:wonmore_money_book/widget/common_app_bar.dart';
import 'package:wonmore_money_book/widget/rounded_login_button.dart';

class LoginScreen extends StatefulWidget {
  final String? message;

  const LoginScreen({super.key, this.message});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();

    // 로그인 후 앱이 다시 열렸을 때 세션 감지
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final Session? session = data.session;
      final currentUser = session?.user;

      if (event == AuthChangeEvent.signedIn && currentUser != null) {
        final userProvider = context.read<UserProvider>();
        await userProvider.setUser(currentUser);
        userProvider.justSignedIn = true;

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message != null && widget.message!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.message!)),
        );
      });
    }
    final isIOS = Platform.isIOS;

    return Scaffold(
      appBar: CommonAppBar(isMainScreen: false,),
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 앱 로고 및 타이틀
              const Icon(Icons.account_balance_wallet,
                  size: 72, color: Colors.deepPurple),
              const SizedBox(height: 16),
              const Text(
                '원모아 가계부',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '가족과 함께 쓰는 예산앱',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),

              // 로그인 버튼 카드
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      RoundedLoginButton(
                        label: '구글 로그인',
                        iconAsset: 'assets/img/g-logo.png',
                        backgroundColor: Colors.white,
                        textColor: Colors.black87,
                        onPressed: () => _signInWithOAuth(context, OAuthProvider.google),
                      ),
                      const SizedBox(height: 16),
                      if (isIOS)
                        SignInWithAppleButton(
                          onPressed: () => _signInWithOAuth(context, OAuthProvider.apple),
                          style: SignInWithAppleButtonStyle.black,
                        ),
                      const SizedBox(height: 16),
                      RoundedLoginButton(
                        label: '카카오 로그인',
                        iconAsset: 'assets/img/kakao_bubble.png',
                        backgroundColor: const Color(0xFFFEE500),
                        textColor: Colors.black,
                        textOpacity: 0.85,
                        onPressed: () => _signInWithOAuth(context, OAuthProvider.kakao),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
              const Text(
                '※ 로그인 시 개인정보 보호정책 및 이용약관에 동의하게 됩니다.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _signInWithOAuth(BuildContext context, OAuthProvider provider) async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: 'wonmore://login-callback',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: $e')),
      );
    }
  }
}

class _LoginButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;

  const _LoginButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: textColor),
        label: Text(label, style: TextStyle(color: textColor)),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 4,
        ),
      ),
    );
  }
}
