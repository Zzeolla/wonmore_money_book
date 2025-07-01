import 'package:drift/drift.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';
import 'package:wonmore_money_book/util/icon_map.dart';

class CategoryModel {
  final String? id;
  final String name;
  final TransactionType type;
  final int? sortOrder;
  final String iconName;
  final int colorValue;
  final String? ownerId;
  // final String? createdBy;
  // final DateTime? createdAt;
  // final String? updatedBy;
  final DateTime? updatedAt;

  CategoryModel({
    this.id,
    required this.name,
    required this.type,
    this.sortOrder,
    required this.iconName,
    required this.colorValue,
    this.ownerId,
    // this.createdBy,
    // this.createdAt,
    // this.updatedBy,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'sort_order': sortOrder,
      'icon_name': iconName,
      'color_value': colorValue,
      'owner_id': ownerId,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      type: TransactionType.values.firstWhere((e) => e.name == json['type']),
      sortOrder: json['sort_order'],
      iconName: json['icon_name'],
      colorValue: json['color_value'],
      ownerId: json['owner_id'],
      // createdBy: json['created_by'],
      // createdAt: DateTime.parse(json['created_at']),
      // updatedBy: json['updated_by'],
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
  // Drift → Model
  factory CategoryModel.fromDriftRow(Category row) {
    return CategoryModel(
      id: row.id,
      name: row.name,
      type: row.type,
      sortOrder: row.sortOrder,
      iconName: row.iconName,
      colorValue: row.colorValue,
      ownerId: row.ownerId,
      updatedAt: row.updatedAt,
    );
  }

  // Model → Drift Companion
  CategoriesCompanion toCompanion() {
    return CategoriesCompanion.insert(
      id: Value(id!),
      name: name,
      type: type,
      sortOrder: sortOrder == null ? const Value.absent() : Value(sortOrder!),
      iconName: Value(iconName),
      colorValue: Value(colorValue),
      ownerId: ownerId == null ? const Value.absent() : Value(ownerId!),
      updatedAt: updatedAt == null ? const Value.absent() : Value(updatedAt!),
    );
  }

  // copyWith
  CategoryModel copyWith({
    String? id,
    String? name,
    TransactionType? type,
    int? sortOrder,
    String? iconName,
    int? colorValue,
    String? ownerId,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      ownerId: ownerId ?? this.ownerId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}