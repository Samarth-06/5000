import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';

/// Satellite & NDVI data from Agromonitoring.com
class AgroApiService {
  Dio get _dio {
    final apiKey = Hive.box(AppConstants.settingsBox).get(AppConstants.keyAgroApiKey, defaultValue: 'PLACEHOLDER');
    return Dio(BaseOptions(
      baseUrl: AppConstants.agroBaseUrl,
      queryParameters: {'appid': apiKey},
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
  }

  /// Register a farm as a polygon on Agromonitoring
  Future<String?> createPolygon({
    required String name,
    required double lat,
    required double lng,
  }) async {
    // Approximate bounding box (~0.01 degree = ~1km square)
    const offset = 0.005;
    try {
      final res = await _dio.post('/polygons', data: {
        'name': name,
        'geo_json': {
          'type': 'Feature',
          'properties': {},
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [
                [lng - offset, lat - offset],
                [lng + offset, lat - offset],
                [lng + offset, lat + offset],
                [lng - offset, lat + offset],
                [lng - offset, lat - offset],
              ]
            ],
          }
        }
      });
      return res.data['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Fetch latest NDVI statistics for a polygon
  Future<Map<String, dynamic>?> fetchNdvi(String polygonId) async {
    try {
      final res = await _dio.get('/ndvi/sat-img', queryParameters: {
        'polyid': polygonId,
        'limit': 10,
      });
      final List data = res.data;
      if (data.isEmpty) return null;
      // Most recent
      final latest = data.first;
      return {
        'mean': _safeDouble(latest, 'mean'),
        'min': _safeDouble(latest, 'min'),
        'max': _safeDouble(latest, 'max'),
        'date': latest['dt'],
        'imageUrl': latest['image']?['truecolor'] ?? '',
        'ndviImageUrl': latest['image']?['falsecolor'] ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  double _safeDouble(Map d, String k) {
    final v = d['data']?[k];
    if (v == null) return 0.0;
    return (v as num).toDouble();
  }
}
