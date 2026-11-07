import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/audio_service.dart';
import '../domain/auth_session.dart';
import 'session_gate.dart';

// Each identity owns a complete container. No catalog, likes or player survive logout.
class SessionScope extends StatefulWidget {
  const SessionScope({
    super.key,
    required this.session,
    required this.token,
    required this.signOut,
    required this.child,
    this.createClient,
  });
  final AuthSession session;
  final TokenSource token;
  final Future<void> Function() signOut;
  final Widget child;
  final ApiClient Function(TokenSource)? createClient;
  @override
  State<SessionScope> createState() => _SessionScopeState();
}

class _SessionScopeState extends State<SessionScope> {
  late final tokenOverride = tokenSourceProvider.overrideWithValue(
    ({bool refresh = false}) => widget.token(refresh: refresh),
  );
  late final signOutOverride = signOutProvider.overrideWithValue(() async {
    if (container.exists(playbackActionsProvider)) {
      await container.read(playbackActionsProvider).stop();
    }
    await widget.signOut();
  });
  late final clientOverride = apiClientProvider.overrideWith((ref) {
    final client =
        widget.createClient?.call(_currentToken) ??
        ApiClient(token: _currentToken);
    ref.onDispose(client.close);
    return client;
  });
  Future<String> _currentToken({bool refresh = false}) =>
      widget.token(refresh: refresh);
  late final ProviderContainer container = ProviderContainer(
    overrides: [
      authSessionProvider.overrideWithValue(widget.session),
      tokenOverride,
      signOutOverride,
      clientOverride,
    ],
  );

  @override
  void didUpdateWidget(covariant SessionScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.subject == widget.session.subject &&
        oldWidget.session.sessionId == widget.session.sessionId &&
        oldWidget.session.name != widget.session.name) {
      // Clerk profile edits can change a display name in an existing session.
      // Refresh identity copy without recreating its player/catalog container.
      container.updateOverrides([
        authSessionProvider.overrideWithValue(widget.session),
        tokenOverride,
        signOutOverride,
        clientOverride,
      ]);
    }
  }

  @override
  void dispose() {
    container.dispose();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UncontrolledProviderScope(
    container: container,
    child: SessionGate(child: widget.child),
  );
}
