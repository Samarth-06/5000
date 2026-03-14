import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/farm_providers.dart';
import '../widgets/glass_card.dart';
import '../widgets/farm_parallax_background.dart';

class FarmHistoryScreen extends ConsumerStatefulWidget {
  const FarmHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FarmHistoryScreen> createState() => _FarmHistoryScreenState();
}

class _FarmHistoryScreenState extends ConsumerState<FarmHistoryScreen> {
  int _selectedDays = 30;
  int _selectedIndex = 0; // 0=All, 1=NDVI, 2=LSWI, 3=RVI, 4=SM

  @override
  Widget build(BuildContext context) {
    final farm = ref.watch(selectedFarmProvider);

    // Try to get Supabase vegetation history
    List<Map<String, dynamic>> vegHistory = [];
    if (farm != null) {
      final vegAsync = ref.watch(
        vegetationHistoryProvider((farmId: farm.id, days: _selectedDays)),
      );
      vegHistory = vegAsync.when(
        data: (data) => data,
        loading: () => <Map<String, dynamic>>[],
        error: (_, __) => <Map<String, dynamic>>[],
      );
    }

    return Scaffold(
      body: FarmParallaxBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      color: AppColors.primaryAccent,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FARM HISTORY',
                          style: TextStyle(
                            color: AppColors.primaryAccent,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontSize: 16,
                          ),
                        ),
                        if (farm != null)
                          Text(
                            farm.name,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () =>
                          ref.read(dashboardProvider.notifier).fetchAll(),
                      icon: const Icon(
                        Icons.refresh,
                        color: AppColors.primaryAccent,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              if (farm == null)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No farm selected.\nGo to Farms tab to select one.',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Time filter chips
                        _timeFilterChips(),
                        const SizedBox(height: 12),
                        // Index selector
                        _indexSelector(),
                        const SizedBox(height: 16),
                        // Multi-index chart from Supabase data
                        if (vegHistory.isNotEmpty)
                          _multiIndexChart(vegHistory)
                        else
                          _emptyHistoryCard(),
                        const SizedBox(height: 16),
                        _historyTimeline(vegHistory),
                        const SizedBox(height: 16),
                        _comparisonCard(vegHistory),
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

  // ── Time Filter Chips ─────────────────────────────────────────────────
  Widget _timeFilterChips() {
    return Row(
      children: [7, 30].map((d) {
        final isSelected = _selectedDays == d;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => setState(() => _selectedDays = d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryAccent
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primaryAccent : Colors.white24,
                ),
              ),
              child: Text(
                'Last $d days',
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Index Selector ────────────────────────────────────────────────────
  Widget _indexSelector() {
    final labels = ['All', 'NDVI', 'LSWI', 'RVI', 'SM'];
    final colors = [
      Colors.white,
      AppColors.primaryAccent,
      AppColors.secondaryAccent2,
      AppColors.softPurple,
      AppColors.goldAccent,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: labels.asMap().entries.map((e) {
          final i = e.key;
          final isSelected = _selectedIndex == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors[i].withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? colors[i] : Colors.white24,
                  ),
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    color: isSelected ? colors[i] : Colors.white54,
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Multi-Index Chart (from Supabase data) ────────────────────────────
  Widget _multiIndexChart(List<Map<String, dynamic>> data) {
    final showNdvi = _selectedIndex == 0 || _selectedIndex == 1;
    final showLswi = _selectedIndex == 0 || _selectedIndex == 2;
    final showRvi = _selectedIndex == 0 || _selectedIndex == 3;
    final showSm = _selectedIndex == 0 || _selectedIndex == 4;

    List<LineChartBarData> lines = [];

    if (showNdvi) {
      lines.add(_buildLine(data, 'ndvi', AppColors.primaryAccent));
    }
    if (showLswi) {
      lines.add(_buildLine(data, 'lswi', AppColors.secondaryAccent2));
    }
    if (showRvi) {
      lines.add(_buildLine(data, 'rvi', AppColors.softPurple));
    }
    if (showSm) {
      lines.add(_buildLine(data, 'sm', AppColors.goldAccent));
    }

    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.show_chart,
                color: AppColors.primaryAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedIndex == 0
                    ? 'VEGETATION INDEX COMPARISON'
                    : [
                        '',
                        'NDVI TREND',
                        'LSWI TREND',
                        'RVI TREND',
                        'SM TREND',
                      ][_selectedIndex],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Legend
          if (_selectedIndex == 0)
            Wrap(
              spacing: 12,
              children: [
                _legendDot('NDVI', AppColors.primaryAccent),
                _legendDot('LSWI', AppColors.secondaryAccent2),
                _legendDot('RVI', AppColors.softPurple),
                _legendDot('SM', AppColors.goldAccent),
              ],
            ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
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
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= data.length)
                          return const SizedBox.shrink();
                        final ts = data[idx]['timestamp']?.toString() ?? '';
                        final d = DateTime.tryParse(ts);
                        if (d == null) return const SizedBox.shrink();
                        return Text(
                          '${d.day}/${d.month}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 8,
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
                maxY: _selectedIndex == 3 ? 5 : 1, // RVI can be > 1
                lineBarsData: lines,
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLine(
    List<Map<String, dynamic>> data,
    String key,
    Color color,
  ) {
    return LineChartBarData(
      spots: data.asMap().entries.map((e) {
        final v = (e.value[key] as num?)?.toDouble() ?? 0.0;
        return FlSpot(e.key.toDouble(), v);
      }).toList(),
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: data.length < 15,
        getDotPainter: (_, __, ___, ____) =>
            FlDotCirclePainter(radius: 3, color: color, strokeWidth: 0),
      ),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 10)),
      ],
    );
  }

  Widget _emptyHistoryCard() {
    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.show_chart, color: AppColors.primaryAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'VEGETATION HISTORY',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'No vegetation history available yet. Refresh dashboard to fetch data from API.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Scan History Timeline ─────────────────────────────────────────────
  Widget _historyTimeline(List<Map<String, dynamic>> history) {
    final reversed = history.reversed.toList();
    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline, color: AppColors.secondaryAccent2, size: 18),
              SizedBox(width: 8),
              Text(
                'SCAN HISTORY',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (reversed.isEmpty)
            const Text(
              'No history yet. Fetch satellite data to populate.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            )
          else
            ...reversed.take(10).toList().asMap().entries.map((entry) {
              final snap = entry.value;
              final ndvi = (snap['ndvi'] as num?)?.toDouble() ?? 0.0;
              final date =
                  DateTime.tryParse(snap['timestamp']?.toString() ?? '') ??
                  DateTime.now();
              final color = ndvi > 0.6
                  ? AppColors.primaryAccent
                  : ndvi > 0.4
                  ? AppColors.goldAccent
                  : Colors.redAccent;
              final statusLabel = ndvi > 0.6
                  ? 'Healthy'
                  : ndvi > 0.4
                  ? 'Moderate'
                  : 'Poor';
              final isLast = entry.key == reversed.length - 1 || entry.key == 9;

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
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.6),
                                  blurRadius: 6,
                                ),
                              ],
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
                                      '${date.day} ${_month(date.month)}, ${date.year}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Text(
                                          'NDVI: ',
                                          style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          ndvi.toStringAsFixed(3),
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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

  // ── Comparison Card ───────────────────────────────────────────────────
  Widget _comparisonCard(List<Map<String, dynamic>> history) {
    if (history.length < 2) return const SizedBox.shrink();
    final first = history.first;
    final last = history.last;
    final firstNdvi = (first['ndvi'] as num?)?.toDouble() ?? 0.0;
    final lastNdvi = (last['ndvi'] as num?)?.toDouble() ?? 0.0;
    final firstTs =
        DateTime.tryParse(first['timestamp']?.toString() ?? '') ??
        DateTime.now();
    final lastTs =
        DateTime.tryParse(last['timestamp']?.toString() ?? '') ??
        DateTime.now();
    final delta = lastNdvi - firstNdvi;
    final improved = delta > 0;
    final deltaColor = improved ? AppColors.primaryAccent : Colors.redAccent;

    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.compare_arrows, color: AppColors.softPurple, size: 18),
              SizedBox(width: 8),
              Text(
                'PERIOD COMPARISON',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _compStat('First', firstTs, firstNdvi),
              Column(
                children: [
                  Icon(
                    improved ? Icons.trending_up : Icons.trending_down,
                    color: deltaColor,
                    size: 32,
                  ),
                  Text(
                    '${improved ? '+' : ''}${delta.toStringAsFixed(3)}',
                    style: TextStyle(
                      color: deltaColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    improved ? 'IMPROVED' : 'DECLINED',
                    style: TextStyle(
                      color: deltaColor,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              _compStat('Latest', lastTs, lastNdvi),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compStat(String label, DateTime date, double ndvi) {
    final color = ndvi > 0.6
        ? AppColors.primaryAccent
        : ndvi > 0.4
        ? AppColors.goldAccent
        : Colors.redAccent;
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          '${date.day}/${date.month}/${date.year}',
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        const SizedBox(height: 8),
        Text(
          ndvi.toStringAsFixed(3),
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _month(int m) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m];
  }
}
