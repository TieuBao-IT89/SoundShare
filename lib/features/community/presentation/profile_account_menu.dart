import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/api_client.dart';
import '../../../l10n/l10n.dart';
import '../../auth/presentation/account_management.dart';

enum _AccountAction { manage, signOut }

/// Session actions live apart from the public profile's music and identity.
class ProfileAccountMenu extends ConsumerStatefulWidget {
  const ProfileAccountMenu({super.key, this.onOpenAccount});
  final Future<void> Function()? onOpenAccount;
  @override
  ConsumerState<ProfileAccountMenu> createState() => _ProfileAccountMenuState();
}

class _ProfileAccountMenuState extends ConsumerState<ProfileAccountMenu> {
  bool busy = false;

  Future<void> select(_AccountAction action) async {
    setState(() => busy = true);
    try {
      if (action == _AccountAction.manage) {
        if (widget.onOpenAccount case final open?) {
          await open();
        } else {
          await openAccountManagement(context);
        }
      } else {
        await ref.read(signOutProvider)();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == _AccountAction.manage
                  ? context.l10n.accountOpenFailed
                  : context.l10n.signOutFailed,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.background.withValues(alpha: .85),
    borderRadius: BorderRadius.circular(24),
    child: PopupMenuButton<_AccountAction>(
      tooltip: context.l10n.accountSection,
      enabled: !busy,
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 304),
      icon: Icon(busy ? Icons.hourglass_top_rounded : Icons.more_horiz_rounded),
      onSelected: select,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _AccountAction.manage,
          child: Row(
            children: [
              const Icon(Icons.manage_accounts_outlined, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(context.l10n.manageAccount)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _AccountAction.signOut,
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: context.colors.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.signOut,
                  style: TextStyle(color: context.colors.error),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
