import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';

class ConfigManager {
  String _removeYamlBlock(String yaml, String blockName) {
    final lines = yaml.split('\n');
    final result = <String>[];
    bool inBlock = false;
    for (var line in lines) {
      if (line.trim().startsWith(blockName + ':')) {
        inBlock = true;
        continue;
      }
      if (inBlock) {
        if (line.trim().isEmpty) continue;
        if (line.isNotEmpty && !line.startsWith(' ') && !line.startsWith('\t') && !line.startsWith('-')) {
          inBlock = false;
        } else {
          continue; // inside block, skip
        }
      }
      result.add(line);
    }
    return result.join('\n');
  }

  /// Extracts the first proxy-group name (type: select) from the YAML.
  /// This is the main selector group that the MATCH rule should reference.
  String? _findMainGroupName(String rawYaml) {
    try {
      final doc = loadYaml(rawYaml);
      if (doc is Map && doc.containsKey('proxy-groups')) {
        final groups = doc['proxy-groups'] as YamlList;
        for (final group in groups) {
          if (group['type'] == 'select' && group['name'] != null) {
            return group['name'].toString();
          }
        }
      }
    } catch (e) {
      print('Failed to parse proxy groups: $e');
    }
    return null;
  }

  Future<String> prepareConfig(String rawYaml) async {
    final dir = await getApplicationDocumentsDirectory();
    final configPath = '${dir.path}/config.yaml';

    // Find the real proxy group name for the MATCH rule
    final groupName = _findMainGroupName(rawYaml) ?? 'GLOBAL';

    final customRules = """
rules:
  - DOMAIN-SUFFIX,ru,DIRECT
  - GEOIP,ru,DIRECT
  - MATCH,$groupName
""";

    final tunConfig = """
tun:
  enable: true
  stack: system
  auto-route: true
  auto-detect-interface: true
  dns-hijack: ['any:53']

external-controller: 127.0.0.1:9090
""";

    String safeYaml = rawYaml;
    safeYaml = _removeYamlBlock(safeYaml, 'external-controller');
    safeYaml = _removeYamlBlock(safeYaml, 'tun');
    safeYaml = _removeYamlBlock(safeYaml, 'rules');

    // Remove inbound ports to prevent unsupported platform errors on Windows
    safeYaml = safeYaml.replaceAll(RegExp(r'^mixed-port:.*$', multiLine: true), '');
    safeYaml = safeYaml.replaceAll(RegExp(r'^socks-port:.*$', multiLine: true), '');
    safeYaml = safeYaml.replaceAll(RegExp(r'^port:.*$', multiLine: true), '');
    safeYaml = safeYaml.replaceAll(RegExp(r'^redir-port:.*$', multiLine: true), '');
    safeYaml = safeYaml.replaceAll(RegExp(r'^tproxy-port:.*$', multiLine: true), '');

    final finalYaml = "$safeYaml\n\n$tunConfig\n\n$customRules";

    final file = File(configPath);
    await file.writeAsString(finalYaml);

    return configPath;
  }

  /// Prepares a minimal config for offline ping testing.
  /// Strips tun, external-controller, AND rules to avoid crashes from
  /// GEOSITE/GEOIP lookups, then injects only a safe catch-all rule.
  Future<String> prepareTestConfig(String rawYaml) async {
    final dir = await getApplicationDocumentsDirectory();
    final configPath = '${dir.path}/test_config.yaml';
    
    String safeYaml = rawYaml;
    safeYaml = _removeYamlBlock(safeYaml, 'external-controller');
    safeYaml = _removeYamlBlock(safeYaml, 'tun');
    safeYaml = _removeYamlBlock(safeYaml, 'rules');
    
    // Remove inbound ports to prevent "address already in use" or unsupported platform errors
    safeYaml = safeYaml.replaceAll(RegExp(r'^mixed-port:.*$', multiLine: true), '');
    safeYaml = safeYaml.replaceAll(RegExp(r'^socks-port:.*$', multiLine: true), '');
    safeYaml = safeYaml.replaceAll(RegExp(r'^port:.*$', multiLine: true), '');
    safeYaml = safeYaml.replaceAll(RegExp(r'^redir-port:.*$', multiLine: true), '');
    safeYaml = safeYaml.replaceAll(RegExp(r'^tproxy-port:.*$', multiLine: true), '');

    // Minimal additions: API endpoint + safe catch-all rule.
    // MATCH,DIRECT is safe — delay testing uses per-proxy API, not routing rules.
    final additions = """

external-controller: 127.0.0.1:9090

rules:
  - MATCH,DIRECT
""";

    final finalYaml = "$safeYaml$additions";
    
    final file = File(configPath);
    await file.writeAsString(finalYaml);

    return configPath;
  }

  /// Parses proxy names directly from raw YAML
  List<String> parseServers(String rawYaml) {
    try {
      final doc = loadYaml(rawYaml);
      if (doc is Map && doc.containsKey('proxies')) {
        final proxies = doc['proxies'] as YamlList;
        return proxies.map((p) => p['name']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
    } catch (e) {
      print('Failed to parse proxies from YAML: $e');
    }
    return [];
  }
}
