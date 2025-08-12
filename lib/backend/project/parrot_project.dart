import 'dart:io';
import 'package:flutter/widgets.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:openboard_wrapper/image_data.dart';
import 'package:openboard_wrapper/obz.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:openboard_wrapper/sound_data.dart';
import 'package:parrotaac/backend/project/board/parrot_board.dart';
import 'package:parrotaac/backend/project/manifest_utils.dart';
import 'package:parrotaac/backend/project/project_settings.dart';
import 'package:parrotaac/backend/project/temp_files.dart';
import 'package:parrotaac/file_utils.dart';
import 'package:parrotaac/utils.dart';
import 'package:path/path.dart' as p;

import 'custom_manifest_keys.dart';
import 'project_interface.dart';
import 'project_utils.dart';

final SvgPicture logo = SvgPicture.asset("assets/images/logo/white_bg.svg");

class ParrotProject extends Obz with AACProject {
  String path;
  ProjectSettings? settings;

  @override
  String Function(String)? get sanatizeFilePathForManifest =>
      (path) => Platform.isWindows ? windowsPathToPosix(path) : path;

  File get manifestFile {
    File file = File(p.join(path, 'manifest.json'));
    file.createSync(recursive: true);
    return file;
  }

  ///only rewrite the boards that have actually updated, can be disabled for testing
  static const bool optimizedSaves = true;
  Set<Obf> boardsThatNeedUpdatedOnWrite = {};

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
      displayImagePath != null ? imageFromPath(displayImagePath!) : logo;
  @override
  String get name {
    return manifestExtendedProperties[nameKey] ??
        p.basenameWithoutExtension(path);
  }

  ParrotProject(
      {super.boards, required String name, required this.path, this.settings})
      : super() {
    manifestExtendedProperties[nameKey] = name;
  }

  ParrotProject.fromDirectory(Directory dir, {this.settings})
      : path = dir.path,
        super.fromDirectory(dir) {
    Map<String, dynamic> manifest = manifestJson;
    manifestExtendedProperties[nameKey] =
        manifest[nameKey] ?? p.basename(dir.path);
  }

  static Future<ParrotProject?> getProject(String projectName) async {
    Directory? dir = await getProjectDir(projectName);
    if (dir == null) {
      return null;
    }
    return ParrotProject.fromDirectory(dir);
  }

  void deleteTempFiles() {
    Directory dir = Directory(tmpImagePath(path));
    if (dir.existsSync()) {
      dir.deleteSync();
    }
    Directory audio = Directory(tmpAudioPath(path));
    if (audio.existsSync()) {
      audio.deleteSync();
    }
  }

  ///maps all the temporary images in projectPath/image/tmp to locations in projectPath/image. Doesn't actually move the files
  Future<Map<String, String>> mapTempImageToPermantSpot() async {
    Map<String, String> out = {};
    String imagesPath = p.join(path, 'images');
    Directory images = Directory(imagesPath);
    if (!images.existsSync()) {
      return {};
    }
    out = mapDirectoryContentToOtherDir(
      inputDir: Directory(
        tmpImagePath(path),
      ),
      outputDir: images,
    );
    return out;
  }

  ///maps all the temporary images in projectPath/audio/tmp to locations in projectPath/image. Doesn't actually move the files
  Future<Map<String, String>> mapTempAudioToPermantSpot() async {
    Map<String, String> out = {};
    String audioPath = p.join(path, 'audio');
    Directory audio = Directory(audioPath);
    if (!audio.existsSync()) {
      return {};
    }
    out = mapDirectoryContentToOtherDir(
      inputDir: Directory(
        tmpAudioPath(path),
      ),
      outputDir: audio,
    );
    return out;
  }

  ///[map] tells the function where to move the old file from to it's new path
  Future<void> moveFiles(
    Map<String, String> map,
  ) async {
    for (MapEntry entry in map.entries) {
      File file = File(entry.key);
      if (file.existsSync()) {
        Directory(p.dirname(entry.value)).createSync(recursive: true);
        file.copySync(entry.value);
        file.deleteSync(recursive: true);
      }
    }
  }

  ///[map] should map the old location to the new location
  void updateImagePathReferencesInProject(Map<String, String> paths) {
    if (paths.isEmpty) {
      return;
    }

    bool pathIsNotNull(ImageData i) => i.path != null;
    for (ImageData image in images.where(pathIsNotNull)) {
      String imageDataPath = p.join(path, image.path);
      if (paths.containsKey(imageDataPath)) {
        image.path = p.relative(paths[imageDataPath]!, from: path);
      }
    }
  }

  void updateAudioPathReferencesInProject(Map<String, String> paths) {
    if (paths.isEmpty) {
      return;
    }

    bool pathIsNotNull(SoundData i) => i.path != null;
    for (SoundData sound in sounds.where(pathIsNotNull)) {
      String imageDataPath = p.join(path, sound.path);
      if (paths.containsKey(imageDataPath)) {
        sound.path = p.relative(paths[imageDataPath]!, from: path);
      }
    }
  }

  ///returns whether or not the rename was successful.
  ///renames the project directory to the new basename, if a  project directory exist
  @override
  Future<bool> rename(String name) async {
    String originalName = name;
    manifestExtendedProperties[nameKey] = name;
    Directory projectDirectory = Directory(path);

    if (projectDirectory.existsSync()) {
      try {
        String parentPath = p.dirname(projectDirectory.path);
        //TODO: i need to update the poroject path and what not
        await projectDirectory.rename(p.join(parentPath, baseName));
      } catch (e) {
        manifestExtendedProperties[nameKey] = originalName;
        return false;
      }
    }

    return true;
  }

  ///this will override any matching files in the directory and leave the other files be
  @override
  Future<String> write() async {
    Directory dir = Directory(path);
    File manifest = manifestFile; // should create dir as well as the manifest
    _setBoardPaths();
    await _writeBoards(dir);
    manifest.writeAsStringSync(manifestString);
    return dir.path;
  }

  void _setBoardPaths() {
    Set<String> usedFilePaths = {};
    for (Obf board in boards) {
      String path =
          board.path ?? p.join("boards/", sanitzeFileName(board.name));

      //technically this also disallows files with the same name in different directories
      path = determineNoncollidingName(path, usedFilePaths);
      usedFilePaths.add(p.basenameWithoutExtension(path));

      path = p.setExtension(path, '.obf');

      board.path = path;
    }
  }

  Future<void> _writeBoards(Directory projectDir) async {
    String fullPath(Obf obf) => p.join(projectDir.path, obf.path);
    for (Obf board in boards) {
      String pathToWrite = fullPath(board);
      await board.writeTo(pathToWrite);
    }
  }

  factory ParrotProject.fromObz(Obz obz, String name, String path) {
    return ParrotProject(boards: obz.boards, name: name, path: path)
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
    if (manifestJson[nameKey] == null) {
      manifestJson[nameKey] = name;
    }
    super.parseManifestJson(manifestJson,
        fullOverride: fullOverride, updateLinkedBoards: updateLinkedBoards);
    return this;
  }
}

class ParrotProjectDisplayData extends DisplayData {
  static const String lastAccessedKey = "ext_last_accessed";
  @override
  String name;
  @override
  DateTime? lastAccessed;
  @override
  String? path;
  Widget? _image;
  @override
  Widget get image {
    return _image ?? logo;
  }

  @override
  set image(Widget? image) {
    _image = image;
  }

  ParrotProjectDisplayData(
    this.name, {
    Widget? image,
    this.path,
    this.lastAccessed,
  }) : _image = image;

  ParrotProjectDisplayData.fromDir(Directory dir)
      : name = p.basename(dir.path) {
    path = dir.path;
    Map<String, dynamic>? manifest = getManifestJson(dir);
    if (manifest == null) {
      return;
    }
    if (manifest.containsKey(nameKey)) {
      name = manifest[nameKey];
    }

    if (manifest.containsKey(lastAccessedKey)) {
      lastAccessed = DateTime.tryParse(manifest[lastAccessedKey]);
    }

    if (manifest.containsKey(imagePathKey)) {
      String imagepath = p.join(dir.path, manifest[imagePathKey]);
      image = imageFromPath(imagepath);
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
