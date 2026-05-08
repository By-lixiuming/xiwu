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
    
    // Sort descending by cost
    entries.sort((a, b) => b.value.compareTo(a.value));

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
          height: 280,
          child: SfCircularChart(
            margin: EdgeInsets.zero,
            annotations: <CircularChartAnnotation>[
              CircularChartAnnotation(
                widget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('总日均', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      totalCost.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.textPrimary),
                    ),
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
                dataLabelMapper: (_PieData data, _) => data.name,
                dataLabelSettings: const DataLabelSettings(
                  isVisible: true,
                  labelPosition: ChartDataLabelPosition.outside,
                  useSeriesColor: true,
                  connectorLineSettings: ConnectorLineSettings(
                    type: ConnectorType.curve,
                    length: '15%',
                  ),
                  textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                innerRadius: '65%',
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // 自定义带进度条图例列表
        ...chartData.map((data) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 图标
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: data.color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(data.emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                // 文本与进度条
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              data.name,
                              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${data.percent.toStringAsFixed(2)}%',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 进度条
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: (data.percent / 100).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: data.color.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 金额
                Text(
                  '¥${data.cost.toStringAsFixed(1)}/天',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
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
