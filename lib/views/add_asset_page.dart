import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xiwu/controllers/asset_controller.dart';
import 'package:xiwu/models/asset_item.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记一笔'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Emoji and Name
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: _emojiIcon,
                      decoration: const InputDecoration(labelText: 'Emoji'),
                      style: const TextStyle(fontSize: 32),
                      textAlign: TextAlign.center,
                      maxLength: 2,
                      onSaved: (val) => _emojiIcon = val ?? '📱',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: '物品名称', hintText: '比如: iPhone 14 Pro'),
                      validator: (val) => val == null || val.isEmpty ? '请输入物品名称' : null,
                      onSaved: (val) => _name = val ?? '',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Category
              DropdownButtonFormField<AssetCategory>(
                value: _category,
                decoration: const InputDecoration(labelText: '分类'),
                items: const [
                  DropdownMenuItem(value: AssetCategory.digital, child: Text('数码外设')),
                  DropdownMenuItem(value: AssetCategory.transport, child: Text('交通出行')),
                  DropdownMenuItem(value: AssetCategory.furniture, child: Text('大件家居')),
                  DropdownMenuItem(value: AssetCategory.fashion, child: Text('服饰箱包')),
                  DropdownMenuItem(value: AssetCategory.service, child: Text('权益/服务')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
                onSaved: (val) => _category = val ?? AssetCategory.digital,
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                decoration: const InputDecoration(labelText: '买入价格 (¥)', hintText: '0.00'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return '请输入买入价格';
                  if (double.tryParse(val) == null) return '请输入有效的数字';
                  return null;
                },
                onSaved: (val) => _buyPrice = double.parse(val!),
              ),
              const SizedBox(height: 16),

              // Date
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

              // Depreciation Model
              DropdownButtonFormField<DepreciationModel>(
                value: _depreciationModel,
                decoration: const InputDecoration(labelText: '折旧模型'),
                items: const [
                  DropdownMenuItem(value: DepreciationModel.modelA_Linear, child: Text('模型A：直线归零法')),
                  DropdownMenuItem(value: DepreciationModel.modelB_DropAndDecay, child: Text('模型B：落地打折+持续贬值')),
                  DropdownMenuItem(value: DepreciationModel.modelC_SlowDecay, child: Text('模型C：保底/缓慢折旧法')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _depreciationModel = val);
                },
                onSaved: (val) => _depreciationModel = val ?? DepreciationModel.modelB_DropAndDecay,
              ),
              const SizedBox(height: 32),

              // Save Button
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
                      currentValue: _buyPrice, // Initial current value is buy price
                      depreciationModel: _depreciationModel,
                      status: ItemStatus.active,
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
}
