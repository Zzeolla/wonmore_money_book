import 'package:flutter/material.dart';

class TodoListScreen extends StatefulWidget {
  final VoidCallback onClose;
  const TodoListScreen({super.key, required this.onClose,});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("todo"),
        ElevatedButton(onPressed: widget.onClose, child: Text("닫기")),
      ],
    );
  }
}
