import 'dart:convert';
import 'dart:io';

import 'package:parrotaac/file_utils.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'custom_manifest_keys.dart';
import 'manifest_utils.dart';

///if name is defined in manifest.json using ext_name return it else return dir base name
Future<String> getProjectName(Directory dir) {
  File? file = getManifestFile(dir);
  String dirName = p.basename(dir.path);

  if (file == null) {
    return Future(() => dirName);
  }

  Map<String, dynamic> decodeTheManifest(String json) => jsonDecode(json);
  String getTheName(Map<String, dynamic> json) =>
      json[nameKey]?.toString() ?? dirName;

  return file.readAsString().then(decodeTheManifest).then(getTheName);
}

Future<String> determineProjectDirectoryName(String path) async {
  String name = p.basenameWithoutExtension(path);
  List<Directory> dirs = await projectDirectories;
  String toPath(Directory dir) => dir.path;
  String toName(String path) => p.basenameWithoutExtension(path);

  Iterable<String> usedNames = dirs.map(toPath).map(toName);
  return determineNoncollidingName(name, usedNames);
}

Future<String> determineProjectName(String path) async {
  String name = p.basenameWithoutExtension(path);
  List<Directory> dirs = await projectDirectories;
  List<String> usedNames = await Future.wait(dirs.map(getProjectName));
  return determineNoncollidingName(name, usedNames);
}

Future<String> determineValidProjectPath(String name) async {
  name = sanitzeFileName(name);
  Iterable<Directory> dirs = await projectDirs();
  Iterable<String> names = dirs.map((d) => d.path).map(p.basename);
  name = determineNoncollidingName(name, names);
  return p.join(await projectTargetDirectory, name);
}

Future<Iterable<Directory>> projectDirs() async {
  Directory convertPathToDir(String path) => Directory(path);
  bool theDirectoryExist(Directory dir) => dir.existsSync();
  Iterable<Directory> getTheSubDirs(Directory dir) => dir
      .listSync()
      .whereType<Directory>()
      .where(
        theDirectoryExist,
      ); //Need to check for existens otherwise it breaks when deleting files

  return projectTargetDirectory.then(convertPathToDir).then(getTheSubDirs);
}

Future<Directory?> getProjectDir(String baseName) async {
  List<Directory> currentDirs = await projectDirectories;
  bool theNameMatches(Directory dir) => p.basename(dir.path) == baseName;
  return currentDirs.where(theNameMatches).firstOrNull;
}

// if performance becomes an issue we could cache this and update as needed
Future<List<Directory>> get projectDirectories async {
  Directory directory = Directory(await projectTargetDirectory);
  Directory? toDir(FileSystemEntity file) => file is Directory ? file : null;
  return directory.listSync().map(toDir).nonNulls.toList();
}

String? _projectTargetPathCache;
Future<String> get projectTargetDirectory async {
  if (_projectTargetPathCache != null) {
    return Future(() => _projectTargetPathCache!);
  }
  const String projectsDirName = 'projects';
  final Directory applicationDocumentsDir =
      await getApplicationDocumentsDirectory();
  final String projectDirPath =
      p.join(applicationDocumentsDir.path, projectsDirName);
  final Directory projectDirectory = Directory(projectDirPath);
  if (!projectDirectory.existsSync()) {
    projectDirectory.createSync();
  }
  _projectTargetPathCache = projectDirPath;
  return projectDirPath;
}
