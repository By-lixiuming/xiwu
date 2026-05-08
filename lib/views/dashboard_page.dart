import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
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
        title: const Text(
          '📊 仪表盘',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Obx(() {
        if (controller.assets.isEmpty) {
          return const Center(
            child: Text(
              '还没有物品数据\n添加一些物品后再来看看吧',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
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
    final filtered = controller.assets.where(
      (a) => _pieStatusFilter.contains(a.status),
    );
    _selectedItemIds.clear();
    _selectedItemIds.addAll(filtered.map((a) => a.id));
  }

  // ================== 日均成本排行榜 ==================

  Widget _buildRankingCard() {
    final ranking = controller.getDailyCostRanking(
      statusFilter: {ItemStatus.active},
    );
    final maxCost = ranking.isNotEmpty
        ? controller.getDailyCost(ranking.first)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                child: const Icon(
                  Icons.leaderboard_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '日均成本排行榜',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '服役中物品 · 从高到低',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          if (ranking.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  '暂无服役中的物品',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
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

  Widget _buildRankingBar(
    int index,
    AssetItem asset,
    double cost,
    double ratio,
  ) {
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '¥${cost.toStringAsFixed(2)}/天',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color.withValues(alpha: 1),
                ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Color(0xFF2E7D5A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '日均成本占比',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
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
          color: isSelected
              ? color.withValues(alpha: 0.3)
              : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildItemSelector() {
    final filtered = controller.assets
        .where((a) => _pieStatusFilter.contains(a.status))
        .toList();
    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '当前筛选条件下没有物品',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: () => _showMultiSelectDialog(filtered),
      icon: const Icon(Icons.checklist_rtl_rounded, size: 18),
      label: Text('选择物品 (${_selectedItemIds.length}/${filtered.length})'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showMultiSelectDialog(List<AssetItem> filtered) {
    // 使用局部状态来管理弹窗内的选中状态
    final Set<int> tempSelectedIds = Set.from(_selectedItemIds);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isAllSelected = tempSelectedIds.length == filtered.length;
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('选择统计物品', style: TextStyle(fontSize: 18)),
                  TextButton(
                    onPressed: () {
                      setDialogState(() {
                        if (isAllSelected) {
                          tempSelectedIds.clear();
                        } else {
                          tempSelectedIds.clear();
                          tempSelectedIds.addAll(filtered.map((a) => a.id));
                        }
                      });
                    },
                    child: Text(isAllSelected ? '取消全选' : '全选'),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final asset = filtered[index];
                    return CheckboxListTile(
                      value: tempSelectedIds.contains(asset.id),
                      title: Text('${asset.emojiIcon} ${asset.name}'),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            if (val) {
                              tempSelectedIds.add(asset.id);
                            } else {
                              tempSelectedIds.remove(asset.id);
                            }
                          });
                        }
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedItemIds.clear();
                      _selectedItemIds.addAll(tempSelectedIds);
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPieChart() {
    final selectedAssets = controller.assets
        .where((a) => _selectedItemIds.contains(a.id))
        .toList();
    if (selectedAssets.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            '请选择要统计的物品',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final proportions = controller.getDailyCostProportions(selectedAssets);
    final entries = proportions.entries.toList();
    
    double totalCost = 0;
    for (var a in selectedAssets) {
      totalCost += controller.getDailyCost(a);
    }

    final chartData = entries.asMap().entries.map((e) {
      final idx = e.key;
      final entry = e.value;
      final color = _chartColors[idx % _chartColors.length];
      final cost = controller.getDailyCost(entry.key);

      return _PieData(
        entry.key.name,
        entry.value * 100,
        color,
        cost,
        entry.key.emojiIcon,
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: SfCircularChart(
            margin: EdgeInsets.zero,
            annotations: <CircularChartAnnotation>[
              CircularChartAnnotation(
                widget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('总计日均', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('¥${totalCost.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary)),
                  ],
                ),
              )
            ],
            series: <CircularSeries>[
              DoughnutSeries<_PieData, String>(
                dataSource: chartData,
                xValueMapper: (_PieData data, _) => data.name,
                yValueMapper: (_PieData data, _) => data.percent,
                pointColorMapper: (_PieData data, _) => data.color,
                dataLabelSettings: const DataLabelSettings(isVisible: false),
                innerRadius: '70%',
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 自定义图例列表
        ...chartData.map((data) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: data.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(data.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.name,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${data.percent.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 75,
                  child: Text(
                    '¥${data.cost.toStringAsFixed(1)}/天',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _PieData {
  final String name;
  final double percent;
  final Color color;
  final double cost;
  final String emoji;
  _PieData(this.name, this.percent, this.color, this.cost, this.emoji);
}
