import 'dart:io';
import 'dart:math' as math;

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/upload_control.dart';
import '../../../core/widgets/aurora_widgets.dart';
import '../../../l10n/l10n.dart';
import '../../home/domain/track_draft.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key, this.filePicker, this.onUpload});
  final FilePicker? filePicker;
  final Future<void> Function(TrackDraft)? onUpload;

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final artistController = TextEditingController();
  final descriptionController = TextEditingController();
  PlatformFile? file;
  PlatformFile? artwork;
  String? message;
  String genre = 'Indie';
  bool busy = false;
  bool choosing = false;
  bool previewReady = false;
  bool uploaded = false;
  bool isPublic = false;
  bool rights = false;
  UploadControl? transfer;
  double? progress;
  bool disposing = false;

  @override
  void dispose() {
    disposing = true;
    transfer?.cancel();
    titleController.dispose();
    artistController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _changed() => setState(() => previewReady = false);

  void _back() {
    if (!busy) context.canPop() ? context.pop() : context.go('/');
  }

  Future<void> _chooseFile({bool image = false}) async {
    setState(() {
      busy = true;
      choosing = true;
      message = null;
      previewReady = false;
      uploaded = false;
    });
    try {
      final result = await (widget.filePicker ?? FilePicker.platform).pickFiles(
        type: FileType.custom,
        allowedExtensions: image ? ['jpg', 'jpeg', 'png', 'webp'] : ['mp3'],
        withData: image || widget.onUpload != null,
      );
      if (!mounted || result == null || result.files.isEmpty) return;
      final selected = result.files.first;
      final extension = selected.extension?.toLowerCase();
      final validType = image
          ? ['jpg', 'jpeg', 'png', 'webp'].contains(extension)
          : extension == 'mp3';
      if (!validType ||
          selected.size <= 0 ||
          selected.size > (image ? 5 : 20) * 1024 * 1024) {
        setState(
          () => message = image
              ? context.l10n.artworkInvalid
              : context.l10n.mp3Invalid,
        );
        return;
      }
      setState(() {
        if (image) {
          artwork = selected;
        } else {
          file = selected;
        }
      });
      if (!image) await _readMetadata(selected);
    } catch (_) {
      if (mounted) setState(() => message = context.l10n.fileOpenError);
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          choosing = false;
        });
      }
    }
  }

  Future<void> _readMetadata(PlatformFile selected) async {
    if (kIsWeb || selected.path == null) return;
    try {
      final metadata = await Future(
        () => readMetadata(File(selected.path!), getImage: false),
      );
      if (!mounted) return;
      if (titleController.text.trim().isEmpty && metadata.title != null) {
        titleController.text = metadata.title!;
      }
      if (artistController.text.trim().isEmpty && metadata.artist != null) {
        artistController.text = metadata.artist!;
      }
    } catch (_) {
      // Valid MP3 files do not always have readable ID3 tags.
    }
  }

  void _preview() {
    FocusScope.of(context).unfocus();
    final detailsValid = formKey.currentState!.validate();
    setState(() {
      message = file == null ? context.l10n.mp3Required : null;
      previewReady = file != null && detailsValid;
    });
  }

  Future<void> _upload() async {
    if (isPublic && !rights) {
      setState(() => message = context.l10n.v3RightsRequired);
      return;
    }
    _preview();
    if (!previewReady) return;
    progress = null;
    transfer = UploadControl(
      onProgress: (loaded, total) {
        if (mounted && !disposing) {
          setState(
            () => progress = total > 0 ? (loaded / total).clamp(0, 1) : null,
          );
        }
      },
      onPhase: (_) {
        if (mounted && !disposing) setState(() {});
      },
    );
    setState(() {
      previewReady = false;
      busy = true;
      uploaded = false;
      message = null;
    });
    try {
      if (file!.bytes == null || (artwork != null && artwork!.bytes == null)) {
        throw const ApiException(400, 'FILE_REQUIRED');
      }
      await widget.onUpload!(
        TrackDraft(
          title: titleController.text.trim(),
          artist: artistController.text.trim(),
          genre: genre,
          description: descriptionController.text.trim(),
          audioName: file!.name,
          audioBytes: file!.bytes!,
          artworkName: artwork?.name,
          artworkBytes: artwork?.bytes,
          visibility: isPublic ? 'public' : 'private',
          rightsConfirmed: rights,
          transfer: transfer,
        ),
      );
      transfer?.check();
      if (mounted) setState(() => uploaded = true);
    } catch (error) {
      if (mounted) {
        setState(
          () => message = error is UploadCancelled
              ? context.l10n.v3UploadCancelled
              : error is ApiException
              ? error.message
              : context.l10n.uploadFailed,
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.uploadMusic),
          leading: IconButton(
            tooltip: t.back,
            onPressed: busy ? null : _back,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: AuroraBackground(
          child: SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide =
                        constraints.maxWidth >= 900 &&
                        MediaQuery.textScalerOf(context).scale(14) <= 22;
                    return Form(
                      key: formKey,
                      child: ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          wide ? 40 : 20,
                          20,
                          wide ? 40 : 20,
                          32,
                        ),
                        children: [
                          Text(
                            t.uploadTitle,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.onUpload == null
                                ? t.uploadDemoSubtitle
                                : t.uploadSubtitle,
                            style: TextStyle(
                              color: context.colors.secondaryText,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 28),
                          if (wide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      _audioSection(),
                                      const SizedBox(height: 20),
                                      _artworkSection(),
                                      if (widget.onUpload != null) ...[
                                        const SizedBox(height: 20),
                                        _privacyNote(),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(flex: 6, child: _detailsSection()),
                              ],
                            )
                          else ...[
                            _audioSection(),
                            const SizedBox(height: 24),
                            _detailsSection(),
                            const SizedBox(height: 24),
                            _artworkSection(),
                            if (widget.onUpload != null) ...[
                              const SizedBox(height: 20),
                              _privacyNote(),
                            ],
                          ],
                          const SizedBox(height: 24),
                          if (busy) ...[
                            Semantics(
                              liveRegion: true,
                              child: GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!MediaQuery.disableAnimationsOf(
                                      context,
                                    )) ...[
                                      LinearProgressIndicator(
                                        value:
                                            transfer?.phase ==
                                                UploadPhase.confirming
                                            ? null
                                            : progress,
                                        minHeight: 3,
                                      ),
                                      const SizedBox(height: 14),
                                    ],
                                    Text(
                                      choosing
                                          ? t.openingFile
                                          : transfer?.phase ==
                                                UploadPhase.confirming
                                          ? t.v3Confirming
                                          : progress != null
                                          ? '${t.v3Sending}: ${(progress! * 100).round()}%'
                                          : t.uploadBusy,
                                      style: TextStyle(
                                        color: context.colors.secondaryText,
                                        height: 1.5,
                                      ),
                                    ),
                                    if (!choosing &&
                                        transfer?.canCancel == true)
                                      TextButton.icon(
                                        onPressed: transfer!.cancel,
                                        icon: const Icon(Icons.close_rounded),
                                        label: Text(t.v3Cancel),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (message != null) ...[
                            Semantics(
                              liveRegion: true,
                              child: GlassCard(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: context.colors.error,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        message!,
                                        style: TextStyle(
                                          color: context.colors.error,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (uploaded) ...[
                            Semantics(
                              liveRegion: true,
                              child: GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: context.colors.success,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      t.uploadSaved,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: context.colors.success,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${titleController.text.trim()} · ${artistController.text.trim()}',
                                      style: TextStyle(
                                        color: context.colors.secondaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextButton.icon(
                                      onPressed: () => context.go('/library'),
                                      icon: const Icon(
                                        Icons.arrow_forward_rounded,
                                      ),
                                      label: Text(t.openLibrary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (previewReady) ...[
                            Semantics(
                              liveRegion: true,
                              child: GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.previewReady,
                                      style: TextStyle(
                                        color: context.colors.success,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${titleController.text.trim()} · ${artistController.text.trim()}',
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      genre == 'Other' ? t.otherGenre : genre,
                                      style: TextStyle(
                                        color: context.colors.secondaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      t.previewNotice,
                                      style: TextStyle(
                                        color: context.colors.secondaryText,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          GradientButton(
                            label: widget.onUpload == null
                                ? t.previewButton
                                : t.uploadButton,
                            icon: widget.onUpload == null
                                ? Icons.headphones_rounded
                                : Icons.cloud_upload_outlined,
                            busy: busy,
                            onPressed: busy || uploaded
                                ? null
                                : (widget.onUpload == null
                                      ? _preview
                                      : _upload),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: busy ? null : _back,
                            child: Text(t.cancel),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _audioSection() {
    final t = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Step(number: '01', title: t.uploadAudioStep),
        const SizedBox(height: 14),
        CustomPaint(
          foregroundPainter: _DashedBorder(context.colors.brandGradient),
          child: Material(
            color: context.colors.surface.withValues(alpha: .7),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: busy ? null : () => _chooseFile(),
              borderRadius: BorderRadius.circular(24),
              child: Semantics(
                button: true,
                enabled: !busy,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 30,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: context.colors.featuredGradient,
                          border: Border.all(
                            color: context.colors.mystic.withValues(alpha: .35),
                          ),
                        ),
                        child: Icon(
                          file == null
                              ? Icons.cloud_upload_outlined
                              : Icons.audio_file_rounded,
                          color: context.colors.mystic,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        file?.name ?? t.chooseMp3,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        file == null
                            ? t.mp3Limit
                            : '${(file!.size / 1024 / 1024).toStringAsFixed(1)} MB · ${t.changeFile}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.colors.secondaryText,
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
      ],
    );
  }

  Widget _detailsSection() {
    final t = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Step(number: '02', title: t.uploadDetailsStep),
          const SizedBox(height: 22),
          if (widget.onUpload != null) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.v3Visibility),
              subtitle: Text(isPublic ? t.v3Public : t.v3Private),
              value: isPublic,
              onChanged: busy || uploaded
                  ? null
                  : (value) => setState(() => isPublic = value),
            ),
            Text(t.v3PublicHint),
            if (isPublic)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.v3Rights),
                value: rights,
                onChanged: busy || uploaded
                    ? null
                    : (value) => setState(() => rights = value ?? false),
              ),
            const SizedBox(height: 24),
          ],
          TextFormField(
            enabled: !busy && !uploaded,
            controller: titleController,
            maxLength: 120,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: t.songTitle,
              hintText: t.titleHint,
              prefixIcon: const Icon(Icons.music_note_outlined),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? t.titleRequired : null,
            onChanged: (_) => _changed(),
          ),
          const SizedBox(height: 14),
          TextFormField(
            enabled: !busy && !uploaded,
            controller: artistController,
            maxLength: 120,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: t.artistName,
              hintText: t.artistHint,
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? t.artistRequired : null,
            onChanged: (_) => _changed(),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: genre,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: t.genre,
              prefixIcon: const Icon(Icons.album_outlined),
            ),
            items:
                const ['Indie', 'Electronic', 'Hip-hop', 'Jazz', 'Pop', 'Other']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value == 'Other' ? t.otherGenre : value),
                      ),
                    )
                    .toList(),
            onChanged: busy || uploaded
                ? null
                : (value) {
                    if (value != null) {
                      setState(() {
                        genre = value;
                        previewReady = false;
                      });
                    }
                  },
          ),
          const SizedBox(height: 22),
          TextFormField(
            enabled: !busy && !uploaded,
            controller: descriptionController,
            maxLines: 3,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: t.descriptionOptional,
              hintText: t.descriptionHint,
              alignLabelWithHint: true,
            ),
            onChanged: (_) => _changed(),
          ),
        ],
      ),
    );
  }

  Widget _artworkSection() {
    final t = context.l10n;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Step(number: '03', title: t.uploadArtworkStep),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: busy ? null : () => _chooseFile(image: true),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14)),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: artwork?.bytes != null
                      ? Image.memory(
                          artwork!.bytes!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.square(
                            dimension: 64,
                            child: Icon(Icons.image_not_supported_outlined),
                          ),
                        )
                      : const SizedBox.square(
                          dimension: 64,
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 30,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    artwork?.name ?? t.addArtwork,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.artworkHint,
            style: TextStyle(
              color: context.colors.secondaryText,
              fontSize: 12,
              height: 1.6,
            ),
          ),
          Text(
            t.artworkOptional,
            style: TextStyle(
              color: context.colors.secondaryText,
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _privacyNote() {
    final t = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          color: context.colors.accentText,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPublic ? t.v3Public : t.uploadPrivateTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                isPublic ? t.v3PublicHint : t.uploadPrivateMessage,
                style: TextStyle(
                  color: context.colors.secondaryText,
                  height: 1.5,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title});
  final String number;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        number,
        style: TextStyle(
          color: context.colors.accentText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.8,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder(this.gradient);
  final Gradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(24)),
      );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final metric in path.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += 13) {
        canvas.drawPath(
          metric.extractPath(start, math.min(start + 7, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorder oldDelegate) =>
      oldDelegate.gradient != gradient;
}
