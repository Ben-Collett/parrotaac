import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openboard_wrapper/_utils.dart';
import 'package:parrotaac/backend/simple_logger.dart';
import 'package:parrotaac/ui/util_widgets/cached_image.dart';

final Map<InlineData, Widget> _imageFromDataCache = {};
Future<XFile?> getImage() {
  return ImagePicker().pickImage(source: ImageSource.gallery);
}

Future<XFile?> getAudioFile() async {
  //TODO: this may cause problems on IOS and android may need to do a custom selection on those platforms
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: FileType.audio,
  );

  return result?.xFiles.firstOrNull;
}

Future<List<String>> getFilesPaths(List<String> extensions) async {
  //TODO: this only works with any on linux I can try using type:FileType.custom and allowedExtensions on other OS's
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
  );
  if (result != null) {
    return result.paths.nonNulls.toList();
  }
  return [];
}

Future<String?> getUserSelectedDirectory() async {
  String? result = await FilePicker.platform
      .getDirectoryPath(dialogTitle: "select folder to export to");
  return result;
}

Widget imageFromPath(String path, {BoxFit fit = BoxFit.contain}) {
  File file = File(path);
  if (path.endsWith('.svg')) {
    return FittedBox(fit: fit, child: SvgPicture.file(file, fit: fit));
  }
  return Image.file(file, fit: fit);
}

Widget imageFromUrl(String url, {BoxFit fit = BoxFit.contain}) {
  return CachedImage(
    url: url,
    fit: fit,
  );
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

void clearImageFromDataCache() {
  _imageFromDataCache.clear();
}
