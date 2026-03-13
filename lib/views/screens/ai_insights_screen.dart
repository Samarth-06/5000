import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/farm_providers.dart';
import '../widgets/glass_card.dart';
import '../widgets/farm_parallax_background.dart';

class AiInsightsScreen extends ConsumerStatefulWidget {
  const AiInsightsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends ConsumerState<AiInsightsScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _scanCtrl;
  late AnimationController _barCtrl;
  late Animation<double> _barAnim;
  int _selectedRisk = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _barCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutQuart);
    _barCtrl.forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scanCtrl.dispose();
    _barCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(dashboardProvider);
    final farm = ref.watch(selectedFarmProvider);
    final ndvi = dashState.ndviData?['mean'] as double? ?? 0.72;
    final humidity = dashState.weatherData?['humidity'] as double? ?? 65.0;
    final temp = dashState.weatherData?['temp'] as double? ?? 28.4;
    final rain = dashState.weatherData?['rainfall'] as double? ?? 0.0;

    // Compute risk scores
    final droughtRisk = _clamp(1.0 - ndvi * 1.2 + (rain == 0 ? 0.3 : 0));
    final pestRisk = _clamp(humidity / 100 * 0.8 + (ndvi < 0.45 ? 0.3 : 0));
    final yieldScore = _clamp(ndvi * 0.7 + (humidity > 50 ? 0.15 : 0) + (rain > 0 ? 0.1 : 0) + (temp < 35 ? 0.05 : 0));
    final soilHealth = _clamp(ndvi * 0.5 + 0.35 + (rain > 5 ? 0.1 : 0));

    // Prediction confidence
    final confidence = _clamp(ndvi * 0.6 + 0.35);

    return Scaffold(
      body: FarmParallaxBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                _header(farm?.name),
                const SizedBox(height: 20),

                // ── AI Scanning Radar ────────────────────────────────────
                _aiRadarCard(ndvi, confidence),
                const SizedBox(height: 16),

                // ── Prediction Score Bars ────────────────────────────────
                _predictionBarsCard(ndvi, droughtRisk, pestRisk, yieldScore, soilHealth),
                const SizedBox(height: 16),

                // ── 7-Day NDVI Forecast ─────────────────────────────────
                _forecastCard(ndvi),
                const SizedBox(height: 16),

                // ── Risk Alerts ──────────────────────────────────────────
                _riskAlertsCard(droughtRisk, pestRisk, humidity, temp, rain),
                const SizedBox(height: 16),

                // ── Recommendation Chips ─────────────────────────────────
                _recommendationsCard(ndvi, droughtRisk, pestRisk),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _header(String? farmName) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.softPurple.withOpacity(0.15 + _pulseCtrl.value * 0.1),
              border: Border.all(color: AppColors.softPurple.withOpacity(0.6 + _pulseCtrl.value * 0.4), width: 1.5),
              boxShadow: [BoxShadow(color: AppColors.softPurple.withOpacity(0.3 * _pulseCtrl.value), blurRadius: 16)],
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.softPurple, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI ANALYSIS', style: TextStyle(color: AppColors.softPurple, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5)),
            Text(farmName ?? 'All Farms', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            _barCtrl.reset();
            _barCtrl.forward();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.softPurple.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.softPurple.withOpacity(0.4)),
            ),
            child: const Row(children: [
              Icon(Icons.refresh, color: AppColors.softPurple, size: 14),
              SizedBox(width: 4),
              Text('RE-SCAN', style: TextStyle(color: AppColors.softPurple, fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ],
    );
  }

  // ─── Radar / Scanning Animation Card ────────────────────────────────────
  Widget _aiRadarCard(double ndvi, double confidence) {
    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Row(children: [
            Icon(Icons.radar, color: AppColors.softPurple, size: 18),
            SizedBox(width: 8),
            Text('SATELLITE AI SCAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            Spacer(),
            Text('LIVE', style: TextStyle(color: AppColors.primaryAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ]),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Radar circle
              AnimatedBuilder(
                animation: _scanCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _RadarPainter(_scanCtrl.value),
                  child: SizedBox(
                    width: 130,
                    height: 130,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(ndvi.toStringAsFixed(2), style: const TextStyle(color: AppColors.primaryAccent, fontSize: 26, fontWeight: FontWeight.bold)),
                          const Text('NDVI', style: TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Stats column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _scanStat('Confidence', '${(confidence * 100).toStringAsFixed(0)}%', AppColors.softPurple),
                  const SizedBox(height: 12),
                  _scanStat('Vegetation', ndvi > 0.6 ? 'Dense' : ndvi > 0.4 ? 'Moderate' : 'Sparse', AppColors.primaryAccent),
                  const SizedBox(height: 12),
                  _scanStat('Data Source', 'Sentinel-2', AppColors.secondaryAccent2),
                  const SizedBox(height: 12),
                  _scanStat('Resolution', '10m × 10m', AppColors.goldAccent),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scanStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 0.5)),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ─── Prediction Score Bars ───────────────────────────────────────────────
  Widget _predictionBarsCard(double ndvi, double drought, double pest, double yield, double soil) {
    final metrics = [
      {'label': '🌿 Yield Score', 'value': yield, 'color': AppColors.primaryAccent, 'suffix': ''},
      {'label': '🌱 Soil Health', 'value': soil, 'color': AppColors.goldAccent, 'suffix': ''},
      {'label': '🔥 Drought Risk', 'value': drought, 'color': Colors.redAccent, 'suffix': ''},
      {'label': '🐛 Pest Risk', 'value': pest, 'color': Colors.orangeAccent, 'suffix': ''},
    ];

    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.bar_chart_rounded, color: AppColors.goldAccent, size: 18),
            SizedBox(width: 8),
            Text('PREDICTION SCORES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ]),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _barAnim,
            builder: (_, __) => Column(
              children: metrics.map((m) {
                final v = (m['value'] as double) * _barAnim.value;
                final color = m['color'] as Color;
                final pct = (v * 100).toStringAsFixed(0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(m['label'] as String, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          Text('$pct%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Stack(
                        children: [
                          Container(height: 8, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6))),
                          FractionallySizedBox(
                            widthFactor: v.clamp(0.0, 1.0),
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: LinearGradient(
                                  colors: [color.withOpacity(0.5), color],
                                ),
                                boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 7-Day NDVI Forecast Chart ───────────────────────────────────────────
  Widget _forecastCard(double currentNdvi) {
    final rng = Random(42);
    final forecast = List.generate(7, (i) {
      final delta = (rng.nextDouble() - 0.45) * 0.08;
      return (currentNdvi + delta * (i + 1)).clamp(0.1, 1.0);
    });

    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.trending_up, color: AppColors.secondaryAccent2, size: 18),
            SizedBox(width: 8),
            Text('7-DAY NDVI FORECAST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            Spacer(),
            Text('AI Predicted', style: TextStyle(color: Colors.white38, fontSize: 10)),
          ]),
          const SizedBox(height: 4),
          const Text('Machine learning prediction based on historical patterns + weather',
              style: TextStyle(color: Colors.white30, fontSize: 10)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(BarChartData(
              barTouchData: BarTouchData(enabled: false),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      final i = v.toInt();
                      if (i < 0 || i >= days.length) return const SizedBox.shrink();
                      return Text(days[i], style: const TextStyle(color: Colors.white38, fontSize: 9));
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: forecast.asMap().entries.map((e) {
                final val = e.value;
                final color = val > 0.6 ? AppColors.primaryAccent : val > 0.4 ? AppColors.goldAccent : Colors.redAccent;
                return BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                    toY: val,
                    width: 22,
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [color.withOpacity(0.4), color],
                    ),
                  ),
                ]);
              }).toList(),
            )),
          ),
        ],
      ),
    );
  }

  // ─── Risk Alerts ─────────────────────────────────────────────────────────
  Widget _riskAlertsCard(double drought, double pest, double humidity, double temp, double rain) {
    final alerts = <Map<String, dynamic>>[];
    if (drought > 0.5) alerts.add({'icon': '🔥', 'label': 'Drought Alert', 'detail': 'Risk ${(drought * 100).toInt()}% — Start irrigation immediately', 'color': Colors.redAccent, 'level': 'HIGH'});
    if (pest > 0.55) alerts.add({'icon': '🐛', 'label': 'Pest Warning', 'detail': 'Conditions favour infestation. Apply organic pesticide.', 'color': Colors.orangeAccent, 'level': 'MEDIUM'});
    if (humidity > 80) alerts.add({'icon': '🍄', 'label': 'Fungal Risk', 'detail': 'High humidity (${humidity.toInt()}%) — Apply fungicide.', 'color': Colors.deepOrange, 'level': 'HIGH'});
    if (temp > 38) alerts.add({'icon': '🌞', 'label': 'Heat Stress', 'detail': 'Temperature ${temp.toInt()}°C — Shade netting advised.', 'color': Colors.amber, 'level': 'MEDIUM'});
    if (alerts.isEmpty) alerts.add({'icon': '✅', 'label': 'All Clear', 'detail': 'No urgent risks detected. Continue routine care.', 'color': AppColors.primaryAccent, 'level': 'LOW'});

    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 18),
            SizedBox(width: 8),
            Text('RISK ALERTS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ]),
          const SizedBox(height: 14),
          ...alerts.map((a) {
            final color = a['color'] as Color;
            return AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.07 + (a['level'] == 'HIGH' ? _pulseCtrl.value * 0.04 : 0)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Text(a['icon'] as String, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a['label'] as String, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(a['detail'] as String, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                      child: Text(a['level'] as String, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Action Recommendations ──────────────────────────────────────────────
  Widget _recommendationsCard(double ndvi, double drought, double pest) {
    final recs = <Map<String, String>>[
      if (drought > 0.4) {'icon': '💧', 'action': 'Start drip irrigation — water 2hrs/day', 'priority': 'Urgent'},
      if (pest > 0.4) {'icon': '🌿', 'action': 'Apply neem oil spray (3ml/L ratio)', 'priority': 'Soon'},
      if (ndvi < 0.55) {'icon': '🌱', 'action': 'Apply NPK fertiliser (10-26-26)', 'priority': 'This week'},
      {'icon': '📸', 'action': 'Schedule next satellite scan in 5 days', 'priority': 'Routine'},
      {'icon': '📊', 'action': 'Review NDVI trend in Farm History tab', 'priority': 'Routine'},
    ];

    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.checklist_rounded, color: AppColors.primaryAccent, size: 18),
            SizedBox(width: 8),
            Text('AI RECOMMENDATIONS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ]),
          const SizedBox(height: 14),
          ...recs.asMap().entries.map((e) {
            final r = e.value;
            final isUrgent = r['priority'] == 'Urgent';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: (isUrgent ? Colors.redAccent : AppColors.primaryAccent).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text(r['icon']!, style: const TextStyle(fontSize: 16))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['action']!, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        Text(r['priority']!, style: TextStyle(color: isUrgent ? Colors.redAccent : AppColors.primaryAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white24, size: 16),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  double _clamp(double v) => v.clamp(0.0, 1.0);
}

// ─── Radar Sweep Painter ─────────────────────────────────────────────────────
class _RadarPainter extends CustomPainter {
  final double sweep;
  _RadarPainter(this.sweep);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    // Rings
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxR * i / 4,
          Paint()..color = AppColors.primaryAccent.withOpacity(0.15)..style = PaintingStyle.stroke..strokeWidth = 0.8);
    }

    // Crosshairs
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy),
        Paint()..color = AppColors.primaryAccent.withOpacity(0.15)..strokeWidth = 0.5);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height),
        Paint()..color = AppColors.primaryAccent.withOpacity(0.15)..strokeWidth = 0.5);

    // Sweep gradient arc
    final sweepAngle = 2 * pi * sweep;
    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle - 1.5,
        endAngle: sweepAngle,
        colors: [Colors.transparent, AppColors.primaryAccent.withOpacity(0.5)],
        center: Alignment.center,
      ).createShader(Rect.fromCircle(center: center, radius: maxR))
      ..style = PaintingStyle.fill;
    canvas.drawArc(Rect.fromCircle(center: center, radius: maxR), sweepAngle - 1.5, 1.5, true, paint);

    // Sweep line
    canvas.drawLine(
      center,
      Offset(center.dx + maxR * cos(sweepAngle), center.dy + maxR * sin(sweepAngle)),
      Paint()..color = AppColors.primaryAccent.withOpacity(0.9)..strokeWidth = 1.5,
    );

    // Blip dots
    final rng = Random(7);
    final blipPaint = Paint()..color = AppColors.primaryAccent;
    for (int i = 0; i < 5; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final r = maxR * (0.2 + rng.nextDouble() * 0.7);
      final dx = center.dx + r * cos(angle);
      final dy = center.dy + r * sin(angle);
      canvas.drawCircle(Offset(dx, dy), 2.5, blipPaint..color = AppColors.primaryAccent.withOpacity(0.6 + rng.nextDouble() * 0.4));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter o) => o.sweep != sweep;
}
