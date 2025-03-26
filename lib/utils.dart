import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

Future<XFile?> getImage() {
  return ImagePicker().pickImage(source: ImageSource.gallery);
}

Widget imageFromPath(String path, {BoxFit fit = BoxFit.contain}) {
  File file = File(path);
  if (path.endsWith('.svg')) {
    return SvgPicture.file(file, fit: fit);
  }
  return Image.file(file, fit: fit);
}
