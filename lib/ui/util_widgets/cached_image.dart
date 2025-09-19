import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:parrotaac/backend/simple_logger.dart';
import 'package:parrotaac/ui/util_widgets/simple_future_builder.dart';

class CachedImage extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const CachedImage({super.key, required this.url, this.fit = BoxFit.contain});

  Widget _toImage(File file) {
    if (_isSvg) {
      return SvgFromFile(file);
    } else {
      return Image.file(file, fit: fit);
    }
  }

  bool get _isSvg => url.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    return SimpleFutureBuilder<File>(
      future: DefaultCacheManager().getSingleFile(url),
      futureId: url,
      onData: _toImage,
    );
  }
}

//TODO: I should find a way to write the sanitized svg to the cache instead of the original
String sanitizeSvg(String svg) {
  // Match the entire <switch> block
  final switchRegex = RegExp(r'<switch>(.*?)</switch>', dotAll: true);
  final match = switchRegex.firstMatch(svg);

  if (match != null) {
    final switchContent = match.group(1)!;

    // Match all direct child elements of <switch>
    final childRegex = RegExp(
      r'<(g|path|rect|circle|[^>]+)[\s\S]*?</\1>',
      dotAll: true,
    );
    final allChildren = childRegex.allMatches(switchContent);

    if (allChildren.isNotEmpty) {
      // Get the last child (fallback)
      final lastChild = allChildren.last.group(0)!;

      // Replace the entire <switch> block with the last child
      svg = svg.replaceFirst(switchRegex, lastChild);
    } else {
      // If no valid children, remove the switch entirely
      svg = svg.replaceFirst(switchRegex, '');
    }
  }

  // Strip Illustrator/Adobe-specific attributes
  svg = svg.replaceAll(RegExp(r'xmlns:[^=]+="[^"]+"'), '');
  svg = svg.replaceAll(RegExp(r'\s+i:[^=]+="[^"]+"'), '');
  svg = svg.replaceAll(RegExp(r'\s+xml:[^=]+="[^"]+"'), '');
  svg = svg.replaceAll(RegExp(r'\s+enable-background="[^"]+"'), '');

  return svg;
}

class SvgFromFile extends StatelessWidget {
  final File file;
  final BoxFit fit;
  const SvgFromFile(this.file, {super.key, this.fit = BoxFit.contain});
  @override
  Widget build(BuildContext context) {
    return SimpleFutureBuilder(
      future: file.readAsString().then(sanitizeSvg),
      futureId: file.path,
      loadingWidget: Container(),
      onData: (content) => SvgPicture.string(content, fit: fit),
    );
  }
}
