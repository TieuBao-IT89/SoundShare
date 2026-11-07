import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'media_session.dart';
import 'notification_artwork_stub.dart'
    if (dart.library.io) 'notification_artwork_native.dart';

final nativeAudioHandlerProvider = Provider<SoundShareAudioHandler?>(
  (ref) => NativeAudioRuntime.handler,
);

abstract final class NativeAudioRuntime {
  static SoundShareAudioHandler? handler;
  static Future<void>? _initializing;
  static Future<void> initialize() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return Future.value();
    }
    return _initializing ??= _initialize();
  }

  static Future<void> _initialize() async {
    handler = await AudioService.init<SoundShareAudioHandler>(
      builder: () =>
          SoundShareAudioHandler(artworkFactory: createNotificationArtwork),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.musicapp.playback',
        androidNotificationChannelName: 'SoundShare — Phát nhạc',
        androidNotificationIcon: 'drawable/ic_stat_soundshare',
        androidShowNotificationBadge: false,
        androidNotificationClickStartsActivity: true,
        // Remove the notification at stop/logout and disable cold resumption
        // of a previous account. Live MediaSession headset commands still work.
        androidResumeOnClick: false,
        // Keep foreground on a user pause, allowing headset resume under Android
        // 12+ restrictions. Explicit stop/logout always publish idle and clear it.
        androidStopForegroundOnPause: false,
        artDownscaleWidth: 512,
        artDownscaleHeight: 512,
        preloadArtwork: false,
      ),
    );
  }
}
