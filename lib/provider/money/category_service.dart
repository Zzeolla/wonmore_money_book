// lib/service/category_service.dart
import 'package:drift/drift.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';

class CategoryService {
  final AppDatabase _db;
  final String? userId;

  CategoryService(this._db, this.userId);

  Future<List<Category>> getAllCategories() async {
    final query = _db.select(_db.categories)
      ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]);
    // if (userId != null) {
    //   query.where((c) => c.userId.equals(userId!));
    // }
    return await query.get();
  }

  Future<List<Category>> getMainCategories(TransactionType type) async {
    final query = _db.select(_db.categories)
      ..where((c) => c.type.equals(type.name));
    return await query.get();
  }

  Future<void> addCategory(CategoriesCompanion category) async {
    final nextOrder = await _db.getNextCategorySortOrder(category.type.value);
    final categoryWithUser = category.copyWith(
      sortOrder: Value(nextOrder),
      // userId: Value(userId),
      createdBy: Value(userId),
      updatedBy: Value(userId),
    );
    await _db.into(_db.categories).insert(categoryWithUser);
  }

  Future<void> updateCategory(Category category) async {
    await (_db.update(_db.categories)
      ..where((c) => c.id.equals(category.id)))
        .write(CategoriesCompanion(
      name: Value(category.name),
      type: Value(category.type),
      iconName: Value(category.iconName),
      colorValue: Value(category.colorValue),
      updatedAt: Value(DateTime.now()),
      updatedBy: Value(userId),
    ));
  }

  Future<void> deleteCategory(int id) async {
    await (_db.delete(_db.categories)
      ..where((c) => c.id.equals(id)))
        .go();
  }

  Future<void> reorderCategories(List<Category> reorderedList) async {
    await _db.reorderCategories(reorderedList);
  }
}
