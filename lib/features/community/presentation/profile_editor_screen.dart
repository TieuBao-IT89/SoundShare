import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/api_client.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/artwork.dart';
import '../../../l10n/l10n.dart';
import '../application/community_providers.dart';
import 'community_widgets.dart';

class ProfileEditorScreen extends ConsumerStatefulWidget {
  const ProfileEditorScreen({super.key});
  @override
  ConsumerState<ProfileEditorScreen> createState() =>
      _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends ConsumerState<ProfileEditorScreen> {
  final form = GlobalKey<FormState>();
  final username = TextEditingController(),
      name = TextEditingController(),
      bio = TextEditingController();
  bool loading = true, busy = false;
  String? message, avatarId, coverId;
  String avatar = '', cover = '';
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final profile = await ref.read(communityRepositoryProvider).me();
      if (!mounted) return;
      username.text = profile.username ?? '';
      name.text = profile.displayName.isEmpty
          ? ref.read(authSessionProvider)?.name ?? ''
          : profile.displayName;
      bio.text = profile.bio;
      setState(() {
        avatar = profile.avatar;
        cover = profile.cover;
        loading = false;
        message = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          loading = false;
          message = context.l10n.v3Unavailable;
        });
      }
    }
  }

  @override
  void dispose() {
    username.dispose();
    name.dispose();
    bio.dispose();
    super.dispose();
  }

  Future<void> pick(bool isCover) async {
    setState(() => busy = true);
    try {
      final files = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
      if (files == null || !mounted) return;
      final file = files.files.single;
      if (file.bytes == null || file.size <= 0 || file.size > 5 * 1024 * 1024) {
        throw const ApiException(413, 'FILE_TOO_LARGE');
      }
      final uploaded = await ref
          .read(communityRepositoryProvider)
          .uploadArtwork(file.name, file.bytes!);
      if (mounted) {
        setState(() {
          if (isCover) {
            coverId = uploaded.id;
            cover = uploaded.url;
          } else {
            avatarId = uploaded.id;
            avatar = uploaded.url;
          }
        });
      }
    } catch (error) {
      if (mounted) communityError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await ref.read(communityRepositoryProvider).updateProfile({
        'username': username.text.trim(),
        'displayName': name.text.trim(),
        'bio': bio.text.trim(),
        if (avatarId != null) 'avatarAssetId': avatarId,
        if (coverId != null) 'coverAssetId': coverId,
      });
      ref.invalidate(myPublicProfileProvider);
      ref.invalidate(publicProfileProvider);
      if (mounted) context.go('/profile');
    } catch (error) {
      if (mounted) communityError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AppScaffold(
      child: ListView(
        padding: const EdgeInsets.all(24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Text(
            t.v3EditProfile,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(t.v3ProfileIntro),
          const SizedBox(height: 24),
          if (loading)
            const LinearProgressIndicator()
          else
            Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (message != null) ...[
                    Text(message!),
                    TextButton(onPressed: load, child: Text(t.tryAgain)),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Artwork(url: avatar, size: 80, radius: 44),
                  ),
                  if (cover.isNotEmpty)
                    LayoutBuilder(
                      builder: (context, bounds) => Artwork(
                        url: cover,
                        size: bounds.maxWidth,
                        height: 120,
                        radius: 8,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    children: [
                      OutlinedButton(
                        onPressed: busy ? null : () => pick(false),
                        child: Text(
                          avatarId == null ? t.v3Avatar : t.v3ImageReady,
                        ),
                      ),
                      OutlinedButton(
                        onPressed: busy ? null : () => pick(true),
                        child: Text(
                          coverId == null ? t.v3Cover : t.v3ImageReady,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: username,
                    enabled: !busy,
                    maxLength: 24,
                    decoration: InputDecoration(
                      labelText: t.v3Username,
                      prefixText: '@',
                    ),
                    validator: (value) {
                      final v = (value ?? '').trim().toLowerCase();
                      return RegExp(r'^[a-z0-9_][a-z0-9._]*[a-z0-9_]$')
                                  .hasMatch(v) &&
                              v.length >= 3 &&
                              !{
                                'admin',
                                'support',
                                'soundshare',
                                'system',
                                'official',
                                'search',
                              }.contains(v)
                          ? null
                          : t.v3InvalidProfile;
                    },
                  ),
                  Text(t.v3UsernamePolicy),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: name,
                    enabled: !busy,
                    maxLength: 100,
                    decoration: InputDecoration(labelText: t.v3DisplayName),
                    validator: (value) => value?.trim().isNotEmpty == true
                        ? null
                        : t.v3InvalidProfile,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: bio,
                    enabled: !busy,
                    maxLength: 500,
                    maxLines: 4,
                    decoration: InputDecoration(labelText: t.v3Bio),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: busy ? null : save,
                    child: Text(busy ? t.uploadBusy : t.v3Save),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
