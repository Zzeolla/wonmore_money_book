import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wonmore_money_book/model/user_model.dart';
import 'package:wonmore_money_book/provider/user_provider.dart';
import 'package:wonmore_money_book/widget/common_app_bar.dart';

class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final sharedUsers = userProvider.sharedUsers ?? [];
    final myUserId = userProvider.userId;
    final ownerId = userProvider.ownerId;
    final budgets = userProvider.myBudgets ?? [];
    final supabase = Supabase.instance.client;

    final sortedUsers = [...sharedUsers]..sort((a, b) {
        if (a.id == ownerId) return -1;
        if (b.id == ownerId) return 1;
        return a.name!.compareTo(b.name!);
      });

    return Scaffold(
      appBar: CommonAppBar(
        isMainScreen: false,
        label: '함께하는 사용자 관리',
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Color(0xFFF2F4F6), size: 30),
            onPressed: () => Navigator.pushNamed(context, '/more/join-group'),
          ),
        ]
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: const [
                Expanded(child: Divider(thickness: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('👥 함께하는 사용자',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                Expanded(child: Divider(thickness: 1)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 4),
              itemCount: sortedUsers.length,
              itemBuilder: (context, index) {
                final user = sortedUsers[index];
                final isOwner = user.id == ownerId;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.amberAccent, width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      backgroundImage: user.isProfile! ? NetworkImage(user.profileUrl!) : null,
                      child: !user.isProfile!
                          ? const Icon(Icons.group, color: Colors.black, size: 28)
                          : null,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name ?? '이름 없음',
                            style: TextStyle(
                              fontWeight: isOwner ? FontWeight.bold : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOwner) const Text('👑'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: isOwner ? Colors.grey : Colors.red,
                      ),
                      onPressed: isOwner ? null : () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('함께하는 사용자 삭제'),
                            content: Text(
                                '${user.name}님을 공유 사용자에서 삭제하시겠습까?\n이 사용자는 더 이상 함께 가계부를 볼 수 없습니다.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('삭제', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirm != true) return;

                        try {
                          final budgetIds = budgets.map((b) => b.id!).toList();

                          // 1. Supabase budget_permissions 삭제
                          await supabase
                              .from('budget_permissions')
                              .delete()
                              .inFilter('budget_id', budgetIds)
                              .eq('user_id', user.id!);

                          await supabase
                              .from('shared_users')
                              .delete()
                              .eq('owner_id', myUserId!)
                              .eq('user_id', user.id!);

                          await userProvider.loadSharedUsers();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${user.name}님이 삭제되었습니다')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('삭제 중 오류가 발생했습니다')),
                          );
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('권한 설정 기능 준비 중')),
                        );
                      },
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
