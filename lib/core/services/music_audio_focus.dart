import 'dart:async';

import 'package:audio_session/audio_session.dart';

/// Conservative music policy: pause on loss/duck/noisy, resume only on an
/// explicit UI/media command. just_audio's automatic interruptions are disabled
/// on Android so there is no second policy which can auto-resume over the user.
class MusicAudioFocus {
  MusicAudioFocus({
    required this.pause,
    required Future<AudioSession> session,
  }) {
    ready = _configure(session);
  }
  final Future<void> Function() pause;
  late final Future<void> ready;
  final _subscriptions = <StreamSubscription<dynamic>>[];
  bool _disposed = false;
  AudioSession? _session;

  Future<void> _configure(Future<AudioSession> future) async {
    final session = await future;
    if (_disposed) return;
    _session = session;
    await session.configure(const AudioSessionConfiguration.music());
    if (_disposed) return;
    _subscriptions.add(
      session.interruptionEventStream.listen((event) {
        if (event.begin && !_disposed) unawaited(pause());
      }),
    );
    _subscriptions.add(
      session.becomingNoisyEventStream.listen((_) {
        if (!_disposed) unawaited(pause());
      }),
    );
  }

  Future<void> deactivate() async {
    await _session?.setActive(false);
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    await deactivate();
  }
}
