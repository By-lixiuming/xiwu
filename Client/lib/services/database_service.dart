import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:xiwu/models/asset_item.dart';
import 'package:xiwu/models/sync_queue_item.dart';

class DatabaseService extends GetxService {
  late Box<AssetItem> _assetBox;
  late Box<SyncQueueItem> _syncBox;
  final _uuid = const Uuid();

  Box<AssetItem> get assetBox => _assetBox;
  Box<SyncQueueItem> get syncBox => _syncBox;

  Future<DatabaseService> init() async {
    // Register adapters
    Hive.registerAdapter(AssetCategoryAdapter());
    Hive.registerAdapter(DepreciationModelAdapter());
    Hive.registerAdapter(ItemStatusAdapter());
    Hive.registerAdapter(AssetItemAdapter());
    Hive.registerAdapter(SyncActionAdapter());
    Hive.registerAdapter(SyncQueueItemAdapter());

    // Open boxes
    _assetBox = await Hive.openBox<AssetItem>('assets');
    _syncBox = await Hive.openBox<SyncQueueItem>('sync_queue');
    return this;
  }

  List<AssetItem> getAllAssets() {
    return _assetBox.values.toList();
  }

  Future<void> addAsset(AssetItem item) async {
    // Generate a simple int ID using the highest current ID + 1
    final newId = (_assetBox.isEmpty ? 0 : _assetBox.values.map((e) => e.id).reduce((a, b) => a > b ? a : b)) + 1;
    item.id = newId;
    
    // 如果没有 updatedAt，补充上
    item.updatedAt ??= DateTime.now().toUtc();

    await _assetBox.put(newId, item);
    await _recordSync(SyncAction.create, item);
  }

  Future<void> updateAsset(AssetItem item) async {
    item.updatedAt = DateTime.now().toUtc();
    await _assetBox.put(item.id, item);
    await _recordSync(SyncAction.update, item);
  }

  Future<void> deleteAsset(int id) async {
    final item = _assetBox.get(id);
    if (item != null) {
      // 本地软删除
      item.isDeleted = true;
      item.deletedAt = DateTime.now().toUtc();
      item.updatedAt = DateTime.now().toUtc();
      await _assetBox.put(id, item); // 保存软删除状态，以便后续查阅或全量清空
      
      await _recordSync(SyncAction.delete, item);
    }
  }

  /// 批量更新所有物品（用于排序持久化）
  Future<void> updateAllAssets(List<AssetItem> items) async {
    final now = DateTime.now().toUtc();
    for (var item in items) {
      item.updatedAt = now;
      await _assetBox.put(item.id, item);
      await _recordSync(SyncAction.update, item);
    }
  }

  /// 记录同步队列
  Future<void> _recordSync(SyncAction action, AssetItem item) async {
    final syncItem = SyncQueueItem(
      id: _uuid.v4(),
      action: action,
      clientId: item.id,
      serverId: item.serverId,
      clientUpdatedAt: item.updatedAt ?? DateTime.now().toUtc(),
      data: action != SyncAction.delete ? {
        'name': item.name,
        'emoji_icon': item.emojiIcon,
        'category': item.category.name,
        'buy_price': item.buyPrice,
        'buy_date': item.buyDate.toIso8601String().split('T').first,
        'current_value': item.currentValue,
        'depreciation_model': item.depreciationModel.name,
        'status': item.status.name,
        'sell_price': item.sellPrice,
        'sell_date': item.sellDate?.toIso8601String().split('T').first,
        'note': item.note,
        'expiry_date': item.expiryDate?.toIso8601String().split('T').first,
        'sort_order': item.sortOrder,
      } : null,
    );
    
    await _syncBox.put(syncItem.id, syncItem);
  }
}
