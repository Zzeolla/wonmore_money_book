// lib/service/asset_service.dart
import 'package:drift/drift.dart';
import 'package:wonmore_money_book/database/database.dart';

class AssetService {
  final AppDatabase _db;
  final String? userId;

  AssetService(this._db, this.userId);

  Future<List<Asset>> getAssets() async {
    final query = _db.select(_db.assets);
    if (userId != null) {
      query.where((a) => a.userId.equals(userId!));
    }
    return await query.get();
  }

  Future<void> addAsset(String name, int targetAmount) async {
    final assetWithUser = AssetsCompanion(
      name: Value(name),
      targetAmount: Value(targetAmount),
      userId: Value(userId),
      createdBy: Value(userId),
      updatedBy: Value(userId),
    );
    await _db.into(_db.assets).insert(assetWithUser);
  }

  Future<void> updateAsset(int id, String name, int targetAmount) async {
    await (_db.update(_db.assets)..where((a) => a.id.equals(id))).write(
      AssetsCompanion(
        name: Value(name),
        targetAmount: Value(targetAmount),
        updatedAt: Value(DateTime.now()),
        updatedBy: Value(userId),
      ),
    );
  }

  Future<void> deleteAsset(int id) async {
    await (_db.delete(_db.assets)..where((a) => a.id.equals(id))).go();
  }
}
