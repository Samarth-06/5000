import 'sat2farm_api_models.dart';

/// Vegetation index data from /api/info and /satellite/ndvi
class VegetationData {
  final double ndvi;
  final double lswi;
  final double rvi;
  final double sm;
  final String captureDate;
  final String? healthStatus;
  final String? satellite;

  VegetationData({
    required this.ndvi,
    required this.lswi,
    required this.rvi,
    required this.sm,
    required this.captureDate,
    this.healthStatus,
    this.satellite,
  });

  factory VegetationData.fromApiInfo(Map<String, dynamic> json) {
    return VegetationData(
      ndvi: (json['NDVI'] as num?)?.toDouble() ?? 0.0,
      lswi: (json['LSWI'] as num?)?.toDouble() ?? 0.0,
      rvi: (json['RVI'] as num?)?.toDouble() ?? 0.0,
      sm: (json['SM'] as num?)?.toDouble() ?? 0.0,
      captureDate: json['capture_date']?.toString() ?? '',
    );
  }

  factory VegetationData.fromSatelliteNdvi(
    Map<String, dynamic> ndviJson,
    Map<String, dynamic> infoJson,
  ) {
    return VegetationData(
      ndvi: (ndviJson['ndvi'] as num?)?.toDouble() ?? 0.0,
      lswi: (infoJson['LSWI'] as num?)?.toDouble() ?? 0.0,
      rvi: (infoJson['RVI'] as num?)?.toDouble() ?? 0.0,
      sm: (infoJson['SM'] as num?)?.toDouble() ?? 0.0,
      captureDate: infoJson['capture_date']?.toString() ?? '',
      healthStatus: ndviJson['health_status']?.toString(),
      satellite: ndviJson['satellite']?.toString(),
    );
  }

  factory VegetationData.fromApiResponses(
    SatelliteNdviResponse ndvi,
    ApiInfoResponse info,
  ) {
    return VegetationData(
      ndvi: ndvi.ndvi,
      lswi: info.lswi,
      rvi: info.rvi,
      sm: info.sm,
      captureDate: info.captureDate,
      healthStatus: ndvi.healthStatus,
      satellite: ndvi.satellite,
    );
  }

  Map<String, dynamic> toSupabase(String farmId) => {
    'farm_id': farmId,
    'ndvi': ndvi,
    'lswi': lswi,
    'rvi': rvi,
    'sm': sm,
    'timestamp': DateTime.now().toIso8601String(),
  };
}
