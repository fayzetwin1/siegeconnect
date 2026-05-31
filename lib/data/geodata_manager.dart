import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Manages downloading and caching of geodata files (GeoSite / GeoIP)
/// required by the Mihomo core for GEOSITE and GEOIP routing rules.
class GeodataManager {
  static const _geositeUrl =
      'https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat';
  static const _geoipUrl =
      'https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat';

  String? _cachedDataDir;

  /// Returns the persistent directory where geodata files are stored.
  /// Creates it if it does not exist.
  Future<String> getDataDirectory() async {
    if (_cachedDataDir != null) return _cachedDataDir!;

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'SiegeConnect', 'mihomo_data'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    _cachedDataDir = dir.path;
    return _cachedDataDir!;
  }

  /// Ensures both `geosite.dat` and `geoip.dat` are present in the data
  /// directory. Downloads them from Loyalsoldier v2ray-rules-dat if missing.
  ///
  /// Throws if the download fails (e.g. no network).
  Future<void> ensureGeodataAvailable() async {
    final dataDir = await getDataDirectory();
    final geositeFile = File(p.join(dataDir, 'geosite.dat'));
    final geoipFile = File(p.join(dataDir, 'geoip.dat'));

    if (geositeFile.existsSync() && geoipFile.existsSync()) {
      return; // already cached
    }

    final dio = Dio(BaseOptions(
      followRedirects: true,
      maxRedirects: 5,
      receiveTimeout: const Duration(seconds: 60),
    ));

    try {
      if (!geositeFile.existsSync()) {
        print('Downloading geosite.dat from Loyalsoldier...');
        await dio.download(_geositeUrl, geositeFile.path);
        print('geosite.dat downloaded (${geositeFile.lengthSync()} bytes).');
      }
      if (!geoipFile.existsSync()) {
        print('Downloading geoip.dat from Loyalsoldier...');
        await dio.download(_geoipUrl, geoipFile.path);
        print('geoip.dat downloaded (${geoipFile.lengthSync()} bytes).');
      }
    } catch (e) {
      // Clean up partial downloads
      if (geositeFile.existsSync() && geositeFile.lengthSync() == 0) {
        geositeFile.deleteSync();
      }
      if (geoipFile.existsSync() && geoipFile.lengthSync() == 0) {
        geoipFile.deleteSync();
      }
      throw Exception('Failed to download geodata: $e');
    }
  }
}
