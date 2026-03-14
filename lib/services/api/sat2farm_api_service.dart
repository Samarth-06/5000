import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../models/vegetation_model.dart';
import '../../models/weather_daypart_model.dart';
import '../../models/crop_advisory_model.dart';
import '../../models/dashboard_models.dart';
import '../../models/sat2farm_api_models.dart';

/// Unified API service for the Sat2Farm API.
class Sat2FarmApiService {
  late final Dio _dio;

  Sat2FarmApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.sat2farmBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
  }

  // ── Dashboard ───────────────────────────────────────────────────────────────
  Future<DashboardSummary?> getDashboard() async {
    try {
      final res = await _dio.get('/dashboard');
      return DashboardSummary.fromJson(res.data);
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

  Future<FarmPolygonResponse?> showPolygon({String? farmId}) async {
    try {
      final query = farmId != null && farmId.isNotEmpty
          ? <String, dynamic>{'farmID': farmId}
          : null;
      final res = await _dio.get('/showPolygon', queryParameters: query);
      return FarmPolygonResponse.fromJson(_asMap(res.data));
    } catch (_) {
      return null;
    }
  }

  Future<PolygonDeleteResponse?> deletePolygon({String? farmId}) async {
    try {
      final query = farmId != null && farmId.isNotEmpty
          ? <String, dynamic>{'farmID': farmId}
          : null;
      final res = await _dio.get('/deletePolygon', queryParameters: query);
      return PolygonDeleteResponse.fromJson(_asMap(res.data));
    } catch (_) {
      return null;
    }
  }

  // ── Satellite / Vegetation ──────────────────────────────────────────────────
  Future<SatelliteNdviResponse?> getSatelliteNdvi() async {
    try {
      final res = await _dio.get('/satellite/ndvi');
      return SatelliteNdviResponse.fromJson(_asMap(res.data));
    } catch (_) {
      return null;
    }
  }

  Future<ApiInfoResponse?> getApiInfo() async {
    try {
      final res = await _dio.get('/api/info');
      return ApiInfoResponse.fromJson(_asMap(res.data));
    } catch (_) {
      return null;
    }
  }

  /// Fetches both endpoints and merges into VegetationData.
  Future<VegetationData?> getVegetationData() async {
    try {
      final results = await Future.wait([
        _dio.get('/satellite/ndvi'),
        _dio.get('/api/info'),
      ]);
      final ndvi = SatelliteNdviResponse.fromJson(_asMap(results[0].data));
      final info = ApiInfoResponse.fromJson(_asMap(results[1].data));
      return VegetationData.fromApiResponses(ndvi, info);
    } catch (_) {
      return null;
    }
  }

  // ── Weather ─────────────────────────────────────────────────────────────────
  Future<List<WeatherDaypart>> getWeatherDaypart() async {
    try {
      final res = await _dio.get('/weather/data/daypart');
      final list = _extractListPayloadDynamic(res.data);
      return list.map((e) => WeatherDaypart.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Irrigation ──────────────────────────────────────────────────────────────
  Future<IrrigationDataResponse?> getIrrigationData() async {
    try {
      final res = await _dio.get('/Irrigation/data');
      return IrrigationDataResponse.fromJson(_asMap(res.data));
    } catch (_) {
      return null;
    }
  }

  // ── Crop Advisory ──────────────────────────────────────────────────────────
  Future<List<CropAdvisory>> getCropAdvisory() async {
    try {
      final res = await _dio.get('/cropadvisory/info');
      final list = _extractListPayloadDynamic(res.data);
      return list.map((e) => CropAdvisory.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Crop Calendar ──────────────────────────────────────────────────────────
  Future<List<CropCalendarEntry>> getCropCalendar() async {
    try {
      final res = await _dio.get('/display/crop/calender/v2');
      final list = _extractListPayloadDynamic(res.data);
      return list.map((e) => CropCalendarEntry.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Soil Report ─────────────────────────────────────────────────────────────
  Future<SoilReport?> getSoilReport(String farmId) async {
    try {
      final res = await _dio.get('/user/soilreport/pdf/$farmId');
      return SoilReport.fromJson(res.data);
    } catch (_) {
      return null;
    }
  }

  // ── Image ──────────────────────────────────────────────────────────────────
  Future<ImageUploadResponse?> saveImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final res = await _dio.post('/save/image', data: formData);
      return ImageUploadResponse.fromJson(_asMap(res.data));
    } catch (_) {
      return null;
    }
  }

  Future<List<RetrievedImage>> retrieveImages() async {
    try {
      final res = await _dio.get('/retrieve/image');
      final list = _extractListPayloadDynamic(res.data);
      return list.map((e) => RetrievedImage.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ImageReport>> getImageAdvisory() async {
    try {
      final res = await _dio.get('/user/get/image/advisory');
      final list = _extractListPayloadDynamic(res.data);
      return list.map((e) => ImageReport.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
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
