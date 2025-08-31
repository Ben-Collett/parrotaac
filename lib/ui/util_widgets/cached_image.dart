import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CachedImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CachedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  bool get _isSvg => url.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: DefaultCacheManager().getSingleFile(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const Icon(Icons.error);
        } else {
          final file = snapshot.data!;
          if (_isSvg) {
            return SvgPicture.file(
              file,
              width: width,
              height: height,
              fit: fit,
            );
          } else {
            return Image.file(
              file,
              width: width,
              height: height,
              fit: fit,
            );
          }
        }
      },
    );
  }
}
