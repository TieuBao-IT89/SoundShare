import 'dart:convert';

class LyricCue {
  const LyricCue(this.atMs, this.text);
  final int atMs;
  final String text;
}

class ParsedLrc {
  const ParsedLrc(this.source, this.cues);
  final String source;
  final List<LyricCue> cues;

  int activeIndex(Duration position) {
    var low = 0, high = cues.length;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (cues[mid].atMs <= position.inMilliseconds) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low - 1;
  }
}

const maxLrcBytes = 65536;

ParsedLrc parseLrc(String input) {
  Never invalid() => throw const FormatException('INVALID_LRC');
  if (input.isEmpty ||
      utf8.encode(input).length > maxLrcBytes ||
      input.runes.any((rune) => rune >= 0xd800 && rune <= 0xdfff) ||
      RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]').hasMatch(input)) {
    invalid();
  }
  final source = input
      .replaceFirst(RegExp('^\uFEFF'), '')
      .replaceAll(RegExp(r'\r\n?'), '\n')
      .trim();
  final rows = source.split('\n');
  if (rows.length > 2000) invalid();
  final cues = <LyricCue>[];
  var offset = 0, seenOffset = false;
  final timestamp = RegExp(r'^\[(\d{1,3}):([0-5]\d)(?:\.(\d{1,3}))?\]');
  for (final row in rows) {
    var rest = row.trim();
    if (rest.isEmpty) continue;
    final header = RegExp(
      r'^\[([a-z][a-z0-9_-]{0,20}):(.*)\]$',
      caseSensitive: false,
    ).firstMatch(rest);
    if (header != null) {
      if (rest.length > 600) invalid();
      if (header[1]!.toLowerCase() == 'offset') {
        if (seenOffset ||
            !RegExp(r'^[+-]?\d{1,5}$').hasMatch(header[2]!) ||
            int.parse(header[2]!).abs() > 30000) {
          invalid();
        }
        offset = int.parse(header[2]!);
        seenOffset = true;
      }
      continue;
    }
    final times = <int>[];
    RegExpMatch? stamp;
    while ((stamp = timestamp.firstMatch(rest)) != null) {
      final value = stamp!;
      final at =
          int.parse(value[1]!) * 60000 +
          int.parse(value[2]!) * 1000 +
          int.parse((value[3] ?? '').padRight(3, '0'));
      if (at > 21600000 || times.length >= 1000) invalid();
      times.add(at);
      rest = rest.substring(value.end).trimLeft();
    }
    final text = rest.trim();
    if (times.isEmpty ||
        text.length > 500 ||
        RegExp(r'^\[\d').hasMatch(text) ||
        RegExp(r'<\d{1,3}:\d{2}(?:\.\d{1,3})?>').hasMatch(text) ||
        cues.length + times.length > 1000) {
      invalid();
    }
    for (final at in times) {
      cues.add(LyricCue(at, text));
    }
  }
  if (!cues.any((cue) => cue.text.isNotEmpty)) invalid();
  final shifted = [
    for (var i = 0; i < cues.length; i++)
      (
        cue: LyricCue((cues[i].atMs - offset).clamp(0, 21630000), cues[i].text),
        order: i,
      ),
  ];
  shifted.sort((a, b) {
    final time = a.cue.atMs.compareTo(b.cue.atMs);
    return time == 0 ? a.order.compareTo(b.order) : time;
  });
  final merged = <LyricCue>[];
  for (final item in shifted) {
    final cue = item.cue;
    if (merged.isNotEmpty && merged.last.atMs == cue.atMs) {
      final last = merged.last;
      if (cue.text.isNotEmpty && !last.text.split('\n').contains(cue.text)) {
        final text = [
          last.text,
          cue.text,
        ].where((s) => s.isNotEmpty).join('\n');
        if (text.length > 2000) invalid();
        merged[merged.length - 1] = LyricCue(cue.atMs, text);
      }
    } else {
      merged.add(cue);
    }
  }
  return ParsedLrc(source, List.unmodifiable(merged));
}
