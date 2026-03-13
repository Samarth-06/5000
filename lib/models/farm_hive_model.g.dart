// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'farm_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FarmHiveModelAdapter extends TypeAdapter<FarmHiveModel> {
  @override
  final int typeId = 0;

  @override
  FarmHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FarmHiveModel(
      id: fields[0] as String,
      name: fields[1] as String,
      cropType: fields[2] as String,
      latitude: fields[3] as double,
      longitude: fields[4] as double,
      areaInAcres: fields[5] as double,
      agroPolygonId: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FarmHiveModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.cropType)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.areaInAcres)
      ..writeByte(6)
      ..write(obj.agroPolygonId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FarmHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
