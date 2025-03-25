import 'dart:io';

import 'package:openboard_wrapper/obf.dart';
import 'package:openboard_wrapper/obz.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// if performance becomes an issue we could cache this and update as needed
Future<List<Directory>> get projectDirectories async {
  Directory directory = Directory(await projectTargetPath);
  Directory? toDir(FileSystemEntity file) => file is Directory ? file : null;
  return directory.listSync().map(toDir).nonNulls.toList();
}

//caches the projectTargetPath to avoid recomputing it every time when invoking projectTargetPath
String? _projectTargetPathCache;
Future<String> get projectTargetPath async {
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
  print(await projectTargetPath);
  return projectDirPath;
}

void importProjectFromPath(String path) {
  if (p.extension(path) == '.obz') {
    _importObzFromPath(path);
  } else if (p.extension(path) == '.obf') {
    _importObfFromPath(path);
  }
}

void _importObfFromPath(String path) {}

//TODO: return obz, maybe future?
void _importObzFromPath(String path) async {}

///will handle a name collision
///increments [inputPath] until it doesn't collide with anything in dirNames
///using the following structure name, name_1, name_2, name_3, name_4 ... name_n

void importObf(File file) {
  Obz project = Obf.fromFile(file).toSimpleObz();
}

File? exportProject(Directory dir) {
  if (exportAsObf(dir)) {
    //return dir.listSync(recursive: true).where((e)=>e.path.endsWith('.obf')).first;
  }
  return null;
}

bool exportAsObf(Directory dir) {
  const int numberOfFilesInObfDir = 2; //manifest.json, file.obf
  bool entityIsDirectory(FileSystemEntity entity) => entity is Directory;
  List<FileSystemEntity> temp = dir.listSync(recursive: true);
  temp.removeWhere(entityIsDirectory);

  return temp.length == numberOfFilesInObfDir;
}
