import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openboard_wrapper/_utils.dart';
import 'package:parrotaac/utils/caching.dart';
import 'package:parrotaac/utils/debugging/simple_logger.dart';
import 'package:parrotaac/ui/util_widgets/cached_image.dart';

final MemoryCache _imageFromDataCache = MemoryCache(maxEntries: 20);
Future<XFile?> getImage() {
  return ImagePicker().pickImage(source: ImageSource.gallery);
}

Widget imageFromPath(String path, {BoxFit fit = BoxFit.contain}) {
  File file = File(path);
  if (path.endsWith('.svg')) {
    return FittedBox(fit: fit, child: SvgFromFile(file));
  }
  return Image.file(file, fit: fit);
}

Widget imageFromUrl(
  String url, {
  BoxFit fit = BoxFit.contain,
  bool useKey = false,
}) {
  return CachedImage(url: url, fit: fit, key: useKey ? ValueKey(url) : null);
}

Future<Widget> futureImageFromUrl(String url, BuildContext context) {
  if (url.endsWith(".svg")) {
    return DefaultCacheManager()
        .getSingleFile(url)
        .then((file) => file.readAsString())
        .then(sanitizeSvg)
        .then(SvgPicture.string);
  }
  return DefaultCacheManager().getSingleFile(url).then((file) {
    if (context.mounted) precacheImage(FileImage(file), context);
    return Image.file(file, fit: BoxFit.contain);
  });
}

Widget imageFromData(InlineData data) {
  if (!_imageFromDataCache.containsKey(data)) {
    late Uint8List bytes;
    if (data.encodingBase == 64) {
      bytes = base64Decode(data.data);
    } else {
      SimpleLogger().logError("unsupported encoding base");
      return Container();
    }

    if (data.dataType.contains("svg")) {
      _imageFromDataCache[data] = SvgPicture.memory(bytes);
    } else {
      _imageFromDataCache[data] = Image.memory(bytes);
    }
  }
  return _imageFromDataCache[data]!;
}
