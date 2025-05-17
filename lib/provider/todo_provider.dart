import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'package:wonmore_money_book/database/database.dart';

class TodoProvider extends ChangeNotifier {
  final AppDatabase _db;
  List<Todo> _todos = [];

  TodoProvider(this._db) {
    _loadTodos();
  }

  List<Todo> get todos => _todos;

  Future<void> _loadTodos() async {
    _todos = await _db.select(_db.todos).get();
    notifyListeners();
  }

  Future<void> addTodo(String title, {String? memo}) async {
    final todo = TodosCompanion.insert(
      title: title,
      memo: memo == null ? const Value.absent() : Value(memo),
    );
    await _db.into(_db.todos).insert(todo);
    await _loadTodos();
  }

  Future<void> toggleTodo(int id, bool isDone) async {
    await (_db.update(_db.todos)..where((t) => t.id.equals(id)))
        .write(TodosCompanion(
      isDone: Value(isDone),
      updatedAt: Value(DateTime.now()),
    ));
    await _loadTodos();
  }

  Future<void> deleteTodo(int id) async {
    await (_db.delete(_db.todos)..where((t) => t.id.equals(id))).go();
    await _loadTodos();
  }
} 