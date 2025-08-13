import 'package:flutter/material.dart';
import 'package:openboard_wrapper/image_data.dart';
import 'package:parrotaac/utils.dart';
import 'package:path/path.dart' as p;

extension ToImage on ImageData {
  Widget toImage({String? projectPath}) {
    if (inlineData != null) {
      return imageFromData(inlineData!);
    } else if (path != null && projectPath != null) {
      String absolutePath = p.join(projectPath, path);
      return imageFromPath(absolutePath);
    } else if (url != null) {
      return imageFromUrl(url!);
    }
    return Placeholder();
  }
}
