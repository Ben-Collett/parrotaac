import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:parrotaac/backend/project/code_gen_allowed/event/project_events.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/extensions/directory_extensions.dart';
import 'package:parrotaac/extensions/file_extensions.dart';
import 'package:parrotaac/extensions/list_extensions.dart';
import 'package:parrotaac/extensions/map_extensions.dart';
import 'package:parrotaac/extensions/object_extensions.dart';
import 'package:parrotaac/ui/event_handler.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

  ///patchFile should be a path .zip file following the patch format
  static Future<void> applyPatch(
    String patchFilePath,
    ProjectEventHandler handler,
  ) async {
    final patchFile = File(patchFilePath);
    if (!await patchFile.exists()) {
      return;
    }

    final inputStream = InputFileStream(patchFile.path);
    final Archive archive = ZipDecoder().decodeStream(inputStream);

    final tempDir = await getTemporaryDirectory();
    final extractPath = p.join(
      tempDir.path,
      "parrot_patch_tmp_dir_${DateTime.now().microsecondsSinceEpoch}",
    );
    await extractArchiveToDisk(archive, extractPath);
    final patchDir = Directory(extractPath);
    List<FileSystemEntity> patchContent = patchDir.listSync();

    Future fileCopy = _copyAudioAndImageFiles(patchContent, handler.project);
    final List<ProjectEvent> events = await _readActions(patchContent);
    await fileCopy;

    Future<void> patchDeletion = patchDir.delete(recursive: true);

    handler.bulkExecute(events, updateUi: false);
    handler.fullUIUpdate();
    handler.clear();
    await patchDeletion;
  }

  static Future<void> _copyAudioAndImageFiles(
    List<FileSystemEntity> patchContent,
    ParrotProject project,
  ) async {
    final outputImagePath = project.imagePath;
    final outputAudioPath = project.audioPath;
    Directory? patchImages = patchContent
        .findFromName("images")
        ?.safeCast<Directory>();

    Directory? patchAudio = patchContent
        .findFromName("audio")
        ?.safeCast<Directory>();

    final Future<void> copyImages = _copyContents(
      sourceDir: patchImages,
      targetDir: Directory(outputImagePath),
    );

    final Future<void> copyAudio = _copyContents(
      sourceDir: patchAudio,
      targetDir: Directory(outputAudioPath),
    );

    await Future.wait([copyAudio, copyImages]);
  }

  static Future<List<ProjectEvent>> _readActions(
    List<FileSystemEntity> patchDir,
  ) async {
    File? actionFile = patchDir.findFromName("actions")?.safeCast<File>();
    if (actionFile == null) {
      return [];
    }
    List<ProjectEvent> events = [];
    void addEvent(String line) {
      Map<String, dynamic> json = jsonDecode(line);
      ProjectEvent? event = ProjectEvent.decode(json);
      if (event != null) {
        events.add(event);
      }
    }

    await actionFile.forEachLine(addEvent);
    return events;
  }

  static Future<void> _copyContents({
    Directory? sourceDir,
    required Directory targetDir,
  }) async {
    return sourceDir?.copyContentTo(targetDir);
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
