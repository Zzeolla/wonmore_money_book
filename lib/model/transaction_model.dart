import 'package:drift/drift.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';

class TransactionModel {
  final String? id;
  final DateTime date;
  final int amount;
  final TransactionType type;
  final String? categoryId;
  final String? assetId;
  final String? title;
  final String? memo;
  final String? installmentId;
  final String? budgetId;
  final String? ownerId;
  final DateTime? updatedAt;

  TransactionModel({
    this.id,
    required this.date,
    required this.amount,
    required this.type,
    this.categoryId,
    this.assetId,
    this.title,
    this.memo,
    this.installmentId,
    this.budgetId,
    this.ownerId,
    this.updatedAt,
  });

  // Model → Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'type': type.name,
      'category_id': categoryId,
      'asset_id': assetId,
      'title': title,
      'memo': memo,
      'installment_id': installmentId,
      'budget_id': budgetId,
      'owner_id': ownerId,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Supabase → Model
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      amount: json['amount'],
      type: TransactionType.values.firstWhere((e) => e.name == json['type']),
      categoryId: json['category_id'],
      assetId: json['asset_id'],
      title: json['title'],
      memo: json['memo'],
      installmentId: json['installment_id'],
      budgetId: json['budget_id'],
      ownerId: json['owner_id'],
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Drift → Model
  factory TransactionModel.fromDriftRow(Transaction row) {
    return TransactionModel(
      id: row.id,
      date: row.date,
      amount: row.amount,
      type: row.type,
      categoryId: row.categoryId,
      assetId: row.assetId,
      title: row.title,
      memo: row.memo,
      installmentId: row.installmentId,
      budgetId: row.budgetId,
      ownerId: row.ownerId,
      updatedAt: row.updatedAt,
    );
  }

  // Model → Drift Companion
  TransactionsCompanion toCompanion() {
    return TransactionsCompanion.insert(
      id: Value(id!),
      date: date,
      amount: amount,
      type: type,
      categoryId: categoryId == null ? const Value.absent() : Value(categoryId!),
      assetId: assetId == null ? const Value.absent() : Value(assetId!),
      title: title == null ? const Value.absent() : Value(title!),
      memo: memo == null ? const Value.absent() : Value(memo!),
      installmentId: installmentId == null ? const Value.absent() : Value(installmentId!),
      budgetId: budgetId == null ? const Value.absent() : Value(budgetId!),
      ownerId: ownerId == null ? const Value.absent() : Value(ownerId!),
      updatedAt: updatedAt == null ? const Value.absent() : Value(updatedAt!),
    );
  }

  // copyWith
  TransactionModel copyWith({
    String? id,
    DateTime? date,
    int? amount,
    TransactionType? type,
    String? categoryId,
    String? assetId,
    String? title,
    String? memo,
    String? installmentId,
    String? budgetId,
    String? ownerId,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      assetId: assetId ?? this.assetId,
      title: title ?? this.title,
      memo: memo ?? this.memo,
      installmentId: installmentId ?? this.installmentId,
      budgetId: budgetId ?? this.budgetId,
      ownerId: ownerId ?? this.ownerId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
