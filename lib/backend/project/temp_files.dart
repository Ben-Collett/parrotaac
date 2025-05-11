import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:parrotaac/file_utils.dart';
import 'package:path/path.dart' as p;

String tmpImagePath(String projectPath) =>
    p.join(projectPath, 'images', 'parrot_tmp');

///returns the relative path from project dir to the temp image file
Future<String> writeTempImage(
  Directory projectDir,
  XFile xfile,
) async {
  Directory dir = Directory(tmpImagePath(projectDir.path));
  dir.createSync(recursive: true);
  Iterable<File> images = dir.listSync().whereType<File>();
  String extension = p.extension(xfile.path);
  String name = p.basenameWithoutExtension(xfile.path);
  Iterable<String> imageNames =
      images.map((f) => f.path).map(p.basenameWithoutExtension);
  name = determineNoncollidingName(name, imageNames);
  String path = p.setExtension(name, extension);
  path = p.join(dir.path, path);

  await xfile.saveTo(path);
  return p.relative(path, from: projectDir.path);
}
