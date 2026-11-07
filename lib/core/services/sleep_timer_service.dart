import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_service.dart';

final sleepTimerProvider =
    StateNotifierProvider<SleepTimerController, DateTime?>((ref) {
      return SleepTimerController(ref);
    });

/// A single cancellable deadline; switching songs does not restart the timer.
/// The account container owns it, just like the existing AudioPlayer.
class SleepTimerController extends StateNotifier<DateTime?> {
  SleepTimerController(this.ref) : super(null);
  final Ref ref;
  Timer? _timer;

  void start(Duration duration) {
    cancel();
    if (duration <= Duration.zero) return;
    state = DateTime.now().add(duration);
    _timer = Timer(duration, () async {
      _timer = null;
      state = null;
      try {
        await ref.read(playbackActionsProvider).pause();
      } catch (_) {
        if (mounted) {
          ref.read(playbackErrorProvider.notifier).state =
              'Audio could not be paused. Please try again.';
        }
      }
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    state = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
