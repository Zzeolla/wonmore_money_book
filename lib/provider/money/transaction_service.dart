// lib/service/transaction_service.dart
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/model/transaction_model.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';

class TransactionService {
  final AppDatabase _db;
  final String? userId;
  final String? ownerId;
  final String? budgetId;
  final SupabaseClient supabase = Supabase.instance.client;

  TransactionService(this._db, this.userId, this.ownerId, this.budgetId);

  Future<bool> hasAnyTransactions() async {
    final query = _db.select(_db.transactions)..limit(1);
    final result = await query.get();
    return result.isNotEmpty;
  }

  Future<List<TransactionModel>> getTransactionsByPeriod(DateTime start, DateTime end) async {
    if (userId == null) {
      final rows = await (_db.select(_db.transactions)
            ..where((t) => t.date.isBetweenValues(start, end)))
          .get();
      return rows.map(TransactionModel.fromDriftRow).toList();
    } else {
      final response = await supabase
          .from('transactions')
          .select()
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String())
          .eq('owner_id', ownerId!)
          .eq('budget_id', budgetId!);

      return response.map(TransactionModel.fromJson).toList();
    }
  }

  Future<List<TransactionModel>> getTransactionsByDate(DateTime date) async {
    if (userId == null) {
      final rows = await (_db.select(_db.transactions)..where((t) => t.date.equals(date))).get();
      return rows.map(TransactionModel.fromDriftRow).toList();
    } else {
      final response = await supabase
          .from('transactions')
          .select()
          .eq('date', date.toIso8601String())
          .eq('owner_id', ownerId!)
          .eq('budget_id', budgetId!);

      return response.map(TransactionModel.fromJson).toList();
    }
  }

  Future<String> addTransaction(TransactionModel model) async {
    final newId = model.id ?? const Uuid().v4();
    final modelWithId = model.id == null
        ? model.copyWith(
            id: newId,
            ownerId: ownerId,
            budgetId: budgetId,
          )
        : model;

    if (userId == null) {
      await _db.into(_db.transactions).insert(modelWithId.toCompanion());
    } else {
      await supabase.from('transactions').insert(modelWithId.toMap());
    }

    return modelWithId.id!;
  }

  Future<void> updateTransaction(String id, TransactionModel model) async {
    final updatedModel = model.copyWith(
      id: id,
      ownerId: ownerId,
      budgetId: budgetId,
      updatedAt: DateTime.now(),
    );
    if (userId == null) {
      await (_db.update(_db.transactions)..where((t) => t.id.equals(id)))
          .write(updatedModel.toCompanion());
    } else {
      await supabase.from('transactions').update(updatedModel.toMap()).eq('id', id);
    }
  }

  Future<void> deleteTransaction(String id) async {
    if (userId == null) {
      await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
    } else {
      await supabase.from('transactions').delete().eq('id', id);
    }
  }

  Future<void> syncTransactions() async {
    final localData = await _db.select(_db.transactions).get();
    final transactionModel = localData.map(TransactionModel.fromDriftRow).toList();

    for (final model in transactionModel) {
      final uploadModel = model.copyWith(
        ownerId: ownerId,
        budgetId: budgetId,
      );
      await supabase.from('transactions').insert(uploadModel.toMap());
    }
  }
}
