import 'package:dio/dio.dart';

class MihomoApi {
  final Dio _dio;

  MihomoApi() : _dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:9090'));

  /// Fetches the list of all available proxies and groups from Mihomo
  Future<Map<String, dynamic>> getProxies() async {
    try {
      final response = await _dio.get('/proxies');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('MihomoApi getProxies Error: $e');
      return {};
    }
  }

  /// Switches the active server for a specific proxy group
  Future<bool> selectProxy(String groupName, String proxyName) async {
    try {
      final response = await _dio.put(
        '/proxies/${Uri.encodeComponent(groupName)}',
        data: {'name': proxyName},
      );
      return response.statusCode == 204;
    } catch (e) {
      print('MihomoApi selectProxy Error: $e');
      return false;
    }
  }

  /// Pings a specific proxy to get its delay.
  ///
  /// Returns:
  ///  - positive int → actual delay in ms
  ///  - `0` → timeout / unreachable
  Future<int> getDelay(String proxyName) async {
    try {
      final response = await _dio.get(
        '/proxies/${Uri.encodeComponent(proxyName)}/delay',
        queryParameters: {
          'timeout': 10000,
          'url': 'http://cp.cloudflare.com/generate_204',
        },
      );
      if (response.statusCode == 200 && response.data['delay'] != null) {
        return response.data['delay'] as int;
      }
    } catch (e) {
      print('MihomoApi getDelay Error for $proxyName: $e');
    }
    return 0; // timeout / error
  }
}
