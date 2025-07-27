import 'package:drift/drift.dart';
import 'package:wonmore_money_book/database/database.dart';

class AssetModel {
  final String? id;
  final String name;
  final int? targetAmount;
  final String? ownerId;
  final DateTime? updatedAt;

  AssetModel({
    this.id,
    required this.name,
    this.targetAmount,
    this.ownerId,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'target_amount': targetAmount,
      'owner_id': ownerId,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['id'],
      name: json['name'],
      targetAmount: json['target_amount'],
      ownerId: json['ownerId'] ?? '',
      updatedAt: DateTime.parse(json['updated_at'])
    );
  }

  // Drift → Model
  factory AssetModel.fromDriftRow(Asset row) {
    return AssetModel(
      id: row.id,
      name: row.name,
      targetAmount: row.targetAmount,
      ownerId: row.ownerId,
      updatedAt: row.updatedAt,
    );
  }

  // Model → Drift Companion
  AssetsCompanion toCompanion() {
    return AssetsCompanion.insert(
      id: Value(id!),
      name: name,
      targetAmount: targetAmount == null ? const Value.absent() : Value(targetAmount),
      ownerId: ownerId == null ? const Value.absent() : Value(ownerId),
      updatedAt: updatedAt == null ? const Value.absent() : Value(updatedAt!),
    );
  }

  // copyWith
  AssetModel copyWith({
    String? id,
    String? name,
    int? targetAmount,
    String? ownerId,
    DateTime? updatedAt,
  }) {
    return AssetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      ownerId: ownerId ?? this.ownerId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
