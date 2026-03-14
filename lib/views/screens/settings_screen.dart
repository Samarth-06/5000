import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../viewmodels/farm_providers.dart';
import '../../viewmodels/locale_provider.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _languageCode = 'en';

  static const Map<String, String> _languageLabelToCode = {
    'English': 'en',
    'Hindi': 'hi',
    'Marathi': 'mr',
    'Kannada': 'kn',
    'Tamil': 'ta',
    'Telugu': 'te',
  };

  static const Map<String, String> _languageCodeToLabel = {
    'en': 'English',
    'hi': 'Hindi',
    'mr': 'Marathi',
    'kn': 'Kannada',
    'ta': 'Tamil',
    'te': 'Telugu',
  };

  @override
  void initState() {
    super.initState();
    final box = Hive.box(AppConstants.settingsBox);
    _languageCode = box.get(AppConstants.keyLanguage, defaultValue: 'en');
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final t = AppLocalizations.of(context);
    final supa = ref.read(supabaseServiceProvider);
    final farms = ref.watch(farmListProvider);
    final user = supa.currentUser;
    final selectedLabel =
        _languageCodeToLabel[locale.languageCode] ?? 'English';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            color: AppColors.primaryAccent,
            fontSize: 16,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User section
            GlassCard(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: AppColors.primaryAccent,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'ACCOUNT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (user != null) ...[
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppColors.primaryAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.email ?? 'Unknown',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'ID: ${user.id.substring(0, 8)}...',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await supa.signOut();
                          if (!mounted) return;
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/', (_) => false);
                        },
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text('SIGN OUT'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Not signed in (Demo Mode)',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
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
                  const Row(
                    children: [
                      Icon(
                        Icons.language,
                        color: AppColors.secondaryAccent2,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'LANGUAGE',
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
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.secondaryAccent2.withOpacity(0.4),
                      ),
                    ),
                    child: DropdownButton<String>(
                      value: selectedLabel,
                      dropdownColor: AppColors.cardBackground,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      style: const TextStyle(color: Colors.white),
                      items: _languageLabelToCode.keys
                          .map(
                            (l) => DropdownMenuItem(value: l, child: Text(l)),
                          )
                          .toList(),
                      onChanged: (v) async {
                        if (v != null) {
                          final code = _languageLabelToCode[v] ?? 'en';
                          setState(() => _languageCode = code);
                          await ref
                              .read(localeProvider.notifier)
                              .setLanguage(code);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${t.t('language')}: ${_languageCodeToLabel[_languageCode] ?? 'English'}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Registered Farms
            GlassCard(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.agriculture,
                        color: AppColors.goldAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'REGISTERED FARMS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${farms.length}',
                        style: const TextStyle(
                          color: AppColors.goldAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (farms.isEmpty)
                    const Text(
                      'No farms registered yet.',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    )
                  else
                    ...farms.map(
                      (f) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.goldAccent.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${f.cropType} • ${f.areaInAcres} acres',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                              onPressed: () => _confirmDelete(f.id, f.name),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // API Info
            GlassCard(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.api, color: AppColors.softPurple, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'API STATUS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Sat2Farm API',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'https://badal023-testapi.hf.space',
                    style: TextStyle(
                      color: AppColors.softPurple,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '✅ Connected',
                    style: TextStyle(
                      color: AppColors.primaryAccent,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Delete Farm', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "$name"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(farmListProvider.notifier).deleteFarm(id);
              Navigator.pop(context);
            },
            child: const Text(
              'DELETE',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
