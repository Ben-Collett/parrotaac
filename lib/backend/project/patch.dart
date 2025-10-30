import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:parrotaac/backend/project/code_gen_allowed/event/project_events.dart';
import 'package:parrotaac/backend/simple_logger.dart';
import 'package:parrotaac/extensions/map_extensions.dart';
import 'package:parrotaac/ui/event_handler.dart';
import 'package:path/path.dart' as p;

class Patch {
  final Map<String, int> newImages = {};
  final Map<String, int> newAudio = {};
  final List<ProjectEvent> actions;

  Patch({required this.actions});
  Future<void> _addImages(ZipFileEncoder encoder) async {
    List<Future> futures = [];
    final newImages = this.newImages.keys;
    for (final imagePath in newImages) {
      futures.add(
        encoder.addFile(File(imagePath), 'images/${p.basename(imagePath)}'),
      );
    }

    await Future.wait(futures);
  }

  void addImageFile(String path) {
    newImages.increment(path);
  }

  void addAudioFile(String path) {
    newAudio.increment(path);
  }

  void removeAudioFile(String path) {
    newAudio.decrement(path);
    newAudio.removeKeyIfBelowThreshold(key: path, threshold: 1);
  }

  void removeImageFile(String path) {
    newImages.decrement(path);
    newImages.removeKeyIfBelowThreshold(key: path, threshold: 1);
  }

  void addAction(ProjectEvent action) {
    actions.add(action);
  }

  void clear() {
    newImages.clear();
    newAudio.clear();
    actions.clear();
  }

  Future<void> _addAudio(ZipFileEncoder encoder) async {
    List<Future> futures = [];

    final newAudio = this.newAudio.keys;
    for (final audio in newAudio) {
      futures.add(encoder.addFile(File(audio), 'audio/${p.basename(audio)}'));
    }

    await Future.wait(futures);
  }

  Future<void> _addActions(ZipFileEncoder encoder) async {
    final tmpActions = File(
      '${Directory.systemTemp.path}/actions_${DateTime.now().microsecondsSinceEpoch}.jsonl',
    );
    final sink = tmpActions.openWrite();
    for (final action in actions) {
      sink.writeln(jsonEncode(action.encode()));
    }
    await sink.close();
    await encoder.addFile(tmpActions, 'actions.jsonl');
    await tmpActions.delete();
  }

  Future<void> apply(ProjectEventHandler handler) {
    throw UnimplementedError();
  }

  static Patch fromZip(File file) {
    throw UnimplementedError();
  }

  //TODO: track version
  /// Writes a Zip version of the patch using the following structure:
  ///   - actions.jsonl
  ///   - images/[image files]
  ///   - audio/[audio files]
  ///the zip file is returned
  ///[mapPaths] will change a file's writing path in the jsonl file
  Future<File> writeZip(
    String outputPath, {
    Map<String, String>? mapPaths,
  }) async {
    final encoder = ZipFileEncoder();
    encoder.create(outputPath);

    try {
      await Future.wait([
        _addActions(encoder),
        _addAudio(encoder),
        _addImages(encoder),
      ]);
    } finally {
      // Finish writing
      encoder.close();
    }

    return File(outputPath);
  }
}
