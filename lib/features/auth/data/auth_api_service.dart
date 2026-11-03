import 'dart:convert';

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';

class BackendCurrentUser {
  const BackendCurrentUser({required this.clerkUserId});

  final String clerkUserId;

  factory BackendCurrentUser.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map<String, dynamic> || data['clerkUserId'] is! String) {
      throw const FormatException('Invalid current user response');
    }

    return BackendCurrentUser(clerkUserId: data['clerkUserId'] as String);
  }
}

class BackendAuthException implements Exception {
  const BackendAuthException(this.statusCode);

  final int statusCode;
}

class AuthApiService {
  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<BackendCurrentUser> getCurrentUser(ClerkAuthState auth) async {
    final sessionToken = await auth.sessionToken();
    final response = await _client
        .get(
          ApiConfig.currentUserUri,
          headers: {
            'Authorization': 'Bearer ${sessionToken.jwt}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw BackendAuthException(response.statusCode);
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Invalid current user response');
    }

    return BackendCurrentUser.fromJson(body);
  }

  void close() => _client.close();
}
