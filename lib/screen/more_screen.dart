import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('더보기'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('프로필'),
            onTap: () {
              // TODO: 프로필 화면으로 이동
            },
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('가계부 공유'),
            onTap: () {
              // TODO: 가계부 공유 기능 구현
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('설정'),
            onTap: () {
              // TODO: 설정 화면으로 이동
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('앱 정보'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '원모아 가계부',
                applicationVersion: '1.0.0',
                applicationIcon: const FlutterLogo(size: 64),
                children: const [
                  Text('원모아 가계부는 가족과 함께 사용하는 가계부 앱입니다.'),
                  SizedBox(height: 16),
                  Text('개발: 원모아'),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.code_outlined),
            title: const Text('오픈소스 라이선스'),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: '원모아 가계부',
                applicationVersion: '1.0.0',
                applicationIcon: const FlutterLogo(size: 64),
              );
            },
          ),
        ],
      ),
    );
  }
} 