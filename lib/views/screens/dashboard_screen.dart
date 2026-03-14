import 'dart:math' as dartMath;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../models/ndvi_history_model.dart';
import '../../viewmodels/farm_providers.dart';
import '../widgets/glass_card.dart';
import '../widgets/farm_parallax_background.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farm = ref.watch(selectedFarmProvider);
    final dashState = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FARM INTELLIGENCE', style: TextStyle(color: AppColors.primaryAccent, fontSize: 16, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
            if (farm != null)
              Text(farm.name, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          if (dashState.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryAccent))),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primaryAccent),
              onPressed: () => ref.read(dashboardProvider.notifier).fetchAll(),
              tooltip: 'Refresh satellite data',
            ),
          IconButton(icon: const Icon(Icons.notifications_active, color: AppColors.goldAccent), onPressed: () {}),
        ],
      ),
      body: FarmParallaxBackground(
        child: farm == null
          ? _noFarmPlaceholder(context)
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
                    if (dashState.error != null) _demoModeBanner(dashState.error!),
                    _ndviCard(dashState),
                    const SizedBox(height: 16),
                    _weatherRow(dashState),
                    const SizedBox(height: 16),
                    _ndviHistoryChart(dashState.ndviHistory),
                    const SizedBox(height: 16),
                    _aiInsightsRow(dashState),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  // ─── Demo Mode Banner ────────────────────────────────────────────────────
  Widget _demoModeBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldAccent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.goldAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: const TextStyle(color: AppColors.goldAccent, fontSize: 12))),
        ],
      ),
    );
  }

  // ─── NDVI Score Card ────────────────────────────────────────────────────
  Widget _ndviCard(DashboardState state) {
    final ndvi = state.ndviData?['mean'] as double? ?? 0.0;
    final Color ndviColor = ndvi > 0.6 ? AppColors.primaryAccent : ndvi > 0.4 ? AppColors.goldAccent : Colors.redAccent;
    final String status = ndvi > 0.6 ? 'HEALTHY' : ndvi > 0.4 ? 'MODERATE' : 'POOR';
    final String advice = ndvi > 0.6 ? 'Crops are thriving. No immediate action needed.' : ndvi > 0.4 ? 'Consider fertilizer boost.' : 'Urgent: Irrigation + soil treatment needed.';

    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.eco, color: AppColors.primaryAccent, size: 20),
              const SizedBox(width: 8),
              const Text('NDVI CROP HEALTH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ndviColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ndviColor.withOpacity(0.5)),
                ),
                child: Text(status, style: TextStyle(color: ndviColor, fontWeight: FontWeight.bold, fontSize: 12)),
              )
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
                    _ndviStat('Mean NDVI', ndvi.toStringAsFixed(3), ndviColor),
                    const SizedBox(height: 8),
                    _ndviStat('Min', (state.ndviData?['min'] as double? ?? 0.0).toStringAsFixed(3), Colors.redAccent),
                    const SizedBox(height: 8),
                    _ndviStat('Max', (state.ndviData?['max'] as double? ?? 0.0).toStringAsFixed(3), AppColors.primaryAccent),
                    const SizedBox(height: 12),
                    Text(advice, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Color scale bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: LinearProgressIndicator(
                value: ndvi.clamp(0.0, 1.0),
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(ndviColor),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0.0', style: TextStyle(color: Colors.white38, fontSize: 10)),
              Text('0.5', style: TextStyle(color: Colors.white38, fontSize: 10)),
              Text('1.0', style: TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ndviGauge(double ndvi, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 110,
          height: 70,
          child: CustomPaint(
            painter: _NdviArcPainter(value: ndvi.clamp(0.0, 1.0), color: color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          ndvi.toStringAsFixed(2),
          style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              shadows: [Shadow(color: color.withOpacity(0.6), blurRadius: 12)]),
        ),
        Text('NDVI INDEX',
            style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 9,
                letterSpacing: 1.5)),
      ],
    );
  }

  Widget _ndviStat(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  // ─── Weather Row ────────────────────────────────────────────────────────
  Widget _weatherRow(DashboardState state) {
    final w = state.weatherData;
    if (w == null) return const SizedBox.shrink();

    final tiles = [
      {'emoji': '🌡️', 'value': '${w['temp']}°C',        'label': 'Temperature', 'color': AppColors.goldAccent},
      {'emoji': '💧',  'value': '${w['humidity']}%',     'label': 'Humidity',    'color': AppColors.secondaryAccent2},
      {'emoji': '🌧️', 'value': '${w['rainfall']} mm',   'label': 'Rainfall',    'color': Colors.blueAccent},
      {'emoji': '💨',  'value': '${w['wind_speed']} m/s','label': 'Wind',        'color': Colors.white70},
      {'emoji': '🌡️', 'value': '${w['feels_like']}°C',  'label': 'Feels Like',  'color': AppColors.softPurple},
      {'emoji': '☁️',  'value': w['description'] ?? '—', 'label': 'Condition',   'color': Colors.white60},
    ];

    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.cloud_rounded, color: AppColors.secondaryAccent2, size: 18),
            SizedBox(width: 8),
            Text('WEATHER & SOIL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ]),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: tiles.map((t) => _weatherTile(
              t['emoji'] as String,
              t['value'] as String,
              t['label'] as String,
              t['color'] as Color,
            )).toList(),
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
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  // ─── NDVI History Chart ─────────────────────────────────────────────────
  Widget _ndviHistoryChart(List<NdviHistoryModel> history) {
    if (history.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.timeline, color: AppColors.primaryAccent, size: 18),
            SizedBox(width: 8),
            Text('NDVI HISTORICAL TREND', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: Colors.white10, strokeWidth: 0.8),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1), style: const TextStyle(color: Colors.white38, fontSize: 9)),
                    reservedSize: 30,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= history.length) return const SizedBox.shrink();
                      final d = history[idx].date;
                      return Text('${d.day}/${d.month}', style: const TextStyle(color: Colors.white38, fontSize: 9));
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: 1,
              lineBarsData: [
                LineChartBarData(
                  spots: history
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.ndviValue))
                      .toList(),
                  isCurved: true,
                  color: AppColors.primaryAccent,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) =>
                        FlDotCirclePainter(radius: 4, color: AppColors.primaryAccent, strokeWidth: 0),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.primaryAccent.withOpacity(0.25), Colors.transparent],
                    ),
                  ),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  // ─── AI Insights Row ────────────────────────────────────────────────────
  Widget _aiInsightsRow(DashboardState state) {
    final ndvi = state.ndviData?['mean'] as double? ?? 0.0;
    final rain = state.weatherData?['rainfall'] as double? ?? 0.0;
    final humidity = state.weatherData?['humidity'] as double? ?? 0.0;

    final insights = [
      if (ndvi < 0.5)
        _insight('🌱', 'Low Crop Health', 'NDVI is ${ndvi.toStringAsFixed(2)}. Apply fertilizer or check irrigation.', Colors.redAccent),
      if (rain == 0.0 && humidity < 60)
        _insight('💧', 'Irrigation Needed', 'No rainfall detected. Low humidity. Turn on irrigation.', AppColors.secondaryAccent2),
      if (ndvi > 0.65)
        _insight('✅', 'Optimal Growth', 'NDVI of ${ndvi.toStringAsFixed(2)} indicates healthy green cover.', AppColors.primaryAccent),
      if (humidity > 80)
        _insight('⚠️', 'Fungal Risk Alert', 'High humidity detected. Apply preventive fungicide.', AppColors.goldAccent),
      _insight('📡', 'Satellite Updated', 'Last satellite scan completed successfully.', Colors.white70),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.auto_awesome, color: AppColors.softPurple, size: 18),
          SizedBox(width: 8),
          Text('AI INSIGHTS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ]),
        const SizedBox(height: 10),
        ...insights,
      ],
    );
  }

  Widget _insight(String emoji, String title, String msg, Color color) {
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
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 3),
                Text(msg, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── No Farm Selected ───────────────────────────────────────────────────
  Widget _noFarmPlaceholder(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.satellite_alt, size: 64, color: AppColors.primaryAccent),
              SizedBox(height: 16),
              Text('No Farm Selected', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Go to Farm Map tab to select or register a farm', style: TextStyle(color: Colors.white54, fontSize: 13), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── NDVI Semi-circle Arc Painter ────────────────────────────────────────────
class _NdviArcPainter extends CustomPainter {
  final double value; // 0.0 – 1.0
  final Color color;
  const _NdviArcPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const startAngle = 3.14159; // π  (left)
    const sweepFull = 3.14159;  // π  (half-circle top arc)

    final rect = Rect.fromLTWH(
      8, 8, size.width - 16, (size.width - 16),
    );

    // Track (background arc)
    canvas.drawArc(
      rect, startAngle, sweepFull, false,
      Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..strokeWidth = 9
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Value fill
    if (value > 0) {
      canvas.drawArc(
        rect, startAngle, sweepFull * value, false,
        Paint()
          ..color = color
          ..strokeWidth = 9
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // End-cap glow dot
    if (value > 0) {
      final angle = startAngle + sweepFull * value;
      final cx = rect.center.dx + rect.width / 2 * dartMath.cos(angle);
      final cy = rect.center.dy + rect.height / 2 * dartMath.sin(angle);
      canvas.drawCircle(
        Offset(cx, cy), 5,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(Offset(cx, cy), 4, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_NdviArcPainter o) => o.value != value || o.color != color;
}
