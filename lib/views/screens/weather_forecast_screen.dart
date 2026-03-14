import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/farm_providers.dart';
import '../../models/weather_daypart_model.dart';
import '../widgets/glass_card.dart';

class WeatherForecastScreen extends ConsumerWidget {
  const WeatherForecastScreen({Key? key}) : super(key: key);

  static const _dayNames = [
    'Day 1',
    'Day 2',
    'Day 3',
    'Day 4',
    'Day 5',
    'Day 6',
    'Day 7',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = ref.watch(dashboardProvider);
    final weather = ds.weatherForecast;
    final irrigation = ds.irrigationData;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WEATHER FORECAST',
          style: TextStyle(
            color: AppColors.primaryAccent,
            fontSize: 16,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryAccent),
            onPressed: () => ref.read(dashboardProvider.notifier).fetchAll(),
          ),
        ],
      ),
      body: weather.isEmpty
          ? const Center(
              child: Text(
                'No weather data available.\nFetch from dashboard first.',
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Irrigation recommendation
                  if (irrigation != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryAccent2.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.secondaryAccent2.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.water_drop,
                            color: AppColors.secondaryAccent2,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'IRRIGATION RECOMMENDATION',
                                  style: TextStyle(
                                    color: AppColors.secondaryAccent2,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Status: ${irrigation.status}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                if (irrigation.dataUrl != null &&
                                    irrigation.dataUrl!.isNotEmpty)
                                  Text(
                                    'Source: ${irrigation.dataUrl}',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 7-day forecast cards
                  const Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.goldAccent,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '7-DAY FORECAST',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...weather.asMap().entries.map(
                    (e) => _dayCard(e.key, e.value),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _dayCard(int index, WeatherDaypart day) {
    final dayLabel = index < _dayNames.length
        ? _dayNames[index]
        : 'Day ${index + 1}';

    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('☀️', style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                dayLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                day.narrative,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _miniTile(
                '🌡️',
                '${day.dayTemp.toStringAsFixed(1)}°',
                'Day',
                AppColors.goldAccent,
              ),
              _miniTile(
                '🌙',
                '${day.nightTemp.toStringAsFixed(1)}°',
                'Night',
                AppColors.softPurple,
              ),
              _miniTile(
                '💧',
                '${day.humidity.toStringAsFixed(0)}%',
                'Humidity',
                AppColors.secondaryAccent2,
              ),
              _miniTile(
                '🌧️',
                '${day.precipChance.toStringAsFixed(0)}%',
                'Rain',
                Colors.blueAccent,
              ),
              _miniTile(
                '💨',
                '${day.windSpeed.toStringAsFixed(1)}',
                'Wind m/s',
                Colors.white70,
              ),
              _miniTile(
                '☁️',
                '${day.cloudCover.toStringAsFixed(0)}%',
                'Cloud',
                Colors.white60,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniTile(String emoji, String value, String label, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
