import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../models/ndvi_history_model.dart';
import '../../viewmodels/farm_providers.dart';
import '../widgets/glass_card.dart';
import '../widgets/farm_parallax_background.dart';

class FarmHistoryScreen extends ConsumerWidget {
  const FarmHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farm = ref.watch(selectedFarmProvider);
    final dashState = ref.watch(dashboardProvider);
    final history = dashState.ndviHistory;

    return Scaffold(
      body: FarmParallaxBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded, color: AppColors.primaryAccent, size: 22),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('FARM HISTORY', style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16)),
                        if (farm != null)
                          Text(farm.name, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => ref.read(dashboardProvider.notifier).fetchAll(),
                      icon: const Icon(Icons.refresh, color: AppColors.primaryAccent, size: 20),
                    ),
                  ],
                ),
              ),

              if (farm == null)
                const Expanded(
                  child: Center(
                    child: Text('No farm selected.\nGo to Farms tab to select one.',
                        style: TextStyle(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _ndviTrendCard(history),
                        const SizedBox(height: 16),
                        _historyTimeline(history, dashState),
                        const SizedBox(height: 16),
                        _comparisionCard(history),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── NDVI Trend Chart ────────────────────────────────────────────────────
  Widget _ndviTrendCard(List<NdviHistoryModel> history) {
    if (history.isEmpty) return const SizedBox.shrink();
    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.show_chart, color: AppColors.primaryAccent, size: 18),
            SizedBox(width: 8),
            Text('NDVI TREND — Last 30 Days', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(LineChartData(
              clipData: const FlClipData.all(),
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
                    reservedSize: 32,
                    getTitlesWidget: (v, _) => Text(
                      v.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white38, fontSize: 9),
                    ),
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
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('${d.day}/${d.month}',
                            style: const TextStyle(color: Colors.white38, fontSize: 8)),
                      );
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
                      .map((e) => FlSpot(e.key.toDouble(), e.value.ndviValue.clamp(0.0, 1.0)))
                      .toList(),
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: AppColors.primaryAccent,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                      radius: 4,
                      color: spot.y > 0.6
                          ? AppColors.primaryAccent
                          : spot.y > 0.4
                              ? AppColors.goldAccent
                              : Colors.redAccent,
                      strokeWidth: 0,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryAccent.withOpacity(0.3),
                        Colors.transparent,
                      ],
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

  // ─── Timeline of NDVI Records ────────────────────────────────────────────
  Widget _historyTimeline(List<NdviHistoryModel> history, DashboardState ds) {
    final reversed = history.reversed.toList();
    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.timeline, color: AppColors.secondaryAccent2, size: 18),
            SizedBox(width: 8),
            Text('SCAN HISTORY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          ]),
          const SizedBox(height: 16),
          if (reversed.isEmpty)
            const Text('No history yet. Fetch satellite data to populate.',
                style: TextStyle(color: Colors.white38, fontSize: 13))
          else
            ...reversed.asMap().entries.map((entry) {
              final i = entry.key;
              final snap = entry.value;
              final ndvi = snap.ndviValue;
              final color = ndvi > 0.6 ? AppColors.primaryAccent : ndvi > 0.4 ? AppColors.goldAccent : Colors.redAccent;
              final statusLabel = ndvi > 0.6 ? 'Healthy' : ndvi > 0.4 ? 'Moderate' : 'Poor';
              final isLast = i == reversed.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 6)],
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Center(
                                child: Container(
                                  width: 1.5,
                                  color: Colors.white12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${snap.date.day} ${_month(snap.date.month)}, ${snap.date.year}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      Text('NDVI: ', style: TextStyle(color: Colors.white38, fontSize: 12)),
                                      Text(ndvi.toStringAsFixed(3), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                                    ]),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(statusLabel, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ─── Comparison Card (first vs. last) ──────────────────────────────────
  Widget _comparisionCard(List<NdviHistoryModel> history) {
    if (history.length < 2) return const SizedBox.shrink();
    final first = history.first;
    final last = history.last;
    final delta = last.ndviValue - first.ndviValue;
    final improved = delta > 0;
    final deltaColor = improved ? AppColors.primaryAccent : Colors.redAccent;

    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.compare_arrows, color: AppColors.softPurple, size: 18),
            SizedBox(width: 8),
            Text('PERIOD COMPARISON', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          ]),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _compStat('First Record', first.date, first.ndviValue, Colors.white60),
              Column(children: [
                Icon(improved ? Icons.trending_up : Icons.trending_down, color: deltaColor, size: 32),
                Text('${improved ? '+' : ''}${delta.toStringAsFixed(3)}',
                    style: TextStyle(color: deltaColor, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(improved ? 'IMPROVED' : 'DECLINED',
                    style: TextStyle(color: deltaColor, fontSize: 10, letterSpacing: 1)),
              ]),
              _compStat('Latest Record', last.date, last.ndviValue, Colors.white60),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compStat(String label, DateTime date, double ndvi, Color textColor) {
    final color = ndvi > 0.6 ? AppColors.primaryAccent : ndvi > 0.4 ? AppColors.goldAccent : Colors.redAccent;
    return Column(
      children: [
        Text(label, style: TextStyle(color: textColor, fontSize: 11)),
        const SizedBox(height: 4),
        Text('${date.day}/${date.month}/${date.year}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 8),
        Text(ndvi.toStringAsFixed(3), style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(_statusLabel(ndvi), style: TextStyle(color: color, fontSize: 10)),
      ],
    );
  }

  String _statusLabel(double v) => v > 0.6 ? 'Healthy' : v > 0.4 ? 'Moderate' : 'Poor';

  String _month(int m) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m];
  }
}
