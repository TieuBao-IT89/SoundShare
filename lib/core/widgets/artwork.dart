import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/l10n.dart';

/// CanvasKit and ambient sampling share the SDK's byte-decoded image on Web.
/// Native platforms retain their existing disk cache.
ImageProvider artworkImageProvider(String url) =>
    kIsWeb ? NetworkImage(url) : CachedNetworkImageProvider(url);

class Artwork extends StatelessWidget {
  const Artwork({
    super.key,
    required this.url,
    this.size = 56,
    this.radius = 14,
    this.semanticLabel,
    this.height,
  });
  final String url;
  final double size;
  final double radius;
  final String? semanticLabel;
  final double? height;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: semanticLabel ?? context.l10n.albumArtwork,
    child: ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: url.isEmpty
            ? _fallback()
            : kIsWeb
            ? Image(
                image: artworkImageProvider(url),
                width: size,
                height: height ?? size,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, synchronous) =>
                    synchronous || frame != null
                    ? child
                    : _fallback(loading: true),
                errorBuilder: (_, _, _) => _fallback(),
              )
            : CachedNetworkImage(
                imageUrl: url,
                width: size,
                height: height ?? size,
                fit: BoxFit.cover,
                fadeInDuration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                fadeOutDuration: Duration.zero,
                placeholder: (context, error) => Container(
                  width: size,
                  height: height ?? size,
                  color: AppColors.surfaceLight,
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    color: AppColors.violet,
                  ),
                ),
                errorWidget: (context, error, stackTrace) => Container(
                  width: size,
                  height: height ?? size,
                  color: AppColors.surfaceLight,
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: AppColors.violet,
                  ),
                ),
              ),
      ),
    ),
  );

  Widget _fallback({bool loading = false}) => Container(
    width: size,
    height: height ?? size,
    color: AppColors.surfaceLight,
    child: Icon(
      loading ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
      color: AppColors.violet,
    ),
  );
}
