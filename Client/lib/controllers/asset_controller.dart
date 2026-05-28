import 'package:get/get.dart';
import 'package:xiwu/models/asset_item.dart';
import 'package:xiwu/services/database_service.dart';

class AssetController extends GetxController {
  final DatabaseService _db = Get.find<DatabaseService>();

  final RxList<AssetItem> assets = <AssetItem>[].obs;

  // 看板详情显示开关
  final RxBool isDetailVisible = true.obs;

  // 列表视图模式：false=单列, true=双列网格
  final RxBool isGridView = false.obs;

  void toggleDetailVisible() {
    isDetailVisible.value = !isDetailVisible.value;
  }

  void toggleGridView() {
    isGridView.value = !isGridView.value;
  }

  @override
  void onInit() {
    super.onInit();
    loadAssets();
  }

  void loadAssets() {
    final rawAssets = _db.getAllAssets();
    // Re-calculate current values dynamically based on time
    for (var asset in rawAssets) {
      if (asset.status == ItemStatus.active) {
        asset.currentValue = _calculateCurrentValue(asset);
        // We do not save this to DB every time to save writes, but we could.
        // It's calculated in-memory for display.
      }
    }
    // 按 sortOrder 排序
    rawAssets.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    assets.assignAll(rawAssets);
  }

  Future<void> addAsset(AssetItem asset) async {
    // 新物品排在最后
    asset.sortOrder = assets.isEmpty ? 0 : assets.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
    await _db.addAsset(asset);
    loadAssets();
  }

  Future<void> updateAsset(AssetItem asset) async {
    await _db.updateAsset(asset);
    loadAssets();
  }

  Future<void> deleteAsset(int id) async {
    await _db.deleteAsset(id);
    loadAssets();
  }

  /// 重新排序物品（拖拽排序后调用）
  Future<void> reorderAssets(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = assets.removeAt(oldIndex);
    assets.insert(newIndex, item);
    // 更新所有物品的 sortOrder
    for (int i = 0; i < assets.length; i++) {
      assets[i].sortOrder = i;
    }
    // 批量持久化
    await _db.updateAllAssets(assets);
    assets.refresh();
  }

  /// 恢复物品为服役中状态
  Future<void> reactivateAsset(AssetItem asset) async {
    asset.status = ItemStatus.active;
    asset.sellPrice = null;
    asset.sellDate = null;
    await _db.updateAsset(asset);
    loadAssets();
  }

  // --- Calculation Logic ---

  double _calculateCurrentValue(AssetItem asset) {
    final now = DateTime.now();
    final daysOwned = now.difference(asset.buyDate).inDays;
    
    if (daysOwned <= 0) return asset.buyPrice;

    double calculatedValue = asset.buyPrice;

    switch (asset.depreciationModel) {
      case DepreciationModel.modelA_Linear:
        // 直线归零: Assume 3 years (1095 days) lifespan for MVP
        const lifespan = 1095.0;
        final dailyDrop = asset.buyPrice / lifespan;
        calculatedValue = asset.buyPrice - (dailyDrop * daysOwned);
        if (calculatedValue < 0) calculatedValue = 0;
        break;
      case DepreciationModel.modelB_DropAndDecay:
        // 落地打折: 20% drop immediately, then 15% per year (365 days)
        final dropValue = asset.buyPrice * 0.8;
        final yearsOwned = daysOwned / 365.0;
        calculatedValue = dropValue * (1 - (0.15 * yearsOwned));
        if (calculatedValue < 0) calculatedValue = 0;
        break;
      case DepreciationModel.modelC_SlowDecay:
        // 缓慢折旧: Max drop to 50% over 5 years (1825 days)
        const lifespan = 1825.0;
        final dropTo = asset.buyPrice * 0.5;
        final maxDropAmount = asset.buyPrice - dropTo;
        final dailyDrop = maxDropAmount / lifespan;
        calculatedValue = asset.buyPrice - (dailyDrop * daysOwned);
        if (calculatedValue < dropTo) calculatedValue = dropTo;
        break;
    }
    return calculatedValue;
  }

  double getDailyCost(AssetItem asset) {
    int days;
    if (asset.status == ItemStatus.archived) {
      // 已出掉：日均成本 = (买入价格 - 卖出价格) / 持有天数
      if (asset.sellDate == null) return 0.0;
      days = asset.sellDate!.difference(asset.buyDate).inDays;
      if (days <= 0) return 0.0;
      final netCost = asset.buyPrice - (asset.sellPrice ?? 0);
      return netCost / days;
    } else if (asset.expiryDate != null) {
      // 有到期时间：从购买日到到期日
      days = asset.expiryDate!.difference(asset.buyDate).inDays;
    } else {
      // 无到期时间：从购买日到当前日期
      days = DateTime.now().difference(asset.buyDate).inDays;
    }
    if (days <= 0) return 0.0;
    return asset.buyPrice / days;
  }

  int getDaysOwned(AssetItem asset) {
    if (asset.status != ItemStatus.active && asset.sellDate != null) {
      return asset.sellDate!.difference(asset.buyDate).inDays;
    }
    return DateTime.now().difference(asset.buyDate).inDays;
  }

  // --- Dashboard Summaries ---

  double get totalInvested => assets.fold(0.0, (sum, item) => sum + item.buyPrice);
  
  double get totalCurrentValue => assets.where((item) => item.status == ItemStatus.active)
      .fold(0.0, (sum, item) => sum + item.currentValue) + 
      assets.where((item) => item.status == ItemStatus.archived)
      .fold(0.0, (sum, item) => sum + (item.sellPrice ?? 0));

  double get totalDepreciation => totalInvested - totalCurrentValue;

  // 总日均成本
  double get totalDailyCost {
    double total = 0.0;
    for (var asset in assets) {
      total += getDailyCost(asset);
    }
    return total;
  }

  // --- 状态统计 ---

  int get activeCount => assets.where((item) => item.status == ItemStatus.active).length;
  int get retiredCount => assets.where((item) => item.status == ItemStatus.retired).length;
  int get archivedCount => assets.where((item) => item.status == ItemStatus.archived).length;

  double get activeRatio => assets.isEmpty ? 0.0 : activeCount / assets.length;
  double get retiredRatio => assets.isEmpty ? 0.0 : retiredCount / assets.length;
  double get archivedRatio => assets.isEmpty ? 0.0 : archivedCount / assets.length;

  // --- 仪表盘数据 ---

  /// 获取按日均成本排序的物品列表（从大到小）
  List<AssetItem> getDailyCostRanking({Set<ItemStatus>? statusFilter}) {
    var filtered = assets.toList();
    if (statusFilter != null && statusFilter.isNotEmpty) {
      filtered = filtered.where((a) => statusFilter.contains(a.status)).toList();
    }
    filtered.sort((a, b) => getDailyCost(b).compareTo(getDailyCost(a)));
    return filtered;
  }

  /// 获取选中物品的日均成本占比数据
  Map<AssetItem, double> getDailyCostProportions(List<AssetItem> selectedItems) {
    final result = <AssetItem, double>{};
    double totalCost = 0;
    for (var item in selectedItems) {
      final cost = getDailyCost(item);
      result[item] = cost;
      totalCost += cost;
    }
    // 计算百分比
    if (totalCost > 0) {
      for (var key in result.keys.toList()) {
        result[key] = result[key]! / totalCost;
      }
    }
    return result;
  }
}
