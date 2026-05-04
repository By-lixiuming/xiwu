import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xiwu/controllers/asset_controller.dart';
import 'package:xiwu/models/asset_item.dart';
import 'package:xiwu/theme/app_theme.dart';
import 'package:xiwu/views/add_asset_page.dart';
import 'package:intl/intl.dart';

class AssetDetailPage extends StatefulWidget {
  final AssetItem asset;

  const AssetDetailPage({super.key, required this.asset});

  @override
  State<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends State<AssetDetailPage> {
  final AssetController controller = Get.find<AssetController>();
  final NumberFormat currencyFormat = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');

  bool _isEditing = false;

  // 编辑模式下的临时值
  late TextEditingController _nameController;
  late TextEditingController _buyPriceController;
  late TextEditingController _noteController;
  late DateTime _editBuyDate;
  late DateTime? _editExpiryDate;
  late AssetCategory _editCategory;
  late DepreciationModel _editDepreciationModel;

  @override
  void initState() {
    super.initState();
    _initEditValues();
  }

  void _initEditValues() {
    _nameController = TextEditingController(text: widget.asset.name);
    _buyPriceController = TextEditingController(text: widget.asset.buyPrice.toString());
    _noteController = TextEditingController(text: widget.asset.note ?? '');
    _editBuyDate = widget.asset.buyDate;
    _editExpiryDate = widget.asset.expiryDate;
    _editCategory = widget.asset.category;
    _editDepreciationModel = widget.asset.depreciationModel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _buyPriceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _enterEditMode() {
    _initEditValues();
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    setState(() => _isEditing = false);
  }

  void _saveEdit() {
    final newName = _nameController.text.trim();
    final newPrice = double.tryParse(_buyPriceController.text.trim());
    if (newName.isEmpty || newPrice == null) {
      Get.snackbar('提示', '请填写完整的物品名称和价格',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
      );
      return;
    }

    widget.asset.name = newName;
    widget.asset.buyPrice = newPrice;
    widget.asset.buyDate = _editBuyDate;
    widget.asset.expiryDate = _editExpiryDate;
    widget.asset.category = _editCategory;
    widget.asset.depreciationModel = _editDepreciationModel;
    widget.asset.note = _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null;

    controller.updateAsset(widget.asset);
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑物品' : '物品详情'),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: _enterEditMode,
              tooltip: '编辑',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _isEditing ? _buildEditMode() : _buildViewMode(),
      ),
    );
  }

  // ================== 查看模式 ==================

  Widget _buildViewMode() {
    return Column(
      children: [
        _buildHeaderCard(),
        const SizedBox(height: 16),
        _buildStatsCard(),
        const SizedBox(height: 16),
        if (widget.asset.expiryDate != null) ...[
          _buildExpiryCard(),
          const SizedBox(height: 16),
        ],
        if (widget.asset.note != null && widget.asset.note!.isNotEmpty) ...[
          _buildNoteCard(),
          const SizedBox(height: 16),
        ],
        _buildCostCard(),
        const SizedBox(height: 32),
        if (widget.asset.status == ItemStatus.active || widget.asset.status == ItemStatus.retired)
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
        if (widget.asset.status == ItemStatus.active)
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
                  side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ),
      ],
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.asset.emojiIcon,
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 16),
          Text(
            widget.asset.name,
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
              widget.asset.status == ItemStatus.active ? '服役中' : widget.asset.status == ItemStatus.retired ? '已退役' : '已出掉',
              style: TextStyle(
                color: widget.asset.status == ItemStatus.active ? AppColors.success : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            categoryName(widget.asset.category),
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final daysOwned = controller.getDaysOwned(widget.asset);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('买入价格', style: TextStyle(color: AppColors.textSecondary)),
                Text(currencyFormat.format(widget.asset.buyPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('买入日期', style: TextStyle(color: AppColors.textSecondary)),
                Text(
                  '${widget.asset.buyDate.year}年${widget.asset.buyDate.month}月${widget.asset.buyDate.day}日',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.asset.status == ItemStatus.active ? '当前残值（估算）' : '卖出价格', style: const TextStyle(color: AppColors.textSecondary)),
                Text(
                  currencyFormat.format(widget.asset.status == ItemStatus.active ? widget.asset.currentValue : (widget.asset.sellPrice ?? 0)),
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

  Widget _buildExpiryCard() {
    final expiryDate = widget.asset.expiryDate!;
    final now = DateTime.now();
    final daysLeft = expiryDate.difference(now).inDays;
    final isExpired = daysLeft < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpired ? AppColors.error.withValues(alpha: 0.4) : AppColors.secondary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isExpired
                  ? AppColors.error.withValues(alpha: 0.15)
                  : AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isExpired ? Icons.event_busy_rounded : Icons.event_available_rounded,
              color: isExpired ? AppColors.error : const Color(0xFF2E7D5A),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('到期日期', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  '${expiryDate.year}年${expiryDate.month}月${expiryDate.day}日',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isExpired ? AppColors.error.withValues(alpha: 0.12) : AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isExpired ? '已过期 ${-daysLeft} 天' : '剩余 $daysLeft 天',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isExpired ? AppColors.error : const Color(0xFF2E7D5A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, size: 18, color: AppColors.textSecondary.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              const Text(
                '说明信息',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.asset.note!,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostCard() {
    final dailyCost = controller.getDailyCost(widget.asset);

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

    // 显示计算方式说明
    String calcNote;
    if (widget.asset.status == ItemStatus.archived) {
      calcNote = '买入价格 ÷ 持有天数';
    } else if (widget.asset.expiryDate != null) {
      calcNote = '买入价格 ÷ 到期天数';
    } else {
      calcNote = '买入价格 ÷ 持有天数';
    }

    return Card(
      color: AppColors.secondary.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              '日均使用成本',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              calcNote,
              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 11),
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

  // ================== 编辑模式 ==================

  Widget _buildEditMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 物品图标 (只读展示)
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(widget.asset.emojiIcon, style: const TextStyle(fontSize: 48)),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 物品名称
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: '物品名称'),
        ),
        const SizedBox(height: 16),

        // 分类选择
        const Text(
          '分类',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kCategoryOptions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final opt = kCategoryOptions[index];
              final isSelected = _editCategory == opt.value;
              return GestureDetector(
                onTap: () => setState(() => _editCategory = opt.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(opt.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        opt.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // 买入价格
        TextFormField(
          controller: _buyPriceController,
          decoration: const InputDecoration(labelText: '买入价格 (¥)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),

        // 买入日期
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _editBuyDate,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              locale: const Locale('zh', 'CN'),
            );
            if (picked != null) {
              setState(() => _editBuyDate = picked);
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: '买入日期',
              suffixIcon: Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary, size: 20),
            ),
            child: Text(
              '${_editBuyDate.year}年${_editBuyDate.month}月${_editBuyDate.day}日',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 到期时间
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _editExpiryDate ?? DateTime.now().add(const Duration(days: 365)),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              locale: const Locale('zh', 'CN'),
            );
            if (picked != null) {
              setState(() => _editExpiryDate = picked);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: '到期时间（选填）',
              suffixIcon: _editExpiryDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                      onPressed: () => setState(() => _editExpiryDate = null),
                    )
                  : const Icon(Icons.event_rounded, color: AppColors.textSecondary, size: 20),
            ),
            child: Text(
              _editExpiryDate != null
                  ? '${_editExpiryDate!.year}年${_editExpiryDate!.month}月${_editExpiryDate!.day}日'
                  : '未设置',
              style: TextStyle(
                fontSize: 16,
                color: _editExpiryDate != null ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 折旧模型
        DropdownButtonFormField<DepreciationModel>(
          initialValue: _editDepreciationModel,
          decoration: const InputDecoration(labelText: '折旧模型'),
          items: const [
            DropdownMenuItem(value: DepreciationModel.modelA_Linear, child: Text('模型A：直线归零法')),
            DropdownMenuItem(value: DepreciationModel.modelB_DropAndDecay, child: Text('模型B：落地打折+持续贬值')),
            DropdownMenuItem(value: DepreciationModel.modelC_SlowDecay, child: Text('模型C：保底/缓慢折旧法')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _editDepreciationModel = val);
          },
        ),
        const SizedBox(height: 16),

        // 说明
        TextFormField(
          controller: _noteController,
          decoration: const InputDecoration(
            labelText: '说明（选填）',
            hintText: '添加物品的备注或说明...',
            alignLabelWithHint: true,
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 32),

        // 保存/取消按钮
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('取消'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _saveEdit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('保存修改'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================== 弹窗操作 ==================

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
                  widget.asset.status = ItemStatus.archived;
                  widget.asset.sellPrice = sellPrice;
                  widget.asset.sellDate = DateTime.now();
                  controller.updateAsset(widget.asset);
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
                controller.deleteAsset(widget.asset.id);
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
                widget.asset.status = ItemStatus.retired;
                controller.updateAsset(widget.asset);
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
