import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/farm_hive_model.dart';
import '../models/ndvi_history_model.dart';
import '../repositories/farm_repository.dart';
import '../services/api/agro_api_service.dart';
import '../services/api/weather_api_service.dart';

// ─── Services / Repos ──────────────────────────────────────────────────────
final farmRepositoryProvider = Provider((_) => FarmRepository());
final agroApiProvider = Provider((_) => AgroApiService());
final weatherApiProvider = Provider((_) => WeatherApiService());

// ─── Farm List ─────────────────────────────────────────────────────────────
class FarmListNotifier extends Notifier<List<FarmHiveModel>> {
  @override
  List<FarmHiveModel> build() => ref.read(farmRepositoryProvider).getAllFarms();

  Future<void> addFarm(FarmHiveModel farm) async {
    await ref.read(farmRepositoryProvider).saveFarm(farm);
    state = ref.read(farmRepositoryProvider).getAllFarms();
  }

  Future<void> deleteFarm(String id) async {
    await ref.read(farmRepositoryProvider).deleteFarm(id);
    state = ref.read(farmRepositoryProvider).getAllFarms();
  }
}

final farmListProvider = NotifierProvider<FarmListNotifier, List<FarmHiveModel>>(
  FarmListNotifier.new,
);

// ─── Selected Farm ────────────────────────────────────────────────────────
class SelectedFarmNotifier extends Notifier<FarmHiveModel?> {
  @override
  FarmHiveModel? build() => null;
  void select(FarmHiveModel? farm) => state = farm;
}

final selectedFarmProvider = NotifierProvider<SelectedFarmNotifier, FarmHiveModel?>(
  SelectedFarmNotifier.new,
);

// ─── Dashboard State ──────────────────────────────────────────────────────
class DashboardState {
  final bool isLoading;
  final Map<String, dynamic>? ndviData;
  final Map<String, dynamic>? weatherData;
  final List<NdviHistoryModel> ndviHistory;
  final String? error;

  const DashboardState({
    this.isLoading = false,
    this.ndviData,
    this.weatherData,
    this.ndviHistory = const [],
    this.error,
  });

  DashboardState copyWith({
    bool? isLoading,
    Map<String, dynamic>? ndviData,
    Map<String, dynamic>? weatherData,
    List<NdviHistoryModel>? ndviHistory,
    String? error,
  }) =>
      DashboardState(
        isLoading: isLoading ?? this.isLoading,
        ndviData: ndviData ?? this.ndviData,
        weatherData: weatherData ?? this.weatherData,
        ndviHistory: ndviHistory ?? this.ndviHistory,
        error: error,
      );
}

class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    final farm = ref.watch(selectedFarmProvider);
    if (farm != null) {
      Future.microtask(fetchAll);
    }
    return const DashboardState();
  }

  Future<void> fetchAll() async {
    final farm = ref.read(selectedFarmProvider);
    if (farm == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      Map<String, dynamic>? ndvi;
      if (farm.agroPolygonId != null && !farm.agroPolygonId!.contains('PLACEHOLDER')) {
        ndvi = await ref.read(agroApiProvider).fetchNdvi(farm.agroPolygonId!);
        if (ndvi != null) {
          await ref.read(farmRepositoryProvider).saveNdviSnapshot(NdviHistoryModel(
            farmId: farm.id,
            ndviValue: ndvi['mean'] ?? 0.0,
            date: DateTime.fromMillisecondsSinceEpoch((ndvi['date'] as int? ?? 0) * 1000),
          ));
        }
      }

      final weather = await ref.read(weatherApiProvider).fetchWeather(farm.latitude, farm.longitude);
      final history = ref.read(farmRepositoryProvider).getNdviHistory(farm.id);

      state = state.copyWith(
        isLoading: false,
        ndviData: ndvi ?? _mockNdvi(),
        weatherData: weather ?? _mockWeather(),
        ndviHistory: history.isNotEmpty ? history : _mockHistory(),
        error: (ndvi == null || weather == null) ? 'Using demo data – add real API keys in Settings' : null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        ndviData: _mockNdvi(),
        weatherData: _mockWeather(),
        ndviHistory: _mockHistory(),
        error: 'Using demo data – add real API keys in Settings',
      );
    }
  }

  Map<String, dynamic> _mockNdvi() => {'mean': 0.72, 'min': 0.48, 'max': 0.89, 'date': 0, 'imageUrl': '', 'ndviImageUrl': ''};

  Map<String, dynamic> _mockWeather() => {'temp': 28.4, 'humidity': 65.0, 'description': 'Partly cloudy', 'wind_speed': 3.2, 'rainfall': 0.0, 'feels_like': 30.1};

  List<NdviHistoryModel> _mockHistory() {
    final now = DateTime.now();
    return List.generate(8, (i) => NdviHistoryModel(
      farmId: 'mock',
      ndviValue: 0.30 + i * 0.06,
      date: now.subtract(Duration(days: (7 - i) * 5)),
    ));
  }
}

final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);
