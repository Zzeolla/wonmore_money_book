// lib/service/favorite_record_service.dart
import 'package:drift/drift.dart';
import 'package:wonmore_money_book/database/database.dart';

class FavoriteRecordService {
  final AppDatabase _db;
  final String? userId;

  FavoriteRecordService(this._db, this.userId);

  Future<List<FavoriteRecord>> loadFavoriteRecords() async {
    final query = _db.select(_db.favoriteRecords);
    // if (userId != null) {
    //   query.where((a) => a.userId.equals(userId!));
    // }
    return await query.get();
  }

  Future<void> addFavoriteRecord(FavoriteRecordsCompanion record) async {
    final recordWithUser = record.copyWith(
      // userId: Value(userId),
      // createdBy: Value(userId),
      // updatedBy: Value(userId),
    );

    await _db.into(_db.favoriteRecords).insert(recordWithUser);
  }

  Future<void> updateFavoriteRecord(int id, FavoriteRecordsCompanion record) async {
    await (_db.update(_db.favoriteRecords)..where((c) => c.id.equals(id)))
        .write(record.copyWith(
      updatedAt: Value(DateTime.now()),
      // updatedBy: Value(userId),
    ));
  }

  Future<void> deleteFavoriteRecord(int id) async {
    await (_db.delete(_db.favoriteRecords)..where((t) => t.id.equals(id))).go();
  }
}
