import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/provider/todo_provider.dart';

class TodoInputDialog extends StatefulWidget {
  const TodoInputDialog({super.key});

  @override
  State<TodoInputDialog> createState() => _TodoInputDialogState();
}

class _TodoInputDialogState extends State<TodoInputDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // todo: 디자인 다시 하기
    // todo: 추가/수정 버튼과 삭제버튼 구현 필요
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MediaQuery.of(context).viewInsets.bottom > 0 ? const SizedBox(height: 12) : const SizedBox(height: 0),
            const Text(
              '할 일 입력',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildTextBox(
              controller: _titleController,
              label: '제목',
              hintText: '무엇을 해야 하나요?',
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildTextBox(
              controller: _memoController,
              label: '메모',
              hintText: '선택 사항',
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.delete_outline, size: 32),
                  tooltip: '취소',
                ),
                IconButton(
                  onPressed: () {
                    final title = _titleController.text.trim();
                    final memo = _memoController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('제목을 입력해 주세요.')),
                      );
                      return;
                    }
                    context.read<TodoProvider>().addTodo(
                      title,
                      memo: memo.isEmpty ? null : memo,
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check, size: 32),
                  tooltip: '추가',
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
    required String hintText,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: const Color(0xFFF1F1FD),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFA79BFF), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFA79BFF), width: 1.2),
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