import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../domain/models/app_settings.dart';
import '../../main.dart'; // To access isarProvider

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final isar = ref.read(isarProvider);
    var settings = isar.appSettings.where().findFirstSync();
    if (settings == null) {
      settings = AppSettings();
      isar.writeTxnSync(() {
        isar.appSettings.putSync(settings!);
      });
    }
    return settings;
  }

  void updateSubLink(String link) {
    final isar = ref.read(isarProvider);
    final updatedSettings = state..subLink = link;
    isar.writeTxnSync(() {
      isar.appSettings.putSync(updatedSettings);
    });
    _triggerRebuild(updatedSettings);
  }

  void setThemeMode(String mode) {
    final isar = ref.read(isarProvider);
    final updatedSettings = state..themeMode = mode;
    isar.writeTxnSync(() {
      isar.appSettings.putSync(updatedSettings);
    });
    _triggerRebuild(updatedSettings);
  }

  void completeIntro() {
    final isar = ref.read(isarProvider);
    final updatedSettings = state..hasSeenIntro = true;
    isar.writeTxnSync(() {
      isar.appSettings.putSync(updatedSettings);
    });
    _triggerRebuild(updatedSettings);
  }

  void clearData() {
    final isar = ref.read(isarProvider);
    final updatedSettings = state
      ..subLink = null
      ..cachedYamlConfig = null
      ..parsedServers = []
      ..hasSeenIntro = false
      ..themeMode = 'system';

    isar.writeTxnSync(() {
      isar.appSettings.putSync(updatedSettings);
    });
    _triggerRebuild(updatedSettings);
  }

  void _triggerRebuild(AppSettings updatedSettings) {
    // Trigger Riverpod rebuild
    state = AppSettings()
      ..id = updatedSettings.id
      ..subLink = updatedSettings.subLink
      ..cachedYamlConfig = updatedSettings.cachedYamlConfig
      ..lastUpdated = updatedSettings.lastUpdated
      ..parsedServers = updatedSettings.parsedServers
      ..themeMode = updatedSettings.themeMode
      ..hasSeenIntro = updatedSettings.hasSeenIntro;
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});
