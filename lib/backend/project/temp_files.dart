import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:parrotaac/file_utils.dart';
import 'package:path/path.dart' as p;

String tmpImagePath(String projectPath) =>
    p.join(projectPath, 'images', 'parrot_tmp');
String tmpAudioPath(String projectPath) =>
    p.join(projectPath, 'audio', 'parrot_tmp');

///returns the relative path from project dir to the temp image file
Future<String> writeTempImage(Directory projectDir, XFile xfile) async {
  Directory dir = Directory(tmpImagePath(projectDir.path));
  dir.createSync(recursive: true);
  Iterable<File> images = dir.listSync().whereType<File>();
  String extension = p.extension(xfile.path);
  String name = p.basenameWithoutExtension(xfile.path);
  Iterable<String> imageNames = images
      .map((f) => f.path)
      .map(p.basenameWithoutExtension);
  name = determineNoncollidingPath(name, imageNames);
  String path = p.setExtension(name, extension);
  path = p.join(dir.path, path);

  await xfile.saveTo(path);
  return p.relative(path, from: projectDir.path);
}

//TODO: code duplication with writeTempImage
Future<String> writeTempAudio(Directory projectDir, XFile xfile) async {
  Directory dir = Directory(tmpAudioPath(projectDir.path));
  dir.createSync(recursive: true);
  Iterable<File> images = dir.listSync().whereType<File>();
  String extension = p.extension(xfile.path);
  String name = p.basenameWithoutExtension(xfile.path);
  Iterable<String> imageNames = images
      .map((f) => f.path)
      .map(p.basenameWithoutExtension);
  name = determineNoncollidingPath(name, imageNames);
  String path = p.setExtension(name, extension);
  path = p.join(dir.path, path);

  await xfile.saveTo(path);
  return p.relative(path, from: projectDir.path);
}

Map<String, String> mapDirectoryContentToOtherDir({
  required Directory inputDir,
  required Directory outputDir,
}) {
  if (!inputDir.existsSync()) {
    return {};
  }
  Map<String, String> out = {};
  final Iterable<String> existingFileNames;
  if (outputDir.existsSync()) {
    existingFileNames = outputDir.listSync().map(
      (f) => p.basenameWithoutExtension(f.path),
    );
  } else {
    existingFileNames = [];
  }

  List<FileSystemEntity> inputDirFiles = inputDir.listSync();

  for (FileSystemEntity entity in inputDirFiles) {
    String newPath = determineNoncollidingPath(entity.path, existingFileNames);
    String basename = p.basename(newPath);
    newPath = p.join(outputDir.path, basename);
    out[entity.path] = newPath;
  }
  return out;
}
