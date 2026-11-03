import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import '../../../app/theme/app_theme.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  PlatformFile? file;
  PlatformFile? artwork;
  String? message;
  bool previewReady = false;
  final titleController = TextEditingController();
  final artistController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    artistController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _chooseFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
    );
    if (result == null || result.files.isEmpty) return;
    final selected = result.files.first;
    setState(() {
      file = selected;
      previewReady = false;
      message = selected.size > 20 * 1024 * 1024
          ? 'Files must be smaller than 20 MB.'
          : null;
    });
    if (selected.size <= 20 * 1024 * 1024) {
      await _readMetadata(selected);
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
      // Some valid MP3 files do not include readable ID3 tags.
    }
  }

  Future<void> _chooseArtwork() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      artwork = result.files.first;
      previewReady = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Share a track'),
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const Text(
          'Share a track with the community.',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose an MP3 and add the details listeners need.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 22),
        InkWell(
          onTap: _chooseFile,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  file == null
                      ? Icons.graphic_eq_rounded
                      : Icons.audio_file_rounded,
                  size: 38,
                  color: AppColors.violet,
                ),
                const SizedBox(height: 12),
                Text(
                  file?.name ?? 'Choose an MP3 file',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  file == null
                      ? 'MP3 · Maximum file size 20 MB'
                      : '${(file!.size / 1024 / 1024).toStringAsFixed(1)} MB',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        if (message != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                message!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
        const SizedBox(height: 20),
        _Field(
          controller: titleController,
          label: 'Song title',
          hint: 'Give your track a name',
          onChanged: () => setState(() => previewReady = false),
        ),
        const SizedBox(height: 14),
        _Field(
          controller: artistController,
          label: 'Artist name',
          hint: 'Who made this track?',
          onChanged: () => setState(() => previewReady = false),
        ),
        const SizedBox(height: 14),
        _Field(
          controller: descriptionController,
          label: 'Description',
          hint: 'Tell listeners a little about it',
          maxLines: 3,
          onChanged: () => setState(() => previewReady = false),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: 'Indie',
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Genre'),
          items:
              const ['Indie', 'Electronic', 'Hip-hop', 'Jazz', 'Pop', 'Other']
                  .map(
                    (genre) =>
                        DropdownMenuItem(value: genre, child: Text(genre)),
                  )
                  .toList(),
          onChanged: (_) {},
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: _chooseArtwork,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(14),
            foregroundColor: AppColors.violet,
          ),
          child: artwork?.bytes == null
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined),
                    SizedBox(width: 8),
                    Text('Add album artwork'),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        artwork!.bytes!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(artwork!.name, overflow: TextOverflow.ellipsis),
                  ],
                ),
        ),
        const SizedBox(height: 20),
        if (previewReady)
          Semantics(
            liveRegion: true,
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.violet),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your track details are ready. Publishing is not connected in this preview.',
                      style: TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        FilledButton(
          onPressed: () {
            if (file == null ||
                file!.size > 20 * 1024 * 1024 ||
                titleController.text.trim().isEmpty ||
                artistController.text.trim().isEmpty) {
              setState(() {
                previewReady = false;
                message = switch ((
                  file,
                  titleController.text.trim(),
                  artistController.text.trim(),
                )) {
                  (null, _, _) => 'Choose an MP3 file first.',
                  (_, '', _) => 'Add a title for this track.',
                  (_, _, '') => 'Add the artist name.',
                  _ => 'Choose an MP3 file smaller than 20 MB.',
                };
              });
              return;
            }
            setState(() {
              message = null;
              previewReady = true;
            });
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.violet,
            padding: const EdgeInsets.all(16),
          ),
          child: const Text('Preview track details'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
        ),
      ],
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.onChanged,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final VoidCallback? onChanged;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: (_) => onChanged?.call(),
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    ],
  );
}
