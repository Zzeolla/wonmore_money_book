// lib/service/asset_service.dart
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/model/asset_model.dart';

class AssetService {
  final AppDatabase _db;
  final String? userId;
  final String? ownerId;
  final SupabaseClient supabase = Supabase.instance.client;

  AssetService(this._db, this.userId, this.ownerId);

  Future<List<AssetModel>> getAssets() async {
    if (userId == null) {
      final localAsset = await _db.select(_db.assets).get();
      return localAsset.map(AssetModel.fromDriftRow).toList();
    } else {
      final response = await supabase
          .from('assets')
          .select()
          .eq('owner_id', ownerId!);

      return response.map(AssetModel.fromJson).toList();
    }
  }

  Future<void> addAsset(String name, int targetAmount) async {
    final assetModel = AssetModel(
      id: const Uuid().v4(),
      name: name,
      targetAmount: targetAmount,
      ownerId: ownerId,
    );
    if (userId == null) {
      await _db.into(_db.assets).insert(assetModel.toCompanion());
    } else {
      await supabase.from('assets').insert(assetModel.toMap());
    }
  }

  Future<void> updateAsset(String id, String name, int targetAmount) async {
    if (userId == null) {
      await (_db.update(_db.assets)..where((a) => a.id.equals(id))).write(
        AssetsCompanion(
          name: Value(name),
          targetAmount: Value(targetAmount),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } else {
      await supabase
          .from('assets')
          .update({
            'name': name,
            'target_amount': targetAmount,
          })
          .eq('id', id);
    }
  }

  Future<void> deleteAsset(String id) async {
    if (userId == null) {
      await (_db.delete(_db.assets)..where((a) => a.id.equals(id))).go();
    } else {
      await supabase
          .from('assets')
          .delete()
          .eq('id', id);
    }
  }

  Future<void> syncAssets() async {
    final localData = await _db.select(_db.assets).get();
    final response = await supabase.from('assets').select().eq('owner_id', ownerId!);
    final supabaseNames = response.map((item) => AssetModel.fromJson(item).name).toSet();
    final modelsToUpload = localData
        .where((a) => !supabaseNames.contains(a.name))
        .map((a) => AssetModel.fromDriftRow(a))
        .toList();


    for (final model in modelsToUpload) {
      final uploadModel = model.copyWith(
        ownerId: ownerId,
      );
      await supabase.from('assets').insert(uploadModel.toMap());
    }
  }
}
