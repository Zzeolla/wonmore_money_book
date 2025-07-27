import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wonmore_money_book/component/banner_ad_widget.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';
import 'package:wonmore_money_book/provider/user_provider.dart';
import 'package:wonmore_money_book/screen/category_management_screen.dart';
import 'package:wonmore_money_book/screen/login_screen.dart';
import 'package:wonmore_money_book/util/clean_app_data.dart';
import 'package:wonmore_money_book/widget/common_app_bar.dart';
import 'package:wonmore_money_book/widget/common_drawer.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isLoggedIn = userProvider.isLoggedIn;
    return Scaffold(
      appBar: CommonAppBar(
        actions: [
          IconButton(
            icon: Icon(
              isLoggedIn ? Icons.logout : Icons.login,
              color: Color(0xFFF2F4F6),
              size: 30,
            ),
            onPressed: () async {
              if (isLoggedIn) {
                await userProvider.signOut();
                Navigator.pushReplacementNamed(context, '/');
              } else {
                Navigator.pushNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      drawer: CommonDrawer(),
      body: Column(
        children: [
          Expanded(
            child: ListTileTheme(
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              dense: false,
              minLeadingWidth: 0,
              child: ListView(
                children: [
                  // ListTile(
                  //   leading: const Icon(Icons.person_outline),
                  //   title: const Text('db삭제 개발용'),
                  //   onTap: () async {
                  //     await clearAllAppData(context);
                  //   },
                  // ),
                  ListTile(
                    leading: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.deepPurple.shade300,
                        child: const Icon(Icons.account_circle_outlined, size: 16, color: Colors.white,),
                      ),
                    ),
                    title: const Text('내 정보'),
                    onTap: isLoggedIn ? () {
                      Navigator.pushNamed(context, '/more/my-info');
                    } : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(message: '이 기능은 로그인 후 사용할 수 있습니다.'),
                        ),
                      );
                    }
                  ),
                  ListTile(
                      leading: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.deepPurple.shade300,
                          child: const Icon(Icons.menu_book_outlined, size: 16, color: Colors.white,),
                        ),
                      ),
                    title: const Text('가계부 관리'),
                    onTap: isLoggedIn ? () {
                      Navigator.pushNamed(context, '/more/edit-budget');
                    } : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(message: '이 기능은 로그인 후 사용할 수 있습니다.'),
                        ),
                      );
                    }
                  ),
                  ListTile(
                      leading: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.deepPurple.shade300,
                          child: const Icon(Icons.group_outlined, size: 16, color: Colors.white,),
                        ),
                      ),
                    title: const Text('함께하는 사용자 관리'),
                    onTap: isLoggedIn ? () {
                      Navigator.pushNamed(context, '/more/edit-user');
                    } : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(message: '이 기능은 로그인 후 사용할 수 있습니다.'),
                        ),
                      );
                    }
                  ),
                  ListTile(
                      leading: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.deepPurple.shade300,
                          child: const Icon(Icons.group_add_outlined, size: 16, color: Colors.white,),
                        ),
                      ),
                    title: const Text('가계부 그룹 공유/참여'),
                    onTap: isLoggedIn ? () {
                      Navigator.pushNamed(context, '/more/join-group');
                    } : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(message: '이 기능은 로그인 후 사용할 수 있습니다.'),
                        ),
                      );
                    }
                  ),
                  ListTile(
                    leading: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.deepPurple.shade300,
                        child: const Icon(Icons.workspace_premium_outlined, size: 16, color: Colors.white,),
                      ),
                    ),
                    title: const Text('Pro 구독하기 (광고 제거 포함)'),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('구독 기능은 추후 제공될 예정입니다.')),
                      );
                    },
                  ),
                  ListTile(
                    leading: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.deepPurple.shade300,
                        child: const Icon(Icons.mode_edit_outline, size: 16, color: Colors.white,),
                      ),
                    ),
                    title: const Text('카테고리 수정'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryManagementScreen(
                            selectedType: TransactionType.income,
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.deepPurple.shade300,
                        child: const Icon(Icons.file_upload_outlined, size: 16, color: Colors.white,),
                      ),
                    ),
                    title: const Text('내보내기'),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('내보내기 기능은 추후 제공될 예정입니다.')),
                      );
                    },
                  ),
                  ListTile(
                    leading: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.deepPurple.shade300,
                        child: const Icon(Icons.settings_outlined, size: 16, color: Colors.white,),
                      ),
                    ),
                    title: const Text('설정'),
                    onTap: () {
                      // TODO: 설정 화면으로 이동
                    },
                  ),
                  ListTile(
                    leading: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.deepPurple.shade300,
                        child: const Icon(Icons.feedback_outlined, size: 16, color: Colors.white,),
                      ),
                    ),
                    title: const Text('피드백 / 문의하기'),
                    onTap: () async {
                      final url = Uri.parse('https://forms.gle/hWi7waHMpDfE9jH79');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('링크를 열 수 없습니다.')),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.deepPurple.shade300,
                        child: const Icon(Icons.share_outlined, size: 16, color: Colors.white,),
                      ),
                    ),
                    title: const Text('앱 공유하기'),
                    onTap: () {
                      // 예: Share.share('원모아 가계부 앱을 사용해보세요!\nhttps://...');
                    },
                  ),
                  ListTile(
                    leading: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.deepPurple.shade300,
                        child: const Icon(Icons.code_outlined, size: 16, color: Colors.white,),
                      ),
                    ),
                    title: const Text('오픈소스 라이선스'),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: '원모아 가계부',
                        applicationVersion: '1.0.0',
                        applicationIcon: const FlutterLogo(size: 64),
                        children: const [
                          Text('원모아 가계부는 가족과 함께 사용하는 가계부 앱입니다.'),
                          SizedBox(height: 16),
                          Text('개발: Zlabo'),
                          SizedBox(height: 16),
                          Text('※ 본 앱은 Google에서 제공하는 광고 SDK를 포함하고 있으며, '
                              '해당 SDK는 Google Play Services 약관(https://developers.google.com/admob/terms)에 따라 사용됩니다.'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          BannerAdWidget(),
        ],
      ),
    );
  }
} 