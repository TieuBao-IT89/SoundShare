import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';

import '../../../core/config/clerk_config.dart';
import '../../../core/services/api_client.dart';
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(semanticsLabel: 'Loading sign-in'),
        ),
      );
    }
    if (failed) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sign-in could not be loaded. Check your connection and retry.',
                ),
                TextButton(onPressed: _load, child: const Text('Try again')),
              ],
            ),
          ),
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
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.graphic_eq_rounded,
                    color: Color(0xFF9B7BFF),
                    size: 64,
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'SOUNDSHARE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      letterSpacing: 2,
                      color: Color(0xFFB8F28B),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Your sound.\nYour space.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Đăng nhập để tải MP3, nghe nhạc và lưu thư viện riêng của bạn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () => _open('sign-in'.toJS),
                    child: const Text('Đăng nhập'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _open('sign-up'.toJS),
                    child: const Text('Tạo tài khoản'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'File của bạn được giữ riêng tư. Xác minh email và khôi phục mật khẩu do Clerk xử lý.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF92919E),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
