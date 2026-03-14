import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/farm_hive_model.dart';
import '../../viewmodels/farm_providers.dart';
import '../widgets/glass_card.dart';
import 'farm_registration_screen.dart';

class FarmSelectionScreen extends ConsumerWidget {
  const FarmSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farms = ref.watch(farmListProvider);
    final selectedFarm = ref.watch(selectedFarmProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MY FARMS',
          style: TextStyle(
            color: AppColors.primaryAccent,
            fontSize: 16,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.primaryAccent,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FarmRegistrationScreen()),
            ),
          ),
        ],
      ),
      body: farms.isEmpty
          ? Center(
              child: GlassCard(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.agriculture,
                      size: 64,
                      color: AppColors.primaryAccent,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Farms Registered',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap + to register your first farm',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FarmRegistrationScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('REGISTER FARM'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: farms.length,
              itemBuilder: (_, i) {
                final farm = farms[i];
                final isSelected = selectedFarm?.id == farm.id;
                return _farmCard(context, ref, farm, isSelected);
              },
            ),
    );
  }

  Widget _farmCard(
    BuildContext context,
    WidgetRef ref,
    FarmHiveModel farm,
    bool isSelected,
  ) {
    final borderColor = isSelected
        ? AppColors.primaryAccent
        : Colors.transparent;

    return GestureDetector(
      onTap: () {
        ref.read(selectedFarmProvider.notifier).select(farm);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected: ${farm.name}'),
            backgroundColor: AppColors.primaryAccent,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 0),
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      (isSelected
                              ? AppColors.primaryAccent
                              : AppColors.secondaryAccent2)
                          .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.agriculture,
                  color: isSelected
                      ? AppColors.primaryAccent
                      : AppColors.secondaryAccent2,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farm.name,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primaryAccent
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${farm.cropType} • ${farm.areaInAcres} acres',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${farm.latitude.toStringAsFixed(4)}, ${farm.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'SELECTED',
                    style: TextStyle(
                      color: AppColors.primaryAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ] else
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white24,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
