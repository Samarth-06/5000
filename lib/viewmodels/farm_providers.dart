import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/farm_hive_model.dart';
import '../models/vegetation_model.dart';
import '../models/weather_daypart_model.dart';
import '../models/crop_advisory_model.dart';
import '../models/dashboard_models.dart';
import '../models/sat2farm_api_models.dart';
import '../repositories/farm_repository.dart';
import '../services/api/sat2farm_api_service.dart';
import '../services/supabase_service.dart';
import '../services/gemini_service.dart';
import '../services/notification_service.dart';
import '../services/smart_analytics.dart';
import 'locale_provider.dart';

// ─── Services / Repos ──────────────────────────────────────────────────────
final farmRepositoryProvider = Provider((_) => FarmRepository());
final sat2farmApiProvider = Provider((_) => Sat2FarmApiService());
final supabaseServiceProvider = Provider((_) => SupabaseService());
final geminiServiceProvider = Provider((_) => GeminiService());

// ─── Farm List ─────────────────────────────────────────────────────────────
class FarmListNotifier extends Notifier<List<FarmHiveModel>> {
  @override
  List<FarmHiveModel> build() => ref.read(farmRepositoryProvider).getAllFarms();

  Future<void> addFarm(FarmHiveModel farm) async {
    await ref.read(farmRepositoryProvider).saveFarm(farm);
    try {
      final supa = ref.read(supabaseServiceProvider);
      if (supa.isLoggedIn) {
        await supa.insertFarm({
          'user_id': supa.currentUser!.id,
          'farm_id': farm.id,
          'crop_type': farm.cropType,
          'location': {'lat': farm.latitude, 'lng': farm.longitude},
          'name': farm.name,
          'area_in_acres': farm.areaInAcres,
        });
      }
    } catch (_) {}
    state = ref.read(farmRepositoryProvider).getAllFarms();
  }

  Future<void> deleteFarm(String id) async {
    await ref.read(farmRepositoryProvider).deleteFarm(id);
    state = ref.read(farmRepositoryProvider).getAllFarms();
  }
}

final farmListProvider =
    NotifierProvider<FarmListNotifier, List<FarmHiveModel>>(
      FarmListNotifier.new,
    );

// ─── Selected Farm ────────────────────────────────────────────────────────
class SelectedFarmNotifier extends Notifier<FarmHiveModel?> {
  @override
  FarmHiveModel? build() => null;
  void select(FarmHiveModel? farm) => state = farm;
}

final selectedFarmProvider =
    NotifierProvider<SelectedFarmNotifier, FarmHiveModel?>(
      SelectedFarmNotifier.new,
    );

// ─── Dashboard State ──────────────────────────────────────────────────────
class DashboardState {
  final bool isLoading;
  final DashboardSummary? summary;
  final VegetationData? vegetation;
  final List<WeatherDaypart> weatherForecast;
  final List<CropAdvisory> cropAdvisory;
  final List<CropCalendarEntry> cropCalendar;
  final IrrigationDataResponse? irrigationData;
  final SoilReport? soilReport;
  final List<Map<String, dynamic>> vegetationHistory;
  final String? irrigationAdvice;
  final int irrigationUrgency;
  final TrendResult? cropTrend;
  final List<List<double>>? farmPolygonCoords;
  final String? error;

  const DashboardState({
    this.isLoading = false,
    this.summary,
    this.vegetation,
    this.weatherForecast = const [],
    this.cropAdvisory = const [],
    this.cropCalendar = const [],
    this.irrigationData,
    this.soilReport,
    this.vegetationHistory = const [],
    this.irrigationAdvice,
    this.irrigationUrgency = 1,
    this.cropTrend,
    this.farmPolygonCoords,
    this.error,
  });

  DashboardState copyWith({
    bool? isLoading,
    DashboardSummary? summary,
    VegetationData? vegetation,
    List<WeatherDaypart>? weatherForecast,
    List<CropAdvisory>? cropAdvisory,
    List<CropCalendarEntry>? cropCalendar,
    IrrigationDataResponse? irrigationData,
    SoilReport? soilReport,
    List<Map<String, dynamic>>? vegetationHistory,
    String? irrigationAdvice,
    int? irrigationUrgency,
    TrendResult? cropTrend,
    List<List<double>>? farmPolygonCoords,
    String? error,
  }) => DashboardState(
    isLoading: isLoading ?? this.isLoading,
    summary: summary ?? this.summary,
    vegetation: vegetation ?? this.vegetation,
    weatherForecast: weatherForecast ?? this.weatherForecast,
    cropAdvisory: cropAdvisory ?? this.cropAdvisory,
    cropCalendar: cropCalendar ?? this.cropCalendar,
    irrigationData: irrigationData ?? this.irrigationData,
    soilReport: soilReport ?? this.soilReport,
    vegetationHistory: vegetationHistory ?? this.vegetationHistory,
    irrigationAdvice: irrigationAdvice ?? this.irrigationAdvice,
    irrigationUrgency: irrigationUrgency ?? this.irrigationUrgency,
    cropTrend: cropTrend ?? this.cropTrend,
    farmPolygonCoords: farmPolygonCoords ?? this.farmPolygonCoords,
    error: error,
  );
}

// ─── Backward-compat extension (used by legacy UI screens) ─────────────────
extension DashboardStateCompat on DashboardState {
  /// Legacy: returns a Map<String,dynamic> mirroring old ndviData shape
  Map<String, dynamic>? get ndviData {
    final s = summary;
    final v = vegetation;
    if (s == null && v == null) return null;
    return {
      'mean': v?.ndvi ?? s?.ndvi ?? 0.0,
      'min':  (v?.ndvi ?? s?.ndvi ?? 0.0) - 0.05,
      'max':  (v?.ndvi ?? s?.ndvi ?? 0.0) + 0.05,
    };
  }

  /// Legacy: returns a Map<String,dynamic> mirroring old weatherData shape
  Map<String, dynamic>? get weatherData {
    final s = summary;
    if (s == null && weatherForecast.isEmpty) return null;
    final w = weatherForecast.isNotEmpty ? weatherForecast.first : null;
    return {
      'temp': s?.temperature ?? w?.dayTemp ?? 0.0,
      'humidity': (vegetation?.sm ?? s?.soilMoisture ?? 0.0).clamp(0, 100),
      'wind_speed': w?.windSpeed ?? 0.0,
      'rain': s?.rainProbability ?? w?.precipChance ?? 0.0,
      'condition': w?.narrative ?? 'clear',
    };
  }

  /// Legacy: returns NDVI history as NdviHistoryModel-like objects via vegetationHistory
  List<Map<String, dynamic>> get ndviHistory =>
      vegetationHistory.map((h) => {
        'ndvi': (h['ndvi'] as num?)?.toDouble() ?? 0.0,
        'timestamp': h['timestamp']?.toString() ?? '',
      }).toList();
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
      final api = ref.read(sat2farmApiProvider);
      final supa = ref.read(supabaseServiceProvider);

      // Parallel fetch all data
      final results = await Future.wait([
        api.getDashboard(), // 0
        api.getVegetationData(), // 1
        api.getWeatherDaypart(), // 2
        api.getCropAdvisory(), // 3
        api.getCropCalendar(), // 4
        api.getIrrigationData(), // 5
        api.getSoilReport(farm.id), // 6
        api.showPolygon(farmId: farm.agroPolygonId ?? farm.id), // 7
      ]);

      final dashboard = results[0] as DashboardSummary?;
      final vegetation = results[1] as VegetationData?;
      final weather = results[2] as List<WeatherDaypart>;
      var advisory = results[3] as List<CropAdvisory>;
      final calendar = results[4] as List<CropCalendarEntry>;
      final irrigation = results[5] as IrrigationDataResponse?;
      final soil = results[6] as SoilReport?;
      final polygonData = results[7] as FarmPolygonResponse?;
      final languageCode = ref.read(localeProvider).languageCode;

      DashboardSummary? translatedDashboard = dashboard;
      if (languageCode != 'en') {
        final gemini = ref.read(geminiServiceProvider);
        if (dashboard != null && dashboard.recommendations.isNotEmpty) {
          final translatedRecommendations = await Future.wait(
            dashboard.recommendations.map(
              (r) => gemini.translateText(
                text: r,
                targetLanguageCode: languageCode,
              ),
            ),
          );
          translatedDashboard = DashboardSummary(
            ndvi: dashboard.ndvi,
            temperature: dashboard.temperature,
            soilMoisture: dashboard.soilMoisture,
            rainProbability: dashboard.rainProbability,
            recommendations: translatedRecommendations,
          );
        }

        if (advisory.isNotEmpty) {
          final translated = await Future.wait(
            advisory.map((a) async {
              final symptoms = await gemini.translateText(
                text: a.symptoms,
                targetLanguageCode: languageCode,
              );
              final solution = await gemini.translateText(
                text: a.solution,
                targetLanguageCode: languageCode,
              );
              return CropAdvisory(
                cropName: a.cropName,
                disease: a.disease,
                pest: a.pest,
                symptoms: symptoms,
                solution: solution,
                affectedPart: a.affectedPart,
              );
            }),
          );
          advisory = translated;
        }
      }

      final existingHistory = await supa.getVegetationHistory(farm.id, 30);
      final previousNdvi = existingHistory.isNotEmpty
          ? (existingHistory.last['ndvi'] as num?)?.toDouble() ?? 0.0
          : 0.0;

      // Store vegetation data to Supabase every fetch.
      if (vegetation != null) {
        try {
          await supa.insertVegetationHistory(vegetation.toSupabase(farm.id));
        } catch (_) {}
      }

      // Store weather to Supabase
      if (weather.isNotEmpty) {
        try {
          await supa.insertWeatherHistory(weather.first.toSupabase(farm.id));
        } catch (_) {}
      }

      final history = await supa.getVegetationHistory(farm.id, 30);

      // Smart irrigation recommendation
      final ndvi = vegetation?.ndvi ?? dashboard?.ndvi ?? 0.0;
      final soilMoist = dashboard?.soilMoisture ?? 0.0;
      final rainProb =
          dashboard?.rainProbability ??
          (weather.isNotEmpty ? weather.first.precipChance : 0.0);
      final temp =
          dashboard?.temperature ??
          (weather.isNotEmpty ? weather.first.dayTemp : 0.0);

      final irrigAdvisor = IrrigationAdvisor(
        soilMoisture: soilMoist,
        ndvi: ndvi,
        rainProbability: rainProb,
        temperature: temp,
      );

      // Crop growth trend analysis
      final ndviValues = history
          .map((h) => (h['ndvi'] as num?)?.toDouble())
          .whereType<double>()
          .toList();
      final trendResult = CropTrendAnalyzer.analyze(ndviValues);

      final polygonCoords = polygonData?.coordinates;

      try {
        await NotificationService.checkAndAlert(
          ndvi: ndvi,
          previousNdvi: previousNdvi,
          soilMoisture: soilMoist,
          rainProbability: rainProb,
          pestAlerts: advisory.map((a) => a.title).toList(),
        );
      } catch (_) {}

      state = state.copyWith(
        isLoading: false,
        summary: translatedDashboard,
        vegetation: vegetation,
        weatherForecast: weather,
        cropAdvisory: advisory,
        cropCalendar: calendar,
        irrigationData: irrigation,
        soilReport: soil,
        vegetationHistory: history,
        irrigationAdvice: irrigAdvisor.recommendation,
        irrigationUrgency: irrigAdvisor.urgency,
        cropTrend: trendResult,
        farmPolygonCoords: polygonCoords,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not reach API: $e',
      );
    }
  }
}

final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);

// ─── Vegetation History Provider (Supabase) ───────────────────────────────
final vegetationHistoryProvider =
    FutureProvider.family<
      List<Map<String, dynamic>>,
      ({String farmId, int days})
    >((ref, params) async {
      final supa = ref.read(supabaseServiceProvider);
      return supa.getVegetationHistory(params.farmId, params.days);
    });

// ─── Weather History Provider ─────────────────────────────────────────────
final weatherHistoryProvider =
    FutureProvider.family<
      List<Map<String, dynamic>>,
      ({String farmId, int days})
    >((ref, params) async {
      final supa = ref.read(supabaseServiceProvider);
      return supa.getWeatherHistory(params.farmId, params.days);
    });

// ─── Image Reports Provider ──────────────────────────────────────────────
final imageReportsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      farmId,
    ) async {
      final supa = ref.read(supabaseServiceProvider);
      return supa.getImageReports(farmId);
    });
