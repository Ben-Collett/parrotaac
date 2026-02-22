import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:parrotaac/audio/audio_source.dart';
import 'package:parrotaac/backend/simple_logger.dart';
import 'package:parrotaac/extensions/null_extensions.dart';
import 'package:synchronized/synchronized.dart';

///singleton
///using any of the play methods will stop already playing sounds
class PreemptiveAudioPlayer {
  PreemptiveAudioPlayer._privateConstructor();
  static final PreemptiveAudioPlayer _internal =
      PreemptiveAudioPlayer._privateConstructor();
  factory PreemptiveAudioPlayer() => _internal;
  final _LinuxSupportingTts _tts = _LinuxSupportingTts();
  Future<List<TTSVoice>> get ttsVoices => _tts.voices;

  final AudioPlayer _audioPlayer = AudioPlayer();

  ///stop count is limited to _maxStopCount and if it's passed then _stopCount will be modded, 10_000 is an arbitrary choice but should be more then enough.
  static const int _maxStopCount = 10_000;

  ///used for synchronization by playIterable to make sure the method stops when it's supposed to
  int _stopCount = 0;
  //note: similar  functionality to the lines above could be achieved using a time stamp but there is no real advantage to that
  final Lock _stopCountLock = Lock();

  Future<void> initialize() {
    return _tts.initialize();
  }

  static Future<Duration> getDuration(AudioSource source) async {
    final Source? audioSource = _getSource(source);
    assert(
      audioSource.isNotNull,
      "cant get duration from this kind of source $source",
    );
    AudioPlayer temp = AudioPlayer();
    await temp.setSource(audioSource!);
    Duration? duration = await temp.getDuration();
    if (duration.isNull) {
      SimpleLogger().logError("null duration somehow $audioSource");
    }

    return duration!;
  }

  void playIterable(Iterable<AudioSource> sources) async {
    List<AudioSource> sourcesCopy = List.from(sources);
    await stop();
    int stopCount = 0;
    await _stopCountLock.synchronized(() {
      stopCount = _stopCount;
    });
    for (AudioSource source in sourcesCopy) {
      //if the [_stopCount] has been updated since the call to this function then escape the loop and terminate the async function
      bool cancel = stopCount != _stopCount;
      if (cancel) {
        break;
      }
      await _play(source);
      await audioPlayerPlayingCompleted();
    }
  }

  void _incrementStopCount() {
    _stopCount = (_stopCount + 1) % _maxStopCount;
  }

  Future<void> play(AudioSource source) async {
    await stop();
    await _play(source);
  }

  Future<void> _play(AudioSource source) async {
    if (source is TTSSource) {
      await _tts.speak(source.value);
    }
    Source? audioSource = _getSource(source);
    if (audioSource != null) {
      await _audioPlayer.play(audioSource);
    }
  }

  static Source? _getSource(AudioSource source) {
    if (source is AudioFilePathSource) {
      return DeviceFileSource(source.path);
    } else if (source is AudioUrlSource) {
      return UrlSource(source.url);
    } else if (source is AudioByteSource) {
      return BytesSource(source.data);
    }
    return null;
  }

  Future<void> audioPlayerPlayingCompleted() async {
    Duration? totalDuration = await _audioPlayer.getDuration();
    Duration? currentPosition = await _audioPlayer.getCurrentPosition();

    if (totalDuration != null && currentPosition != null) {
      Duration delay = totalDuration - currentPosition;
      await Future.delayed(delay);
    }
  }

  Future<void> stop() async {
    await _stopCountLock.synchronized(() async {
      _incrementStopCount();
      await _tts.stop();
      await _audioPlayer.stop();
    });
  }
}

class _LinuxSupportingTts {
  final FlutterTts _tts = FlutterTts();
  Process? linuxTtsProcess;
  bool initialized = false;
  Future<void> initialize() async {
    if (!Platform.isLinux) {
      await _tts.awaitSpeakCompletion(true);
    }
    initialized = true;
  }

  ///returns a future when the tts speaking finishes
  Future<void> speak(String toSpeak) async {
    assert(initialized, "non initialized speak call");
    if (Platform.isLinux) {
      linuxTtsProcess = await Process.start("speak", [toSpeak]);
      await linuxTtsProcess?.exitCode;
    } else {
      await _tts.speak(toSpeak);
    }
  }

  Future<List<TTSVoice>> get voices async {
    if (Platform.isLinux || Platform.isWindows || Platform.isFuchsia) {
      return [
        TTSVoice.fromMap({"name": "System"}),
      ];
    }
    //TODO: need to test on android and ios and macos
    dynamic voices = await _tts.getVoices;
    List<Map> voicesList = voices as List<Map>;
    return voicesList.map(TTSVoice.fromMap).toList();
  }

  Future<void> stop() async {
    if (Platform.isLinux) {
      linuxTtsProcess?.kill();
    } else {
      await _tts.stop();
    }
  }
}

class TTSVoice {
  final Map _asMap;
  String get name => _asMap["name"];
  String? get locale => _asMap["locale"];
  TTSVoice.fromMap(Map map) : _asMap = map;
}
