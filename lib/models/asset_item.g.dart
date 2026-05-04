// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssetItemAdapter extends TypeAdapter<AssetItem> {
  @override
  final int typeId = 3;

  @override
  AssetItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AssetItem(
      id: fields[0] as int,
      name: fields[1] as String,
      emojiIcon: fields[2] as String,
      category: fields[3] as AssetCategory,
      buyPrice: fields[4] as double,
      buyDate: fields[5] as DateTime,
      currentValue: fields[6] as double,
      depreciationModel: fields[7] as DepreciationModel,
      status: fields[8] as ItemStatus,
      sellPrice: fields[9] as double?,
      sellDate: fields[10] as DateTime?,
      note: fields[11] as String?,
      expiryDate: fields[12] as DateTime?,
      sortOrder: fields[13] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AssetItem obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.emojiIcon)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.buyPrice)
      ..writeByte(5)
      ..write(obj.buyDate)
      ..writeByte(6)
      ..write(obj.currentValue)
      ..writeByte(7)
      ..write(obj.depreciationModel)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.sellPrice)
      ..writeByte(10)
      ..write(obj.sellDate)
      ..writeByte(11)
      ..write(obj.note)
      ..writeByte(12)
      ..write(obj.expiryDate)
      ..writeByte(13)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AssetCategoryAdapter extends TypeAdapter<AssetCategory> {
  @override
  final int typeId = 0;

  @override
  AssetCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AssetCategory.digital;
      case 1:
        return AssetCategory.transport;
      case 2:
        return AssetCategory.furniture;
      case 3:
        return AssetCategory.fashion;
      case 4:
        return AssetCategory.service;
      case 5:
        return AssetCategory.appliance;
      case 6:
        return AssetCategory.entertainment;
      case 7:
        return AssetCategory.sports;
      case 8:
        return AssetCategory.education;
      case 9:
        return AssetCategory.housing;
      case 10:
        return AssetCategory.other;
      default:
        return AssetCategory.digital;
    }
  }

  @override
  void write(BinaryWriter writer, AssetCategory obj) {
    switch (obj) {
      case AssetCategory.digital:
        writer.writeByte(0);
        break;
      case AssetCategory.transport:
        writer.writeByte(1);
        break;
      case AssetCategory.furniture:
        writer.writeByte(2);
        break;
      case AssetCategory.fashion:
        writer.writeByte(3);
        break;
      case AssetCategory.service:
        writer.writeByte(4);
        break;
      case AssetCategory.appliance:
        writer.writeByte(5);
        break;
      case AssetCategory.entertainment:
        writer.writeByte(6);
        break;
      case AssetCategory.sports:
        writer.writeByte(7);
        break;
      case AssetCategory.education:
        writer.writeByte(8);
        break;
      case AssetCategory.housing:
        writer.writeByte(9);
        break;
      case AssetCategory.other:
        writer.writeByte(10);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DepreciationModelAdapter extends TypeAdapter<DepreciationModel> {
  @override
  final int typeId = 1;

  @override
  DepreciationModel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DepreciationModel.modelA_Linear;
      case 1:
        return DepreciationModel.modelB_DropAndDecay;
      case 2:
        return DepreciationModel.modelC_SlowDecay;
      default:
        return DepreciationModel.modelA_Linear;
    }
  }

  @override
  void write(BinaryWriter writer, DepreciationModel obj) {
    switch (obj) {
      case DepreciationModel.modelA_Linear:
        writer.writeByte(0);
        break;
      case DepreciationModel.modelB_DropAndDecay:
        writer.writeByte(1);
        break;
      case DepreciationModel.modelC_SlowDecay:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepreciationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ItemStatusAdapter extends TypeAdapter<ItemStatus> {
  @override
  final int typeId = 2;

  @override
  ItemStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ItemStatus.active;
      case 1:
        return ItemStatus.archived;
      case 2:
        return ItemStatus.retired;
      default:
        return ItemStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, ItemStatus obj) {
    switch (obj) {
      case ItemStatus.active:
        writer.writeByte(0);
        break;
      case ItemStatus.archived:
        writer.writeByte(1);
        break;
      case ItemStatus.retired:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
