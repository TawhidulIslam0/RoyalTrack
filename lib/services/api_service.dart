
import 'package:dio/dio.dart';

import 'app_settings.dart';

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  Dio get _dio => Dio(
        BaseOptions(
          baseUrl: AppSettings.instance.backendUrl,
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 18),
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

  // Normalize Clash Royale player and clan tags.
  String normalizeTag(String raw) {
    final cleaned = raw
        .trim()
        .replaceAll('#', '')
        .toUpperCase();

    if (cleaned.isEmpty ||
        !RegExp(r'^[0289PYLQGRJCUV]+$').hasMatch(cleaned)) {
      throw const FormatException(
        'Enter a valid Clash Royale tag '
        '(letters/numbers from the tag alphabet).',
      );
    }

    return Uri.encodeComponent('#$cleaned');
  }

  // Generic GET request.
  Future<dynamic> get(String path) async {
    try {
      final response = await _dio.get(path);
      return response.data;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;

      if (status == 404) {
        throw Exception(
          'Not found. Check the tag and try again.',
        );
      }

      if (status == 403 || status == 401) {
        throw Exception(
          'API access denied. Check the backend API token '
          'and allowlisted IP.',
        );
      }

      if (status == 429) {
        throw Exception(
          'API rate limit reached. Please wait before retrying.',
        );
      }

      if (status == 500 || status == 502 || status == 503) {
        throw Exception(
          'The backend server is temporarily unavailable. '
          'Please try again later.',
        );
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Connection timed out. Please try again.',
        );
      }

      if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Unable to connect to the server. '
          'Check your internet connection.',
        );
      }

      final detail = body is Map
          ? body['message'] ?? body['reason'] ?? e.message
          : e.message;

      throw Exception(
        detail?.toString() ??
            'Network request failed. '
                'Check your connection and backend.',
      );
    }
  }

  // Player information.
  Future<Map<String, dynamic>> player(String tag) async {
    final data = await get(
      '/v1/players/${normalizeTag(tag)}',
    );

    if (data is! Map) {
      throw const FormatException(
        'Invalid player response from server.',
      );
    }

    return Map<String, dynamic>.from(data);
  }

  // Player battle history.
  Future<List<dynamic>> battles(String tag) async {
    final data = await get(
      '/v1/players/${normalizeTag(tag)}/battlelog',
    );

    if (data is List) {
      return List<dynamic>.from(data);
    }

    if (data is Map && data['items'] is List) {
      return List<dynamic>.from(data['items'] as List);
    }

    return const [];
  }

  // Clan information.
  Future<Map<String, dynamic>> clan(String tag) async {
    final data = await get(
      '/v1/clans/${normalizeTag(tag)}',
    );

    if (data is! Map) {
      throw const FormatException(
        'Invalid clan response from server.',
      );
    }

    return Map<String, dynamic>.from(data);
  }

  // Clan members.
  Future<List<dynamic>> clanMembers(String tag) async {
    final data = await get(
      '/v1/clans/${normalizeTag(tag)}/members',
    );

    if (data is List) {
      return List<dynamic>.from(data);
    }

    if (data is Map) {
      final list =
          data['items'] ?? data['memberList'] ?? const [];

      if (list is List) {
        return List<dynamic>.from(list);
      }
    }

    return const [];
  }

  // Cards catalog.
  Future<Map<String, dynamic>> cards() async {
    final data = await get('/v1/cards');

    if (data is! Map) {
      throw const FormatException(
        'Invalid cards response from server.',
      );
    }

    return Map<String, dynamic>.from(data);
  }

  // Player rankings.
  Future<dynamic> rankings(String locationId) {
    final encodedLocation =
        Uri.encodeComponent(locationId.trim());

    return get(
      '/v1/locations/$encodedLocation/rankings/players',
    );
  }

  // Test backend connection.
  Future<bool> testConnection() async {
    await get('/v1/cards');
    return true;
  }
}
