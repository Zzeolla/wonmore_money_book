// lib/service/favorite_record_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/model/favorite_record_model.dart';

class FavoriteRecordService {
  final AppDatabase _db;
  final String? userId;
  final String? ownerId;
  final String? budgetId;
  final SupabaseClient supabase = Supabase.instance.client;

  FavoriteRecordService(this._db, this.userId, this.ownerId, this.budgetId);

  Future<List<FavoriteRecordModel>> loadFavoriteRecords() async {
    if (userId == null) {
      final localFavoriteRecord = await _db.select(_db.favoriteRecords).get();
      return localFavoriteRecord.map(FavoriteRecordModel.fromDriftRow).toList();
    } else {
      final response = await supabase
          .from('favorite_records')
          .select()
          .or(
          'and(period.eq.none,created_by.eq.$userId,owner_id.eq.$ownerId),and(period.neq.none,owner_id.eq.$ownerId,budget_id.eq.$budgetId)'
      );

      return response.map(FavoriteRecordModel.fromJson).toList();
    }
  }

  Future<String> addFavoriteRecord(FavoriteRecordModel model) async {
    final newId = model.id ?? const Uuid().v4();
    final modelWithId = model.id == null
        ? model.copyWith(
      id: newId,
      ownerId: ownerId,
      budgetId: budgetId,
    ) : model;

    if (userId == null) {
      await _db.into(_db.favoriteRecords).insert(modelWithId.toCompanion());
    } else {
      await supabase.from('favorite_records').insert(modelWithId.toMap());
    }

    return newId;
  }

  Future<void> updateFavoriteRecord(String id, FavoriteRecordModel model) async {
    final updatedModel = model.copyWith(
      id: id,
      ownerId: ownerId,
      budgetId: budgetId,
      updatedAt: DateTime.now(),
    );
    if (userId == null) {
      await (_db.update(_db.favoriteRecords)..where((c) => c.id.equals(id)))
          .write(updatedModel.toCompanion());
    } else {
      await supabase.from('favorite_records').update(updatedModel.toMap()).eq('id', id);
    }
  }

  Future<void> deleteFavoriteRecord(String id) async {
    if (userId == null) {
      await (_db.delete(_db.favoriteRecords)..where((t) => t.id.equals(id))).go();
    } else {
      await supabase.from('favorite_records').delete().eq('id', id);
    }
  }

  Future<void> syncFavoriteRecords() async {
    final localData = await _db.select(_db.favoriteRecords).get();
    final favoriteRecordModel = localData.map(FavoriteRecordModel.fromDriftRow).toList();

    for (final model in favoriteRecordModel) {
      final uploadModel = model.copyWith(
        ownerId: ownerId,
        budgetId: budgetId,
      );
      await supabase.from('favorite_records').insert(uploadModel.toMap());
    }
  }
}
