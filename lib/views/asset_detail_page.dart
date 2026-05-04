import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xiwu/controllers/asset_controller.dart';
import 'package:xiwu/models/asset_item.dart';
import 'package:xiwu/theme/app_theme.dart';
import 'package:intl/intl.dart';

class AssetDetailPage extends StatelessWidget {
  final AssetItem asset;
  
  AssetDetailPage({super.key, required this.asset});

  final AssetController controller = Get.find<AssetController>();
  final NumberFormat currencyFormat = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('物品详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildStatsCard(),
            const SizedBox(height: 16),
            _buildCostCard(),
            const SizedBox(height: 32),
            if (asset.status == ItemStatus.active || asset.status == ItemStatus.retired)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showArchiveDialog(context),
                  icon: const Icon(Icons.archive),
                  label: const Text('出掉 / 转卖 / 报废'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: AppColors.textPrimary,
                  ),
                ),
              ),
            if (asset.status == ItemStatus.active)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showRetireDialog(context),
                    icon: const Icon(Icons.pause_circle_outline),
                    label: const Text('退役（不再使用）'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            asset.emojiIcon,
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 16),
          Text(
            asset.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              asset.status == ItemStatus.active ? '服役中' : asset.status == ItemStatus.retired ? '已退役' : '已出掉',
              style: TextStyle(
                color: asset.status == ItemStatus.active ? AppColors.success : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final daysOwned = controller.getDaysOwned(asset);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('买入价格', style: TextStyle(color: AppColors.textSecondary)),
                Text(currencyFormat.format(asset.buyPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(asset.status == ItemStatus.active ? '当前残值' : '卖出价格', style: const TextStyle(color: AppColors.textSecondary)),
                Text(
                  currencyFormat.format(asset.status == ItemStatus.active ? asset.currentValue : (asset.sellPrice ?? 0)),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('已持有天数', style: TextStyle(color: AppColors.textSecondary)),
                Text('$daysOwned 天', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostCard() {
    final dailyCost = controller.getDailyCost(asset);
    
    // Fun milk tea equivalent copy
    String funCopy = "";
    if (dailyCost <= 0) {
      funCopy = "不仅没花钱，反而赚到了！🎉";
    } else if (dailyCost < 1) {
      funCopy = "每天不到一块钱，约等于白嫖！";
    } else if (dailyCost < 5) {
      funCopy = "每天一瓶矿泉水，物超所值。";
    } else if (dailyCost < 20) {
      funCopy = "相当于每天省下了一杯奶茶！🥤";
    } else {
      funCopy = "成本有点高，要多用用才回本哦！";
    }

    return Card(
      color: AppColors.secondary.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              '日均使用成本',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '¥${dailyCost.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              funCopy,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showArchiveDialog(BuildContext context) {
    double? sellPrice;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('出掉 / 报废'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('填写入手时的残值（如果是送人或报废请填0）：'),
              const SizedBox(height: 16),
              TextField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '最终价格'),
                onChanged: (val) => sellPrice = double.tryParse(val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (sellPrice != null) {
                  asset.status = ItemStatus.archived;
                  asset.sellPrice = sellPrice;
                  asset.sellDate = DateTime.now();
                  controller.updateAsset(asset);
                  Get.back();
                  Get.back(); // Return to home
                }
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除物品'),
          content: const Text('确定要永久删除这个物品记录吗？'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                controller.deleteAsset(asset.id);
                Get.back();
                Get.back();
              },
              child: const Text('删除', style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }

  void _showRetireDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('退役物品'),
          content: const Text('将此物品标记为「已退役」？\n退役后物品不再计算折旧，但仍可随时转卖或恢复。'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                asset.status = ItemStatus.retired;
                controller.updateAsset(asset);
                Get.back();
                Get.back(); // Return to home
              },
              child: const Text('确认退役'),
            ),
          ],
        );
      },
    );
  }
}
