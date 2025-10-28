import 'dart:io';

import 'package:parrotaac/backend/quick_store.dart';

const _imagesQuickstoreName = "temp_images";
const _audioQuickstoreName = "temp_audio";

class ProjectTempFileManager {
  final IndexedQuickstore imageQuickstore;
  final IndexedQuickstore audioQuickstore;
  ProjectTempFileManager._(this.imageQuickstore, this.audioQuickstore);
  static Future<ProjectTempFileManager> generateFileManager(
    String projectPath,
  ) async {
    final imageQuickstore = IndexedQuickstore(
      _imagesQuickstoreName,
      path: projectPath,
    );
    final audioQuickstore = IndexedQuickstore(
      _audioQuickstoreName,
      path: projectPath,
    );

    await Future.wait([
      imageQuickstore.initialize(),
      audioQuickstore.initialize(),
    ]);

    return ProjectTempFileManager._(imageQuickstore, audioQuickstore);
  }

  Iterable<File> get images => imageQuickstore
      .getAllData()
      .whereType<String>()
      .map((path) => File(path));

  Iterable<File> get sounds => audioQuickstore
      .getAllData()
      .whereType<String>()
      .map((path) => File(path));

  Future<void> addImage(String path) {
    return imageQuickstore.pushAndWrite(path);
  }

  Future<void> addAudio(String path) {
    return audioQuickstore.pushAndWrite(path);
  }

  Future<void> updateTopImage(String path) async {
    await imageQuickstore.removeTop();
    return addImage(path);
  }

  Future<void> updateTopAudio(String path) async {
    await audioQuickstore.removeTop();
    return addAudio(path);
  }

  Future<void> finalizeTempFiles() async {
    await Future.wait([imageQuickstore.clear(), audioQuickstore.clear()]);
  }
}
