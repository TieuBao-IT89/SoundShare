import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
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
  late final container = ProviderContainer(
    overrides: [
      authSessionProvider.overrideWithValue(widget.session),
      tokenSourceProvider.overrideWithValue(widget.token),
      signOutProvider.overrideWithValue(widget.signOut),
      apiClientProvider.overrideWith((ref) {
        final client =
            widget.createClient?.call(widget.token) ??
            ApiClient(token: widget.token);
        ref.onDispose(client.close);
        return client;
      }),
    ],
  );
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
