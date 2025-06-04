import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/provider/todo_provider.dart';
import 'package:wonmore_money_book/widget/custom_circle_button.dart';

class TodoInputDialog extends StatefulWidget {
  final int? todoId;
  final String? initialTitle;
  final String? initialMemo;

  const TodoInputDialog({
    super.key,
    this.todoId,
    this.initialTitle,
    this.initialMemo,
  });

  @override
  State<TodoInputDialog> createState() => _TodoInputDialogState();
}

class _TodoInputDialogState extends State<TodoInputDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _memoController.text = widget.initialMemo ?? '';
  }
  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Dialog(
      backgroundColor: const Color(0xFFF1F1FD),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MediaQuery.of(context).viewInsets.bottom > 0
                ? const SizedBox(height: 12)
                : const SizedBox(height: 0),
            const Text(
              '할 일 입력',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 24),

            // 제목 필드
            _buildTextBox(
              controller: _titleController,
              label: '할 일',
              icon: Icons.edit,
              hintText: '무엇을 해야 하나요?',
              isRequired: true,
            ),
            const SizedBox(height: 20),
            _buildTextBox(
              controller: _memoController,
              label: '메모',
              icon: Icons.chat_bubble_outline,
              hintText: '선택 사항',
              maxLines: 3,
            ),
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
                CustomCircleButton(
                  icon: Icons.check,
                  color: Colors.white,
                  backgroundColor: const Color(0xFFA79BFF),
                  onTap: () async {
                    final title = _titleController.text.trim();
                    final memo = _memoController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('할 일을 입력해 주세요.')),
                      );
                      return;
                    }

                    if (widget.todoId != null) {
                      final hasChanges = widget.initialTitle != title || widget.initialMemo != memo;

                      if (hasChanges) {
                        await context.read<TodoProvider>().updateTodo(
                          widget.todoId!,
                          title,
                          memo.isEmpty ? null : memo,
                        );
                      } else {
                        Navigator.pop(context);
                        return;
                      }
                    } else {
                      await context.read<TodoProvider>().addTodo(
                        title,
                        memo.isEmpty ? null : memo,
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
}
