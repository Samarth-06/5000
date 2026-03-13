import 'package:hive/hive.dart';

part 'farm_hive_model.g.dart';

@HiveType(typeId: 0)
class FarmHiveModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String cropType;

  @HiveField(3)
  late double latitude;

  @HiveField(4)
  late double longitude;

  @HiveField(5)
  late double areaInAcres;

  @HiveField(6)
  String? agroPolygonId; // Agromonitoring polygon ID after registration

  FarmHiveModel({
    required this.id,
    required this.name,
    required this.cropType,
    required this.latitude,
    required this.longitude,
    required this.areaInAcres,
    this.agroPolygonId,
  });
}
