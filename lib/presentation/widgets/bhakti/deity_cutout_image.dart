import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../domain/entities/bhakti_deity.dart';

/// Resolves local asset + optional network URL for a deity key.
({String asset, String url}) resolveDeityPortrait(
  String deity, {
  List<BhaktiDeity> deities = const [],
}) {
  for (final d in deities) {
    if (d.matches(deity)) {
      return (asset: d.imageAsset, url: d.imageUrl.trim());
    }
  }
  return (asset: MandirTheme.getDeityImageAsset(deity), url: '');
}

/// Bundled cut-out, or network image when [BhaktiDeity.imageUrl] is set.
class DeityCutoutImage extends StatelessWidget {
  final BhaktiDeity deity;
  final BoxFit fit;
  final Alignment alignment;

  const DeityCutoutImage({
    super.key,
    required this.deity,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.bottomCenter,
  });

  @override
  Widget build(BuildContext context) {
    return DeityPortraitImage(
      imageAsset: deity.imageAsset,
      imageUrl: deity.imageUrl,
      fit: fit,
      alignment: alignment,
    );
  }
}

/// Portrait from asset and/or remote [imageUrl] (remote wins when set).
class DeityPortraitImage extends StatelessWidget {
  final String imageAsset;
  final String imageUrl;
  final BoxFit fit;
  final Alignment alignment;
  final double? height;
  final double? width;
  final int? cacheHeight;
  final int? cacheWidth;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const DeityPortraitImage({
    super.key,
    required this.imageAsset,
    this.imageUrl = '',
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.height,
    this.width,
    this.cacheHeight,
    this.cacheWidth,
    this.errorBuilder,
  });

  Widget _assetImage() {
    final effectiveHeight =
        (cacheHeight == null && cacheWidth == null) ? 720 : cacheHeight;
    return Image.asset(
      imageAsset,
      fit: fit,
      alignment: alignment,
      height: height,
      width: width,
      cacheHeight: effectiveHeight,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      errorBuilder: errorBuilder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    if (url.isEmpty) return _assetImage();
    final effectiveHeight =
        (cacheHeight == null && cacheWidth == null) ? 720 : cacheHeight;

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      alignment: alignment,
      height: height,
      width: width,
      memCacheHeight: effectiveHeight,
      memCacheWidth: cacheWidth,
      placeholder: (context, _) => _assetImage(),
      errorWidget: (context, _, _) => _assetImage(),
    );
  }
}
