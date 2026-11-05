import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

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
    label: semanticLabel ?? 'Album artwork',
    child: ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
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
}
