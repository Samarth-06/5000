import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';
import '../models/farm_hive_model.dart';
import '../models/ndvi_history_model.dart';

class FarmRepository {
  Box<FarmHiveModel> get _farmsBox => Hive.box<FarmHiveModel>(AppConstants.farmsBox);
  Box<NdviHistoryModel> get _ndviBox => Hive.box<NdviHistoryModel>(AppConstants.ndviHistoryBox);

  // ─── Farms ───────────────────────────────────────────────────────────────
  List<FarmHiveModel> getAllFarms() => _farmsBox.values.toList();

  FarmHiveModel? getFarm(String id) => _farmsBox.get(id);

  Future<void> saveFarm(FarmHiveModel farm) => _farmsBox.put(farm.id, farm);

  Future<void> deleteFarm(String id) => _farmsBox.delete(id);

  // ─── NDVI History ────────────────────────────────────────────────────────
  List<NdviHistoryModel> getNdviHistory(String farmId) =>
      _ndviBox.values.where((e) => e.farmId == farmId).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  Future<void> saveNdviSnapshot(NdviHistoryModel snap) async {
    final key = '${snap.farmId}_${snap.date.millisecondsSinceEpoch}';
    await _ndviBox.put(key, snap);
  }
}
