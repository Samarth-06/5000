/// 7-day weather data from /weather/data/daypart
class WeatherDaypart {
  final List<double> temperature; // [day, night]
  final double humidity;
  final double windSpeed;
  final double precipChance;
  final double cloudCover;
  final String narrative;
  final String validTimeUtc;

  WeatherDaypart({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.precipChance,
    required this.cloudCover,
    required this.narrative,
    required this.validTimeUtc,
  });

  double get dayTemp => temperature.isNotEmpty ? temperature[0] : 0.0;
  double get nightTemp => temperature.length > 1 ? temperature[1] : dayTemp;

  factory WeatherDaypart.fromJson(Map<String, dynamic> json) {
    List<double> temps = [];
    final rawTemp = json['temperature'];
    if (rawTemp is List) {
      temps = rawTemp.map((e) => (e as num).toDouble()).toList();
    }
    return WeatherDaypart(
      temperature: temps,
      humidity: double.tryParse(json['relativeHumidity']?.toString() ?? '0') ?? 0.0,
      windSpeed: double.tryParse(json['WindSpeed']?.toString() ?? '0') ?? 0.0,
      precipChance: double.tryParse(json['precipChance']?.toString() ?? '0') ?? 0.0,
      cloudCover: double.tryParse(json['cloudCover']?.toString() ?? '0') ?? 0.0,
      narrative: json['narrative']?.toString() ?? '',
      validTimeUtc: json['validTimeUtc']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toSupabase(String farmId) => {
        'farm_id': farmId,
        'temperature': dayTemp,
        'humidity': humidity,
        'wind_speed': windSpeed,
        'rainfall_probability': precipChance,
        'narrative': narrative,
        'timestamp': DateTime.now().toIso8601String(),
      };
}
