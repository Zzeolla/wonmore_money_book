import 'package:drift/drift.dart';
import 'package:wonmore_money_book/database/database.dart';

class InstallmentModel {
  String? id;
  DateTime date;
  int totalAmount;
  int months;
  String? categoryId;
  String? assetId;
  String? title;
  String? memo;
  String? ownerId;
  String? budgetId;
  DateTime? updatedAt;

  InstallmentModel({
    this.id,
    required this.date,
    required this.totalAmount,
    required this.months,
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
      'date': date.toIso8601String(),
      'total_amount': totalAmount,
      'months': months,
      'category_id': categoryId,
      'asset_id': assetId,
      'title': title,
      'memo': memo,
      'owner_id': ownerId,
      'budget_id': budgetId,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory InstallmentModel.fromJson(Map<String, dynamic> json) {
    return InstallmentModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      totalAmount: json['total_amount'],
      months: json['months'],
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
  factory InstallmentModel.fromDriftRow(Installment row) {
    return InstallmentModel(
      id: row.id,
      date: row.date,
      totalAmount: row.totalAmount,
      months: row.months,
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
  InstallmentsCompanion toCompanion() {
    return InstallmentsCompanion.insert(
      id: Value(id!),
      date: date,
      totalAmount: totalAmount,
      months: months,
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
  InstallmentModel copyWith({
    String? id,
    DateTime? date,
    int? totalAmount,
    int? months,
    String? categoryId,
    String? assetId,
    String? title,
    String? memo,
    String? ownerId,
    String? budgetId,
    DateTime? updatedAt,
  }) {
    return InstallmentModel(
      id: id ?? this.id,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      months: months ?? this.months,
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
