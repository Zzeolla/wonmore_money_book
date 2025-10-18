import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wonmore_money_book/component/banner_ad_widget.dart';
import 'package:wonmore_money_book/dialog/budget_chooser_dialog.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';
import 'package:wonmore_money_book/provider/user_provider.dart';
import 'package:wonmore_money_book/screen/category_management_screen.dart';
import 'package:wonmore_money_book/screen/login_screen.dart';
import 'package:wonmore_money_book/service/export_service.dart';
import 'package:wonmore_money_book/service/record_ad_service.dart';
import 'package:wonmore_money_book/widget/common_app_bar.dart';
import 'package:wonmore_money_book/widget/common_drawer.dart';

class MoreScreen extends StatelessWidget {
  final Future<void> Function() onRestartTutorial;
  const MoreScreen({super.key, required this.onRestartTutorial});

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
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
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
                  // ListTile(
                  //   leading: const Icon(Icons.person_outline),
                  //   title: const Text('광고 횟수 초기화'),
                  //   onTap: () async {
                  //     await RecordAdService.resetToday();
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
                  const Divider(),
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
                  const Divider(),
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
                  const Divider(),
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
                  const Divider(),
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
                    onTap: isLoggedIn ? () {
                      Navigator.pushNamed(context, '/more/paywall');
                    } : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(message: '이 기능은 로그인 후 사용할 수 있습니다.'),
                        ),
                      );
                    },
                  ),
                  const Divider(),
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
                  const Divider(),
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
                    onTap: () async {
                      final ctx   = context;
                      final user  = ctx.read<UserProvider>();
                      final money = ctx.read<MoneyProvider>();

                      // 1) (로그인 시) 내보낼 가계부 선택
                      String titleSuffix = '전체(게스트)';
                      String? selectedBudgetId;
                      String? selectedGroupId;

                      if (user.isLoggedIn) {
                        final picked = await showBudgetChooserDialog(
                          ctx,
                          title: '내보낼 가계부 선택',
                          performSwitch: false, // 전환하지 않고 선택만
                        );
                        if (picked == null) return;

                        selectedBudgetId = picked['budgetId'];
                        selectedGroupId = picked['groupId'];
                        final groupName  = picked['groupName'] ?? '그룹';
                        final budgetName = picked['budgetName'] ?? '가계부';
                        titleSuffix = '{$groupName}·{$budgetName}';

                        if (selectedBudgetId == null || selectedBudgetId.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('가계부 식별자가 없습니다. 다시 시도해 주세요.')),
                          );
                          return;
                        }
                      }

                      // 2) 기간 선택 (초기값: 최근 30일)
                      final now = DateTime.now();
                      final initialRange = DateTimeRange(
                        start: now.subtract(const Duration(days: 30)),
                        end: now,
                      );
                      final range = await showDateRangePicker(
                        context: ctx,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        initialDateRange: initialRange,
                      );
                      if (range == null) return;

                      // 3) 조회 → 엑셀 생성 → 공유 (로딩 표시)
                      await _withLoading(ctx, () async {
                        // 네가 수정해둔 시그니처에 맞춤 (게스트면 null 전달)
                        try {
                          final txs = await money.getTransactionsByPeriod(
                            range.start,
                            range.end,
                            selectedBudgetId: selectedBudgetId,
                          );

                          if (txs.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('선택한 기간에 내보낼 거래가 없습니다.')),
                            );
                            return;
                          }

                          final categoryMap = await money.getCategoryNameMapForBudget(selectedBudgetId, ownerId: selectedGroupId!,);
                          final assetMap    = await money.getAssetNameMapForBudget(selectedBudgetId, ownerId: selectedGroupId,);

                          final result = await ExportService.buildExcelAndSaveToDownloads(
                            txs: txs,
                            titleSuffix: titleSuffix,
                            categoryNameById: categoryMap,
                            assetNameById: assetMap,
                          );

                          // 저장 안내
                          if (result.savedPathOrUri != null && result.savedPathOrUri!.isNotEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('다운로드에 저장됨: ${result.filename}')),
                            );
                          } else {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('저장 경로 확인 불가(기기 정책). 공유/열기로 사용하세요.')),
                            );
                          }

                          // 공유 여부 묻기
                          final share = await showDialog<bool>(
                            context: ctx,
                            builder: (_) => AlertDialog(
                              title: const Text('내보내기 완료'),
                              content: const Text('공용 Downloads 폴더에 저장했습니다.\n추가로 공유하시겠습니까?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('아니오')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('공유하기')),
                              ],
                            ),
                          );

                          if (share == true) {
                            await ExportService.shareExport(
                              result,
                              shareText: '원모아 가계부 내보내기: $titleSuffix',
                              shareSubject: '원모아 가계부 내보내기',
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('파일 저장에 실패했습니다: $e')),
                          );
                        }
                      });
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.deepPurple.shade300,
                        child: const Icon(Icons.school, size: 16, color: Colors.white,),
                      ),
                    ),
                    title: const Text('튜토리얼 다시보기'),
                    onTap: () async => await onRestartTutorial(), // ✅ 호출만 비동기
                  ),
                  const Divider(),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('설정 화면은 추후 지원할 예정입니다.'))
                      );
                      // TODO: 설정 화면으로 이동
                    },
                  ),
                  const Divider(),
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
                  const Divider(),
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
                    onTap: () => shareApp(context),
                  ),
                  const Divider(),
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

  Future<void> shareApp(BuildContext context) async {
    final String androidLink = 'https://play.google.com/store/apps/details?id=com.zlabo.wonmoremoneybook';
    final String iosLink     = 'https://apps.apple.com/app/idXXXXXXXXXX'; // 실제 앱 ID로 교체

    final String link = Platform.isIOS ? iosLink : androidLink;

    final String text = [
      '원모아 가계부 앱을 사용해보세요!',
      '가족 가계부 + 개인 용돈, 한 앱에서 함께 관리합니다.',
      link, // 사용자가 좋아하는 "plain URL" 그대로
    ].join('\n');

    // iPad/웹뷰 등에서 팝오버 위치 지정 시 안전
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      text,
      subject: '원모아 가계부',
      sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : Rect.zero,
    );
  }

  Future<T?> _withLoading<T>(BuildContext context, Future<T> Function() task) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      return await task();
    } finally {
      if (context.mounted) Navigator.of(context).pop(); // close loading
    }
  }


}