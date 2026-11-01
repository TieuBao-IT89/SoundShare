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
  bool uploading = false;
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
    setState(() => artwork = result.files.first);
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
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
      children: [
        const Text(
          'Put your sound out there.',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Share a song with listeners everywhere.',
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
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.graphic_eq_rounded,
                  size: 38,
                  color: AppColors.violet,
                ),
                const SizedBox(height: 9),
                Text(
                  file?.name ?? 'Choose an MP3 file',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  file == null
                      ? 'MP3 · Up to 20 MB'
                      : '${(file!.size / 1024 / 1024).toStringAsFixed(1)} MB',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              message!,
              style: const TextStyle(color: Colors.orangeAccent),
            ),
          ),
        const SizedBox(height: 20),
        _Field(
          controller: titleController,
          label: 'Song title',
          hint: 'Give your track a name',
        ),
        const SizedBox(height: 14),
        _Field(
          controller: artistController,
          label: 'Artist name',
          hint: 'Who made this track?',
        ),
        const SizedBox(height: 14),
        _Field(
          controller: descriptionController,
          label: 'Description',
          hint: 'Tell listeners a little about it',
          maxLines: 3,
        ),
        const SizedBox(height: 14),
        const Text('Genre', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: 'Indie',
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
        if (uploading) const LinearProgressIndicator(color: AppColors.violet),
        FilledButton(
          onPressed: uploading
              ? null
              : () {
                  if (file == null ||
                      file!.size > 20 * 1024 * 1024 ||
                      titleController.text.trim().isEmpty ||
                      artistController.text.trim().isEmpty) {
                    setState(
                      () =>
                          message = file == null ? 'Choose an MP3 file first.' : 'Add a title and artist, and keep the file under 20 MB.',
                    );
                    return;
                  }
                  setState(() => uploading = true);
                  final messenger = ScaffoldMessenger.of(context);
                  Future<void>.delayed(const Duration(milliseconds: 700), () {
                    if (!mounted) return;
                    setState(() => uploading = false);
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Upload preview complete. Connect Supabase to publish this track.',
                        ),
                      ),
                    );
                  });
                },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.violet,
            padding: const EdgeInsets.all(16),
          ),
          child: Text(uploading ? 'Preparing…' : 'Share track'),
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
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint),
      ),
    ],
  );
}
