import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedProductImage extends StatelessWidget {
  const CachedProductImage({super.key, required this.url, this.width, this.height, this.fit = BoxFit.cover});
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: width == null ? null : (width! * MediaQuery.devicePixelRatioOf(context)).round(),
      memCacheHeight: height == null ? null : (height! * MediaQuery.devicePixelRatioOf(context)).round(),
      placeholder: (_, __) => const ColoredBox(color: Color(0x12000000)),
      errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}
