import 'package:drift/drift.dart';
import 'package:wonmore_money_book/database/database.dart';

class TodoModel {
  String? id;
  String title;
  String? memo;
  bool? isDone;
  String? ownerId;
  DateTime? updatedAt;

  TodoModel({
    this.id,
    required this.title,
    this.memo,
    this.isDone,
    this.ownerId,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'memo': memo,
      'is_done': isDone,
      'owner_id': ownerId,
      'updated_at': updatedAt,
    };
  }

  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id: json['id'],
      title: json['title'],
      memo: json['memo'],
      isDone: json['is_done'],
      ownerId: json['owner_id'],
      updatedAt: DateTime.parse(json['updated_at'])
    );
  }

  // Drift → Model
  factory TodoModel.fromDriftRow(Todo row) {
    return TodoModel(
      id: row.id,
      title: row.title,
      memo: row.memo,
      isDone: row.isDone,
      ownerId: row.ownerId,
      updatedAt: row.updatedAt,
    );
  }

  // Model → Drift Companion
  TodosCompanion toCompanion() {
    return TodosCompanion.insert(
      id: Value(id!),
      title: title,
      memo: Value(memo),
      isDone: Value(isDone!),
      ownerId: ownerId == null ? const Value.absent() : Value(ownerId),
      updatedAt: updatedAt == null ? const Value.absent() : Value(updatedAt!),
    );
  }

  // copyWith
  TodoModel copyWith({
    String? id,
    String? title,
    String? memo,
    bool? isDone,
    String? ownerId,
    DateTime? updatedAt,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      memo: memo ?? this.memo,
      isDone: isDone ?? this.isDone,
      ownerId: ownerId ?? this.ownerId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
