import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _signInWithOAuth(BuildContext context, OAuthProvider provider) async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: 'wonmore://login-callback',
      );

      // auth.onAuthStateChange에서 이 이벤트를 감지하도록 설정
      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        final user = session?.user;
        if (user != null) {
          final exists = await checkUserExists(user.id);

          if (!exists) {
            // 신규 유저라면
            await createUser(user); // Supabase DB에 사용자 생성
            // await migrateLocalDataToSupabase(); // 🔁 로컬 데이터를 Supabase로 이전 TODO: 구현 필요
          } else {
            // 기존 유저라면
            // await syncSupabaseDataToLocal(); // 🔁 Supabase 데이터를 로컬 DB로 덮어쓰기 TODO: 구현 필요
          }

          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/main');
          }
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: $e')),
      );
    }
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

  Future<void> createUser(User user) async {
    await Supabase.instance.client.from('users').insert({
      'id': user.id,
      'email': user.email,
      'created_at': DateTime.now().toIso8601String(),
      // 닉네임, 프로필은 설정 화면에서 입력받을 예정
    });
  }

  Future<bool> checkUserExists(String userId) async {
    final response = await Supabase.instance.client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response != null;
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
