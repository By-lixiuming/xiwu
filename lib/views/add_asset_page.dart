import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xiwu/controllers/asset_controller.dart';
import 'package:xiwu/models/asset_item.dart';
import 'package:xiwu/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// 预定义的图标选项列表
class IconOption {
  final String emoji;
  final String label;
  const IconOption(this.emoji, this.label);
}

const List<IconOption> kIconOptions = [
  // 数码
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
  // 娱乐
  IconOption('🎮', '游戏机'),
  IconOption('🎸', '乐器'),
  IconOption('🎬', '影音'),
  IconOption('📺', '电视'),
  // 家居家电
  IconOption('🛋', '沙发'),
  IconOption('🪑', '椅子'),
  IconOption('🛏', '床'),
  IconOption('💡', '灯具'),
  IconOption('🧊', '冰箱'),
  IconOption('🫧', '洗衣机'),
  IconOption('♨️', '空调'),
  // 出行
  IconOption('🚗', '汽车'),
  IconOption('🚲', '自行车'),
  IconOption('🛵', '摩托车'),
  IconOption('🛴', '滑板车'),
  // 服饰
  IconOption('👔', '衣服'),
  IconOption('👟', '鞋子'),
  IconOption('👜', '箱包'),
  IconOption('⌚', '手表'),
  IconOption('💍', '首饰'),
  IconOption('🕶', '眼镜'),
  // 运动
  IconOption('🏋️', '健身'),
  IconOption('⚽', '球类'),
  IconOption('🎿', '滑雪'),
  IconOption('🏊', '游泳'),
  // 权益/服务
  IconOption('🎫', '会员'),
  IconOption('📦', '订阅'),
  IconOption('🏥', '保险'),
  // 学习
  IconOption('📚', '书籍'),
  IconOption('🎓', '课程'),
  // 房产
  IconOption('🏠', '房产'),
  IconOption('🏢', '公寓'),
  // 其他
  IconOption('🔧', '工具'),
  IconOption('🧸', '玩具'),
  IconOption('💎', '收藏品'),
  IconOption('📦', '其他'),
];

/// 分类名称映射
String categoryName(AssetCategory cat) {
  switch (cat) {
    case AssetCategory.digital:
      return '📱 数码外设';
    case AssetCategory.transport:
      return '🚗 交通出行';
    case AssetCategory.furniture:
      return '🛋 大件家居';
    case AssetCategory.fashion:
      return '👜 服饰箱包';
    case AssetCategory.service:
      return '🎫 权益/服务';
    case AssetCategory.appliance:
      return '♨️ 家电';
    case AssetCategory.entertainment:
      return '🎮 娱乐';
    case AssetCategory.sports:
      return '🏋️ 运动健身';
    case AssetCategory.education:
      return '📚 学习教育';
    case AssetCategory.housing:
      return '🏠 房产';
    case AssetCategory.other:
      return '📦 其他';
  }
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
              _buildIconPicker(),
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
              DropdownButtonFormField<AssetCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: '分类'),
                items: AssetCategory.values
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(categoryName(cat)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
                onSaved: (val) => _category = val ?? AssetCategory.digital,
              ),
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

              // 买入日期
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _buyDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _buyDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: '买入日期'),
                  child: Text(DateFormat('yyyy-MM-dd').format(_buyDate)),
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

  Widget _buildIconPicker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: kIconOptions.map((opt) {
          final isSelected = _emojiIcon == opt.emoji;
          return GestureDetector(
            onTap: () => setState(() => _emojiIcon = opt.emoji),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  opt.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
