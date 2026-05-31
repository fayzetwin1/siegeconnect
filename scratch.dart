import 'dart:io';

void main() {
  String rawYaml = '''
port: 7890
socks-port: 7891
external-controller: 127.0.0.1:9090

rules:
  - MATCH,DIRECT
  
  - DOMAIN,google.com
  
tun:
  enable: false
''';

  String _removeYamlBlock(String yaml, String blockName) {
    final lines = yaml.split('\\n');
    final result = <String>[];
    bool inBlock = false;
    for (var line in lines) {
      if (line.trim().startsWith(blockName + ':')) {
        inBlock = true;
        continue;
      }
      if (inBlock) {
        if (line.trim().isEmpty) continue;
        if (line.isNotEmpty && !line.startsWith(' ') && !line.startsWith('\\t')) {
          inBlock = false;
        } else {
          continue;
        }
      }
      result.add(line);
    }
    return result.join('\\n');
  }

  String safe = rawYaml;
  safe = _removeYamlBlock(safe, 'external-controller');
  safe = _removeYamlBlock(safe, 'rules');
  safe = _removeYamlBlock(safe, 'tun');

  print('SAFE YAML:');
  print(safe);

  final regex = RegExp(r'\b([a-zA-Z]{2})\b');
  final match1 = regex.firstMatch('FI via RU by Eversiege')?.group(1);
  final match2 = regex.firstMatch(' RU Node [WL]')?.group(1);
  final match3 = regex.firstMatch('BY via DE by fayzetwin')?.group(1);
  
  print('FI: ' + match1.toString());
  print('RU: ' + match2.toString());
  print('BY: ' + match3.toString());
}
