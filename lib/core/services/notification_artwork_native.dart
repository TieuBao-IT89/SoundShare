import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'media_artwork.dart';

MediaArtworkStore createNotificationArtwork() => NativeNotificationArtwork();

/// Android receives a local image, never the signed artwork URL. Failures are
/// swallowed here, avoiding audio_service's remote-image error logger.
class NativeNotificationArtwork implements MediaArtworkStore {
  NativeNotificationArtwork({
    http.Client? client,
    Future<Directory> Function()? directory,
  }) : _client = client ?? http.Client(),
       _directory = directory ?? getTemporaryDirectory;
  final http.Client _client;
  final Future<Directory> Function() _directory;
  final _files = <File>[];
  final _cache = <String, Uri>{};
  Future<Uri?>? _fallback;
  static int _storeSerial = 0;
  final _prefix =
      'soundshare-media-${DateTime.now().microsecondsSinceEpoch}-${_storeSerial++}';
  bool _disposed = false;
  int _serial = 0;

  @override
  Future<Uri?> resolve(String artworkUrl) async {
    if (_disposed) return null;
    final fallback = await (_fallback ??= _logo());
    if (_disposed) return null;
    if (_cache.containsKey(artworkUrl)) return _cache[artworkUrl];
    final uri = Uri.tryParse(artworkUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return fallback;
    }
    try {
      final request = http.Request('GET', uri);
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 ||
          (response.contentLength ?? 0) > 5 * 1024 * 1024) {
        await response.stream.listen((_) {}).cancel();
        return fallback;
      }
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 10),
      )) {
        if (_disposed || bytes.length + chunk.length > 5 * 1024 * 1024) {
          return fallback;
        }
        bytes.add(chunk);
      }
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes.takeBytes());
      ui.ImageDescriptor? descriptor;
      ui.Codec? codec;
      ui.Image? image;
      try {
        descriptor = await ui.ImageDescriptor.encoded(buffer);
        if (descriptor.width * descriptor.height > 40000000) return fallback;
        codec = await descriptor.instantiateCodec(
          targetWidth: 512,
          targetHeight: 512,
        );
        image = (await codec.getNextFrame()).image;
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        if (png == null || _disposed) return fallback;
        final local = await _write(png.buffer.asUint8List());
        if (local != null && !_disposed) {
          _cache[artworkUrl] = local;
          if (_cache.length > 8) {
            final old = _cache.remove(_cache.keys.first)!;
            unawaited(_delete(File.fromUri(old)));
          }
        }
        return local ?? fallback;
      } finally {
        image?.dispose();
        codec?.dispose();
        descriptor?.dispose();
        buffer.dispose();
      }
    } catch (_) {
      return _disposed ? null : fallback;
    }
  }

  Future<Uri?> _logo() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawColor(const ui.Color(0xFF171A29), ui.BlendMode.src);
    final paint = ui.Paint()
      ..color = const ui.Color(0xFFB9A6F8)
      ..strokeWidth = 24
      ..strokeCap = ui.StrokeCap.round;
    const heights = [55.0, 110.0, 155.0, 90.0, 40.0];
    for (var i = 0; i < heights.length; i++) {
      final x = 144.0 + i * 56;
      canvas.drawLine(
        ui.Offset(x, 256 - heights[i]),
        ui.Offset(x, 256 + heights[i]),
        paint,
      );
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(512, 512);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes == null ? null : await _write(bytes.buffer.asUint8List());
    } finally {
      image.dispose();
      picture.dispose();
    }
  }

  Future<Uri?> _write(Uint8List bytes) async {
    if (_disposed) return null;
    final root = await _directory();
    if (_disposed) return null;
    final file = File.fromUri(root.uri.resolve('$_prefix-${_serial++}.png'));
    _files.add(file);
    await file.writeAsBytes(bytes, flush: true);
    if (_disposed) {
      await _delete(file);
      return null;
    }
    return file.uri;
  }

  Future<void> _delete(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      /* Temporary cache. */
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _client.close();
    _cache.clear();
    for (final file in _files) {
      unawaited(_delete(file));
    }
    _files.clear();
  }
}
