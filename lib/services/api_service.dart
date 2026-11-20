import 'package:dio/dio.dart';
import 'app_settings.dart';

class ApiService {
  ApiService._();
  static final instance = ApiService._();
  Dio get _dio => Dio(BaseOptions(
    baseUrl: AppSettings.instance.backendUrl,
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 18),
    headers: {'Accept': 'application/json'},
  ));

  String normalizeTag(String raw) {
    final cleaned = raw.trim().replaceAll('#', '').toUpperCase();
    if (cleaned.isEmpty || !RegExp(r'^[0289PYLQGRJCUV]+$').hasMatch(cleaned)) {
      throw const FormatException('Enter a valid Clash Royale tag (letters/numbers from the tag alphabet).');
    }
    return Uri.encodeComponent('#$cleaned');
  }
  Future<dynamic> get(String path) async {
    try {
      final response = await _dio.get(path);
      return response.data;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      if (status == 404) throw Exception('Not found. Check the tag and try again.');
      if (status == 403 || status == 401) throw Exception('API access denied. Check the backend API token and allowlisted IP.');
      if (status == 429) throw Exception('API rate limit reached. Please wait before retrying.');
      final detail = body is Map ? (body['message'] ?? body['reason'] ?? e.message) : e.message;
      throw Exception(detail ?? 'Network request failed. Check your connection and backend.');
    } catch (e) {
      rethrow;
    }
  }
  Future<Map<String, dynamic>> player(String tag) async => Map<String, dynamic>.from(await get('/v1/players/${normalizeTag(tag)}'));
  Future<List<dynamic>> battles(String tag) async => List<dynamic>.from(await get('/v1/players/${normalizeTag(tag)}/battlelog'));
  Future<Map<String, dynamic>> clan(String tag) async => Map<String, dynamic>.from(await get('/v1/clans/${normalizeTag(tag)}'));
  Future<List<dynamic>> clanMembers(String tag) async => List<dynamic>.from(await get('/v1/clans/${normalizeTag(tag)}/members'));
  Future<Map<String, dynamic>> cards() async => Map<String, dynamic>.from(await get('/v1/cards'));
  Future<dynamic> rankings(String locationId) => get('/v1/locations/$locationId/rankings/players');
  Future<bool> testConnection() async {
    await get('/v1/cards');
    return true;
  }
}
