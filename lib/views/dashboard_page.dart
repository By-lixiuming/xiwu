import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:xiwu/controllers/asset_controller.dart';
import 'package:xiwu/models/asset_item.dart';
import 'package:xiwu/theme/app_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AssetController controller = Get.find<AssetController>();

  // 饼图筛选状态
  final Set<ItemStatus> _pieStatusFilter = {ItemStatus.active};
  // 饼图选中的物品ID
  final Set<int> _selectedItemIds = {};
  // 是否已初始化选中
  bool _initialized = false;
  // 饼图触摸的索引
  int _touchedPieIndex = -1;

  // 马卡龙色板
  static const List<Color> _chartColors = [
    Color(0xFFFFAAA5), // 粉橘
    Color(0xFFA8E6CF), // 薄荷绿
    Color(0xFFFFD3B6), // 桃色
    Color(0xFFDCEDC1), // 嫩绿
    Color(0xFFFFB7B2), // 浅粉
    Color(0xFFB5EAD7), // 淡绿
    Color(0xFFC7CEEA), // 淡紫
    Color(0xFFF8B4D9), // 粉紫
    Color(0xFFE2F0CB), // 嫩黄绿
    Color(0xFFFFDAC1), // 杏色
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 仪表盘', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Obx(() {
        if (controller.assets.isEmpty) {
          return const Center(
            child: Text('还没有物品数据\n添加一些物品后再来看看吧', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.5)),
          );
        }

        // 初始化时默认全选当前筛选状态下的物品
        if (!_initialized) {
          _initializeSelection();
          _initialized = true;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildRankingCard(),
            const SizedBox(height: 20),
            _buildPieChartCard(),
            const SizedBox(height: 100),
          ],
        );
      }),
    );
  }

  void _initializeSelection() {
    final filtered = controller.assets.where((a) => _pieStatusFilter.contains(a.status));
    _selectedItemIds.clear();
    _selectedItemIds.addAll(filtered.map((a) => a.id));
  }

  // ================== 日均成本排行榜 ==================

  Widget _buildRankingCard() {
    final ranking = controller.getDailyCostRanking(statusFilter: {ItemStatus.active});
    final maxCost = ranking.isNotEmpty ? controller.getDailyCost(ranking.first) : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.leaderboard_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('日均成本排行榜', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          Text('服役中物品 · 从高到低', style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.7))),
          const SizedBox(height: 20),
          if (ranking.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('暂无服役中的物品', style: TextStyle(color: AppColors.textSecondary))),
            )
          else
            ...ranking.take(10).toList().asMap().entries.map((entry) {
              final idx = entry.key;
              final asset = entry.value;
              final cost = controller.getDailyCost(asset);
              final ratio = maxCost > 0 ? cost / maxCost : 0.0;
              return _buildRankingBar(idx, asset, cost, ratio);
            }),
        ],
      ),
    );
  }

  Widget _buildRankingBar(int index, AssetItem asset, double cost, double ratio) {
    final color = _chartColors[index % _chartColors.length];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(asset.emojiIcon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  asset.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '¥${cost.toStringAsFixed(2)}/天',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color.withValues(alpha: 1)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ================== 日均占比饼图 ==================

  Widget _buildPieChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pie_chart_rounded, color: Color(0xFF2E7D5A), size: 20),
              ),
              const SizedBox(width: 10),
              const Text('日均成本占比', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          // 状态筛选
          _buildStatusFilter(),
          const SizedBox(height: 12),
          // 物品选择
          _buildItemSelector(),
          const SizedBox(height: 20),
          // 饼图
          _buildPieChart(),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Wrap(
      spacing: 8,
      children: [
        _buildFilterChip('服役中', ItemStatus.active, const Color(0xFFA8E6CF)),
        _buildFilterChip('已退役', ItemStatus.retired, const Color(0xFFB0BEC5)),
        _buildFilterChip('已出掉', ItemStatus.archived, const Color(0xFFFFDAC1)),
      ],
    );
  }

  Widget _buildFilterChip(String label, ItemStatus status, Color color) {
    final isSelected = _pieStatusFilter.contains(status);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _pieStatusFilter.remove(status);
          } else {
            _pieStatusFilter.add(status);
          }
          _initializeSelection();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.3) : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.withValues(alpha: 0.2), width: isSelected ? 2 : 1),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: AppColors.textPrimary)),
      ),
    );
  }

  Widget _buildItemSelector() {
    final filtered = controller.assets.where((a) => _pieStatusFilter.contains(a.status)).toList();
    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('当前筛选条件下没有物品', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        // 全选/全不选
        GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedItemIds.length == filtered.length) {
                _selectedItemIds.clear();
              } else {
                _selectedItemIds.clear();
                _selectedItemIds.addAll(filtered.map((a) => a.id));
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _selectedItemIds.length == filtered.length ? AppColors.primary.withValues(alpha: 0.15) : AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              _selectedItemIds.length == filtered.length ? '取消全选' : '全选',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
        ),
        ...filtered.map((asset) {
          final isSelected = _selectedItemIds.contains(asset.id);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) { _selectedItemIds.remove(asset.id); } else { _selectedItemIds.add(asset.id); }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(asset.emojiIcon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(asset.name, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: AppColors.textPrimary)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPieChart() {
    final selectedAssets = controller.assets.where((a) => _selectedItemIds.contains(a.id)).toList();
    if (selectedAssets.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('请选择要统计的物品', style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    final proportions = controller.getDailyCostProportions(selectedAssets);
    final entries = proportions.entries.toList();

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                      _touchedPieIndex = -1;
                      return;
                    }
                    _touchedPieIndex = response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: entries.asMap().entries.map((e) {
                final idx = e.key;
                final entry = e.value;
                final isTouched = idx == _touchedPieIndex;
                final color = _chartColors[idx % _chartColors.length];
                return PieChartSectionData(
                  value: entry.value * 100,
                  title: isTouched ? '${(entry.value * 100).toStringAsFixed(1)}%' : '',
                  color: color,
                  radius: isTouched ? 55 : 45,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  badgeWidget: isTouched ? null : Text(entry.key.emojiIcon, style: const TextStyle(fontSize: 18)),
                  badgePositionPercentageOffset: 1.3,
                );
              }).toList(),
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 图例
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: entries.asMap().entries.map((e) {
            final idx = e.key;
            final entry = e.value;
            final color = _chartColors[idx % _chartColors.length];
            final cost = controller.getDailyCost(entry.key);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 4),
                Text('${entry.key.emojiIcon} ${entry.key.name}', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                const SizedBox(width: 4),
                Text('¥${cost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
