//TODO: I need to work out away to test this with the application directory, perhaps an integration test would work but path_provider doesn't load for unit test
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:openboard_wrapper/obz.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/file_utils.dart';
import 'package:parrotaac/project_interface.dart';
import 'package:path/path.dart' as p;
import 'package:parrotaac/board_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:parrotaac/parrot_board.dart';

class ParrotProject extends Obz with AACProject {
  static const String _targetDirectoryName = 'projects_directory';
  static const String _nameKey = "ext_name";
  @override
  String get name {
    return manifestExtendedProperties[_nameKey];
  }

  ///the default directory path for projects
  static Future<String> get targetDirectoryPath async {
    return getApplicationDocumentsDirectory()
        .then((dir) => p.join(dir.path, _targetDirectoryName));
  }

  ///if name is defined in manifest.json using ext_name return it else return dir base name
  static Future<String> getProjectName(Directory dir) {
    File? file = _getManifestFile(dir);
    String dirName = p.basename(dir.path);

    if (file == null) {
      return Future(() => dirName);
    }

    Map<String, dynamic> decodeTheManifest(String json) => jsonDecode(json);
    String getTheName(Map<String, dynamic> json) =>
        json[_nameKey]?.toString() ?? dirName;

    return file.readAsString().then(decodeTheManifest).then(getTheName);
  }

  static File? _getManifestFile(Directory dir) {
    return dir
        .listSync()
        .whereType<File>()
        .where((file) => p.basename(file.path) == 'manifest.json')
        .firstOrNull;
  }

  ParrotProject({super.boards, required String name}) : super() {
    manifestExtendedProperties[_nameKey] = name;
  }

  ParrotProject.fromDirectory(Directory dir) : super.fromDirectory(dir) {
    Map<String, dynamic> manifest = manifestJson;
    name = manifest[_nameKey] ?? p.basename(dir.path);
  }

  static Future<String> _determineProjectName(String path) async {
    String name = p.basename(path);
    List<Directory> dirs = await projectDirectories;
    return determineNoncollidingName(
        name, dirs.map((dir) => p.basename(dir.path)));
  }

  ///return the  path of the imported project
  ///[path] is the path to the .obz to import
  ///[outputPath] is the path to output the file
  static Future<String> importArchiveFromPath(String path,
      {String? outputPath}) async {
    final inputStream = InputFileStream(path);
    final Archive archive = ZipDecoder().decodeStream(inputStream);

    String outPath;
    if (outputPath == null) {
      String name = await _determineProjectName(path);
      outPath = await projectTargetPath;
      outPath = p.join(outPath, name);
    } else {
      outPath = outputPath;
    }

    await extractArchiveToDisk(archive, outPath);
    return outPath;
  }

  static Future<ParrotProject?> getProject(String projectName) async {
    Directory? dir = await getProjectDir(projectName);
    if (dir == null) {
      return null;
    }
    return ParrotProject.fromDirectory(dir);
  }

  static Future<Directory?> getProjectDir(String baseName) async {
    List<Directory> currentDirs = await projectDirectories;
    bool theNameMatches(Directory dir) => p.basename(dir.path) == baseName;
    return currentDirs.where(theNameMatches).firstOrNull;
  }

  ///returns the path to the imported project
  ///automatically sets the board path to boards/(the basename of [toImport]) if [boardPath] is not specified
  static Future<String> importFromObfFile(
    File toImport, {
    String? projectName,
    String? outputPath,
    String? boardPath,
  }) {
    final String baseName = p.basenameWithoutExtension(toImport.path);
    final String importedName = projectName ?? baseName;
    final Obf board = Obf.fromFile(toImport);
    if (boardPath == null) {
      board.path = p.join('boards/', p.basename(toImport.path));
    } else {
      board.path = boardPath;
    }
    final Obz simpleObz = board.toSimpleObz();
    return ParrotProject.fromObz(simpleObz, importedName)
        .write(path: outputPath);
  }

  ///returns whether or not the rename was successful.
  ///renames the project directory to the new basename, if a  project directory exist
  @override
  Future<bool> rename(String name, {Directory? projectDirectory}) async {
    String originalName = name;
    manifestExtendedProperties[_nameKey] = name;
    Directory? projectDirOptional =
        projectDirectory ?? await getProjectDir(name);
    if (projectDirectory?.existsSync() ?? false) {
      Directory projectDir =
          projectDirOptional!; //?? false provides null safety
      try {
        String parentPath = p.dirname(projectDir.path);
        projectDir.renameSync(p.join(parentPath, baseName));
      } catch (e) {
        manifestExtendedProperties[_nameKey] = originalName;
        return false;
      }
    }

    return true;
  }

  ///writes to targetDirectoryPath by default. This behavior is overridden by the optional [path] parameter.
  ///this will override any matching files in the directory and leave the other files be
  @override
  Future<String> write({String? path}) async {
    Directory dir;
    if (path == null) {
      Directory? temp = await getProjectDir(baseName);
      dir = temp ?? await _asDirectory;
    } else {
      dir = Directory(path);
    }

    File manifest = File(p.join(dir.path, 'manifest.json'));
    manifest.createSync(
        recursive: true); // should create dir as well as the manifest

    manifest.writeAsStringSync(manifestString);

    String fullPath(Obf obf) => p.join(dir.path, obf.path);
    Set<String> usedFilePaths = {};
    for (Obf board in boards) {
      String path =
          board.path ?? p.join("boards/", sanitzeFileName(board.name));
      path = determineNoncollidingName(path, usedFilePaths);
      usedFilePaths.add(path);
      path = p.setExtension(path, '.obf');

      board.path = path;
      String pathToWrite = fullPath(board);
      await board.writeTo(pathToWrite);
    }

    return dir.path;
  }

  Future<String> get projectPath {
    return targetDirectoryPath.then((path) => p.join(path, baseName));
  }

  ///returns a Future with a directory object set to the the path of the project, this method does not create that directory, nor does it write a any data to it.
  Future<Directory> get _asDirectory {
    Directory maptToDir(String path) => Directory(path);
    return targetDirectoryPath
        .then((target) => p.join(target, baseName))
        .then(maptToDir);
  }

  factory ParrotProject.fromObz(Obz obz, String name) {
    return ParrotProject(boards: obz.boards, name: name)
        .parseManifestJson(obz.manifestJson);
  }

  @override
  ParrotProject parseManifestString(String json, {bool fullOverride = false}) {
    super.parseManifestString(json, fullOverride: fullOverride);
    return this;
  }

  @override
  ParrotProject parseManifestJson(Map<String, dynamic> manifestJson,
      {bool fullOverride = true}) {
    super.parseManifestJson(manifestJson, fullOverride: fullOverride);
    return this;
  }
}

//TODO: figure out how to add image
class ParrotProjectDisplayData {
  String name;
  ParrotProjectDisplayData(this.name);
  ParrotProjectDisplayData.fromDirectory(Directory dir)
      : name = p.basename(dir.path) {
    File? manifest = ParrotProject._getManifestFile(dir);
    if (manifest != null) {
      Map<String, dynamic> json = jsonDecode(manifest.readAsStringSync());
      if (json.containsKey(ParrotProject._nameKey)) {
        name = json[ParrotProject._nameKey];
      }
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is! ParrotProjectDisplayData) return false;
    return name == other.name;
  }

  @override
  int get hashCode => name.hashCode;
  @override
  String toString() {
    return name;
  }
}
