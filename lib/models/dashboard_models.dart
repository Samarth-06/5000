/// Image diagnosis result from /user/get/image/advisory
class ImageReport {
  final String cropName;
  final String diseaseName;
  final String symptoms;
  final String solution;
  final String advisory;
  final String? imageUrl;

  ImageReport({
    required this.cropName,
    required this.diseaseName,
    required this.symptoms,
    required this.solution,
    required this.advisory,
    this.imageUrl,
  });

  factory ImageReport.fromJson(Map<String, dynamic> json) {
    return ImageReport(
      cropName: json['crop_name']?.toString() ?? '',
      diseaseName: json['disease_name']?.toString() ?? '',
      symptoms: json['symptoms']?.toString() ?? '',
      solution: json['disease_solution']?.toString() ?? '',
      advisory: json['advisory']?.toString() ?? '',
      imageUrl: json['Image_URL']?.toString(),
    );
  }

  Map<String, dynamic> toSupabase(String farmId) => {
    'farm_id': farmId,
    'image_url': imageUrl ?? '',
    'disease': diseaseName,
    'advisory': advisory.isNotEmpty
        ? advisory
        : (symptoms.isNotEmpty ? symptoms : 'Crop: $cropName'),
    'solution': solution,
    'created_at': DateTime.now().toIso8601String(),
  };
}

/// Dashboard summary from /dashboard
class DashboardSummary {
  final double ndvi;
  final double temperature;
  final double soilMoisture;
  final double rainProbability;
  final List<String> recommendations;

  DashboardSummary({
    required this.ndvi,
    required this.temperature,
    required this.soilMoisture,
    required this.rainProbability,
    required this.recommendations,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      ndvi: (json['ndvi'] as num?)?.toDouble() ?? 0.0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      soilMoisture: (json['soil_moisture'] as num?)?.toDouble() ?? 0.0,
      rainProbability: (json['rain_probability'] as num?)?.toDouble() ?? 0.0,
      recommendations:
          (json['recommendations'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

/// Soil report from /user/soilreport/pdf/{farmid}
class SoilReport {
  final String? pdfUrl;
  final String? csvUrl;
  final String? nImage;
  final String? pImage;
  final String? kImage;
  final String? phImage;

  SoilReport({
    this.pdfUrl,
    this.csvUrl,
    this.nImage,
    this.pImage,
    this.kImage,
    this.phImage,
  });

  factory SoilReport.fromJson(Map<String, dynamic> json) {
    final png = json['png'] as Map<String, dynamic>? ?? {};
    return SoilReport(
      pdfUrl: json['pdf']?.toString(),
      csvUrl: json['csv']?.toString(),
      nImage: png['N']?.toString(),
      pImage: png['P']?.toString(),
      kImage: png['K']?.toString(),
      phImage: png['pH']?.toString(),
    );
  }
}
