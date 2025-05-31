import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/component/banner_ad_widget.dart';
import 'package:wonmore_money_book/dialog/custom_delete_dialog.dart';
import 'package:wonmore_money_book/dialog/record_input_dialog.dart';
import 'package:wonmore_money_book/dialog/todo_input_dialog.dart';
import 'package:wonmore_money_book/provider/todo_provider.dart';
import 'package:wonmore_money_book/provider/money_provider.dart';
import 'package:another_flushbar/flushbar.dart';

class TodoListScreen extends StatelessWidget {
  final VoidCallback onClose;

  const TodoListScreen({super.key, required this.onClose});

  void _showFlushBar(BuildContext outerContext, int todoId, String title) {
    late Flushbar flush;

    flush = Flushbar(
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(8),
      messageText: Text('"$title" 처리됨', style: const TextStyle(color: Colors.white)),
      duration: const Duration(seconds: 5),
      backgroundColor: Colors.black87,
      mainButton: Builder(
        builder: (buttonContext) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () async {
                print("🔔 [내역 추가] 버튼 눌림");
                await flush.dismiss(); // 💡 Flushbar 먼저 닫기
                await Future.delayed(const Duration(milliseconds: 150)); // 💡 닫힌 후 약간의 딜레이
                print("💬 flushbar 닫힘 후 dialog 띄우기 시도");

                if (outerContext.mounted) {
                  Navigator.of(outerContext, rootNavigator: true).push(
                    PageRouteBuilder(
                      opaque: false,
                      barrierDismissible: true,
                      barrierColor: Colors.black54,
                      pageBuilder: (_, __, ___) {
                        return Center(
                          child: RecordInputDialog(
                            initialDate: DateTime.now(),
                            initialTitle: title,
                            categories: outerContext.read<MoneyProvider>().categories,
                            assetList: outerContext.read<MoneyProvider>().assets.map((e) => e.name).toList(),
                          ),
                        );
                      },
                    ),
                  );

                  // print("📦 showDialog 실행 시작");
                  // showDialog(
                  //   context: outerContext,
                  //   useRootNavigator: true,
                  //   builder: (_) {
                  //     print("📦 RecordInputDialog 생성됨");
                  //     return RecordInputDialog(
                  //       initialDate: DateTime.now(),
                  //       initialTitle: title,
                  //       categories: outerContext.read<MoneyProvider>().categories,
                  //       assetList: outerContext.read<MoneyProvider>().assets.map((e) => e.name).toList(),
                  //     );
                  //   },
                  // );
                }
              },
              child: const Text('내역 추가', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                outerContext.read<TodoProvider>().toggleTodo(todoId, false);
                Navigator.of(outerContext).pop();
              },
              child: const Text('되돌리기', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    flush.show(outerContext); // Flushbar 띄우기
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
          child: todos.isEmpty
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
                        await context.read<TodoProvider>().deleteTodo(todo.id);
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
}