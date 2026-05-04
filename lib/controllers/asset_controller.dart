import 'package:get/get.dart';
import 'package:xiwu/models/asset_item.dart';
import 'package:xiwu/services/database_service.dart';

class AssetController extends GetxController {
  final DatabaseService _db = Get.find<DatabaseService>();

  final RxList<AssetItem> assets = <AssetItem>[].obs;

  // 看板详情显示开关
  final RxBool isDetailVisible = true.obs;

  void toggleDetailVisible() {
    isDetailVisible.value = !isDetailVisible.value;
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
    assets.assignAll(rawAssets);
  }

  Future<void> addAsset(AssetItem asset) async {
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
    if (asset.status == ItemStatus.archived) {
      if (asset.sellDate == null || asset.sellPrice == null) return 0.0;
      final days = asset.sellDate!.difference(asset.buyDate).inDays;
      if (days <= 0) return 0.0;
      return (asset.buyPrice - asset.sellPrice!) / days;
    } else {
      final days = DateTime.now().difference(asset.buyDate).inDays;
      if (days <= 0) return 0.0;
      return (asset.buyPrice - asset.currentValue) / days;
    }
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
}
