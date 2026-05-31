import 'package:isar/isar.dart';

part 'app_settings.g.dart';

@collection
class AppSettings {
  Id id = Isar.autoIncrement;

  String? subLink;

  String? cachedYamlConfig;

  DateTime? lastUpdated;

  bool isSplitTunnelingEnabled = false;

  List<String> allowedApps = [];

  List<String> parsedServers = [];

  String? activeServer;

  String themeMode = 'system';

  bool hasSeenIntro = false;
}
