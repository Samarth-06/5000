class FarmModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double areaInAcres;
  final String cropType;

  FarmModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.areaInAcres,
    required this.cropType,
  });
}

class SatelliteMetricsModel {
  final String date;
  final double cloudCover;
  final String resolution;

  SatelliteMetricsModel({
    required this.date,
    required this.cloudCover,
    required this.resolution,
  });
}

class NDVIModel {
  final double score;
  final String status;
  final String imageUrl;

  NDVIModel({
    required this.score,
    required this.status,
    required this.imageUrl,
  });
}

class WeatherModel {
  final double temperature;
  final double humidity;
  final double rainfallExpected;

  WeatherModel({
    required this.temperature,
    required this.humidity,
    required this.rainfallExpected,
  });
}

class SoilModel {
  final double moisture;
  final double nitrogen;
  final double phLevel;

  SoilModel({
    required this.moisture,
    required this.nitrogen,
    required this.phLevel,
  });
}

class AlertModel {
  final String id;
  final String title;
  final String message;
  final String severity; // High, Medium, Low
  final DateTime date;

  AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.date,
  });
}

class AIInsightModel {
  final String title;
  final String description;
  final String actionRequired;

  AIInsightModel({
    required this.title,
    required this.description,
    required this.actionRequired,
  });
}
