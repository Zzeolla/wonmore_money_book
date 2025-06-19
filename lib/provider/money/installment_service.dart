// lib/service/installment_service.dart
import 'package:drift/drift.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';

class InstallmentService {
  final AppDatabase _db;
  final String? userId;

  InstallmentService(this._db, this.userId);

  Future<void> addInstallment(InstallmentsCompanion installment) async {
    final installmentWithUser = installment.copyWith(
      userId: Value(userId),
      createdBy: Value(userId),
      updatedBy: Value(userId),
    );

    final installmentId =
    await _db.into(_db.installments).insert(installmentWithUser);

    await _createTransactionsFromInstallment(installmentId, installmentWithUser);
  }

  Future<void> updateInstallment(int id, InstallmentsCompanion installment) async {
    await (_db.delete(_db.transactions)
      ..where((t) => t.installmentId.equals(id)))
        .go();

    await (_db.update(_db.installments)
      ..where((i) => i.id.equals(id)))
        .write(installment.copyWith(
      updatedAt: Value(DateTime.now()),
      updatedBy: Value(userId),
    ));

    await _createTransactionsFromInstallment(id, installment);
  }

  Future<void> deleteInstallment(int id) async {
    await (_db.delete(_db.transactions)
      ..where((t) => t.installmentId.equals(id)))
        .go();

    await (_db.delete(_db.installments)
      ..where((i) => i.id.equals(id)))
        .go();
  }

  Future<void> _createTransactionsFromInstallment(
      int installmentId,
      InstallmentsCompanion installment,
      ) async {
    final months = installment.months.value;
    final totalAmount = installment.totalAmount.value;
    final title = installment.title.value;
    final startDate = installment.date.value;

    final baseAmount = totalAmount ~/ months;
    final remainder = totalAmount % months;

    for (int i = 0; i < months; i++) {
      final amount = i == 0 ? baseAmount + remainder : baseAmount;
      final date = _calculateInstallmentDate(startDate, i);

      await _db.into(_db.transactions).insert(
        TransactionsCompanion(
          date: Value(date),
          amount: Value(amount),
          type: Value(TransactionType.expense),
          categoryId: installment.categoryId,
          assetId: installment.assetId,
          title: Value('$title (${i + 1}/$months)'),
          memo: installment.memo,
          installmentId: Value(installmentId),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
          userId: Value(userId),
          createdBy: Value(userId),
          updatedBy: Value(userId),
        ),
      );
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
