import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiwu/services/api_service.dart';
import 'package:xiwu/services/auth_service.dart';
import 'package:xiwu/services/database_service.dart';
import 'package:xiwu/models/asset_item.dart';
import 'package:xiwu/models/sync_queue_item.dart';

class SyncEngine extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();
  final AuthService _authService = Get.find<AuthService>();
  final DatabaseService _dbService = Get.find<DatabaseService>();

  final RxBool isSyncing = false.obs;
  late SharedPreferences _prefs;

  Future<SyncEngine> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // 如果已登录，启动时触发一次同步
    if (_authService.isLoggedIn.value) {
      sync();
    }
    
    // 监听登录状态变化
    ever(_authService.isLoggedIn, (isLogged) {
      if (isLogged) {
        sync();
      } else {
        // 登出时可以考虑清理队列或最后同步时间
        _prefs.remove('last_sync_at');
      }
    });

    return this;
  }

  Future<void> sync() async {
    if (isSyncing.value || !_authService.isLoggedIn.value) return;
    
    isSyncing.value = true;
    try {
      final lastSyncStr = _prefs.getString('last_sync_at');
      
      // 1. 推送本地队列 (Push)
      final queueItems = _dbService.syncBox.values.toList();
      if (queueItems.isNotEmpty) {
        await _pushChanges(queueItems);
      }

      // 2. 拉取云端变更 (Pull / Full)
      if (lastSyncStr != null) {
        await _pullChanges(DateTime.parse(lastSyncStr));
      } else {
        await _fullSync();
      }
    } catch (e) {
      print('Sync failed: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> _pushChanges(List<SyncQueueItem> items) async {
    final changes = items.map((item) => {
      'action': item.action.name,
      'client_id': item.clientId,
      'server_id': item.serverId,
      'data': item.data,
      'client_updated_at': item.clientUpdatedAt.toIso8601String(),
    }).toList();

    final response = await _apiService.dio.post('/sync/push', data: {
      'changes': changes,
      'last_sync_at': _prefs.getString('last_sync_at'),
    });

    if (response.statusCode == 200) {
      final data = response.data;
      
      // 更新本地的 server_id 映射
      for (var mapping in data['id_mappings']) {
        final int clientId = mapping['client_id'];
        final String serverId = mapping['server_id'];
        
        final asset = _dbService.assetBox.get(clientId);
        if (asset != null) {
          asset.serverId = serverId;
          asset.save();
        }
      }

      // 清理已推送的队列
      await _dbService.syncBox.clear();
      
      // 更新上次同步时间
      await _prefs.setString('last_sync_at', data['server_time']);
    }
  }

  Future<void> _pullChanges(DateTime since) async {
    final response = await _apiService.dio.get('/sync/pull', queryParameters: {
      'since': since.toIso8601String(),
    });

    if (response.statusCode == 200) {
      final data = response.data;
      final List changes = data['changes'];
      
      for (var change in changes) {
        final String action = change['action'];
        final int clientId = change['client_id'];
        final Map<String, dynamic>? itemData = change['data'];

        if (action == 'delete') {
          // 只把本地对应的数据硬删除即可（避免再次推入同步队列，绕开 deleteAsset 方法）
          if (_dbService.assetBox.containsKey(clientId)) {
            await _dbService.assetBox.delete(clientId);
          }
        } else if (action == 'update' || action == 'create') {
          // 根据 server_id 或 client_id 找到本地项
          var localItem = _dbService.assetBox.get(clientId);
          
          if (localItem != null) {
            // 更新现有项，但不触发 _recordSync
            _applyDataToAsset(localItem, itemData!);
            localItem.serverId = change['server_id'];
            localItem.updatedAt = DateTime.parse(change['updated_at']);
            await localItem.save();
          } else {
            // 在本地新建项，使用给定的 client_id
            final newItem = AssetItem(
              id: clientId,
              name: itemData!['name'],
              emojiIcon: itemData['emoji_icon'],
              category: _parseCategory(itemData['category']),
              buyPrice: (itemData['buy_price'] as num).toDouble(),
              buyDate: DateTime.parse(itemData['buy_date']),
              currentValue: (itemData['current_value'] as num).toDouble(),
              depreciationModel: _parseDepreciation(itemData['depreciation_model']),
              status: _parseStatus(itemData['status']),
              serverId: change['server_id'],
              updatedAt: DateTime.parse(change['updated_at']),
              sortOrder: itemData['sort_order'] ?? 0,
            );
            await _dbService.assetBox.put(clientId, newItem);
          }
        }
      }
      
      await _prefs.setString('last_sync_at', data['server_time']);
    }
  }

  Future<void> _fullSync() async {
    final response = await _apiService.dio.get('/sync/full');
    
    if (response.statusCode == 200) {
      final data = response.data;
      final List items = data['items'];
      
      // 清空本地数据，以云端为准
      // TODO: 生产环境可能需要更安全的合并策略
      await _dbService.assetBox.clear();
      
      for (var itemData in items) {
        final int clientId = itemData['client_id'];
        final newItem = AssetItem(
          id: clientId,
          name: itemData['name'],
          emojiIcon: itemData['emoji_icon'],
          category: _parseCategory(itemData['category']),
          buyPrice: (itemData['buy_price'] as num).toDouble(),
          buyDate: DateTime.parse(itemData['buy_date']),
          currentValue: (itemData['current_value'] as num).toDouble(),
          depreciationModel: _parseDepreciation(itemData['depreciation_model']),
          status: _parseStatus(itemData['status']),
          serverId: itemData['id'],
          updatedAt: DateTime.parse(itemData['updated_at']),
          sortOrder: itemData['sort_order'] ?? 0,
        );
        await _dbService.assetBox.put(clientId, newItem);
      }
      
      await _prefs.setString('last_sync_at', data['server_time']);
    }
  }

  // 辅助解析枚举方法
  AssetCategory _parseCategory(String catStr) {
    return AssetCategory.values.firstWhere((e) => e.name == catStr, orElse: () => AssetCategory.other);
  }
  
  DepreciationModel _parseDepreciation(String modStr) {
    return DepreciationModel.values.firstWhere((e) => e.name == modStr, orElse: () => DepreciationModel.modelA_Linear);
  }
  
  ItemStatus _parseStatus(String statStr) {
    return ItemStatus.values.firstWhere((e) => e.name == statStr, orElse: () => ItemStatus.active);
  }

  void _applyDataToAsset(AssetItem asset, Map<String, dynamic> data) {
    asset.name = data['name'];
    asset.emojiIcon = data['emoji_icon'];
    asset.category = _parseCategory(data['category']);
    asset.buyPrice = (data['buy_price'] as num).toDouble();
    asset.buyDate = DateTime.parse(data['buy_date']);
    asset.currentValue = (data['current_value'] as num).toDouble();
    asset.depreciationModel = _parseDepreciation(data['depreciation_model']);
    asset.status = _parseStatus(data['status']);
    asset.sellPrice = data['sell_price'] != null ? (data['sell_price'] as num).toDouble() : null;
    asset.sellDate = data['sell_date'] != null ? DateTime.parse(data['sell_date']) : null;
    asset.note = data['note'];
    asset.expiryDate = data['expiry_date'] != null ? DateTime.parse(data['expiry_date']) : null;
    asset.sortOrder = data['sort_order'] ?? 0;
  }
}
