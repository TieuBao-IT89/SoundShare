import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';

import '../../../core/config/clerk_config.dart';
import '../../../core/services/api_client.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/aurora_widgets.dart';
import '../../../core/widgets/authentication_header.dart';
import '../../../l10n/l10n.dart';
import '../domain/auth_session.dart';
import 'session_scope.dart';

@JS('soundshareAuth.initialize')
external JSPromise<JSString> _initialize(JSString key);
@JS('soundshareAuth.watch')
external void _watch(JSFunction listener);
@JS('soundshareAuth.unwatch')
external void _unwatch(JSFunction listener);
@JS('soundshareAuth.token')
external JSPromise<JSString> _token(JSBoolean refresh);
@JS('soundshareAuth.signOut')
external JSPromise<JSAny?> _signOut();
@JS('soundshareAuth.enter')
external void _enter(JSString mode);
@JS('soundshareAuth.manageAccount')
external JSBoolean _manageAccount();

bool openWebAccount() => _manageAccount().toDart;

class WebAuthGate extends StatefulWidget {
  const WebAuthGate({super.key, required this.child});
  final Widget child;
  @override
  State<WebAuthGate> createState() => _WebAuthGateState();
}

class _WebAuthGateState extends State<WebAuthGate> {
  AuthSession? session;
  bool loading = true;
  bool failed = false;
  int loadAttempt = 0;
  late final JSFunction listener = ((JSString value) {
    if (mounted) _receive(value.toDart);
  }).toJS;

  void _receive(String value) {
    final data = jsonDecode(value);
    if (!loading &&
        session?.subject == data?['id'] &&
        session?.name == data?['name'] &&
        session?.sessionId == data?['sessionId']) {
      return;
    }
    setState(() {
      session = data == null
          ? null
          : AuthSession.fromJson(Map<String, dynamic>.from(data));
      loading = false;
      failed = false;
    });
  }

  Future<void> _load() async {
    final attempt = ++loadAttempt;
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      _unwatch(listener);
      final value = await _initialize(ClerkConfig.publishableKey.toJS).toDart
          .timeout(const Duration(seconds: 25));
      if (!mounted || attempt != loadAttempt) return;
      _receive(value.toDart);
      _watch(listener);
    } catch (_) {
      if (mounted && attempt == loadAttempt) {
        setState(() {
          loading = false;
          failed = true;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    try {
      _unwatch(listener);
    } catch (_) {
      // The bridge asset can be unavailable when initialization failed.
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return AuthenticationScaffold(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AuthenticationHeader(compact: true),
            const SizedBox(height: 32),
            if (MediaQuery.disableAnimationsOf(context))
              const Icon(Icons.hourglass_top_rounded, color: AppColors.cyan)
            else
              CircularProgressIndicator(
                semanticsLabel: context.l10n.loadingSignIn,
              ),
            const SizedBox(height: 16),
            Text(context.l10n.loadingSignIn),
          ],
        ),
      );
    }
    if (failed) {
      return AuthenticationScaffold(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AuthenticationHeader(compact: true),
            const SizedBox(height: 32),
            Text(context.l10n.signInLoadFailed, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            GradientButton(
              onPressed: _load,
              label: context.l10n.tryAgain,
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      );
    }
    if (session == null) return const _SignInScreen();
    final user = session!;
    return SessionScope(
      key: ValueKey((user.subject, user.sessionId)),
      session: user,
      token: ({bool refresh = false}) async {
        try {
          return (await _token(refresh.toJS).toDart
                  .timeout(const Duration(seconds: 15)))
              .toDart;
        } on TimeoutException {
          throw const ApiException(0, 'SESSION_TIMEOUT');
        } catch (_) {
          throw const ApiException(401, 'UNAUTHORIZED');
        }
      },
      signOut: () async {
        await _signOut().toDart;
      },
      child: widget.child,
    );
  }
}

class _SignInScreen extends StatefulWidget {
  const _SignInScreen();
  @override
  State<_SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<_SignInScreen> {
  bool failed = false;
  void enter() {
    try {
      _enter('welcome'.toJS);
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) enter();
    });
  }

  @override
  Widget build(BuildContext context) => AuthenticationScaffold(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AuthenticationHeader(compact: true),
        const SizedBox(height: 28),
        Text(
          failed ? context.l10n.signInLoadFailed : context.l10n.loadingSignIn,
        ),
        const SizedBox(height: 20),
        TextButton(onPressed: enter, child: Text(context.l10n.signIn)),
      ],
    ),
  );
}
