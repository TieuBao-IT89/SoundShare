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
@JS('soundshareAuth.open')
external void _open(JSString mode);
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

class _SignInScreen extends StatelessWidget {
  const _SignInScreen();
  @override
  Widget build(BuildContext context) => AuthenticationScaffold(
    child: AuroraReveal(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AuthenticationHeader(),
          const SizedBox(height: 36),
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.welcomeBack,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.signInSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 28),
                GradientButton(
                  onPressed: () => _open('sign-in'.toJS),
                  label: context.l10n.signIn,
                  icon: Icons.arrow_forward_rounded,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _open('sign-up'.toJS),
                  child: Text(context.l10n.signUp),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.cyan,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.signInPrivateNote,
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.secureAccountNote,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}
