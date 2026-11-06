import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/config/app_mode.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/aurora_widgets.dart';
import '../../../core/widgets/catalog_widgets.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../l10n/l10n.dart';
import '../../auth/presentation/account_management.dart';
import '../../home/application/catalog_provider.dart';
import '../../community/presentation/public_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final demo = ref.watch(demoModeProvider);
    if (!demo) return const PublicProfileScreen();
    final session = demo ? null : ref.watch(authSessionProvider);
    final name = demo ? t.guestName : (session?.name ?? t.accountName);
    final catalog = ref.watch(catalogProvider);
    final count = catalog.asData?.value.length;
    final likes = count == null
        ? null
        : ref.watch(likedSongIndicesProvider).length;

    return AppScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final roomy = constraints.maxWidth >= 680;
          final identity = GlassCard(
            gradient: AppGradients.soft,
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.primary,
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.surface,
                    child: session == null || name.trim().isEmpty
                        ? const Icon(
                            Icons.person_outline_rounded,
                            size: 38,
                            color: AppColors.text,
                          )
                        : Text(
                            String.fromCharCode(name.trim().runes.first)
                                .toUpperCase(),
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  name,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  demo ? t.profileDemoNote : t.profilePrivateNote,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.secondaryText, height: 1.6),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 24,
                  runSpacing: 18,
                  children: [
                    _MusicCount(
                      count: count,
                      label: demo ? t.sampleCatalog : t.yourUploads,
                    ),
                    _MusicCount(count: likes, label: t.likedTracks),
                  ],
                ),
                if (demo) ...[
                  const SizedBox(height: 24),
                  Text(
                    t.demoBadge,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppColors.cyan, letterSpacing: 1.2),
                  ),
                ],
              ],
            ),
          );
          final actions = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeading(t.yourMusic),
              const SizedBox(height: 14),
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    _ProfileAction(
                      icon: Icons.library_music_outlined,
                      title: t.libraryTitle,
                      subtitle: t.profileLibraryHint,
                      onTap: () => context.go('/library'),
                    ),
                    const Divider(height: 1),
                    _ProfileAction(
                      icon: Icons.cloud_upload_outlined,
                      title: t.uploadMusic,
                      subtitle: t.profileUploadHint,
                      onTap: () => context.push('/upload'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.cyan,
                      size: 24,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t.profilePrivacyTitle,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      demo ? t.demoLibraryNote : t.profilePrivacyMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              if (!demo) ...[
                const SizedBox(height: 28),
                SectionHeading(t.accountSection),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.secondaryText,
                  ),
                  title: Text(t.accountProvider),
                  subtitle: Text(
                    t.accountProviderNote,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (session != null) ...[
                  const AccountManagementButton(),
                  const SizedBox(height: 12),
                ],
                const _SignOutButton(),
              ],
            ],
          );

          return ListView(
            padding: EdgeInsets.fromLTRB(
              roomy ? 36 : 20,
              28,
              roomy ? 36 : 20,
              32,
            ),
            children: [
              ScreenHeading(
                eyebrow: t.profileEyebrow,
                title: t.profileTitle,
                subtitle: t.profileSubtitle,
              ),
              const SizedBox(height: 28),
              if (constraints.maxWidth >= 900 &&
                  MediaQuery.textScalerOf(context).scale(14) <= 22)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: AuroraReveal(child: identity)),
                    const SizedBox(width: 28),
                    Expanded(
                      flex: 5,
                      child: AuroraReveal(delay: 70, child: actions),
                    ),
                  ],
                )
              else ...[
                AuroraReveal(child: identity),
                const SizedBox(height: 28),
                actions,
              ],
              const SizedBox(height: 36),
              Row(
                children: [
                  const AuroraLogo(size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.brandTagline,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.secondaryText),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MusicCount extends StatelessWidget {
  const _MusicCount({required this.count, required this.label});
  final int? count;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        count?.toString() ?? '—',
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: AppColors.secondaryText),
      ),
    ],
  );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    leading: Icon(icon, color: AppColors.mystic),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        subtitle,
        style: const TextStyle(color: AppColors.secondaryText, height: 1.5),
      ),
    ),
    trailing: const Icon(
      Icons.arrow_forward_rounded,
      size: 20,
      color: AppColors.secondaryText,
    ),
    onTap: onTap,
  );
}

class _SignOutButton extends ConsumerStatefulWidget {
  const _SignOutButton();

  @override
  ConsumerState<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends ConsumerState<_SignOutButton> {
  bool busy = false;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: busy
        ? null
        : () async {
            setState(() => busy = true);
            try {
              try {
                await ref.read(audioPlayerProvider).pause();
              } catch (_) {
                // The session still needs to close if playback cannot pause.
              }
              await ref.read(signOutProvider)();
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.signOutFailed)),
                );
              }
            } finally {
              if (mounted) setState(() => busy = false);
            }
          },
    icon: const Icon(Icons.logout_rounded, size: 20),
    label: Text(busy ? context.l10n.signingOut : context.l10n.signOut),
    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
  );
}
