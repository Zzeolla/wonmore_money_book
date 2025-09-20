import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';
import 'package:wonmore_money_book/provider/todo_provider.dart';
import 'package:wonmore_money_book/provider/user_provider.dart';

/// 가계부 변경 다이얼로그 (심플)
/// - UserProvider.budgetEntries를 그대로 사용 (현재 순서/정렬 로직은 UserProvider에서 처리)
/// - 항목 탭 시: setOwnerId → setBudgetId 적용 후 닫힘
/// - 현재 선택 중인 가계부에는 '현재' 배지 표시
Future<Map<String, String>?> showBudgetChooserDialog(
  BuildContext context, {
  String title = '가계부 변경',
  bool performSwitch = true,
}) async {
  final user = context.read<UserProvider>();
  final money = context.read<MoneyProvider>();
  final todo = context.read<TodoProvider>();

  // 최신 데이터 기준으로 렌더링
  final entries = user.budgetEntries;
  final currentOwnerId = user.ownerId;
  final currentBudgetId = user.budgetId;
  final currentUserId = user.userId;

  return showDialog<Map<String, String>>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.6,
          child: entries.isEmpty
              ? const Center(child: Text('표시할 가계부가 없습니다.'))
              : ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final e = entries[i];
              final groupId = e['groupId'] as String? ?? '';
              final groupName = e['groupName'] as String? ?? '그룹';
              final budgetId = e['budgetId'] as String? ?? '';
              final budgetName = e['budgetName'] as String? ?? '가계부';
              final isMine = e['isMine'] == true;

              final isCurrentGroup = (groupId == currentOwnerId);
              final isCurrentBudget = (budgetId == currentBudgetId);

              return ListTile(
                dense: true,
                leading: Icon(
                  isMine ? Icons.home : Icons.group,
                  color: isMine ? const Color(0xFFA79BFF) : null,
                ),
                title: Text(
                  '$groupName · $budgetName',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: isCurrentGroup
                    ? const Text('현재 그룹', style: TextStyle(fontSize: 12))
                    : null,
                trailing: isCurrentBudget
                    ? const _NowChip()
                    : const Icon(Icons.chevron_right),
                onTap: () async {
                  final result = {
                    'groupName': groupName,
                    'groupId': groupId,
                    'budgetName': budgetName,
                    'budgetId': budgetId,
                  };

                  if (!performSwitch) {
                    Navigator.pop(ctx, result);
                    return;
                  }

                  final groupChanged  = groupId   != currentOwnerId;
                  final budgetChanged = budgetId  != currentBudgetId;

                  if (!groupChanged && !budgetChanged) {
                    Navigator.pop(ctx, null);
                    return;
                  }
                  // 1) UserProvider 동기화
                  if (groupChanged) {
                    await user.setOwnerId(groupId);    // 내부에서 budgets 재로딩 & last_* 업데이트
                  }
                  await user.setBudgetId(budgetId);    // 선택 예산 확정

                  // 2) 다른 Provider 초기화(= Drawer와 동일한 흐름)
                  if (groupChanged) {
                    await money.setOwnerId(groupId, budgetId);
                    if (currentUserId != null) {
                      await todo.setUserId(currentUserId, groupId);
                    }
                  } else {
                    // 그룹은 그대로, 가계부만 변경
                    await money.setBudgetId(budgetId);
                  }

                  if (context.mounted) Navigator.pop(ctx, result);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('가계부가 "$groupName · $budgetName"로 변경되었습니다.')),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('닫기'),
          ),
        ],
      );
    },
  );
}

class _NowChip extends StatelessWidget {
  const _NowChip();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        '현재',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
