import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/dialog/record_input_dialog.dart';
import 'package:wonmore_money_book/dialog/todo_input_dialog.dart';
import 'package:wonmore_money_book/provider/todo_provider.dart';
import 'package:wonmore_money_book/provider/money_provider.dart';
import 'package:another_flushbar/flushbar.dart';

class TodoListScreen extends StatelessWidget {
  final VoidCallback onClose;

  const TodoListScreen({super.key, required this.onClose});

  void _showFlushBar(BuildContext context, int todoId, String title) {
    Flushbar(
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(8),
      messageText: Text('"$title" 처리됨', style: const TextStyle(color: Colors.white)),
      duration: const Duration(seconds: 5),
      mainButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (_) => RecordInputDialog(
                  initialDate: DateTime.now(),
                  initialTitle: title,
                  categories: context.read<MoneyProvider>().categories,
                  assetList: context.read<MoneyProvider>().assets.map((e) => e.name).toList(),
                ),
              );
            },
            child: const Text('내역 추가', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              context.read<TodoProvider>().toggleTodo(todoId, false);
              Navigator.of(context).pop();
            },
            child: const Text('되돌리기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: Colors.black87,
    ).show(context);
  }

  void _confirmDelete(BuildContext context, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );
    if (confirm == true) {
      context.read<TodoProvider>().deleteTodo(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final todos = context.watch<TodoProvider>().todos.where((t) => !t.isDone).toList();

    return WillPopScope(
      onWillPop: () {
        onClose();
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F1FD),
        body: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return Dismissible(
                key: ValueKey(todo.id),
                direction: DismissDirection.startToEnd,
                onDismissed: (_) {
                  context.read<TodoProvider>().toggleTodo(todo.id, true);
                  _showFlushBar(context, todo.id, todo.title);
                },
                background: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check, color: Colors.white),
                ),
                child: Card(
                  // todo: 카드 선택 시 todo_input_dialog 파일 띄워주기
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.amberAccent, width: 1),
                  ),
                  child: InkWell(
                    onLongPress: () => _confirmDelete(context, todo.id),
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
                            radius: 14,
                            backgroundColor: Colors.deepPurple.shade300,
                            child: const Icon(Icons.checklist, size: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              todo.title,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.radio_button_unchecked, color: Colors.deepPurpleAccent),
                            onPressed: () {
                              context.read<TodoProvider>().toggleTodo(todo.id, true);
                              _showFlushBar(context, todo.id, todo.title);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: Container(
          height: 50,
          width: double.infinity,
          color: Colors.grey.shade300,
          child: const Center(
            child: Text('광고 자리', style: TextStyle(color: Colors.black54)),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const TodoInputDialog(),
          ),
          backgroundColor: Color(0xFFA79BFF),
          child: Icon(Icons.add, color: Colors.white, size: 36),
        ),
      ),
    );
  }
}