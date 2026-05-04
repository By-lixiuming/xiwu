import 'package:hive/hive.dart';

part 'asset_item.g.dart';

@HiveType(typeId: 0)
enum AssetCategory {
  @HiveField(0)
  digital, // 数码外设
  @HiveField(1)
  transport, // 交通出行
  @HiveField(2)
  furniture, // 大件家居
  @HiveField(3)
  fashion, // 服饰箱包
  @HiveField(4)
  service, // 权益/服务
  @HiveField(5)
  appliance, // 家电
  @HiveField(6)
  entertainment, // 娱乐
  @HiveField(7)
  sports, // 运动健身
  @HiveField(8)
  education, // 学习教育
  @HiveField(9)
  housing, // 房产
  @HiveField(10)
  other, // 其他
}

@HiveType(typeId: 1)
enum DepreciationModel {
  @HiveField(0)
  modelA_Linear, // 直线归零法
  @HiveField(1)
  modelB_DropAndDecay, // 落地打折+持续贬值
  @HiveField(2)
  modelC_SlowDecay, // 保值/缓慢折旧法
}

@HiveType(typeId: 2)
enum ItemStatus {
  @HiveField(0)
  active, // 服役中
  @HiveField(1)
  archived, // 已出掉
  @HiveField(2)
  retired, // 已退役
}

@HiveType(typeId: 3)
class AssetItem extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String emojiIcon;

  @HiveField(3)
  AssetCategory category;

  @HiveField(4)
  double buyPrice;

  @HiveField(5)
  DateTime buyDate;

  @HiveField(6)
  double currentValue;

  @HiveField(7)
  DepreciationModel depreciationModel;

  @HiveField(8)
  ItemStatus status;

  @HiveField(9)
  double? sellPrice;

  @HiveField(10)
  DateTime? sellDate;

  @HiveField(11)
  String? note;

  @HiveField(12)
  DateTime? expiryDate;

  @HiveField(13, defaultValue: 0)
  int sortOrder;

  AssetItem({
    required this.id,
    required this.name,
    required this.emojiIcon,
    required this.category,
    required this.buyPrice,
    required this.buyDate,
    required this.currentValue,
    required this.depreciationModel,
    required this.status,
    this.sellPrice,
    this.sellDate,
    this.note,
    this.expiryDate,
    this.sortOrder = 0,
  });
}
