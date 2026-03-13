import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/farm_providers.dart';
import '../widgets/glass_card.dart';
import 'dashboard_shell.dart';
import 'farm_registration_screen.dart';

class FarmSelectionScreen extends ConsumerWidget {
  const FarmSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farms = ref.watch(farmListProvider);
    final selectedFarm = ref.watch(selectedFarmProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1117), Color(0xFF0A192F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('SELECT FARM', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
                        Text('Choose a farm to monitor', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const FarmRegistrationScreen(isFirstLaunch: false))),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('ADD'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (farms.isEmpty)
                Expanded(
                  child: Center(
                    child: GlassCard(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.agriculture, color: AppColors.primaryAccent, size: 64),
                          const SizedBox(height: 16),
                          const Text('No farms registered', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Add your first farm to start satellite monitoring', style: TextStyle(color: Colors.white54, fontSize: 13), textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushReplacement(context,
                                MaterialPageRoute(builder: (_) => const FarmRegistrationScreen(isFirstLaunch: true))),
                            icon: const Icon(Icons.add),
                            label: const Text('ADD FARM'),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: farms.length,
                    itemBuilder: (context, i) {
                      final farm = farms[i];
                      final isSelected = selectedFarm?.id == farm.id;
                      return GestureDetector(
                        onTap: () {
                          ref.read(selectedFarmProvider.notifier).select(farm);
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => const DashboardShell()));
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryAccent.withOpacity(0.1) : const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryAccent : Colors.white12,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: AppColors.primaryAccent.withOpacity(0.2), blurRadius: 12)]
                                : [],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.primaryAccent.withOpacity(0.4)),
                                  ),
                                  child: const Icon(Icons.eco, color: AppColors.primaryAccent, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(farm.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text('${farm.cropType} • ${farm.areaInAcres} Acres',
                                          style: const TextStyle(color: Colors.white54, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Text('${farm.latitude.toStringAsFixed(4)}, ${farm.longitude.toStringAsFixed(4)}',
                                          style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'monospace')),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    if (isSelected)
                                      const Icon(Icons.check_circle, color: AppColors.primaryAccent),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            backgroundColor: const Color(0xFF161B22),
                                            title: const Text('Delete Farm', style: TextStyle(color: Colors.white)),
                                            content: Text('Remove "${farm.name}"?', style: const TextStyle(color: Colors.white70)),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          ref.read(farmListProvider.notifier).deleteFarm(farm.id);
                                        }
                                      },
                                      child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
