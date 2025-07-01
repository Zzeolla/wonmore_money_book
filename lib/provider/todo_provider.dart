import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/model/todo_model.dart';

class TodoProvider extends ChangeNotifier {
  final AppDatabase _db;
  final SupabaseClient supabase = Supabase.instance.client;
  String? _userId;
  String? _ownerId;
  List<TodoModel> _todos = [];

  TodoProvider(this._db) {
    _loadTodos();
  }

  List<TodoModel> get todos => _todos;

  Future<void> setUserId(String? userId, String? ownerId) async {
    _userId = userId;
    _ownerId = ownerId;
    _loadTodos();
  }

  Future<void> syncTodoLocalDataToSupabase() async {
    final localData = await _db.select(_db.todos).get();
    final todoModel = localData.map(TodoModel.fromDriftRow).toList();

    for (final model in todoModel) {
      final uploadModel = model.copyWith(
        ownerId: _ownerId,
      );
      await supabase.from('todos').insert(uploadModel.toMap());
    }
    await _db.delete(_db.todos).go();
  }

  Future<void> _loadTodos() async {
    if (_userId == null) {
      final localTodo = await _db.select(_db.todos).get();
      _todos = localTodo.map(TodoModel.fromDriftRow).toList();

    } else {
      final response = await Supabase.instance.client
          .from('todos')
          .select()
          .eq('is_done', false)
          .order('created_at');
      _todos = response.map(TodoModel.fromJson).toList();
    }
    notifyListeners();
  }

  Future<void> addTodo(String title, String? memo) async {
    final todoModel = TodoModel(
      id: const Uuid().v4(),
      title: title,
      memo: memo,
      isDone: false,
      ownerId: _ownerId,
    );

    if(_userId == null) {
      await _db.into(_db.todos).insert(todoModel.toCompanion());
    } else {
      await supabase.from('todos').insert(todoModel.toMap());
    }
    await _loadTodos();
  }

  Future<void> toggleTodo(String id, bool isDone) async {
    if (_userId == null) {
      await (_db.update(_db.todos)..where((t) => t.id.equals(id)))
          .write(TodosCompanion(
        isDone: Value(isDone),
        updatedAt: Value(DateTime.now()),
      ));
    } else {
      await supabase.from('todos').update({
        'is_done': isDone,
      }).eq('id', id);
    }

    await _loadTodos();
  }

  Future<void> updateTodo(String id, String title, String? memo) async {
    if (_userId == null) {
      await (_db.update(_db.todos)..where((t) => t.id.equals(id))).write(
        TodosCompanion(
          title: Value(title),
          memo: memo == null ? const Value.absent() : Value(memo),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } else {
      final updatedMap = {
        'title': title,
        'memo': memo,
      };
      await supabase.from('todos').update(updatedMap).eq('id', id);
    }

    await _loadTodos();
  }

  Future<void> deleteTodo(String id) async {
    if (_userId == null) {
      await (_db.delete(_db.todos)..where((t) => t.id.equals(id))).go();
    } else {
      await supabase.from('todos').delete().eq('id', id);
    }

    await _loadTodos();
  }

} 