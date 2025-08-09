// lib/service/category_service.dart
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/model/category_model.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';

class CategoryService {
  final AppDatabase _db;
  final String? userId;
  final String? ownerId;
  final SupabaseClient supabase = Supabase.instance.client;

  RealtimeChannel? _realtimeChannel;

  CategoryService(this._db, this.userId, this.ownerId);

  Future<List<CategoryModel>> getAllCategories() async {
    if (userId == null) {
      final query = _db.select(_db.categories)
        ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]);
      final localCategory = await query.get();
      return localCategory.map(CategoryModel.fromDriftRow).toList();
    } else {
      final response = await supabase.from('categories').select().eq('owner_id', ownerId!)
          .order('sort_order', ascending: true);
      return response.map(CategoryModel.fromJson).toList();
    }
  }

  Future<List<CategoryModel>> getMainCategories(TransactionType type) async {
    if (userId == null) {
      final query = _db.select(_db.categories)..where((c) => c.type.equals(type.name));
      final localCategory = await query.get();
      return localCategory.map(CategoryModel.fromDriftRow).toList();
    } else {
      final response = await supabase.from('categories').select().eq('owner_id', ownerId!)
          .eq('type', type.name).order('sort_order', ascending: true);
      return response.map(CategoryModel.fromJson).toList();
    }
  }

  Future<void> addCategory(CategoryModel model) async {
    final newId = model.id ?? const Uuid().v4();
    final nextOrder = await getNextCategorySortOrder(model.type);
    final modelWithId = model.id == null ? model.copyWith(
      id: newId,
      sortOrder: nextOrder,
      ownerId: ownerId,
    ) : model;

    if (userId == null) {
      await _db.into(_db.categories).insert(modelWithId.toCompanion());
    } else {
      await supabase.from('categories').insert(modelWithId.toMap());
    }
  }

  Future<void> updateCategory(CategoryModel model) async {
    final updatedModel = model.copyWith(
      ownerId: ownerId,
      updatedAt: DateTime.now(),
    );

    if (userId == null) {
      await (_db.update(_db.categories)..where((c) => c.id.equals(model.id!)))
          .write(updatedModel.toCompanion());
    } else {
      await supabase.from('categories').update(updatedModel.toMap()).eq('id', model.id!);
    }
  }

  Future<void> deleteCategory(String id) async {
    if (userId == null) {
      await (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
    } else {
      await supabase.from('categories').delete().eq('id', id);
    }
  }

  Future<void> reorderCategories(List<CategoryModel> reorderedList) async {
    if (userId == null) {
      // 로컬 DB에 반영
      await _db.batch((batch) {
        for (int i = 0; i < reorderedList.length; i++) {
          final updatedModel = reorderedList[i].copyWith(
            sortOrder: i,
            updatedAt: DateTime.now(),
          );
          batch.update(
            _db.categories,
            updatedModel.toCompanion(),
            where: (c) => c.id.equals(updatedModel.id!),
          );
        }
      });
    } else {
      // Supabase에 반영
      for (int i = 0; i < reorderedList.length; i++) {
        final model = reorderedList[i];
        await supabase
            .from('categories')
            .update({'sort_order': i})
            .eq('id', model.id!)
            .eq('owner_id', ownerId!);
      }
    }
  }

  Future<void> syncCategories() async {
    final localData = await _db.select(_db.categories).get();
    final response = await supabase.from('categories').select().eq('owner_id', ownerId!);
    final supabaseNames = response.map((item) => CategoryModel.fromJson(item).name).toSet();
    final modelsToUpload = localData
        .where((a) => !supabaseNames.contains(a.name))
        .map((a) => CategoryModel.fromDriftRow(a))
        .toList();


    for (final model in modelsToUpload) {
      final uploadModel = model.copyWith(
        ownerId: ownerId,
      );
      await supabase.from('categories').insert(uploadModel.toMap());
    }
  }

  Future<int> getNextCategorySortOrder(TransactionType type) async {
    if (userId == null) {
      final maxOrder = await _db.getMaxSortOrderByType(type);
      return maxOrder + 1;
    } else {
      final response = await supabase
          .from('categories')
          .select('sort_order')
          .eq('type', type.name)
          .eq('owner_id', ownerId!)
          .order('sort_order', ascending: false)
          .limit(1);

      final maxSortOrder = response.isNotEmpty
          ? (response.first['sort_order'] as int? ?? 0)
          : 0;

      return maxSortOrder + 1;
    }
  }
}
