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
    loadTodos();
  }

  List<TodoModel> get todos => _todos;

  Future<void> setUserId(String? userId, String? ownerId) async {
    _userId = userId;
    _ownerId = ownerId;
    loadTodos();
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

  Future<void> loadTodos() async {
    if (_userId == null) {
      final localTodo = await _db.select(_db.todos).get();
      _todos = localTodo.map(TodoModel.fromDriftRow).toList();

    } else {
      /// TODO: 추후에는 디폴트가 createdBy를 기준으로 내가 만든것만 보이게 하고, todolist를 공유할 지 말지를 선택해서 ownerId들에게 보이는 걸로도 설정 가능하게 바꾸기로
      final response = await Supabase.instance.client
          .from('todos')
          .select()
          .eq('is_done', false)
          .eq('owner_id', _ownerId!)
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
    await loadTodos();
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

    await loadTodos();
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

    await loadTodos();
  }

  Future<void> deleteTodo(String id) async {
    if (_userId == null) {
      await (_db.delete(_db.todos)..where((t) => t.id.equals(id))).go();
    } else {
      await supabase.from('todos').delete().eq('id', id);
    }

    await loadTodos();
  }

} 