import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../services/notification_service.dart';
import '../../viewmodels/farm_providers.dart';
import '../widgets/glass_card.dart';
import '../widgets/farm_parallax_background.dart';
import 'farm_registration_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _agroKeyCtrl;
  late TextEditingController _weatherKeyCtrl;
  late TextEditingController _mapsKeyCtrl;
  String _selectedLang = 'English';

  final _langs = ['English', 'Hindi', 'Marathi'];

  @override
  void initState() {
    super.initState();
    final box = Hive.box(AppConstants.settingsBox);
    _agroKeyCtrl = TextEditingController(text: box.get(AppConstants.keyAgroApiKey, defaultValue: ''));
    _weatherKeyCtrl = TextEditingController(text: box.get(AppConstants.keyWeatherApiKey, defaultValue: ''));
    _mapsKeyCtrl = TextEditingController(text: box.get(AppConstants.keyGoogleMapsKey, defaultValue: ''));
    _selectedLang = box.get(AppConstants.keyLanguage, defaultValue: 'English');
  }

  @override
  void dispose() {
    _agroKeyCtrl.dispose();
    _weatherKeyCtrl.dispose();
    _mapsKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final box = Hive.box(AppConstants.settingsBox);
    await box.put(AppConstants.keyAgroApiKey, _agroKeyCtrl.text.trim());
    await box.put(AppConstants.keyWeatherApiKey, _weatherKeyCtrl.text.trim());
    await box.put(AppConstants.keyGoogleMapsKey, _mapsKeyCtrl.text.trim());
    await box.put(AppConstants.keyLanguage, _selectedLang);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF228B22),
        content: Row(children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 8),
          Text('Settings saved! Restart to apply API keys.', style: TextStyle(color: Colors.white)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final farms = ref.watch(farmListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS', style: TextStyle(color: AppColors.primaryAccent, letterSpacing: 1.5)),
      ),
      body: FarmParallaxBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API Keys
            GlassCard(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('API KEYS', Icons.vpn_key),
                  const SizedBox(height: 4),
                  const Text('Replace placeholders with real keys for live data',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 20),
                  _apiKeyTile(
                    label: 'Agromonitoring NDVI Key',
                    subtitle: 'Get free key at agromonitoring.com/api/get',
                    ctrl: _agroKeyCtrl,
                    icon: Icons.satellite_alt,
                    color: AppColors.primaryAccent,
                  ),
                  const SizedBox(height: 14),
                  _apiKeyTile(
                    label: 'OpenWeatherMap Key',
                    subtitle: 'Get free key at openweathermap.org/api',
                    ctrl: _weatherKeyCtrl,
                    icon: Icons.cloud,
                    color: AppColors.secondaryAccent2,
                  ),
                  const SizedBox(height: 14),
                  _apiKeyTile(
                    label: 'Google Maps Android Key',
                    subtitle: 'Get from console.cloud.google.com',
                    ctrl: _mapsKeyCtrl,
                    icon: Icons.map,
                    color: AppColors.goldAccent,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Language
            GlassCard(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('LANGUAGE', Icons.language),
                  const SizedBox(height: 16),
                  Row(
                    children: _langs.map((lang) {
                      final isSelected = lang == _selectedLang;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedLang = lang),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryAccent : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: isSelected ? AppColors.primaryAccent : Colors.white24),
                            ),
                            child: Text(lang,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                )),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Farm Management
            GlassCard(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('FARMS (${farms.length})', Icons.agriculture),
                  const SizedBox(height: 16),
                  ...farms.map((farm) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.eco, color: AppColors.primaryAccent, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(farm.name,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  Text('${farm.cropType} • ${farm.areaInAcres} acres',
                                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => ref.read(farmListProvider.notifier).deleteFarm(farm.id),
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const FarmRegistrationScreen(isFirstLaunch: false))),
                      icon: const Icon(Icons.add, color: AppColors.primaryAccent),
                      label: const Text('ADD NEW FARM', style: TextStyle(color: AppColors.primaryAccent)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Notifications ─────────────────────────────
            GlassCard(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('NOTIFICATIONS', Icons.notifications_rounded),
                  const SizedBox(height: 6),
                  const Text(
                    'Farm alerts for NDVI drops, irrigation, pests, and weather.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  // Request permission
                  _notifTile(
                    icon: Icons.notifications_active,
                    label: 'Enable Notifications',
                    sub: 'Request / re-grant permission',
                    color: AppColors.primaryAccent,
                    onTap: () async {
                      await NotificationService.init();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF228B22),
                          content: Text('Permission requested! Check device prompt.'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Test notification
                  _notifTile(
                    icon: Icons.send_rounded,
                    label: 'Send Test Notification',
                    sub: 'Verify alerts are working on this device',
                    color: AppColors.softPurple,
                    onTap: () async {
                      await NotificationService.sendTest();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.softPurple.withOpacity(0.9),
                          content: const Row(children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Test notification sent!',
                                style: TextStyle(color: Colors.white)),
                          ]),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text('SAVE ALL SETTINGS', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryAccent, size: 18),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ],
    );
  }

  Widget _notifTile({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          )),
          Icon(Icons.chevron_right, color: color.withOpacity(0.5), size: 18),
        ]),
      ),
    );
  }

  Widget _apiKeyTile({required String label, required String subtitle, required TextEditingController ctrl, required IconData icon, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: 'Paste your API key here...',
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: color.withOpacity(0.3))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: color, width: 1.5)),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
