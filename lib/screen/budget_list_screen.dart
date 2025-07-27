import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wonmore_money_book/dialog/budget_input_dialog.dart';
import 'package:wonmore_money_book/model/subscription_model.dart';
import 'package:wonmore_money_book/model/user_model.dart';
import 'package:wonmore_money_book/provider/user_provider.dart';
import 'package:wonmore_money_book/model/budget_model.dart';
import 'package:wonmore_money_book/widget/common_app_bar.dart';

class BudgetListScreen extends StatelessWidget {
  const BudgetListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final originalBudgets = userProvider.myBudgets ?? [];

// ✅ 주 가계부를 제일 위로 정렬
    final budgets = [...originalBudgets]..sort((a, b) {
      if (a.isMain == true && b.isMain != true) return -1;
      if (a.isMain != true && b.isMain == true) return 1;
      return 0;
    });
    final myPlan = userProvider.myPlan ?? SubscriptionModel.free();

    if (budgets.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 64, color: Color(0xFFB0AFFF)),
              SizedBox(height: 16),
              Text(
                '가계부가 없습니다',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5A5A89)),
              ),
              SizedBox(height: 12),
              Text(
                '새로운 가계부를 추가해보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CommonAppBar(
        isMainScreen: false,
        label: '가계부 목록',
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFF2F4F6), size: 30),
            onPressed: () {
              if (budgets.length < (myPlan.maxBudgets ?? 0)) {
                // 가계부 추가 가능
                showDialog(
                  context: context,
                  builder: (_) => BudgetInputDialog(), // 원하는 다이얼로그
                );
              } else {
                // 제한 도달
                if (myPlan.planName == 'free') {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('업그레이드 필요'),
                      content: Text('가계부는 최대 ${myPlan.maxBudgets}개까지만 생성할 수 있습니다.\nPro로 업그레이드 해보세요!'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
                        TextButton(onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/more/plan'); /// Todo: 업그레이드 화면으로 이동하는 스크린도 만들어야겠다
                        }, child: const Text('업그레이드')),
                      ],
                    ),
                  );
                } else {
                  // Pro인데도 초과 생성 시도
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('가계부 생성 불가'),
                      content: const Text('플랜 한도에 도달하여 더 이상 가계부를 생성할 수 없습니다.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
                      ],
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Expanded(child: Divider(thickness: 1)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child:
                      Text('📒 내 가계부', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const Expanded(child: Divider(thickness: 1)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 12),
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final budget = budgets[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.amberAccent, width: 1),
                  ),
                  child: InkWell(
                    onTap: () async {
                      if (budget.id != null) {

                        // 1. budget_permissions에서 user_id 리스트 조회
                        final permissionRows = await Supabase.instance.client
                            .from('budget_permissions')
                            .select('user_id')
                            .eq('budget_id', budget.id!);

                        final permittedUserIds = permissionRows
                            .map<String>((row) => row['user_id'] as String)
                            .toList();

                        // 2. users 테이블에서 해당 user 정보 조회
                        List<UserModel> permittedUsers = [];
                        if (permittedUserIds.isNotEmpty) {
                          final userRows = await Supabase.instance.client
                              .from('users')
                              .select('*')
                              .inFilter('id', permittedUserIds);

                          permittedUsers = userRows
                              .map<UserModel>((json) => UserModel.fromJson(json))
                              .toList();
                        }

                        showDialog(
                          context: context,
                          builder: (context) =>
                              BudgetInputDialog(
                                budgetId: budget.id,
                                initialTitle: budget.name,
                                permittedUser: permittedUsers,
                              ),
                        );
                      }
                    },
                    onLongPress: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('가계부 삭제'),
                          content: const Text('정말 삭제하시겠습니까?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('취소')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('삭제')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        // await context.read<UserProvider>().deleteBudget(budget.id);
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   const SnackBar(content: Text('삭제되었습니다')),
                        // );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amberAccent, width: 1),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.deepPurple.shade300,
                            child: const Icon(Icons.menu_book, size: 18, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () async {
                              final userId = context.read<UserProvider>().userId;
                              final ownerId = context.read<UserProvider>().ownerId;

                              if (userId == null || ownerId == null) return;

                              // 1. 현재 사용자의 모든 가계부 is_main = false 로 변경
                              final supabase = Supabase.instance.client;
                              await supabase
                                  .from('budgets')
                                  .update({'is_main': false})
                                  .eq('owner_id', ownerId);

                              // 2. 선택한 가계부만 is_main = true
                              await supabase
                                  .from('budgets')
                                  .update({'is_main': true})
                                  .eq('id', budget.id!);

                              // 3. 로컬 상태 갱신
                              await context.read<UserProvider>().loadBudgets();
                            },
                            child: Icon(
                              budget.isMain == true ? Icons.star : Icons.star_border,
                              color: budget.isMain == true ? Colors.orangeAccent : Colors.black54,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              budget.name ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 24, color: Colors.grey),
                            onPressed: () async {
                              // 수정 다이얼로그 띄우기
                              final permissionRows = await Supabase.instance.client
                                  .from('budget_permissions')
                                  .select('user_id')
                                  .eq('budget_id', budget.id!);

                              final permittedUserIds = permissionRows
                                  .map<String>((row) => row['user_id'] as String)
                                  .toList();

                              List<UserModel> permittedUsers = [];
                              if (permittedUserIds.isNotEmpty) {
                                final userRows = await Supabase.instance.client
                                    .from('users')
                                    .select('*')
                                    .inFilter('id', permittedUserIds);

                                permittedUsers = userRows
                                    .map<UserModel>((json) => UserModel.fromJson(json))
                                    .toList();
                              }

                              showDialog(
                                context: context,
                                builder: (context) => BudgetInputDialog(
                                  budgetId: budget.id,
                                  initialTitle: budget.name,
                                  permittedUser: permittedUsers,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
