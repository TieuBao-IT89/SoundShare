import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/authentication_header.dart';
import '../../../l10n/l10n.dart';

/// The beta SDK owns its form mode and verification steps. Do not imitate them.
class NativeAuthScreen extends StatefulWidget {
  const NativeAuthScreen({super.key});
  @override
  State<NativeAuthScreen> createState() => _NativeAuthScreenState();
}

class _NativeAuthScreenState extends State<NativeAuthScreen> {
  bool entering = false;
  @override
  Widget build(BuildContext context) => AuthenticationScaffold(
    welcome: !entering,
    child: entering
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AuthenticationHeader(compact: true),
              const SizedBox(height: 24),
              const ClerkErrorListener(child: ClerkAuthentication()),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: () => setState(() => entering = true),
                child: Text(context.l10n.authContinue),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.secureAccountNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
  );
}
