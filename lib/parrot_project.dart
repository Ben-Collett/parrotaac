//TODO: I need to work out away to test this with the application directory, perhaps an integration test would work but path_provider doesn't load for unit test
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';

import 'package:archive/archive_io.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:openboard_wrapper/obz.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/default_board_strings.dart';
import 'package:parrotaac/file_utils.dart';
import 'package:parrotaac/project_interface.dart';
import 'package:parrotaac/utils.dart';
import 'package:path/path.dart' as p;
import 'package:parrotaac/board_utils.dart';
import 'package:parrotaac/parrot_board.dart';

final SvgPicture logo = SvgPicture.asset("assets/images/logo/white_bg.svg");

class ParrotProject extends Obz with AACProject {
  static const String nameKey = "ext_name";
  static const String imagePathKey = 'ext_display_image_path';

  String? get displayImagePath {
    return manifestExtendedProperties[imagePathKey];
  }

  set displayImagePath(String? path) {
    if (path == null) {
      manifestExtendedProperties.remove(imagePathKey);
    } else {
      manifestExtendedProperties[imagePathKey] = path;
    }
  }

  @override
  Widget get displayImage =>
      displayImagePath != null ? Image.file(File(displayImagePath!)) : logo;
  @override
  String get name {
    return manifestExtendedProperties[nameKey];
  }

  static Future<ParrotProject> writeDefaultProject(
    String projectName, {
    String? projectImagePath,
  }) async {
    ParrotProject project = ParrotProject(
      boards: [Obf.fromJsonString(defaultRootObf)],
      name: projectName,
    );

    await project
        .parseManifestString(
            defaultManifest(name: projectName, imagePath: projectImagePath))
        .write();

    if (projectImagePath != null) {
      Directory projectDir = await project._asDirectory;
      String imgDirPath = p.join(projectDir.path, 'images/');
      Directory(imgDirPath).createSync();

      String imageFilePath = p.join(imgDirPath, 'project_image');
      String extension = p.extension(projectImagePath);
      imageFilePath = p.setExtension(imageFilePath, extension);

      await File(projectImagePath).copy(imageFilePath);
    }
    return project;
  }

  static Future<Directory> get projectParentDirectory async {
    return Directory(await projectTargetPath);
  }

  static Future<Iterable<Directory>> projectDirs() async {
    Directory convertPathToDir(String path) => Directory(path);
    Iterable<Directory> getTheSubDirs(Directory dir) =>
        dir.listSync().whereType<Directory>();

    return projectTargetPath.then(convertPathToDir).then(getTheSubDirs);
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
        json[nameKey]?.toString() ?? dirName;

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
    manifestExtendedProperties[nameKey] = name;
  }

  ParrotProject.fromDirectory(Directory dir) : super.fromDirectory(dir) {
    Map<String, dynamic> manifest = manifestJson;
    rename(manifest[nameKey] ?? p.basename(dir.path));
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
    manifestExtendedProperties[nameKey] = name;
    Directory? projectDirOptional =
        projectDirectory ?? await getProjectDir(name);
    if (projectDirectory?.existsSync() ?? false) {
      Directory projectDir =
          projectDirOptional!; //?? false provides null safety
      try {
        String parentPath = p.dirname(projectDir.path);
        projectDir.renameSync(p.join(parentPath, baseName));
      } catch (e) {
        manifestExtendedProperties[nameKey] = originalName;
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

    _setBoardPaths();
    _writeBoards(dir);
    manifest.writeAsStringSync(manifestString);
    return dir.path;
  }

  void _setBoardPaths() {
    Set<String> usedFilePaths = {};
    for (Obf board in boards) {
      String path =
          board.path ?? p.join("boards/", sanitzeFileName(board.name));
      path = determineNoncollidingName(path, usedFilePaths);
      usedFilePaths.add(path);
      path = p.setExtension(path, '.obf');

      board.path = path;
    }
  }

  void _writeBoards(Directory projectDir) async {
    String fullPath(Obf obf) => p.join(projectDir.path, obf.path);
    for (Obf board in boards) {
      String pathToWrite = fullPath(board);
      await board.writeTo(pathToWrite);
    }
  }

  Future<String> get projectPath {
    return projectTargetPath;
  }

  ///returns a Future with a directory object set to the the path of the project, this method does not create that directory, nor does it write a any data to it.
  Future<Directory> get _asDirectory {
    Directory maptToDir(String path) => Directory(path);
    return projectPath
        .then((target) => p.join(target, baseName))
        .then(maptToDir);
  }

  factory ParrotProject.fromObz(Obz obz, String name) {
    return ParrotProject(boards: obz.boards, name: name)
        .parseManifestJson(obz.manifestJson);
  }

  @override
  ParrotProject parseManifestString(String json,
      {bool fullOverride = false, bool updateLinkedBoards = true}) {
    super.parseManifestString(json,
        fullOverride: fullOverride, updateLinkedBoards: updateLinkedBoards);
    return this;
  }

  @override
  ParrotProject parseManifestJson(Map<String, dynamic> manifestJson,
      {bool fullOverride = true, bool updateLinkedBoards = true}) {
    super.parseManifestJson(manifestJson,
        fullOverride: fullOverride, updateLinkedBoards: updateLinkedBoards);
    return this;
  }
}

class ParrotProjectDisplayData extends DisplayData {
  @override
  String name;
  Widget? _image;
  @override
  Widget get image {
    return _image ?? logo;
  }

  @override
  set image(Widget? image) {
    _image = image;
  }

  ParrotProjectDisplayData(this.name, {Widget? image}) : _image = image;
  ParrotProjectDisplayData.fromDir(Directory dir)
      : name = p.basename(dir.path) {
    File? manifest = ParrotProject._getManifestFile(dir);
    if (manifest != null) {
      Map<String, dynamic> json = jsonDecode(manifest.readAsStringSync());
      if (json.containsKey(ParrotProject.nameKey)) {
        name = json[ParrotProject.nameKey];
      }

      if (json.containsKey(ParrotProject.imagePathKey)) {
        String path = dir.path;
        path = p.join(dir.path, json[ParrotProject.imagePathKey]);
        BoxFit fit = BoxFit.contain;
        image = imageFromPath(path, fit: fit);
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
