import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xiwu/controllers/asset_controller.dart';
import 'package:xiwu/models/asset_item.dart';
import 'package:xiwu/theme/app_theme.dart';
import 'package:xiwu/views/add_asset_page.dart';
import 'package:xiwu/views/asset_detail_page.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final AssetController controller = Get.put(AssetController());
  final NumberFormat currencyFormat = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('惜物 Xiwu', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Obx(() {
        if (controller.assets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/empty_state.png', width: 250),
                const SizedBox(height: 24),
                const Text(
                  '还没添加任何物品呢，\n快来记一笔吧！',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildDashboardCard(),
            const SizedBox(height: 24),
            const Text(
              '我的物品',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            ...controller.assets.map((asset) => _buildAssetCard(asset)),
            const SizedBox(height: 80), // spacing for FAB
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => AddAssetPage());
        },
        icon: const Icon(Icons.add),
        label: const Text('记一笔', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDashboardCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 第一行：总投入本金 + 日均成本 ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTopStatItem('💰 总投入本金', controller.totalInvested),
              _buildTopStatItem('📅 总日均成本', controller.totalDailyCost),
            ],
          ),

          const SizedBox(height: 20),

          // --- 分隔线 ---
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.2),
          ),

          const SizedBox(height: 16),

          // --- 第二行：当前总残值 + 总折损（可隐藏）+ 眼睛开关 ---
          Row(
            children: [
              Expanded(
                child: controller.isDetailVisible.value
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailStatItem('当前总残值', controller.totalCurrentValue),
                          _buildDetailStatItem('总折损', controller.totalDepreciation),
                        ],
                      )
                    : const Text(
                        '****',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: controller.toggleDetailVisible,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    controller.isDetailVisible.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- 分隔线 ---
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.2),
          ),

          const SizedBox(height: 16),

          // --- 第三行：三种状态占比统计 ---
          _buildStatusBar('服役中', controller.activeCount, controller.activeRatio, AppColors.secondary),
          const SizedBox(height: 10),
          _buildStatusBar('已退役', controller.retiredCount, controller.retiredRatio, const Color(0xFFB0BEC5)),
          const SizedBox(height: 10),
          _buildStatusBar('已出掉', controller.archivedCount, controller.archivedRatio, const Color(0xFFFFCC80)),
        ],
      )),
    );
  }

  Widget _buildTopStatItem(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          currencyFormat.format(value),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailStatItem(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(value),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar(String label, int count, double ratio, Color barColor) {
    final total = controller.assets.length;
    final percent = total > 0 ? (ratio * 100).toStringAsFixed(0) : '0';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$label  $count 件',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Text(
              '$percent%',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              // 背景
              Container(
                height: 8,
                width: double.infinity,
                color: Colors.white.withOpacity(0.15),
              ),
              // 进度
              FractionallySizedBox(
                widthFactor: ratio.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssetCard(AssetItem asset) {
    final dailyCost = controller.getDailyCost(asset);

    String statusText;
    Color statusBgColor;
    Color statusTextColor;
    switch (asset.status) {
      case ItemStatus.active:
        statusText = '服役中';
        statusBgColor = AppColors.success;
        statusTextColor = Colors.green.shade800;
        break;
      case ItemStatus.retired:
        statusText = '已退役';
        statusBgColor = const Color(0xFFB0BEC5).withOpacity(0.3);
        statusTextColor = AppColors.textPrimary;
        break;
      case ItemStatus.archived:
        statusText = '已出掉';
        statusBgColor = AppColors.textSecondary.withOpacity(0.2);
        statusTextColor = AppColors.textPrimary;
        break;
    }

    return Card(
      child: InkWell(
        onTap: () {
          Get.to(() => AssetDetailPage(asset: asset));
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    asset.emojiIcon,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '日均: ¥${dailyCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('当前残值', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    '¥${(asset.status == ItemStatus.active ? asset.currentValue : asset.sellPrice ?? 0).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        color: statusTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
