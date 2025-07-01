import 'package:drift/drift.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/model/period_type.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';

class FavoriteRecordModel {
  String? id;
  int amount;
  TransactionType type;
  PeriodType period;
  DateTime? startDate;
  DateTime? lastGeneratedDate;
  String? categoryId;
  String? assetId;
  String? title;
  String? memo;
  String? ownerId;
  String? budgetId;
  DateTime? updatedAt;

  FavoriteRecordModel({
    this.id,
    required this.amount,
    required this.type,
    required this.period,
    this.startDate,
    this.lastGeneratedDate,
    this.categoryId,
    this.assetId,
    this.title,
    this.memo,
    this.ownerId,
    this.budgetId,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type.name,
      'period': period.name,
      'start_date': startDate?.toIso8601String(),
      'last_generated_date': lastGeneratedDate?.toIso8601String(),
      'category_id': categoryId,
      'asset_id': assetId,
      'title': title,
      'memo': memo,
      'owner_id': ownerId,
      'budget_id': budgetId,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory FavoriteRecordModel.fromJson(Map<String, dynamic> json) {
    return FavoriteRecordModel(
      id: json['id'],
      amount: json['amount'],
      type: TransactionType.values.firstWhere((e) => e.name == json['type']),
      period: PeriodType.values.firstWhere((e) => e.name == json['period']),
      startDate: DateTime.parse(json['start_date']),
      lastGeneratedDate: DateTime.parse(json['last_generated_date']),
      categoryId: json['category_id'],
      assetId: json['asset_id'],
      title: json['title'],
      memo: json['memo'],
      ownerId: json['owner_id'],
      budgetId: json['budget_id'],
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Drift → Model
  factory FavoriteRecordModel.fromDriftRow(FavoriteRecord row) {
    return FavoriteRecordModel(
      id: row.id,
      amount: row.amount,
      type: row.type,
      period: row.period,
      startDate: row.startDate,
      lastGeneratedDate: row.lastGeneratedDate,
      categoryId: row.categoryId,
      assetId: row.assetId,
      title: row.title,
      memo: row.memo,
      ownerId: row.ownerId,
      budgetId: row.budgetId,
      updatedAt: row.updatedAt,
    );
  }

  // Model → Drift Companion
  FavoriteRecordsCompanion toCompanion() {
    return FavoriteRecordsCompanion.insert(
      id: Value(id!),
      amount: amount,
      type: type,
      period: period,
      startDate: startDate == null ? const Value.absent() : Value(startDate!),
      lastGeneratedDate: lastGeneratedDate == null ? const Value.absent() : Value(lastGeneratedDate!),
      categoryId: categoryId == null ? const Value.absent() : Value(categoryId!),
      assetId: assetId == null ? const Value.absent() : Value(assetId!),
      title: title == null ? const Value.absent() : Value(title!),
      memo: memo == null ? const Value.absent() : Value(memo!),
      ownerId: ownerId == null ? const Value.absent() : Value(ownerId!),
      budgetId: budgetId == null ? const Value.absent() : Value(budgetId!),
      updatedAt: updatedAt == null ? const Value.absent() : Value(updatedAt!),
    );
  }

  // copyWith
  FavoriteRecordModel copyWith({
    String? id,
    int? amount,
    TransactionType? type,
    PeriodType? period,
    DateTime? startDate,
    DateTime? lastGeneratedDate,
    String? categoryId,
    String? assetId,
    String? title,
    String? memo,
    String? ownerId,
    String? budgetId,
    DateTime? updatedAt,
  }) {
    return FavoriteRecordModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
      categoryId: categoryId ?? this.categoryId,
      assetId: assetId ?? this.assetId,
      title: title ?? this.title,
      memo: memo ?? this.memo,
      ownerId: ownerId ?? this.ownerId,
      budgetId: budgetId ?? this.budgetId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
