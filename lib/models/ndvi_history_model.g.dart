// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ndvi_history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NdviHistoryModelAdapter extends TypeAdapter<NdviHistoryModel> {
  @override
  final int typeId = 1;

  @override
  NdviHistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NdviHistoryModel(
      farmId: fields[0] as String,
      ndviValue: fields[1] as double,
      date: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, NdviHistoryModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.farmId)
      ..writeByte(1)
      ..write(obj.ndviValue)
      ..writeByte(2)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NdviHistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
