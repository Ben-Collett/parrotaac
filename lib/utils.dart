import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

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
