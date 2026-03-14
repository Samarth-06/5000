import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final box = Hive.box(AppConstants.settingsBox);
    final languageCode =
        box.get(AppConstants.keyLanguage, defaultValue: 'en') as String;
    return Locale(languageCode);
  }

  Future<void> setLanguage(String languageCode) async {
    final box = Hive.box(AppConstants.settingsBox);
    await box.put(AppConstants.keyLanguage, languageCode);
    state = Locale(languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
