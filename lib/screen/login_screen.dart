import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;

import 'package:wonmore_money_book/provider/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
        userProvider.justSignedIn = true;

        final response = await Supabase.instance.client
            .from('users').select().eq('id', currentUser.id).maybeSingle();

        if (response == null) {
          final email = currentUser.email ?? '';
          final name = email.contains('@') ? email
              .split('@')
              .first : '사용자';

          await Supabase.instance.client.from('users').insert({
            'id': currentUser.id,
            'email': email,
            'name': name,
          });


        }
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/main');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    return Scaffold(
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
                      _LoginButton(
                        label: 'Google로 로그인',
                        icon: Icons.g_mobiledata,
                        backgroundColor: Colors.white,
                        textColor: Colors.black87,
                        onPressed: () => _signInWithOAuth(
                            context, OAuthProvider.google),
                      ),
                      const SizedBox(height: 16),
                      if (isIOS)
                        _LoginButton(
                          label: 'Apple로 로그인',
                          icon: Icons.apple,
                          backgroundColor: Colors.black,
                          textColor: Colors.white,
                          onPressed: () => _signInWithOAuth(
                              context, OAuthProvider.apple),
                        ),
                      const SizedBox(height: 16),
                      _LoginButton(
                        label: '카카오로 로그인',
                        icon: Icons.chat_bubble,
                        backgroundColor: const Color(0xFFFFE812),
                        textColor: Colors.black,
                        onPressed: () {
                          // TODO: Kakao 연동
                        },
                      ),
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
