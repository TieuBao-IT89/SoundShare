import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// UI-only position subscription. Android's MediaSession extrapolates from
/// playback events; hidden Flutter screens do not need position timer ticks.
class VisiblePlaybackPosition extends StatefulWidget {
  const VisiblePlaybackPosition({
    super.key,
    required this.player,
    required this.builder,
  });
  final AudioPlayer player;
  final Widget Function(BuildContext, Duration) builder;
  @override
  State<VisiblePlaybackPosition> createState() =>
      _VisiblePlaybackPositionState();
}

class _VisiblePlaybackPositionState extends State<VisiblePlaybackPosition>
    with WidgetsBindingObserver {
  StreamSubscription<Duration>? _subscription;
  late Duration _position;
  bool _foreground = true;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _position = widget.player.position;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    _sync();
  }

  @override
  void didUpdateWidget(covariant VisiblePlaybackPosition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player != widget.player) {
      _cancel();
      _sync();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
    if (_foreground && mounted) setState(() {});
  }

  void _cancel() {
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  void _sync() {
    if (!_visible || !_foreground) {
      _cancel();
      return;
    }
    if (_subscription != null) return;
    _position = widget.player.position;
    _subscription = widget.player.positionStream.listen(
      (position) {
        if (mounted && _visible && _foreground && position != _position) {
          setState(() => _position = position);
        }
      },
      onError: (Object _) {
        /* Playback errors are handled by the engine owner. */
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _position);
}
