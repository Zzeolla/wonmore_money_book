// lib/service/transaction_service.dart
import 'package:drift/drift.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';

class TransactionService {
  final AppDatabase _db;
  final String? userId;

  TransactionService(this._db, this.userId);

  Future<bool> hasAnyTransactions() async {
    final query = _db.select(_db.transactions)..limit(1);
    final result = await query.get();
    return result.isNotEmpty;
  }

  Future<List<Transaction>> getTransactionsByPeriod(DateTime start, DateTime end) async {
    final query = _db.select(_db.transactions)
      ..where((t) => t.date.isBetweenValues(start, end));
    if (userId != null) {
      query.where((t) => t.userId.equals(userId!));
    }
    return await query.get();
  }

  Future<List<Transaction>> getTransactionsByDate(DateTime date) async {
    final query = _db.select(_db.transactions)
      ..where((t) => t.date.equals(date));
    if (userId != null) {
      query.where((t) => t.userId.equals(userId!));
    }
    return await query.get();
  }

  Future<int> addTransaction(TransactionsCompanion tx) async {
    final txWithUser = tx.copyWith(
      userId: Value(userId),
      createdBy: Value(userId),
      updatedBy: Value(userId),
    );
    return await _db.into(_db.transactions).insert(txWithUser);
  }

  Future<void> updateTransaction(int id, TransactionsCompanion tx) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id)))
        .write(tx.copyWith(
      updatedAt: Value(DateTime.now()),
      updatedBy: Value(userId),
    ));
  }

  Future<void> deleteTransaction(int id) async {
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }
}
