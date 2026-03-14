import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/farm_providers.dart';
import '../widgets/farm_parallax_background.dart';
import '../widgets/glass_card.dart';
import 'ai_insights_screen.dart';
import 'ai_advisor_screen.dart';
import 'image_diagnosis_screen.dart';
import 'soil_report_screen.dart';
import 'farm_history_screen.dart';
import 'farm_selection_screen.dart';

/// AI Hub — groups all secondary screens into a beautiful sub-nav grid.
/// Accessible from the bottom nav "AI Hub" tab.
class AiHubScreen extends ConsumerStatefulWidget {
  const AiHubScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AiHubScreen> createState() => _AiHubScreenState();
}

class _AiHubScreenState extends ConsumerState<AiHubScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _go(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final farm = ref.watch(selectedFarmProvider);

    return Scaffold(
      body: FarmParallaxBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.softPurple.withOpacity(
                                0.12 + _pulseCtrl.value * 0.08),
                            border: Border.all(
                              color: AppColors.softPurple.withOpacity(
                                  0.5 + _pulseCtrl.value * 0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.softPurple
                                    .withOpacity(0.3 * _pulseCtrl.value),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.auto_awesome,
                              color: AppColors.softPurple, size: 22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AI HUB',
                              style: TextStyle(
                                color: AppColors.softPurple,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              )),
                          Text(
                            farm != null
                                ? '${farm.name} · ${farm.cropType}'
                                : 'Select a farm to personalise',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Farm section ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: _sectionHeader('🌾  Farm Management'),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildListDelegate([
                    _hubCard(
                      icon: Icons.agriculture,
                      label: 'My Farms',
                      sub: 'Select or manage farms',
                      color: AppColors.primaryAccent,
                      onTap: () => _go(const FarmSelectionScreen()),
                    ),
                    _hubCard(
                      icon: Icons.history_rounded,
                      label: 'Farm History',
                      sub: 'NDVI & weather trends',
                      color: AppColors.goldAccent,
                      onTap: () => _go(const FarmHistoryScreen()),
                    ),
                  ]),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                  ),
                ),
              ),

              // ── AI section ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _sectionHeader('🤖  AI & Satellite'),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildListDelegate([
                    _hubCard(
                      icon: Icons.radar,
                      label: 'AI Insights',
                      sub: 'Satellite analysis & risk',
                      color: AppColors.softPurple,
                      onTap: () => _go(const AiInsightsScreen()),
                    ),
                    _hubCard(
                      icon: Icons.smart_toy_rounded,
                      label: 'AI Advisor',
                      sub: 'Ask Gemini anything',
                      color: const Color(0xFF00BCD4),
                      onTap: () => _go(const AiAdvisorScreen()),
                    ),
                  ]),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                  ),
                ),
              ),

              // ── Diagnosis section ──────────────────────────────────────
              SliverToBoxAdapter(
                child: _sectionHeader('🔬  Diagnosis & Reports'),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverGrid(
                  delegate: SliverChildListDelegate([
                    _hubCard(
                      icon: Icons.camera_alt_rounded,
                      label: 'Image Diagnose',
                      sub: 'Identify crop diseases',
                      color: Colors.orangeAccent,
                      onTap: () => _go(const ImageDiagnosisScreen()),
                    ),
                    _hubCard(
                      icon: Icons.terrain,
                      label: 'Soil Report',
                      sub: 'N · P · K · pH analysis',
                      color: const Color(0xFF8BC34A),
                      onTap: () => _go(const SoilReportScreen()),
                    ),
                  ]),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _hubCard({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.4), width: 1),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Open',
                          style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_forward_ios, color: color, size: 8),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
