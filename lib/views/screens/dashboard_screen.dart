import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../services/smart_analytics.dart';
import '../../viewmodels/farm_providers.dart';
import '../widgets/glass_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farm = ref.watch(selectedFarmProvider);
    final ds = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FARM INTELLIGENCE',
              style: TextStyle(
                color: AppColors.primaryAccent,
                fontSize: 16,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (farm != null)
              Text(
                farm.name,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
          ],
        ),
        actions: [
          if (ds.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryAccent,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primaryAccent),
              onPressed: () => ref.read(dashboardProvider.notifier).fetchAll(),
            ),
        ],
      ),
      body: farm == null
          ? _noFarmPlaceholder()
          : RefreshIndicator(
              color: AppColors.primaryAccent,
              backgroundColor: AppColors.cardBackground,
              onRefresh: () => ref.read(dashboardProvider.notifier).fetchAll(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ds.error != null)
                      _banner(
                        ds.error!,
                        AppColors.goldAccent,
                        Icons.info_outline,
                      ),
                    _cropHealthScore(ds),
                    const SizedBox(height: 16),
                    _ndviHealthCard(ds),
                    const SizedBox(height: 16),
                    _weatherSoilRow(ds),
                    const SizedBox(height: 16),
                    _smartIrrigationCard(ds),
                    const SizedBox(height: 16),
                    _cropTrendCard(ds),
                    const SizedBox(height: 16),
                    _cropAdvisoryCards(ds),
                    const SizedBox(height: 16),
                    _recommendationsCard(ds),
                    const SizedBox(height: 16),
                    _ndviHistoryChart(ds.vegetationHistory),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _banner(String msg, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg, style: TextStyle(color: color, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── Crop Health Score ──────────────────────────────────────────────────
  Widget _cropHealthScore(DashboardState ds) {
    final ndvi = ds.vegetation?.ndvi ?? ds.summary?.ndvi ?? 0.0;
    final soilMoist = ds.summary?.soilMoisture ?? 0.0;
    final score = ((ndvi * 60) + (soilMoist / 100 * 40)).clamp(0.0, 100.0);
    final color = score > 70
        ? AppColors.primaryAccent
        : score > 45
        ? AppColors.goldAccent
        : Colors.redAccent;

    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Text(
                  '${score.toInt()}',
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CROP HEALTH SCORE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  score > 70
                      ? 'Excellent condition'
                      : score > 45
                      ? 'Moderate — monitor closely'
                      : 'Poor — action required',
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── NDVI Health Card ──────────────────────────────────────────────────
  Widget _ndviHealthCard(DashboardState ds) {
    final ndvi = ds.vegetation?.ndvi ?? ds.summary?.ndvi ?? 0.0;
    final Color ndviColor = ndvi > 0.6
        ? AppColors.primaryAccent
        : ndvi > 0.4
        ? AppColors.goldAccent
        : Colors.redAccent;
    final healthStatus =
        ds.vegetation?.healthStatus ??
        (ndvi > 0.6
            ? 'HEALTHY'
            : ndvi > 0.4
            ? 'MODERATE'
            : 'POOR');

    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.eco, color: AppColors.primaryAccent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'VEGETATION INDEX',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ndviColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ndviColor.withOpacity(0.5)),
                ),
                child: Text(
                  healthStatus,
                  style: TextStyle(
                    color: ndviColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ndviGauge(ndvi, ndviColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statRow('NDVI', ndvi.toStringAsFixed(3), ndviColor),
                    if (ds.vegetation != null) ...[
                      const SizedBox(height: 8),
                      _statRow(
                        'LSWI',
                        ds.vegetation!.lswi.toStringAsFixed(3),
                        AppColors.secondaryAccent2,
                      ),
                      const SizedBox(height: 8),
                      _statRow(
                        'RVI',
                        ds.vegetation!.rvi.toStringAsFixed(3),
                        AppColors.softPurple,
                      ),
                      const SizedBox(height: 8),
                      _statRow(
                        'SM',
                        ds.vegetation!.sm.toStringAsFixed(3),
                        AppColors.goldAccent,
                      ),
                    ],
                    if (ds.vegetation?.satellite != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Source: ${ds.vegetation!.satellite}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ndviColorScale(ndvi),
        ],
      ),
    );
  }

  Widget _ndviColorScale(double ndvi) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 10,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF8B4513),
                  Color(0xFFDAA520),
                  Color(0xFF90EE90),
                  Color(0xFF006400),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0.0 Poor',
              style: TextStyle(color: Colors.white38, fontSize: 9),
            ),
            Text('0.2', style: TextStyle(color: Colors.white38, fontSize: 9)),
            Text('0.4', style: TextStyle(color: Colors.white38, fontSize: 9)),
            Text('0.6', style: TextStyle(color: Colors.white38, fontSize: 9)),
            Text(
              '1.0 Healthy',
              style: TextStyle(color: Colors.white38, fontSize: 9),
            ),
          ],
        ),
      ],
    );
  }

  Widget _ndviGauge(double ndvi, Color color) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: ndvi.clamp(0.0, 1.0),
            strokeWidth: 10,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ndvi.toStringAsFixed(2),
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'NDVI',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ── Weather + Soil ────────────────────────────────────────────────────
  Widget _weatherSoilRow(DashboardState ds) {
    final summary = ds.summary;
    final weather = ds.weatherForecast.isNotEmpty
        ? ds.weatherForecast.first
        : null;
    final tiles = <Map<String, dynamic>>[
      {
        'emoji': '🌡️',
        'value': '${summary?.temperature ?? weather?.dayTemp ?? '—'}°C',
        'label': 'Temperature',
        'color': AppColors.goldAccent,
      },
      {
        'emoji': '💧',
        'value': '${weather?.humidity.toStringAsFixed(0) ?? '—'}%',
        'label': 'Humidity',
        'color': AppColors.secondaryAccent2,
      },
      {
        'emoji': '🌧️',
        'value':
            '${summary?.rainProbability ?? weather?.precipChance.toStringAsFixed(0) ?? '—'}%',
        'label': 'Rain Prob.',
        'color': Colors.blueAccent,
      },
      {
        'emoji': '🌱',
        'value': '${summary?.soilMoisture ?? '—'}%',
        'label': 'Soil Moisture',
        'color': AppColors.secondaryAccent1,
      },
      {
        'emoji': '💨',
        'value': '${weather?.windSpeed.toStringAsFixed(1) ?? '—'} m/s',
        'label': 'Wind',
        'color': Colors.white70,
      },
      {
        'emoji': '☁️',
        'value': weather?.narrative ?? '—',
        'label': 'Condition',
        'color': Colors.white60,
      },
    ];
    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.cloud_rounded,
                color: AppColors.secondaryAccent2,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'WEATHER & SOIL',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: tiles
                .map(
                  (t) => _weatherTile(
                    t['emoji'] as String,
                    t['value'] as String,
                    t['label'] as String,
                    t['color'] as Color,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _weatherTile(String emoji, String value, String label, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ── Smart Irrigation ─────────────────────────────────────────────────
  Widget _smartIrrigationCard(DashboardState ds) {
    final advice = ds.irrigationAdvice;
    if (advice == null || advice.isEmpty) return const SizedBox.shrink();

    final urgency = ds.irrigationUrgency;
    final color = urgency == 2
        ? Colors.redAccent
        : urgency == 1
        ? AppColors.goldAccent
        : AppColors.primaryAccent;
    final urgencyLabel = urgency == 2
        ? 'URGENT'
        : urgency == 1
        ? 'MODERATE'
        : 'LOW';

    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.water_drop,
                color: AppColors.secondaryAccent2,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'SMART IRRIGATION',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  urgencyLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  urgency == 2
                      ? Icons.warning
                      : urgency == 1
                      ? Icons.info
                      : Icons.check_circle,
                  color: color,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    advice,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Crop Trend ───────────────────────────────────────────────────────
  Widget _cropTrendCard(DashboardState ds) {
    final trend = ds.cropTrend;
    if (trend == null) return const SizedBox.shrink();

    final color = trend.trend == TrendDirection.improving
        ? AppColors.primaryAccent
        : trend.trend == TrendDirection.declining
        ? Colors.redAccent
        : AppColors.goldAccent;
    final icon = trend.trend == TrendDirection.improving
        ? Icons.trending_up
        : trend.trend == TrendDirection.declining
        ? Icons.trending_down
        : Icons.trending_flat;

    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: AppColors.softPurple, size: 18),
              const SizedBox(width: 8),
              const Text(
                'CROP GROWTH TREND',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trend.message,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Slope: ${trend.slope.toStringAsFixed(4)} / scan',
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
        ],
      ),
    );
  }

  // ── Crop Advisory ────────────────────────────────────────────────────
  Widget _cropAdvisoryCards(DashboardState ds) {
    if (ds.cropAdvisory.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.local_florist, color: Colors.orangeAccent, size: 18),
            SizedBox(width: 8),
            Text(
              'CROP ADVISORY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...ds.cropAdvisory.map((a) {
          final color = a.isDisease ? Colors.redAccent : Colors.orangeAccent;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Text(
                  a.isDisease ? '🦠' : '🐛',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (a.affectedPart != null)
                        Text(
                          'Part: ${a.affectedPart}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      Text(
                        'Symptoms: ${a.symptoms}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '✅ ${a.solution}',
                        style: const TextStyle(
                          color: AppColors.primaryAccent,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Recommendations ──────────────────────────────────────────────────
  Widget _recommendationsCard(DashboardState ds) {
    final recs = ds.summary?.recommendations ?? [];
    if (recs.isEmpty) return const SizedBox.shrink();
    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.goldAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'RECOMMENDATIONS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recs.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.arrow_right,
                    color: AppColors.primaryAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── NDVI History Chart ──────────────────────────────────────────────
  Widget _ndviHistoryChart(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return const SizedBox.shrink();

    final points = history
        .map(
          (e) => (
            ts: DateTime.tryParse(e['timestamp']?.toString() ?? ''),
            ndvi: (e['ndvi'] as num?)?.toDouble() ?? 0.0,
          ),
        )
        .where((e) => e.ts != null)
        .toList();
    if (points.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline, color: AppColors.primaryAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'NDVI TREND',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Colors.white10, strokeWidth: 0.8),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                        ),
                      ),
                      reservedSize: 30,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= points.length)
                          return const SizedBox.shrink();
                        final d = points[idx].ts!;
                        return Text(
                          '${d.day}/${d.month}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 1,
                lineBarsData: [
                  LineChartBarData(
                    spots: points
                        .asMap()
                        .entries
                        .map(
                          (e) => FlSpot(
                            e.key.toDouble(),
                            e.value.ndvi.clamp(0.0, 1.0),
                          ),
                        )
                        .toList(),
                    isCurved: true,
                    color: AppColors.primaryAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.primaryAccent,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryAccent.withOpacity(0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noFarmPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.satellite_alt,
                size: 64,
                color: AppColors.primaryAccent,
              ),
              SizedBox(height: 16),
              Text(
                'No Farm Selected',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Go to Farms tab to select or register a farm',
                style: TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
