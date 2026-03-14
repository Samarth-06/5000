class FarmListResponse {
  final List<String> farmIds;

  const FarmListResponse({required this.farmIds});

  factory FarmListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['Farm IDs'];
    if (raw is List) {
      return FarmListResponse(farmIds: raw.map((e) => e.toString()).toList());
    }
    return const FarmListResponse(farmIds: []);
  }
}

class PolygonAddResponse {
  final String? farmId;
  final String status;

  const PolygonAddResponse({required this.farmId, required this.status});

  bool get isSuccess => status.toLowerCase() == 'success';

  factory PolygonAddResponse.fromJson(Map<String, dynamic> json) {
    return PolygonAddResponse(
      farmId: json['farmID']?.toString(),
      status: json['status']?.toString() ?? 'unknown',
    );
  }
}

class PolygonDeleteResponse {
  final String status;
  final String? message;

  const PolygonDeleteResponse({required this.status, this.message});

  bool get isSuccess => status.toLowerCase() == 'success';

  factory PolygonDeleteResponse.fromJson(Map<String, dynamic> json) {
    return PolygonDeleteResponse(
      status: (json['status'] ?? (json['error'] != null ? 'error' : 'unknown'))
          .toString(),
      message: json['error']?.toString() ?? json['message']?.toString(),
    );
  }
}

class FarmPolygonResponse {
  final String farmId;
  final String cropType;
  final String district;
  final String state;
  final String? sowingDate;
  final double area;
  final int? cropStage;
  final List<double>? center;
  final List<List<double>> coordinates;

  const FarmPolygonResponse({
    required this.farmId,
    required this.cropType,
    required this.district,
    required this.state,
    required this.sowingDate,
    required this.area,
    required this.cropStage,
    required this.center,
    required this.coordinates,
  });

  bool get hasCoordinates => coordinates.isNotEmpty;

  factory FarmPolygonResponse.fromJson(Map<String, dynamic> json) {
    final coords = _extractCoordinates(json);
    final center = _extractCenter(json);
    final area = (json['area'] as num?)?.toDouble() ?? 0.0;

    return FarmPolygonResponse(
      farmId: json['farmID']?.toString() ?? '',
      cropType: json['crop_type']?.toString() ?? '',
      district: json['District']?.toString() ?? '',
      state: json['State']?.toString() ?? '',
      sowingDate: json['Sowing_date']?.toString(),
      area: area,
      cropStage: (json['crop_stage'] as num?)?.toInt(),
      center: center,
      coordinates: coords.isNotEmpty
          ? coords
          : _generateBoundaryFromCenter(center: center, areaAcres: area),
    );
  }

  static List<List<double>> _extractCoordinates(Map<String, dynamic> json) {
    final geo = json['geo_json'];
    if (geo is! Map<String, dynamic>) return const [];
    final geometry = geo['geometry'];
    if (geometry is! Map<String, dynamic>) return const [];
    final rawCoords = geometry['coordinates'];
    if (rawCoords is! List || rawCoords.isEmpty) return const [];
    final ring = rawCoords.first;
    if (ring is! List) return const [];

    final out = <List<double>>[];
    for (final p in ring) {
      if (p is List && p.length >= 2) {
        final lng = (p[0] as num?)?.toDouble();
        final lat = (p[1] as num?)?.toDouble();
        if (lng != null && lat != null) {
          out.add([lng, lat]);
        }
      }
    }
    return out;
  }

  static List<double>? _extractCenter(Map<String, dynamic> json) {
    final raw = json['Center'];
    if (raw is List && raw.length >= 2) {
      final lng = (raw[0] as num?)?.toDouble();
      final lat = (raw[1] as num?)?.toDouble();
      if (lng != null && lat != null) return [lng, lat];
    }
    return null;
  }

  static List<List<double>> _generateBoundaryFromCenter({
    required List<double>? center,
    required double areaAcres,
  }) {
    if (center == null || center.length < 2) return const [];
    final lng = center[0];
    final lat = center[1];
    final acres = areaAcres > 0 ? areaAcres : 1.0;
    final sideMeters = (acres * 4047).clamp(400.0, 1000000.0);
    final halfMeters = sideMeters / 2;
    final latOffset = halfMeters / 111320;
    final lngOffset = halfMeters / (111320 * 0.9);
    return [
      [lng - lngOffset, lat - latOffset],
      [lng + lngOffset, lat - latOffset],
      [lng + lngOffset, lat + latOffset],
      [lng - lngOffset, lat + latOffset],
      [lng - lngOffset, lat - latOffset],
    ];
  }
}

class IrrigationDataResponse {
  final String status;
  final String? dataUrl;

  const IrrigationDataResponse({required this.status, this.dataUrl});

  factory IrrigationDataResponse.fromJson(Map<String, dynamic> json) {
    return IrrigationDataResponse(
      status: json['status']?.toString() ?? 'unknown',
      dataUrl: json['Irrigation_data']?.toString(),
    );
  }
}

class SatelliteNdviResponse {
  final double ndvi;
  final String? satellite;
  final String? healthStatus;
  final String? farmId;

  const SatelliteNdviResponse({
    required this.ndvi,
    required this.satellite,
    required this.healthStatus,
    required this.farmId,
  });

  factory SatelliteNdviResponse.fromJson(Map<String, dynamic> json) {
    return SatelliteNdviResponse(
      ndvi: (json['ndvi'] as num?)?.toDouble() ?? 0.0,
      satellite: json['satellite']?.toString(),
      healthStatus: json['health_status']?.toString(),
      farmId: json['farmID']?.toString(),
    );
  }
}

class ApiInfoResponse {
  final double ndvi;
  final double lswi;
  final double rvi;
  final double sm;
  final String captureDate;

  const ApiInfoResponse({
    required this.ndvi,
    required this.lswi,
    required this.rvi,
    required this.sm,
    required this.captureDate,
  });

  factory ApiInfoResponse.fromJson(Map<String, dynamic> json) {
    return ApiInfoResponse(
      ndvi: (json['NDVI'] as num?)?.toDouble() ?? 0.0,
      lswi: (json['LSWI'] as num?)?.toDouble() ?? 0.0,
      rvi: (json['RVI'] as num?)?.toDouble() ?? 0.0,
      sm: (json['SM'] as num?)?.toDouble() ?? 0.0,
      captureDate: json['capture_date']?.toString() ?? '',
    );
  }
}

class ImageUploadResponse {
  final String status;
  final String? imageUrl;
  final String? message;

  const ImageUploadResponse({
    required this.status,
    required this.imageUrl,
    required this.message,
  });

  bool get isSuccess => status.toLowerCase() == 'success';

  factory ImageUploadResponse.fromJson(Map<String, dynamic> json) {
    return ImageUploadResponse(
      status: json['status']?.toString() ?? 'unknown',
      imageUrl: json['Image_URL']?.toString() ?? json['image_url']?.toString(),
      message: json['message']?.toString(),
    );
  }
}

class RetrievedImage {
  final String imageName;
  final String imageUrl;
  final String? flag;
  final String? farmId;

  const RetrievedImage({
    required this.imageName,
    required this.imageUrl,
    required this.flag,
    required this.farmId,
  });

  factory RetrievedImage.fromJson(Map<String, dynamic> json) {
    return RetrievedImage(
      imageName: json['Image_Name']?.toString() ?? '',
      imageUrl: json['Image_URL']?.toString() ?? '',
      flag: json['flag']?.toString(),
      farmId: json['Farm_ID']?.toString(),
    );
  }
}
