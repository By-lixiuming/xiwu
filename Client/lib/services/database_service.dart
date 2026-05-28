import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:xiwu/models/asset_item.dart';

class DatabaseService extends GetxService {
  late Box<AssetItem> _assetBox;

  Future<DatabaseService> init() async {
    // Register adapters
    Hive.registerAdapter(AssetCategoryAdapter());
    Hive.registerAdapter(DepreciationModelAdapter());
    Hive.registerAdapter(ItemStatusAdapter());
    Hive.registerAdapter(AssetItemAdapter());

    // Open box
    _assetBox = await Hive.openBox<AssetItem>('assets');
    return this;
  }

  List<AssetItem> getAllAssets() {
    return _assetBox.values.toList();
  }

  Future<void> addAsset(AssetItem item) async {
    // Generate a simple int ID using the highest current ID + 1 or timestamp
    final newId = (_assetBox.isEmpty ? 0 : _assetBox.values.map((e) => e.id).reduce((a, b) => a > b ? a : b)) + 1;
    item.id = newId;
    await _assetBox.put(newId, item);
  }

  Future<void> updateAsset(AssetItem item) async {
    await _assetBox.put(item.id, item);
  }

  Future<void> deleteAsset(int id) async {
    await _assetBox.delete(id);
  }

  /// 批量更新所有物品（用于排序持久化）
  Future<void> updateAllAssets(List<AssetItem> items) async {
    for (var item in items) {
      await _assetBox.put(item.id, item);
    }
  }
}
