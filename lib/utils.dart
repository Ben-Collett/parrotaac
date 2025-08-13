import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openboard_wrapper/_utils.dart';
import 'package:parrotaac/backend/simple_logger.dart';

Future<XFile?> getImage() {
  return ImagePicker().pickImage(source: ImageSource.gallery);
}

Future<XFile?> getAudioFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    allowedExtensions: ['mp3', 'wav'],
  );

  return result?.xFiles.firstOrNull;
}

Future<List<String>> getFilesPaths(List<String> extensions) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowedExtensions: extensions,
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
  if (url.endsWith('.svg')) {
    return FittedBox(
      fit: fit,
      child: SvgPicture.network(
        url,
      ),
    );
  }
  return Image.network(url, fit: fit);
}

Widget imageFromData(InlineData data) {
  late Uint8List bytes;
  SimpleLogger().logDebug("imageFromData called");
  if (data.encodingBase == 64) {
    bytes = base64Decode(data.data);
  } else {
    SimpleLogger().logError("unsupported encoding base");
    return Container();
  }

  if (data.dataType.contains("svg")) {
    return SvgPicture.memory(bytes);
  }
  return Image.memory(bytes);
}
