import 'dart:io';

import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/simple_logger.dart';
import 'package:parrotaac/extensions/directory_extensions.dart';
import 'package:path/path.dart' as p;

class FileCleanupData {
  final Set<String> referencedImages;
  final Set<String> referencedAudio;
  final Set<String> actualAudio;
  final Set<String> actualImages;

  FileCleanupData._({
    required this.actualImages,
    required this.actualAudio,
    required this.referencedImages,
    required this.referencedAudio,
  });

  static Future<FileCleanupData> fromProject(ParrotProject project) async {
    String toPath(File file) => file.path;
    Set<String> mapToFilePathsSet(List<FileSystemEntity> entities) =>
        entities.whereType<File>().map(toPath).toSet();

    Future<Set<String>> actualImages = Directory(
      project.imagePath,
    ).toListFuture().then(mapToFilePathsSet);
    Future<Set<String>> actualAudio = Directory(
      project.audioPath,
    ).toListFuture().then(mapToFilePathsSet);

    Set<String> referencedImages = project.images
        .map((img) => p.join(project.path, img.path))
        .nonNulls
        .toSet();
    Set<String> referencedAudio = project.sounds
        .map((img) => p.join(project.path, img.path))
        .nonNulls
        .toSet();

    return FileCleanupData._(
      actualImages: await actualImages,
      actualAudio: await actualAudio,
      referencedImages: referencedImages,
      referencedAudio: referencedAudio,
    );
  }

  Future<void> cleanUp() async {
    await Future.wait([_cleanUpImages(), _cleanUpAudio()]);
  }

  Future<void> _cleanUpImages() {
    return _cleanUpFiles(actualImages, referencedImages);
  }

  Future<void> _cleanUpAudio() {
    return _cleanUpFiles(actualAudio, referencedAudio);
  }

  Future<void> _cleanUpFiles(Set<String> actual, Set<String> referenced) async {
    Set<String> unrefrenced = actual.difference(referenced);
    Iterable<Future> futures = unrefrenced.map(_delete);
    await Future.wait(futures);
  }

  Future<void> _delete(String path) async {
    try {
      await File(path).delete();
    } catch (_) {}
  }
}
