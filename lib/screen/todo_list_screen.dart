import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/component/banner_ad_widget.dart';
import 'package:wonmore_money_book/dialog/custom_delete_dialog.dart';
import 'package:wonmore_money_book/dialog/record_input_dialog.dart';
import 'package:wonmore_money_book/dialog/todo_input_dialog.dart';
import 'package:wonmore_money_book/model/home_screen_tab.dart';
import 'package:wonmore_money_book/provider/home_screen_tab_provider.dart';
import 'package:wonmore_money_book/provider/todo_provider.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';
import 'package:another_flushbar/flushbar.dart';

class TodoListScreen extends StatefulWidget {
  final VoidCallback onClose;

  const TodoListScreen({super.key, required this.onClose});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  bool _isFlushbar = false;

  void _showFlushBar(BuildContext context, String todoId, String title) {
    _isFlushbar = true;
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
              showDialog(
                context: context,
                useRootNavigator: true,
                builder: (_) => RecordInputDialog(
                  initialDate: DateTime.now(),
                  initialTitle: title,
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

  @override
  Widget build(BuildContext context) {
    final todos = context.watch<TodoProvider>().todos.where((t) => !t.isDone!).toList();

    if (todos.isEmpty && _isFlushbar) {
      // 5초 후에 한 번만 실행되도록
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _isFlushbar = false;
          });
        }
      });
    }

    return WillPopScope(
      onWillPop: () {
        widget.onClose();
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F1FD),
        body: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: todos.isEmpty && !_isFlushbar
          ? const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.note_alt_outlined, size: 64, color: Color(0xFFB0AFFF)),
                  SizedBox(height: 16),
                  Text(
                    '할 일이 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A5A89),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '장보기 목록, 처리해야 할 금융 업무, \n기념일 체크 등 해야 할 일을 추가해 주세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          )
          : ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return Dismissible(
                key: ValueKey(todo.id),
                direction: DismissDirection.startToEnd,
                onDismissed: (_) {
                  context.read<TodoProvider>().toggleTodo(todo.id!, true);
                  _showFlushBar(context, todo.id!, todo.title);
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
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.amberAccent, width: 1),
                  ),
                  child: InkWell(
                    onLongPress: () async {
                      final result = await showCustomDeleteDialog(
                        context,
                        message: '이 할 일을 정말 삭제할까요?',
                      );
                      if (result!) {
                        await context.read<TodoProvider>().deleteTodo(todo.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('삭제되었습니다.')),
                        );
                      }
                    },
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => TodoInputDialog(
                          todoId: todo.id,
                          initialTitle: todo.title,
                          initialMemo: todo.memo,
                        ),
                      );
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
                              context.read<TodoProvider>().toggleTodo(todo.id!, true);
                              _showFlushBar(context, todo.id!, todo.title);
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
        bottomNavigationBar: BannerAdWidget(),
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

  void _handleFlushbarCleanup() async {
    await Future.delayed(const Duration(seconds: 5));
    _isFlushbar = false;
  }
}