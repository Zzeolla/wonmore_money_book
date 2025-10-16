import 'dart:async';
import 'dart:io' show Platform;
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
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
  StreamSubscription<AuthState>? _authSub;
  bool _handled = false;

  @override
  void initState() {
    super.initState();

    // 로그인 후 앱이 다시 열렸을 때 세션 감지
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      // 화면이 이미 dispose되었으면 즉시 탈출
      if (!mounted) return;

      final event = data.event;
      final Session? session = data.session;
      final currentUser = session?.user;

      if (event == AuthChangeEvent.signedIn && currentUser != null) {
        if (_handled) return; // 중복 방지
        _handled = true;

        // context를 쓰는 시점 이전에 provider reference를 잡아두고,
        // await 이후에도 mounted 재확인
        final userProvider = context.read<UserProvider>();
        try {
          await userProvider.setUser(currentUser);
          userProvider.justSignedIn = true;

          if (!mounted) return; // await 후 재확인
          // 안전한 내비게이션 (원하면 pushNamedAndRemoveUntil로 전환)
          Navigator.of(context).pushReplacementNamed('/');
        } catch (e, st) {
          // 디버깅용 로그
          // ignore: avoid_print
          print('auth listener error: $e\n$st');
          _handled = false; // 실패 시 다시 시도 가능하게
        }
      }
    });
  }

  @override
  void dispose() {
    // ✅ 반드시 구독 해제
    _authSub?.cancel();
    _authSub = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message != null && widget.message!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return; // 안전
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.message!)),
        );
      });
    }
    final isIOS = Platform.isIOS;

    return Scaffold(
      appBar: const CommonAppBar(isMainScreen: false,),
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
                          onPressed: _signInWithAppleNative,
                          style: SignInWithAppleButtonStyle.black,
                          text: '애플 로그인'
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: $e')),
      );
    }
  }

  String _randomNonce([int length = 32]) {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final r = Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  Future<void> _signInWithAppleNative() async {
    try {
      final rawNonce = _randomNonce();
      final hashed = _sha256(rawNonce);

      // 1) iOS 네이티브 인증 창
      final cred = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashed, // ← 중요
      );

      final idToken = cred.identityToken;
      if (idToken == null) {
        throw Exception('Apple identityToken is null');
      }

      // 2) Supabase에 토큰 전달 (브라우저 X)
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce, // ← 해시 전의 원본
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple 로그인 실패: $e')),
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
