// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DemandForecastAdapter extends TypeAdapter<DemandForecast> {
  @override
  final int typeId = 5;

  @override
  DemandForecast read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DemandForecast(
      productId: fields[0] as String,
      productName: fields[1] as String,
      currentStock: fields[2] as int,
      predictedReorderDate: fields[3] as DateTime,
      recommendedQuantity: fields[4] as int,
      daysUntilReorder: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DemandForecast obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.currentStock)
      ..writeByte(3)
      ..write(obj.predictedReorderDate)
      ..writeByte(4)
      ..write(obj.recommendedQuantity)
      ..writeByte(5)
      ..write(obj.daysUntilReorder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DemandForecastAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StockHealthScoreAdapter extends TypeAdapter<StockHealthScore> {
  @override
  final int typeId = 6;

  @override
  StockHealthScore read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockHealthScore(
      productId: fields[0] as String,
      productName: fields[1] as String,
      healthScore: fields[2] as int,
      status: fields[3] as String,
      currentStock: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, StockHealthScore obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.healthScore)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.currentStock);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockHealthScoreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
