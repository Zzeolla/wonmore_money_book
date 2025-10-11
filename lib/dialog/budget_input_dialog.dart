import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/dialog/custom_confirm_dialog.dart';
import 'package:wonmore_money_book/model/budget_model.dart';
import 'package:wonmore_money_book/model/user_model.dart';
import 'package:wonmore_money_book/provider/user_provider.dart';
import 'package:wonmore_money_book/widget/custom_circle_button.dart';

class BudgetInputDialog extends StatefulWidget {
  final String? budgetId;
  final String? initialTitle;
  final List<UserModel>? permittedUser;

  const BudgetInputDialog({
    super.key,
    this.budgetId,
    this.initialTitle,
    this.permittedUser,
  });

  @override
  State<BudgetInputDialog> createState() => _BudgetInputDialogState();
}

class _BudgetInputDialogState extends State<BudgetInputDialog> {
  final TextEditingController _titleController = TextEditingController();
  final Set<String> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';

    if (widget.permittedUser != null) {
      for (final user in widget.permittedUser!) {
        if (user.id != null) {
          _selectedUserIds.add(user.id!);
        }
      }
    }
  }
  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final sharedUser = userProvider.sharedUsers;

    return Dialog(
      backgroundColor: const Color(0xFFF1F1FD),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MediaQuery.of(context).viewInsets.bottom > 0
                  ? const SizedBox(height: 12)
                  : const SizedBox(height: 0),
              const Text(
                '가계부 입력',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 24),

              // 제목 필드
              _buildTextBox(
                controller: _titleController,
                label: '가계부 추가',
                icon: Icons.edit,
                hintText: '가족 공용 가계부',
                isRequired: true,
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: const [
                    Icon(Icons.lock_outline, color: Color(0xFFA79BFF)),
                    SizedBox(width: 12),
                    Text(
                      '권한 설정 *',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              _buildPermissionSection(userProvider),
              const SizedBox(height: 32),

              // 하단 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CustomCircleButton(
                      icon: Icons.close,
                      color: Colors.black54,
                      backgroundColor: const Color(0xFFE5E6EB),
                      onTap: () => Navigator.pop(context)),
                  if (widget.budgetId != null)
                    CustomCircleButton(
                      icon: Icons.delete_outline,
                      color: Colors.white,
                      backgroundColor: const Color(0xFFA79BFF),
                      onTap: () async {
                        if (widget.budgetId != null) {
                          final targetBudget = userProvider.budgets?.firstWhere(
                                (b) => b.id == widget.budgetId,
                            orElse: () => BudgetModel(), // 예외 방지용
                          );

                          if (targetBudget?.isMain == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('주 가계부는 삭제할 수 없습니다')),
                            );
                            return;
                          }

                          final result = await showCustomConfirmDialog(
                            context,
                            message: '이 가계부를 정말 삭제할까요?',
                          );

                          if (result == true) {
                            await context.read<UserProvider>().deleteBudget(widget.budgetId!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('삭제되었습니다')),
                            );
                            Navigator.pop(context);
                          }
                        }
                      },
                    ),
                  CustomCircleButton(
                    icon: Icons.check,
                    color: Colors.white,
                    backgroundColor: const Color(0xFFA79BFF),
                    onTap: () async {
                      final title = _titleController.text.trim();
                      final selectedUserIds = _selectedUserIds.toSet();

                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('가계부 이름을 입력해주세요')),
                        );
                        return;
                      }

                      if (widget.budgetId != null) {
                        final originalTitle = widget.initialTitle ?? '';
                        final originalUserIds = widget.permittedUser?.map((u) => u.id).whereType<String>().toSet() ?? {};

                        final hasTitleChanged = title != originalTitle;
                        final hasPermissionChanged = selectedUserIds.length != originalUserIds.length ||
                            !selectedUserIds.containsAll(originalUserIds);

                        if (hasTitleChanged || hasPermissionChanged) {
                          await context.read<UserProvider>().updateBudget(
                            widget.budgetId!,
                            title,
                            selectedUserIds, // 권한 사용자 목록도 함께 전달
                          );
                        } else {
                          Navigator.pop(context);
                          return;
                        }
                      } else {
                        await context.read<UserProvider>().addBudget(
                          title,
                          selectedUserIds,
                        );
                      }
                      Navigator.pop(context);
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextBox({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 28, color: const Color(0xFFA79BFF)),
            const SizedBox(width: 12),
            Text(isRequired ? '$label *' : label,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionSection(UserProvider userProvider) {
    final currentUserId = userProvider.userId;
    final sharedUsers = [...(userProvider.mySharedUsers ?? [])];

// ✅ 현재 유저가 제일 위로 오도록 정렬
    sharedUsers.sort((a, b) {
      if (a.id == currentUserId) return -1;
      if (b.id == currentUserId) return 1;
      return 0;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sharedUsers.map((user) {
        final isSelected = _selectedUserIds.contains(user.id);
        final isCurrentUser = user.id == currentUserId;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isCurrentUser ? Colors.grey.shade300 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD0D5DD)),
          ),
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(user.name ?? ''),
            trailing: Checkbox(
              value: isCurrentUser ? true : isSelected,
              onChanged: isCurrentUser
                  ? null // 현재 유저는 체크 비활성화
                  : (value) {
                setState(() {
                  if (value == true) {
                    _selectedUserIds.add(user.id ?? '');
                  } else {
                    _selectedUserIds.remove(user.id);
                  }
                });
              },
              activeColor: const Color(0xFFA79BFF),
              checkColor: Colors.white,
              tristate: false,
            ),
          ),
        );
      }).toList(),
    );
  }
}
