/// Smart irrigation recommendation engine.
/// Uses rule-based logic on soil moisture, NDVI, rain probability, and temperature.
class IrrigationAdvisor {
  final double soilMoisture;
  final double ndvi;
  final double rainProbability;
  final double temperature;

  IrrigationAdvisor({
    required this.soilMoisture,
    required this.ndvi,
    required this.rainProbability,
    required this.temperature,
  });

  /// Returns a recommendation string.
  String get recommendation {
    if (soilMoisture < 30 && rainProbability < 30) {
      return '💧 IRRIGATE NOW — Soil moisture is critically low (${soilMoisture.toStringAsFixed(0)}%) and rain is unlikely.';
    }
    if (soilMoisture > 60) {
      return '✅ NO IRRIGATION NEEDED — Soil moisture is sufficient (${soilMoisture.toStringAsFixed(0)}%).';
    }
    if (rainProbability > 60) {
      return '🌧️ DELAY IRRIGATION — High rain probability (${rainProbability.toStringAsFixed(0)}%). Wait for natural rainfall.';
    }
    if (soilMoisture < 40 && ndvi < 0.4) {
      return '⚠️ IRRIGATE SOON — Low moisture + poor crop health. Water within 24 hours.';
    }
    if (temperature > 35 && soilMoisture < 50) {
      return '🌡️ LIGHT IRRIGATION — High temps may accelerate evaporation. Apply light watering.';
    }
    return '📊 MONITOR — Conditions are acceptable. Check again in 12 hours.';
  }

  /// Returns urgency level: 0=low, 1=medium, 2=high
  int get urgency {
    if (soilMoisture < 30 && rainProbability < 30) return 2;
    if (soilMoisture > 60) return 0;
    if (rainProbability > 60) return 0;
    if (soilMoisture < 40 && ndvi < 0.4) return 2;
    return 1;
  }

  /// Returns a color for the urgency level
  String get urgencyLabel {
    switch (urgency) {
      case 2:
        return 'URGENT';
      case 1:
        return 'MODERATE';
      default:
        return 'LOW';
    }
  }
}

/// Crop growth trend analyzer.
/// Computes the NDVI slope from historical data and provides insight messages.
class CropTrendAnalyzer {
  /// Analyze a list of NDVI values (chronological order) and return insight.
  static TrendResult analyze(List<double> ndviValues) {
    if (ndviValues.length < 2) {
      return TrendResult(
        slope: 0,
        message: '📊 Insufficient data for trend analysis.',
        trend: TrendDirection.stable,
      );
    }

    // Simple linear regression slope
    final n = ndviValues.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += ndviValues[i];
      sumXY += i * ndviValues[i];
      sumXX += i * i;
    }
    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);

    if (slope > 0.005) {
      return TrendResult(
        slope: slope,
        message: 'Crop growth improving',
        trend: TrendDirection.improving,
      );
    } else if (slope < -0.005) {
      final detail = slope < -0.02
          ? 'Vegetation health declining'
          : 'Possible water stress detected';
      return TrendResult(
        slope: slope,
        message: detail,
        trend: TrendDirection.declining,
      );
    } else {
      return TrendResult(
        slope: slope,
        message: 'Crop growth stable',
        trend: TrendDirection.stable,
      );
    }
  }
}

enum TrendDirection { improving, stable, declining }

class TrendResult {
  final double slope;
  final String message;
  final TrendDirection trend;
  TrendResult({
    required this.slope,
    required this.message,
    required this.trend,
  });
}
