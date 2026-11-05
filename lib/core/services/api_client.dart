import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../../features/auth/domain/auth_session.dart';

typedef TokenSource = Future<String> Function({bool refresh});
final authSessionProvider = Provider<AuthSession?>((ref) => null);
final tokenSourceProvider = Provider<TokenSource>(
  (ref) =>
      ({bool refresh = false}) async =>
          throw const ApiException(401, 'UNAUTHORIZED'),
);
final signOutProvider = Provider<Future<void> Function()>((ref) => () async {});
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(token: ref.watch(tokenSourceProvider));
  ref.onDispose(client.close);
  return client;
});

class ApiException implements Exception {
  const ApiException(this.status, this.code);
  final int status;
  final String code;
  String get message => code == 'TRACK_ALREADY_EXISTS'
      ? 'This MP3 is already in your library with different details. Choose a different file.'
      : switch (status) {
          401 => 'Your session could not be verified. Please sign in again.',
          413 => 'The file is too large.',
          415 => 'This file type or file content is not supported.',
          429 => 'Too many requests. Please wait a few minutes and try again.',
          400 => 'Some details are invalid. Check your file and track details.',
          404 => 'This track or uploaded file is no longer available.',
          409 => 'This file is being processed. Wait a moment and retry.',
          _ => 'The service could not complete this request. Check your connection and try again.',
        };
}

class ApiClient {
  ApiClient({required this.token, http.Client? client, this.baseUrl})
    : _client = client ?? http.Client();
  final TokenSource token;
  final http.Client _client;
  final String? baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${baseUrl ?? ApiConfig.baseUrl}/api/v1$path')
          .replace(queryParameters: query?.isEmpty == true ? null : query);

  Future<dynamic> _send(Future<http.Response> Function(String) request) async {
    try {
      var response = await request(await token());
      if (response.statusCode == 401) {
        response = await request(await token(refresh: true));
      }
      if (response.statusCode == 204) return null;
      final body = jsonDecode(response.body);
      if (response.statusCode >= 400) {
        throw ApiException(
          response.statusCode,
          body is Map
              ? (body['error']?['code'] as String? ?? 'REQUEST_FAILED')
              : 'REQUEST_FAILED',
        );
      }
      if (body is! Map ||
          body['success'] != true ||
          !body.containsKey('data')) {
        throw const FormatException();
      }
      return body['data'];
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(0, 'CONNECTION_FAILED');
    }
  }

  Future<dynamic> request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) => _send((jwt) async {
    final request = http.Request(method, _uri(path, query))
      ..headers.addAll({
        'Authorization': 'Bearer $jwt',
        'Accept': 'application/json',
      });
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    return http.Response.fromStream(
      await _client.send(request).timeout(const Duration(seconds: 20)),
    ).timeout(const Duration(seconds: 20));
  });

  Future<String> upload(String kind, String name, Uint8List bytes) async {
    final ext = name.split('.').last.toLowerCase();
    final type = kind == 'audio'
        ? MediaType('audio', 'mpeg')
        : MediaType('image', ext == 'jpg' ? 'jpeg' : ext);
    final result = await _send((jwt) async {
      final request = http.MultipartRequest('POST', _uri('/uploads/$kind'))
        ..headers['Authorization'] = 'Bearer $jwt';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: name,
          contentType: type,
        ),
      );
      return http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 90)),
      ).timeout(const Duration(seconds: 90));
    });
    return result['id'] as String;
  }

  void close() => _client.close();
}
