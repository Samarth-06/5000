import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';

class WeatherApiService {
  Dio get _dio {
    final apiKey = Hive.box(AppConstants.settingsBox).get(AppConstants.keyWeatherApiKey, defaultValue: 'PLACEHOLDER');
    return Dio(BaseOptions(
      baseUrl: AppConstants.weatherBaseUrl,
      queryParameters: {'appid': apiKey, 'units': 'metric'},
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
  }

  Future<Map<String, dynamic>?> fetchWeather(double lat, double lng) async {
    try {
      final res = await _dio.get('/weather', queryParameters: {
        'lat': lat,
        'lon': lng,
      });
      final d = res.data;
      return {
        'temp': (d['main']['temp'] as num).toDouble(),
        'humidity': (d['main']['humidity'] as num).toDouble(),
        'description': d['weather'][0]['description'],
        'icon': d['weather'][0]['icon'],
        'wind_speed': (d['wind']['speed'] as num).toDouble(),
        'rainfall': (d['rain']?['1h'] as num?)?.toDouble() ?? 0.0,
        'feels_like': (d['main']['feels_like'] as num).toDouble(),
      };
    } catch (_) {
      return null;
    }
  }
}
