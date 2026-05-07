import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xiwu/controllers/asset_controller.dart';
import 'package:xiwu/models/asset_item.dart';
import 'package:xiwu/theme/app_theme.dart';
import 'package:xiwu/views/asset_detail_page.dart';
import 'package:intl/intl.dart';

/// 首页内容组件（嵌入到 MainScaffold 中）
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AssetController>();
    final currencyFormat = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');

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
            _InvestmentCard(controller: controller, currencyFormat: currencyFormat),
            const SizedBox(height: 12),
            _StatusCards(controller: controller),
            const SizedBox(height: 24),
            _SectionHeader(controller: controller),
            const SizedBox(height: 12),
            if (controller.isGridView.value)
              _GridView(controller: controller)
            else
              _ReorderableAssetList(controller: controller, currencyFormat: currencyFormat),
            const SizedBox(height: 100), // spacing for bottom nav
          ],
        );
      }),
    );
  }
}

// ================== 可拖拽排序的物品列表 ==================

class _ReorderableAssetList extends StatelessWidget {
  final AssetController controller;
  final NumberFormat currencyFormat;

  const _ReorderableAssetList({required this.controller, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final elevation = Tween<double>(begin: 0, end: 8).evaluate(animation);
            return Material(
              elevation: elevation,
              borderRadius: BorderRadius.circular(24),
              color: Colors.transparent,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
              child: child,
            );
          },
          child: child,
        );
      },
      itemCount: controller.assets.length,
      onReorder: controller.reorderAssets,
      itemBuilder: (context, index) {
        final asset = controller.assets[index];
        return ReorderableDelayedDragStartListener(
          key: ValueKey(asset.id),
          index: index,
          child: _AssetCard(asset: asset, controller: controller),
        );
      },
    );
  }
}

// ================== 单列物品卡片 ==================

class _AssetCard extends StatelessWidget {
  final AssetItem asset;
  final AssetController controller;

  const _AssetCard({required this.asset, required this.controller});

  @override
  Widget build(BuildContext context) {
    final dailyCost = controller.getDailyCost(asset);
    final daysOwned = controller.getDaysOwned(asset);

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
        statusBgColor = const Color(0xFFB0BEC5).withValues(alpha: 0.3);
        statusTextColor = AppColors.textPrimary;
        break;
      case ItemStatus.archived:
        statusText = '已出掉';
        statusBgColor = AppColors.textSecondary.withValues(alpha: 0.2);
        statusTextColor = AppColors.textPrimary;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Get.to(() => AssetDetailPage(asset: asset));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // 拖拽手柄
              Icon(
                Icons.drag_handle_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                size: 18,
              ),
              const SizedBox(width: 8),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    asset.emojiIcon,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '日均: ¥${dailyCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
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
                  const Text('服役天数', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    '$daysOwned 天',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(6),
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

// ================== 投资看板卡片 ==================

class _InvestmentCard extends StatelessWidget {
  final AssetController controller;
  final NumberFormat currencyFormat;

  const _InvestmentCard({required this.controller, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFAAA5), Color(0xFFFFD3B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('💰 总投入本金', controller.totalInvested),
              _buildStatItem('📅 总日均成本', controller.totalDailyCost),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: controller.toggleDetailVisible,
            child: Row(
              children: [
                AnimatedRotation(
                  turns: controller.isDetailVisible.value ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.arrow_right_rounded, color: Colors.white70, size: 24),
                ),
                const SizedBox(width: 4),
                Text(
                  controller.isDetailVisible.value ? '收起详情' : '展开详情',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                const SizedBox(width: 8),
                Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.2))),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailItem('当前总残值', controller.totalCurrentValue),
                  _buildDetailItem('总折损', controller.totalDepreciation),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: controller.isDetailVisible.value
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      )),
    );
  }

  Widget _buildStatItem(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 6),
        Text(
          currencyFormat.format(value),
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(value),
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ================== 状态统计卡片 ==================

class _StatusCards extends StatelessWidget {
  final AssetController controller;
  const _StatusCards({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildCard('服役中', controller.activeCount, Icons.play_circle_outline_rounded, const Color(0xFFA8E6CF), const Color(0xFF2E7D5A))),
        const SizedBox(width: 10),
        Expanded(child: _buildCard('已退役', controller.retiredCount, Icons.pause_circle_outline_rounded, const Color(0xFFB0BEC5), const Color(0xFF546E7A))),
        const SizedBox(width: 10),
        Expanded(child: _buildCard('已出掉', controller.archivedCount, Icons.check_circle_outline_rounded, const Color(0xFFFFDAC1), const Color(0xFFBF6C2E))),
      ],
    );
  }

  Widget _buildCard(String label, int count, IconData icon, Color bgColor, Color iconColor) {
    final total = controller.assets.length;
    final percent = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: bgColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: bgColor.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('$count 件', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text('$percent%', style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ================== Section Header ==================

class _SectionHeader extends StatelessWidget {
  final AssetController controller;
  const _SectionHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('我的物品', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToggle(Icons.view_list_rounded, !controller.isGridView.value, () { if (controller.isGridView.value) controller.toggleGridView(); }, true),
              Container(width: 1, height: 24, color: AppColors.background),
              _buildToggle(Icons.grid_view_rounded, controller.isGridView.value, () { if (!controller.isGridView.value) controller.toggleGridView(); }, false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggle(IconData icon, bool isActive, VoidCallback onTap, bool isLeft) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(12) : Radius.zero,
            right: !isLeft ? const Radius.circular(12) : Radius.zero,
          ),
        ),
        child: Icon(icon, size: 20, color: isActive ? AppColors.primary : AppColors.textSecondary),
      ),
    );
  }
}

// ================== 双列网格 ==================

class _GridView extends StatelessWidget {
  final AssetController controller;
  const _GridView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final assets = controller.assets;
    final List<Widget> rows = [];
    for (int i = 0; i < assets.length; i += 2) {
      final first = assets[i];
      final second = (i + 1 < assets.length) ? assets[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(child: _GridCard(asset: first, controller: controller)),
              const SizedBox(width: 10),
              Expanded(child: second != null ? _GridCard(asset: second, controller: controller) : const SizedBox.shrink()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _GridCard extends StatelessWidget {
  final AssetItem asset;
  final AssetController controller;
  const _GridCard({required this.asset, required this.controller});

  @override
  Widget build(BuildContext context) {
    final dailyCost = controller.getDailyCost(asset);
    Color statusColor;
    switch (asset.status) {
      case ItemStatus.active: statusColor = const Color(0xFFA8E6CF); break;
      case ItemStatus.retired: statusColor = const Color(0xFFB0BEC5); break;
      case ItemStatus.archived: statusColor = const Color(0xFFFFDAC1); break;
    }

    return GestureDetector(
      onTap: () => Get.to(() => AssetDetailPage(asset: asset)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text(asset.emojiIcon, style: const TextStyle(fontSize: 24))),
                ),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              ],
            ),
            const SizedBox(height: 12),
            Text(asset.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('日均 ¥${dailyCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('残值 ¥${(asset.status == ItemStatus.active ? asset.currentValue : asset.sellPrice ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
