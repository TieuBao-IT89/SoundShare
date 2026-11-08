import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../domain/lrc.dart';

/// Shared LRC input for a new recording and the existing-track editor.
class LrcAttachment extends StatefulWidget {
  const LrcAttachment({
    super.key,
    required this.onChanged,
    this.initialValue,
    this.enabled = true,
    this.filePicker,
  });
  final void Function(String? source, bool valid) onChanged;
  final String? initialValue;
  final bool enabled;
  final FilePicker? filePicker;
  @override
  State<LrcAttachment> createState() => _LrcAttachmentState();
}

class _LrcAttachmentState extends State<LrcAttachment> {
  late final controller = TextEditingController(
    text: widget.initialValue ?? '',
  );
  bool choosing = false, expanded = false;
  String? error;
  int? count;
  @override
  void initState() {
    super.initState();
    expanded = widget.initialValue?.isNotEmpty ?? false;
    if (expanded) count = parseLrc(widget.initialValue!).cues.length;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void validate(String value) {
    String? normalized;
    var valid = true;
    int? lines;
    try {
      if (value.trim().isNotEmpty) {
        final lrc = parseLrc(value);
        normalized = lrc.source;
        lines = lrc.cues.length;
      }
    } on FormatException {
      valid = false;
    }
    setState(() {
      error = valid ? null : context.l10n.v11InvalidLrc;
      count = lines;
    });
    widget.onChanged(normalized, valid);
  }

  Future<void> choose() async {
    setState(() => choosing = true);
    try {
      final result = await (widget.filePicker ?? FilePicker.platform).pickFiles(
        type: FileType.custom,
        allowedExtensions: ['lrc'],
        withData: true,
      );
      if (!mounted || result == null || result.files.isEmpty) return;
      final file = result.files.single;
      if (file.extension?.toLowerCase() != 'lrc' ||
          file.size < 1 ||
          file.size > maxLrcBytes ||
          file.bytes == null ||
          file.bytes!.length > maxLrcBytes) {
        throw const FormatException();
      }
      final text = utf8.decode(file.bytes!, allowMalformed: false);
      parseLrc(text);
      controller.text = text;
      setState(() => expanded = true);
      validate(text);
    } catch (_) {
      if (mounted) {
        setState(() => error = context.l10n.v11InvalidLrc);
        widget.onChanged(null, false);
      }
    } finally {
      if (mounted) setState(() => choosing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.v11AttachTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(t.v11LrcHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: widget.enabled && !choosing ? choose : null,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(choosing ? t.openingFile : t.v11ChooseLrc),
            ),
            TextButton(
              onPressed: widget.enabled && !choosing
                  ? () => setState(() => expanded = !expanded)
                  : null,
              child: Text(t.v11PasteLrc),
            ),
            if (controller.text.isNotEmpty)
              TextButton(
                onPressed: widget.enabled && !choosing
                    ? () {
                        controller.clear();
                        validate('');
                      }
                    : null,
                child: Text(t.v11ClearLrc),
              ),
          ],
        ),
        if (expanded)
          TextField(
            key: const ValueKey('lrc-input'),
            controller: controller,
            enabled: widget.enabled && !choosing,
            minLines: 3,
            maxLines: 6,
            maxLength: maxLrcBytes,
            decoration: InputDecoration(
              labelText: t.playerLyrics,
              hintText: t.v11LrcExample,
              errorText: error,
            ),
            onChanged: validate,
          ),
        if (!expanded && error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (count != null && error == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(t.v11LinesReady(count!)),
          ),
      ],
    );
  }
}
