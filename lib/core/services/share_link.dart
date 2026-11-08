import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/api_config.dart';
import '../../l10n/l10n.dart';
import 'share_transport_stub.dart'
    if (dart.library.js_interop) 'share_transport_web.dart';

Future<void> shareLink(BuildContext context, String path) async {
  const publicUrl = String.fromEnvironment('PUBLIC_APP_URL');
  final origin = publicUrl.isNotEmpty
      ? publicUrl
      : kIsWeb
      ? Uri.base.origin
      : ApiConfig.baseUrl;
  final uri = Uri.parse(origin).replace(path: '/', fragment: path, query: null);
  try {
    if (kIsWeb) {
      if (await shareWeb(uri.toString())) return;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      await const MethodChannel('soundshare/share')
          .invokeMethod<void>('share', uri.toString());
      return;
    }
  } catch (_) {
    /* Platform unavailable: copy the same public link. */
  }
  await Clipboard.setData(ClipboardData(text: uri.toString()));
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.v3Copied)));
  }
}
