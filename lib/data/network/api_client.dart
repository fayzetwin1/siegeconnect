import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio;

  ApiClient() : _dio = Dio() {
    _dio.options.headers = {
      'User-Agent': 'Clash.Meta',
    };
  }

  Future<String> fetchSubConfig(String url) async {
    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        return response.data.toString();
      } else {
        throw Exception('Failed to fetch config. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error while fetching config: $e');
    }
  }
}
