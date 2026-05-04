import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xiwu/controllers/asset_controller.dart';
import 'package:xiwu/models/asset_item.dart';
import 'package:xiwu/theme/app_theme.dart';

/// 预定义的图标选项列表
class IconOption {
  final String emoji;
  final String label;
  const IconOption(this.emoji, this.label);
}

/// 按分组组织图标
class IconGroup {
  final String groupName;
  final List<IconOption> icons;
  const IconGroup(this.groupName, this.icons);
}

const List<IconGroup> kIconGroups = [
  IconGroup('数码', [
    IconOption('📱', '手机'),
    IconOption('💻', '笔记本'),
    IconOption('🖥', '台式机'),
    IconOption('⌨️', '键盘'),
    IconOption('🖱', '鼠标'),
    IconOption('🎧', '耳机'),
    IconOption('📷', '相机'),
    IconOption('🖨', '打印机'),
    IconOption('💾', '硬盘'),
    IconOption('📡', '路由器'),
  ]),
  IconGroup('娱乐', [
    IconOption('🎮', '游戏机'),
    IconOption('🎸', '乐器'),
    IconOption('🎬', '影音'),
    IconOption('📺', '电视'),
  ]),
  IconGroup('家居家电', [
    IconOption('🛋', '沙发'),
    IconOption('🪑', '椅子'),
    IconOption('🛏', '床'),
    IconOption('💡', '灯具'),
    IconOption('🧊', '冰箱'),
    IconOption('🫧', '洗衣机'),
    IconOption('♨️', '空调'),
  ]),
  IconGroup('出行', [
    IconOption('🚗', '汽车'),
    IconOption('🚲', '自行车'),
    IconOption('🛵', '摩托车'),
    IconOption('🛴', '滑板车'),
  ]),
  IconGroup('服饰', [
    IconOption('👔', '衣服'),
    IconOption('👟', '鞋子'),
    IconOption('👜', '箱包'),
    IconOption('⌚', '手表'),
    IconOption('💍', '首饰'),
    IconOption('🕶', '眼镜'),
  ]),
  IconGroup('运动', [
    IconOption('🏋️', '健身'),
    IconOption('⚽', '球类'),
    IconOption('🎿', '滑雪'),
    IconOption('🏊', '游泳'),
  ]),
  IconGroup('权益/服务', [
    IconOption('🎫', '会员'),
    IconOption('📦', '订阅'),
    IconOption('🏥', '保险'),
  ]),
  IconGroup('学习', [
    IconOption('📚', '书籍'),
    IconOption('🎓', '课程'),
  ]),
  IconGroup('房产', [
    IconOption('🏠', '房产'),
    IconOption('🏢', '公寓'),
  ]),
  IconGroup('其他', [
    IconOption('🔧', '工具'),
    IconOption('🧸', '玩具'),
    IconOption('💎', '收藏品'),
    IconOption('📦', '其他'),
  ]),
];

/// 分类数据
class CategoryOption {
  final AssetCategory value;
  final String emoji;
  final String label;
  const CategoryOption(this.value, this.emoji, this.label);
}

const List<CategoryOption> kCategoryOptions = [
  CategoryOption(AssetCategory.digital, '📱', '数码外设'),
  CategoryOption(AssetCategory.transport, '🚗', '交通出行'),
  CategoryOption(AssetCategory.furniture, '🛋', '大件家居'),
  CategoryOption(AssetCategory.fashion, '👜', '服饰箱包'),
  CategoryOption(AssetCategory.service, '🎫', '权益/服务'),
  CategoryOption(AssetCategory.appliance, '♨️', '家电'),
  CategoryOption(AssetCategory.entertainment, '🎮', '娱乐'),
  CategoryOption(AssetCategory.sports, '🏋️', '运动健身'),
  CategoryOption(AssetCategory.education, '📚', '学习教育'),
  CategoryOption(AssetCategory.housing, '🏠', '房产'),
  CategoryOption(AssetCategory.other, '📦', '其他'),
];

/// 分类名称映射（保留给其他页面使用）
String categoryName(AssetCategory cat) {
  for (final opt in kCategoryOptions) {
    if (opt.value == cat) return '${opt.emoji} ${opt.label}';
  }
  return '📦 其他';
}

class AddAssetPage extends StatefulWidget {
  const AddAssetPage({super.key});

  @override
  State<AddAssetPage> createState() => _AddAssetPageState();
}

class _AddAssetPageState extends State<AddAssetPage> {
  final AssetController controller = Get.find<AssetController>();
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _emojiIcon = '📱';
  AssetCategory _category = AssetCategory.digital;
  double _buyPrice = 0.0;
  DateTime _buyDate = DateTime.now();
  DepreciationModel _depreciationModel = DepreciationModel.modelB_DropAndDecay;
  String _note = '';

  /// 获取当前选中图标的标签
  String _getSelectedIconLabel() {
    for (final group in kIconGroups) {
      for (final icon in group.icons) {
        if (icon.emoji == _emojiIcon) return icon.label;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('记一笔')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 图标选择 ---
              const Text(
                '选择图标',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              _buildIconSelector(),
              const SizedBox(height: 20),

              // 物品名称
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '物品名称',
                  hintText: '比如: iPhone 16 Pro',
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? '请输入物品名称' : null,
                onSaved: (val) => _name = val ?? '',
              ),
              const SizedBox(height: 16),

              // 分类
              const Text(
                '分类',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              _buildCategorySelector(),
              const SizedBox(height: 16),

              // 买入价格
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '买入价格 (¥)',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return '请输入买入价格';
                  if (double.tryParse(val) == null) return '请输入有效的数字';
                  return null;
                },
                onSaved: (val) => _buyPrice = double.parse(val!),
              ),
              const SizedBox(height: 16),

              // 买入日期（中文年月日格式）
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _buyDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    locale: const Locale('zh', 'CN'),
                  );
                  if (picked != null) {
                    setState(() => _buyDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '买入日期',
                    suffixIcon: Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  child: Text(
                    '${_buyDate.year}年${_buyDate.month}月${_buyDate.day}日',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 折旧模型
              DropdownButtonFormField<DepreciationModel>(
                initialValue: _depreciationModel,
                decoration: const InputDecoration(labelText: '折旧模型'),
                items: const [
                  DropdownMenuItem(
                    value: DepreciationModel.modelA_Linear,
                    child: Text('模型A：直线归零法'),
                  ),
                  DropdownMenuItem(
                    value: DepreciationModel.modelB_DropAndDecay,
                    child: Text('模型B：落地打折+持续贬值'),
                  ),
                  DropdownMenuItem(
                    value: DepreciationModel.modelC_SlowDecay,
                    child: Text('模型C：保底/缓慢折旧法'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _depreciationModel = val);
                },
                onSaved: (val) => _depreciationModel =
                    val ?? DepreciationModel.modelB_DropAndDecay,
              ),
              const SizedBox(height: 16),

              // 说明/备注
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '说明（选填）',
                  hintText: '添加物品的备注或说明...',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                onSaved: (val) => _note = val ?? '',
              ),
              const SizedBox(height: 32),

              // 保存按钮
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    final newItem = AssetItem(
                      id: 0, // Will be set in DatabaseService
                      name: _name,
                      emojiIcon: _emojiIcon,
                      category: _category,
                      buyPrice: _buyPrice,
                      buyDate: _buyDate,
                      currentValue:
                          _buyPrice, // Initial current value is buy price
                      depreciationModel: _depreciationModel,
                      status: ItemStatus.active,
                      note: _note.isNotEmpty ? _note : null,
                    );

                    controller.addAsset(newItem);
                    Get.back();
                  }
                },
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 图标选择器：点击展开弹窗选择
  Widget _buildIconSelector() {
    return InkWell(
      onTap: () => _showIconPickerDialog(),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  _emojiIcon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getSelectedIconLabel(),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// 图标选择弹窗
  void _showIconPickerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String tempSelected = _emojiIcon;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // 顶部手柄 + 标题
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      children: [
                        // 拖动手柄
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '选择图标',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() => _emojiIcon = tempSelected);
                                Navigator.pop(context);
                              },
                              child: const Text(
                                '确定',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // 图标列表
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: kIconGroups.length,
                      itemBuilder: (context, index) {
                        final group = kIconGroups[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 分组标题
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  group.groupName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              // 图标网格
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: group.icons.map((opt) {
                                  final isSelected =
                                      tempSelected == opt.emoji;
                                  return GestureDetector(
                                    onTap: () {
                                      setSheetState(
                                          () => tempSelected = opt.emoji);
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                                .withValues(alpha: 0.15)
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: isSelected
                                            ? Border.all(
                                                color: AppColors.primary,
                                                width: 2)
                                            : Border.all(
                                                color: Colors.grey
                                                    .withValues(alpha: 0.15),
                                                width: 1),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            opt.emoji,
                                            style: const TextStyle(
                                                fontSize: 24),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            opt.label,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color:
                                                  AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 分类选择器：横向滑动 Chip 选择
  Widget _buildCategorySelector() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kCategoryOptions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final opt = kCategoryOptions[index];
          final isSelected = _category == opt.value;
          return GestureDetector(
            onTap: () => setState(() => _category = opt.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    opt.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
