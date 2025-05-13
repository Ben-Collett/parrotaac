//TODO: write unit test for this function
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:openboard_wrapper/obz.dart';
import 'package:parrotaac/backend/project/project_utils.dart';
import 'package:parrotaac/file_utils.dart';
import 'package:path/path.dart' as p;

import 'manifest_utils.dart';
import 'parrot_project.dart';

Future<String> import(
  String path, {
  String? outputPath,
  DateTime? lastAccessedTime,
  String? projectName,
}) async {
  String extension = p.extension(path);
  DateTime currentTime = lastAccessedTime ?? DateTime.now();
  String? pathWroteTo;
  if (extension == '.obf') {
    pathWroteTo = await importFromObfFile(
      File(path),
      projectName: projectName,
      outputPath: outputPath,
    );
  } else if (extension == '.obz') {
    pathWroteTo = await importArchiveFromPath(
      path,
      projectName: projectName,
      outputPath: outputPath,
    );
  }

  if (pathWroteTo != null) {
    updateAccessedTimeInManifest(Directory(pathWroteTo), time: currentTime);
  }
  return pathWroteTo ?? "";
}

///returns the path to the imported project
///automatically sets the board path to boards/(the basename of [toImport]) if [boardPath] is not specified
Future<String> importFromObfFile(
  File toImport, {
  String? projectName,
  String? outputPath,
  String? boardPath,
}) async {
  final String baseName = p.basenameWithoutExtension(toImport.path);
  String importedName;
  if (outputPath == null) {
    importedName = await determineProjectDirectoryName(projectName ?? baseName);
  } else {
    importedName = p.basename(outputPath);
  }

  final Obf board = Obf.fromFile(toImport);
  if (boardPath == null) {
    board.path = p.join('boards/', sanitzeFileName(importedName));
  } else {
    board.path = boardPath;
  }
  final Obz simpleObz = board.toSimpleObz();
  final simpleProject = ParrotProject.fromObz(
      simpleObz, p.basenameWithoutExtension(importedName), outputPath ?? "");
  return await simpleProject.write(path: outputPath);
}

///return the  path of the imported project
///[path] is the path to the .obz to import
///[outputPath] is the path to output the file
Future<String> importArchiveFromPath(
  String path, {
  DateTime? lastAccessedTime,
  String? outputPath,
  String? projectName, //TODO: refactor this
}) async {
  final inputStream = InputFileStream(path);
  final Archive archive = ZipDecoder().decodeStream(inputStream);

  String outPath;
  if (outputPath == null) {
    String name;
    if (projectName != null) {
      name = await determineProjectDirectoryName(projectName);
    } else {
      name = await determineProjectDirectoryName(path);
    }
    outPath = await projectTargetDirectory;
    outPath = p.join(outPath, name);
  } else {
    outPath = outputPath;
  }
  String? name;
  if (outputPath == null) {
    name = await determineProjectName(outPath);
  }
  await extractArchiveToDisk(archive, outPath);

  if (lastAccessedTime != null) {
    updateAccessedTimeInManifest(Directory(outPath), time: lastAccessedTime);
  }
  if (name != null) {
    setProjectNameInManifest(Directory(outPath), name);
  }

  return outPath;
}
