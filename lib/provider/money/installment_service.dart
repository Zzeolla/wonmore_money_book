// lib/service/installment_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/model/installment_model.dart';
import 'package:wonmore_money_book/model/transaction_model.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';

class InstallmentService {
  final AppDatabase _db;
  final String? userId;
  final String? ownerId;
  final String? budgetId;
  final SupabaseClient supabase = Supabase.instance.client;

  InstallmentService(this._db, this.userId, this.ownerId, this.budgetId);

  Future<void> addInstallment(InstallmentModel model) async {
    final newId = model.id ?? const Uuid().v4();
    final modelWithId = model.id == null
        ? model.copyWith(
      id: newId,
      ownerId: ownerId,
      budgetId: budgetId,
    )
        : model;

    if (userId == null) {
      await _db.into(_db.installments).insert(modelWithId.toCompanion());
    } else {
      await supabase.from('installments').insert(modelWithId.toMap());
    }

    await _createTransactionsFromInstallment(newId, modelWithId);
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
  Future<void> updateInstallment(String id, InstallmentModel model) async {
    final updatedModel = model.copyWith(
      id: id,
      ownerId: ownerId,
      budgetId: budgetId,
      updatedAt: DateTime.now(),
    );
    if (userId == null) {
      await (_db.delete(_db.transactions)..where((t) => t.installmentId.equals(id))).go();
      await (_db.update(_db.installments)..where((i) => i.id.equals(id))).write(updatedModel.toCompanion());
    } else {
      await supabase.from('transactions').delete().eq('installment_id', id);
      await supabase.from('installments').update(updatedModel.toMap()).eq('id', id);
    }
    await _createTransactionsFromInstallment(id, updatedModel);
  }

  Future<void> deleteInstallment(String id) async {
    if (userId == null) {
      await (_db.delete(_db.transactions)..where((t) => t.installmentId.equals(id))).go();
      await (_db.delete(_db.installments)..where((i) => i.id.equals(id))).go();
    } else {
      await supabase.from('transactions').delete().eq('installment_id', id);
      await supabase.from('installments').delete().eq('id', id);
    }
  }

  Future<void> syncInstallments() async {
    final localData = await _db.select(_db.installments).get();
    final installmentModel = localData.map(InstallmentModel.fromDriftRow).toList();

    for (final model in installmentModel) {
      final uploadModel = model.copyWith(
        ownerId: ownerId,
        budgetId: budgetId,
      );
      await supabase.from('favorite_records').insert(uploadModel.toMap());
    }
  }

  Future<void> _createTransactionsFromInstallment(
    String installmentId,
    InstallmentModel installment,
  ) async {
    final months = installment.months;
    final totalAmount = installment.totalAmount;
    final title = installment.title;
    final startDate = installment.date;

    final baseAmount = totalAmount ~/ months;
    final remainder = totalAmount % months;

    for (int i = 0; i < months; i++) {
      final amount = i == 0 ? baseAmount + remainder : baseAmount;
      final date = _calculateInstallmentDate(startDate, i);

      final transaction = TransactionModel(
        id: const Uuid().v4(),
        date: date,
        amount: amount,
        type: TransactionType.expense,
        categoryId: installment.categoryId,
        assetId: installment.assetId,
        title: '$title (${i + 1}/$months)',
        memo: installment.memo,
        installmentId: installmentId,
        ownerId: ownerId,
        budgetId: budgetId,
      );

      if (userId == null) {
        await _db.into(_db.transactions).insert(transaction.toCompanion());
      } else {
        await supabase.from('transactions').insert(transaction.toMap());
      }
    }
  }

  DateTime _calculateInstallmentDate(DateTime baseDate, int offset) {
    final year = baseDate.year;
    final month = baseDate.month + offset;
    final tentative = DateTime(year, month, 1, baseDate.hour, baseDate.minute);
    final lastDay = DateTime(tentative.year, tentative.month + 1, 0).day;
    final day = baseDate.day > lastDay ? lastDay : baseDate.day;

    return DateTime(tentative.year, tentative.month, day, baseDate.hour, baseDate.minute);
  }
}
