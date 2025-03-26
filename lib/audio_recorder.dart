import 'dart:io';
import 'package:record/record.dart';
import 'package:path/path.dart' as p;

//TODO: implement an is recording getter, possibly using pgrep for linux
//TODO: tested on linux and windows, needs tested on mac, ios and android. Can't be tested in android emulator
///singleton
class MyAudioRecorder {
  final _LinuxSupportingRecorder _recorder = _LinuxSupportingRecorder();

  MyAudioRecorder._privateConstructor();
  static final MyAudioRecorder _internal =
      MyAudioRecorder._privateConstructor();
  factory MyAudioRecorder() => _internal;

  /// linux will automatically switch to a wav format as this recorder supports no other format for linux, do to me not wanting to learn more about arecord
  void start({
    required Directory parentDirectory,
    required String fileName,
    String extension = '.wav',
    RecordConfig config = const RecordConfig(encoder: AudioEncoder.wav),
  }) async {
    if (await _recorder.hasPermission()) {
      fileName = p.setExtension(fileName, extension);
      _recorder.start(parentDirectory, fileName, config: config);
    }
  }

  void stop() async {
    _recorder.stop();
  }
}

class _LinuxSupportingRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  Process? recordProcess;

  ///if on linux the file format will automatically be set to a wav
  void start(
    Directory parentDirectory,
    String fileNameWithExtension, {
    required RecordConfig config,
  }) async {
    await stop();
    String path = p.join(parentDirectory.path, fileNameWithExtension);
    if (Platform.isLinux) {
      p.setExtension(fileNameWithExtension, '.wav');
      recordProcess =
          await Process.start("arecord", ['-f', 'cd', '-t', 'wav', path]);
    } else {
      _recorder.start(config, path: path);
    }
  }

  Future<void> stop() async {
    if (Platform.isLinux) {
      recordProcess?.kill(ProcessSignal.sigint);
    } else {
      await _recorder.stop();
    }
  }

  Future<bool> hasPermission() {
    if (Platform.isLinux) {
      return Future(() => true);
    }
    return _recorder.hasPermission();
  }
}
