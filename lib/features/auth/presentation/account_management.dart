import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/aurora_widgets.dart';
import '../../../l10n/l10n.dart';
import 'web_auth_stub.dart' if (dart.library.js_interop) 'web_auth.dart';

/// Opens the provider's account UI. Account edits remain owned by Clerk.
class AccountManagementButton extends StatefulWidget {
  const AccountManagementButton({super.key, this.onOpen});
  final Future<void> Function()? onOpen;

  @override
  State<AccountManagementButton> createState() =>
      _AccountManagementButtonState();
}

class _AccountManagementButtonState extends State<AccountManagementButton> {
  bool busy = false;

  Future<void> _open() async {
    setState(() => busy = true);
    try {
      if (widget.onOpen case final callback?) {
        await callback();
      } else if (kIsWeb) {
        if (!openWebAccount()) throw StateError('Account UI unavailable');
      } else {
        final auth = ClerkAuth.of(context, listen: false);
        final title = context.l10n.manageAccount;
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => ClerkAuth(
              authState: auth,
              child: Scaffold(
                appBar: AppBar(title: Text(title)),
                body: AuroraBackground(
                  child: SafeArea(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: const SingleChildScrollView(
                          padding: EdgeInsets.all(24),
                          child: ClerkErrorListener(
                            child: ClerkUserButton(additionalActions: []),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.accountOpenFailed)));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: busy ? null : _open,
    icon: const Icon(Icons.manage_accounts_outlined),
    label: Text(context.l10n.manageAccount),
  );
}
