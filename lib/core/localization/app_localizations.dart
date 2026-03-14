import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const delegate = _AppLocalizationsDelegate();

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
    Locale('kn'),
    Locale('ta'),
    Locale('te'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('en'));
  }

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'dashboard': 'Dashboard',
      'settings': 'Settings',
      'language': 'Language',
      'showVegetationIndex': 'Show Vegetation Index',
      'smartIrrigation': 'Smart Irrigation',
      'cropAdvisory': 'Crop Advisory',
      'aiFarmAdvisor': 'AI Farm Advisor',
      'weatherSummary': 'Weather Summary',
    },
    'hi': {
      'dashboard': 'डैशबोर्ड',
      'settings': 'सेटिंग्स',
      'language': 'भाषा',
      'showVegetationIndex': 'वनस्पति सूचकांक दिखाएं',
      'smartIrrigation': 'स्मार्ट सिंचाई',
      'cropAdvisory': 'फसल सलाह',
      'aiFarmAdvisor': 'एआई फार्म सलाहकार',
      'weatherSummary': 'मौसम सारांश',
    },
    'mr': {
      'dashboard': 'डॅशबोर्ड',
      'settings': 'सेटिंग्स',
      'language': 'भाषा',
      'showVegetationIndex': 'वनस्पती निर्देशांक दाखवा',
      'smartIrrigation': 'स्मार्ट सिंचन',
      'cropAdvisory': 'पीक सल्ला',
      'aiFarmAdvisor': 'एआय फार्म सल्लागार',
      'weatherSummary': 'हवामान सारांश',
    },
    'kn': {
      'dashboard': 'ಡ್ಯಾಶ್‌ಬೋರ್ಡ್',
      'settings': 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
      'language': 'ಭಾಷೆ',
      'showVegetationIndex': 'ಸಸ್ಯ ಸೂಚ್ಯಂಕ ತೋರಿಸಿ',
      'smartIrrigation': 'ಸ್ಮಾರ್ಟ್ ನೀರಾವರಿ',
      'cropAdvisory': 'ಬೆಳೆ ಸಲಹೆ',
      'aiFarmAdvisor': 'ಎಐ ಫಾರ್ಮ್ ಸಲಹೆಗಾರ',
      'weatherSummary': 'ಹವಾಮಾನ ಸಾರಾಂಶ',
    },
    'ta': {
      'dashboard': 'டாஷ்போர்டு',
      'settings': 'அமைப்புகள்',
      'language': 'மொழி',
      'showVegetationIndex': 'தாவர குறியீட்டை காட்டு',
      'smartIrrigation': 'ஸ்மார்ட் பாசனம்',
      'cropAdvisory': 'பயிர் ஆலோசனை',
      'aiFarmAdvisor': 'ஏஐ பண்ணை ஆலோசகர்',
      'weatherSummary': 'வானிலை சுருக்கம்',
    },
    'te': {
      'dashboard': 'డ్యాష్‌బోర్డ్',
      'settings': 'సెట్టింగ్స్',
      'language': 'భాష',
      'showVegetationIndex': 'వెజిటేషన్ ఇండెక్స్ చూపించు',
      'smartIrrigation': 'స్మార్ట్ నీటిపారుదల',
      'cropAdvisory': 'పంట సలహా',
      'aiFarmAdvisor': 'ఏఐ ఫార్మ్ సలహాదారు',
      'weatherSummary': 'వాతావరణ సారాంశం',
    },
  };

  String t(String key) {
    final lang = _strings[locale.languageCode] ?? _strings['en']!;
    return lang[key] ?? _strings['en']![key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .map((e) => e.languageCode)
      .contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
