import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/farm_providers.dart';
import '../widgets/glass_card.dart';

class SoilReportScreen extends ConsumerWidget {
  const SoilReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = ref.watch(dashboardProvider);
    final soil = ds.soilReport;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOIL REPORT', style: TextStyle(color: AppColors.primaryAccent, fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
      ),
      body: soil == null
          ? const Center(child: Text('No soil report available.\nFetch data from dashboard first.', style: TextStyle(color: Colors.white54), textAlign: TextAlign.center))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.terrain, color: AppColors.goldAccent, size: 20),
                          SizedBox(width: 8),
                          Text('SOIL NUTRIENT ANALYSIS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ]),
                        const SizedBox(height: 8),
                        const Text('Soil nutrient images from satellite analysis', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        const SizedBox(height: 20),
                        _nutrientCard('🧪', 'Nitrogen (N)', soil.nImage, Colors.greenAccent),
                        const SizedBox(height: 12),
                        _nutrientCard('🔬', 'Phosphorus (P)', soil.pImage, AppColors.secondaryAccent2),
                        const SizedBox(height: 12),
                        _nutrientCard('⚗️', 'Potassium (K)', soil.kImage, AppColors.goldAccent),
                        const SizedBox(height: 12),
                        _nutrientCard('🧫', 'pH Level', soil.phImage, AppColors.softPurple),
                      ],
                    ),
                  ),
                  if (soil.pdfUrl != null) ...[
                    const SizedBox(height: 16),
                    GlassCard(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [
                            Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 18),
                            SizedBox(width: 8),
                            Text('FULL REPORT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 8),
                          Text('PDF: ${soil.pdfUrl}', style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace')),
                          if (soil.csvUrl != null) ...[
                            const SizedBox(height: 4),
                            Text('CSV: ${soil.csvUrl}', style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace')),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _nutrientCard(String emoji, String label, String? imageUrl, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              imageUrl ?? 'No data available',
              style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        )),
        if (imageUrl != null)
          Icon(Icons.open_in_new, color: color, size: 18),
      ]),
    );
  }
}
