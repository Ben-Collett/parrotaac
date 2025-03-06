//TODO: the test work, even ran in a group, but I get async gaps and missing pluggin warnings when doing so, for now running the test one at a time is the best option until I have time to go back and figure out how to sort out the error.
import 'dart:convert';
import 'dart:io';
import 'package:file/memory.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:openboard_wrapper/obz.dart';
import 'package:path_provider/path_provider.dart';

import 'package:path/path.dart' as p;
import './boards/board_strings.dart';
import './boards/manifest_stings.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parrotaac/parrot_project.dart';
import 'package:parrotaac/parrot_board.dart';

void equalProjectes(Obz b1, Obz b2) {
  Map<String, dynamic> toJson(Obf board) => board.toJson();
  expect(b1.manifestJson, b2.manifestJson);
  expect(b1.boards.map(toJson).toSet(), b2.boards.map(toJson).toSet());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  //TODO: make this in memory so I don't have to delete files. for some reason the below line works but not with trying to list files which I need
  //MemoryFileSystem system = MemoryFileSystem(style: FileSystemStyle.posix);
  Directory targetDir = Directory.systemTemp;
  targetDir.createSync();
  group('parrot board test', () {
    test('simple board write', () async {
      String targetPath = p.join(targetDir.path, "simple.obf");
      Obf board = Obf.fromJsonString(simpleBoard);
      Map<String, dynamic> expected = board.toJson();
      await board.writeTo(targetPath);
      File file = File(targetPath);
      Map<String, dynamic> actual = Obf.fromFile(file).toJson();
      file.deleteSync(); //TODO: maybe I can use setup and tearDown or something like that to handle this.
      expect(actual, expected);
    });
    test('test import board', () async {
      //TODO: find a way to get ride of this repeated code
      String targetPath = p.join(targetDir.path, "simple2.obf");
      Obf board = Obf.fromJsonString(simpleBoard);
      board.path = "boards/simple2.obf";
      ParrotProject expectedBoard =
          ParrotProject.fromObz(board.toSimpleObz(), "simple2");
      await board.writeTo(targetPath);
      File simpleFile = File(targetPath);
      String importTargetPath = p.join(targetDir.path, "import_dir");
      await ParrotProject.importFromObfFile(simpleFile,
          outputPath: importTargetPath);

      Directory dir = Directory(importTargetPath);
      Obz fromDir = Obz.fromDirectory(dir);
      ParrotProject actualBoard = ParrotProject.fromObz(fromDir, "simple2");

      equalProjectes(actualBoard, expectedBoard);

      dir.deleteSync(recursive: true);
      simpleFile.deleteSync();
    });
  });
  group('ParrotProject Tests', () {
    test('write and read simple', () async {
      final archivePath = p.join(targetDir.path, "test_archive.zip");
      final projectTargetPath = p.join(targetDir.path, "simple_project/");
      final Archive archive = Archive();

      ArchiveFile file = ArchiveFile.string("simple.obf", simpleBoard);

      ArchiveFile manifest =
          ArchiveFile.string("manifest.json", simpleManifestString);

      archive.add(file);
      archive.add(manifest);

      File(archivePath).writeAsBytesSync(ZipEncoder().encode(archive));

      await ParrotProject.importArchiveFromPath(archivePath,
          outputPath: projectTargetPath);

      Obf simpleObf = Obf.fromJsonString(simpleBoard);
      ParrotProject expected = ParrotProject(name: "simp", boards: [simpleObf])
          .parseManifestString(simpleManifestString);
      ParrotProject actual =
          ParrotProject.fromDirectory(Directory(projectTargetPath));

      equalProjectes(actual, expected);

      File(archivePath).deleteSync();
      Directory(projectTargetPath).deleteSync(recursive: true);
    });
  });

  test('rename no dir', () async {
    ParrotProject simpleProject = await makeSimpleProjectObject('samp');
    String name = 'name';
    await simpleProject.rename(name, projectDirectory: Directory("bull"));
    expect(simpleProject.name, name);
  });
  test('rename with dir', () async {
    String originalName = 'simp';
    String path = p.join(targetDir.path, originalName);
    ParrotProject simpleProject = await writeSimpleProject(path);
    Directory dir = Directory(path);
    String name = 'name';
    await simpleProject.rename(name, projectDirectory: dir);
    String newPath = p.join(targetDir.path, name);
    expect(simpleProject.name, name);
    Directory(newPath).deleteSync(recursive: true);
  });
  test('basename', () {
    String expectedBaseName = "hello world!";
    String name = "hell*o\\ wor/ld!";
    ParrotProject project = ParrotProject(name: name);
    expect(project.baseName, expectedBaseName);
  });
  test('get display data', () async {
    String name = 'somp';
    String path = p.join(targetDir.path, name);
    ParrotProject simpleProject = await writeSimpleProject(path);
    Directory dir = Directory(path);

    var expected = ParrotProjectDisplayData(name);

    expect(ParrotProjectDisplayData.fromDirectory(dir), expected);

    dir.deleteSync(recursive: true);
  });
}

Future<ParrotProject> writeSimpleProject(String path) async {
  ParrotProject out = await makeSimpleProjectObject(path);
  Map<String, dynamic> json = jsonDecode(simpleManifestString);
  json['ext_name'] = p.basename(path); //TODO: find a way to not hard code name
  await out.parseManifestJson(json).write(path: path);
  return out;
}

Future<ParrotProject> makeSimpleProjectObject(String path) async {
  List<Obf> boards = [Obf.fromJsonString(simpleBoard)];
  ParrotProject out = ParrotProject(name: p.basename(path), boards: boards);
  return out;
}
