import 'package:hive/hive.dart';

part 'ndvi_history_model.g.dart';

@HiveType(typeId: 1)
class NdviHistoryModel extends HiveObject {
  @HiveField(0)
  late String farmId;

  @HiveField(1)
  late double ndviValue;

  @HiveField(2)
  late DateTime date;

  NdviHistoryModel({
    required this.farmId,
    required this.ndviValue,
    required this.date,
  });
}
