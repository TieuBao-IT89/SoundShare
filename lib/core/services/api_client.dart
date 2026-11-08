import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../../features/auth/domain/auth_session.dart';
import '../../l10n/l10n.dart';
import 'upload_control.dart';
import 'upload_transport.dart'
    if (dart.library.js_interop) 'upload_transport_web.dart';

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
  String get message => switch (code) {
    'INVALID_LRC' => appCopy.v11InvalidLrc,
    'LYRICS_CHANGED' => appCopy.v11LyricsChanged,
    'LYRICS_UNAVAILABLE' => appCopy.v11LoadFailed,
    'USERNAME_TAKEN' => appCopy.v3UsernameTaken,
    'PROFILE_REQUIRED' => appCopy.v3ProfileRequired,
    'RIGHTS_REQUIRED' => appCopy.v3RightsRequired,
    'COMMUNITY_UNAVAILABLE' => appCopy.v3Unavailable,
    'SOCIAL_UNAVAILABLE' => appCopy.v3Unavailable,
    'UPLOAD_CANCELLED' => appCopy.v3UploadCancelled,
    'TRACK_ALREADY_EXISTS' => appCopy.errorAlreadySaved,
    'SESSION_TIMEOUT' => appCopy.sessionTimeout,
    _ => switch (status) {
      401 => appCopy.sessionInvalid,
      413 => appCopy.errorFileTooLarge,
      415 => appCopy.errorFileType,
      429 => appCopy.errorRateLimit,
      400 => appCopy.errorInvalidDetails,
      404 => appCopy.errorNotFound,
      409 => appCopy.errorBusy,
      _ => appCopy.errorConnection,
    },
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
    } on UploadCancelled {
      throw const ApiException(0, 'UPLOAD_CANCELLED');
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

  Future<String> upload(
    String kind,
    String name,
    Uint8List bytes, {
    UploadControl? control,
  }) async {
    final ext = name.split('.').last.toLowerCase();
    final type = kind == 'audio'
        ? MediaType('audio', 'mpeg')
        : MediaType('image', ext == 'jpg' ? 'jpeg' : ext);
    final result = await _send((jwt) async {
      control?.check();
      final request = http.AbortableMultipartRequest(
        'POST',
        _uri('/uploads/$kind'),
        abortTrigger: control?.aborted,
      )..headers['Authorization'] = 'Bearer $jwt';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: name,
          contentType: type,
        ),
      );
      return sendUpload(
        _client,
        request,
        control,
      ).timeout(const Duration(seconds: 90));
    });
    return result['id'] as String;
  }

  void close() => _client.close();
}
