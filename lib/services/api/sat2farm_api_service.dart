import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../models/vegetation_model.dart';
import '../../models/weather_daypart_model.dart';
import '../../models/crop_advisory_model.dart';
import '../../models/dashboard_models.dart';
import '../../models/sat2farm_api_models.dart';

/// Unified API service for the Sat2Farm satellite data API.
/// Base URL: https://badal023-testapi.hf.space
class Sat2FarmApiService {
  late final Dio _dio;

  Sat2FarmApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.sat2farmBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  /// Build standard query params, always including farmID when available.
  Map<String, dynamic> _q({String? farmId, Map<String, dynamic>? extra}) {
    final m = <String, dynamic>{};
    if (farmId != null && farmId.isNotEmpty) m['farmID'] = farmId;
    if (extra != null) m.addAll(extra);
    return m;
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────
  /// GET /dashboard → ndvi, temperature, soil_moisture, rain_probability, recommendations
  Future<DashboardSummary?> getDashboard({String? farmId}) async {
    try {
      final res = await _dio.get('/dashboard', queryParameters: _q(farmId: farmId));
      return DashboardSummary.fromJson(_asMap(res.data));
    } catch (_) {
      return null;
    }
  }

  // ── Farm Management ────────────────────────────────────────────────────────
  Future<FarmListResponse> getFarmList() async {
    try {
      final res = await _dio.get('/farm/list');
      return FarmListResponse.fromJson(_asMap(res.data));
    } catch (_) {
      return const FarmListResponse(farmIds: []);
    }
  }

  Future<PolygonAddResponse?> addPolygon(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/addPolygon', data: data);
      return PolygonAddResponse.fromJson(_asMap(res.data));
    } catch (_) {
      return null;
    }
  }

  /// Convenience: register a farm location with the Sat2Farm API.
  Future<void> registerFarm({required double lat, required double lng, required String farmId}) async {
    await addPolygon({'farmID': farmId, 'lat': lat, 'lng': lng});
  }

  Future<FarmPolygonResponse?> showPolygon({String? farmId}) async {
    try {
      final res = await _dio.get('/showPolygon', queryParameters: _q(farmId: farmId));
      return FarmPolygonResponse.fromJson(_asMap(res.data));
    } catch (_) {
      return null;
    }
  }

  Future<PolygonDeleteResponse?> deletePolygon({String? farmId}) async {
    try {
      final res = await _dio.get('/deletePolygon', queryParameters: _q(farmId: farmId));
      return PolygonDeleteResponse.fromJson(_asMap(res.data));
    } catch (_) {
      return null;
    }
  }

  // ── Satellite / Vegetation ──────────────────────────────────────────────────
  /// GET /satellite/ndvi → ndvi, satellite, health_status
  Future<SatelliteNdviResponse?> getSatelliteNdvi({String? farmId}) async {
    try {
      final res = await _dio.get('/satellite/ndvi', queryParameters: _q(farmId: farmId));
      return SatelliteNdviResponse.fromJson(_asMap(res.data));
    } catch (_) {
      return null;
    }
  }

  /// GET /api/info → NDVI, LSWI, RVI, SM, capture_date
  Future<ApiInfoResponse?> getApiInfo({String? farmId}) async {
    try {
      final res = await _dio.get('/api/info', queryParameters: _q(farmId: farmId));
      return ApiInfoResponse.fromJson(_asMap(res.data));
    } catch (_) {
      return null;
    }
  }

  /// Fetches /satellite/ndvi and /api/info in parallel, merges into VegetationData.
  Future<VegetationData?> getVegetationData({String? farmId}) async {
    try {
      final params = _q(farmId: farmId);
      final results = await Future.wait([
        _dio.get('/satellite/ndvi', queryParameters: params),
        _dio.get('/api/info', queryParameters: params),
      ]);
      final ndvi = SatelliteNdviResponse.fromJson(_asMap(results[0].data));
      final info = ApiInfoResponse.fromJson(_asMap(results[1].data));
      return VegetationData.fromApiResponses(ndvi, info);
    } catch (_) {
      return null;
    }
  }

  // ── Weather ─────────────────────────────────────────────────────────────────
  /// GET /weather/data/daypart → 7-day weather forecast list
  Future<List<WeatherDaypart>> getWeatherDaypart({String? farmId}) async {
    try {
      final res = await _dio.get('/weather/data/daypart',
          queryParameters: _q(farmId: farmId));
      final list = _extractListPayloadDynamic(res.data);
      return list.map((e) => WeatherDaypart.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Irrigation ──────────────────────────────────────────────────────────────
  Future<IrrigationDataResponse?> getIrrigationData({String? farmId}) async {
    try {
      final res = await _dio.get('/Irrigation/data',
          queryParameters: _q(farmId: farmId));
      return IrrigationDataResponse.fromJson(_asMap(res.data));
    } catch (_) {
      return null;
    }
  }

  // ── Crop Advisory ──────────────────────────────────────────────────────────
  /// GET /cropadvisory/info → active crop diseases/pests with solutions
  Future<List<CropAdvisory>> getCropAdvisory({String? farmId}) async {
    try {
      final res = await _dio.get('/cropadvisory/info',
          queryParameters: _q(farmId: farmId));
      final list = _extractListPayloadDynamic(res.data);
      return list.map((e) => CropAdvisory.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Crop Calendar ──────────────────────────────────────────────────────────
  Future<List<CropCalendarEntry>> getCropCalendar({String? farmId}) async {
    try {
      final res = await _dio.get('/display/crop/calender/v2',
          queryParameters: _q(farmId: farmId));
      final list = _extractListPayloadDynamic(res.data);
      return list.map((e) => CropCalendarEntry.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Soil Report ─────────────────────────────────────────────────────────────
  /// GET /user/soilreport/pdf/{farmId} → PDF, CSV, N/P/K/pH images
  Future<SoilReport?> getSoilReport(String farmId) async {
    try {
      final res = await _dio.get('/user/soilreport/pdf/$farmId');
      return SoilReport.fromJson(_asMap(res.data));
    } catch (_) {
      return null;
    }
  }

  // ── Image ──────────────────────────────────────────────────────────────────
  Future<ImageUploadResponse?> saveImage(String filePath, {String? farmId}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        if (farmId != null) 'farmID': farmId,
      });
      final res = await _dio.post('/save/image', data: formData);
      return ImageUploadResponse.fromJson(_asMap(res.data));
    } catch (_) {
      return null;
    }
  }

  Future<List<RetrievedImage>> retrieveImages({String? farmId}) async {
    try {
      final res = await _dio.get('/retrieve/image',
          queryParameters: _q(farmId: farmId));
      final list = _extractListPayloadDynamic(res.data);
      return list.map((e) => RetrievedImage.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ImageReport>> getImageAdvisory({String? farmId}) async {
    try {
      final res = await _dio.get('/user/get/image/advisory',
          queryParameters: _q(farmId: farmId));
      final list = _extractListPayloadDynamic(res.data);
      return list.map((e) => ImageReport.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _extractListPayload(Map<String, dynamic> json) {
    final raw = json['value'] ?? json['data'] ?? json['items'] ?? json;
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  List<Map<String, dynamic>> _extractListPayloadDynamic(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return _extractListPayload(_asMap(data));
  }
}
