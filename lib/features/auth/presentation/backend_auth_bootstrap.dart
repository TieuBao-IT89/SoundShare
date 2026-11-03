import 'dart:async';

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/backend_auth_provider.dart';
import '../data/auth_api_service.dart';

class BackendAuthBootstrap extends ConsumerStatefulWidget {
  const BackendAuthBootstrap({
    super.key,
    required this.authState,
    required this.child,
  });

  final ClerkAuthState authState;
  final Widget child;

  @override
  ConsumerState<BackendAuthBootstrap> createState() =>
      _BackendAuthBootstrapState();
}

class _BackendAuthBootstrapState extends ConsumerState<BackendAuthBootstrap> {
  final _authApiService = AuthApiService();

  @override
  void initState() {
    super.initState();
    unawaited(_verifyBackendSession());
  }

  Future<void> _verifyBackendSession() async {
    ref.read(backendCurrentUserProvider.notifier).state =
        const AsyncValue.loading();

    try {
      final user = await _authApiService.getCurrentUser(widget.authState);
      if (!mounted) return;
      ref.read(backendCurrentUserProvider.notifier).state = AsyncValue.data(
        user,
      );
    } catch (error, stackTrace) {
      if (!mounted) return;
      ref.read(backendCurrentUserProvider.notifier).state = AsyncValue.error(
        error,
        stackTrace,
      );
    }
  }

  @override
  void dispose() {
    _authApiService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
