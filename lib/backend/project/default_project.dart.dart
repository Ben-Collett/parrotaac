import 'dart:io';

import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/default_board_strings.dart';
import 'package:path/path.dart' as p;

import 'parrot_project.dart';

Future<ParrotProject> writeDefaultProject(
  String projectName, {
  required String path,
  String? projectImagePath,
}) async {
  ParrotProject project = ParrotProject(
    boards: [Obf.fromJsonString(defaultRootObf)],
    path: path,
    name: projectName,
  );

  await project
      .parseManifestString(
        defaultManifest(
          name: projectName,
          imagePath: projectImagePath,
        ),
      )
      .write();

  if (projectImagePath != null) {
    String imgDirPath = p.join(path, 'images/');
    Directory(imgDirPath).createSync();

    String imageFilePath = p.join(imgDirPath, 'project_image');
    String extension = p.extension(projectImagePath);
    imageFilePath = p.setExtension(imageFilePath, extension);

    await File(projectImagePath).copy(imageFilePath);
  }
  return project;
}
