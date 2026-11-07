import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundshare/core/config/api_config.dart';

void main() {
  test('Web uses its HTTPS origin even when the browser reports Android', () {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      debugDefaultTargetPlatformOverride = platform;
      expect(
        ApiConfig.baseUrl,
        kIsWeb
            ? Uri.base.origin
            : platform == TargetPlatform.android
            ? 'http://10.0.2.2:3000'
            : 'http://localhost:3000',
      );
      expect(ApiConfig.currentUserUri.path, '/api/v1/auth/me');
    }
  });
}
