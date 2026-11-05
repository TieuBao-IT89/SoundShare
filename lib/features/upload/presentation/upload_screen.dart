import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/catalog_widgets.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key, this.filePicker});
  final FilePicker? filePicker;

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
  bool previewReady = false;

  @override
  void dispose() {
    titleController.dispose();
    artistController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _changed() => setState(() => previewReady = false);
  void _back() => context.canPop() ? context.pop() : context.go('/');

  Future<void> _chooseFile({bool image = false}) async {
    setState(() {
      busy = true;
      message = null;
      previewReady = false;
    });
    try {
      final result = await (widget.filePicker ?? FilePicker.platform).pickFiles(
        type: FileType.custom,
        allowedExtensions: image ? ['jpg', 'jpeg', 'png', 'webp'] : ['mp3'],
        withData: image,
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
              ? 'Choose a JPG, PNG or WebP image up to 5 MB.'
              : 'Choose a non-empty MP3 file up to 20 MB.',
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
      if (mounted) {
        setState(
          () =>
              message = 'The file could not be opened. Please choose it again.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
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
    final detailsValid = formKey.currentState!.validate();
    setState(() {
      message = file == null ? 'Choose an MP3 file first.' : null;
      previewReady = file != null && detailsValid;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Prepare a track'),
      leading: IconButton(
        tooltip: 'Back to browsing',
        onPressed: _back,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
              children: [
                const ScreenHeading(
                  eyebrow: 'MADE BY YOU',
                  title: 'Give your sound\na place to land.',
                  subtitle: 'Prepare a local preview. Nothing is published or sent yet.',
                ),
                const SizedBox(height: 28),
                const _Step(number: '01', title: 'Start with the sound'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: busy ? null : () => _chooseFile(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(22),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        file == null
                            ? Icons.graphic_eq_rounded
                            : Icons.audio_file_rounded,
                        size: 36,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        file?.name ?? 'Choose an MP3 file',
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        file == null
                            ? 'MP3 · Up to 20 MB'
                            : '${(file!.size / 1024 / 1024).toStringAsFixed(1)} MB · Change file',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (busy)
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Semantics(
                      liveRegion: true,
                      child: const Text('Opening file…'),
                    ),
                  ),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        message!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                const SizedBox(height: 28),
                const _Step(number: '02', title: 'Tell its story'),
                const SizedBox(height: 14),
                TextFormField(
                  controller: titleController,
                  maxLength: 120,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Song title',
                    hintText: 'Give your track a name',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Add a title for this track.'
                      : null,
                  onChanged: (_) => _changed(),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: artistController,
                  maxLength: 120,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Artist name',
                    hintText: 'Who made this track?',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Add the artist name.'
                      : null,
                  onChanged: (_) => _changed(),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: genre,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Genre'),
                  items:
                      const [
                            'Indie',
                            'Electronic',
                            'Hip-hop',
                            'Jazz',
                            'Pop',
                            'Other',
                          ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        genre = value;
                        previewReady = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'A little context for your listeners',
                  ),
                  onChanged: (_) => _changed(),
                ),
                const SizedBox(height: 28),
                const _Step(number: '03', title: 'Set the scene'),
                const SizedBox(height: 8),
                const Text(
                  'Optional artwork · JPG, PNG or WebP up to 5 MB.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: busy ? null : () => _chooseFile(image: true),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: Row(
                    children: [
                      if (artwork?.bytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            artwork!.bytes!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.image_not_supported_outlined),
                          ),
                        )
                      else
                        const Icon(Icons.add_photo_alternate_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          artwork?.name ?? 'Add album artwork',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                if (previewReady)
                  Semantics(
                    liveRegion: true,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your local preview is ready',
                            style: TextStyle(
                              color: AppColors.mint,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${titleController.text.trim()} · ${artistController.text.trim()}',
                          ),
                          Text(
                            genre,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Publishing is not available in this preview. Your file has not been uploaded.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                FilledButton(
                  onPressed: busy ? null : _preview,
                  child: const Text(
                    'Preview track details',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: _back, child: const Text('Cancel')),
              ],
            ),
          ),
        ),
      ),
    ),
  );
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
        style: const TextStyle(
          color: AppColors.violet,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}
