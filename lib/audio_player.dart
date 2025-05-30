import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:parrotaac/audio/audio_source.dart';
import 'package:synchronized/synchronized.dart';

///singleton
///using any of the play methods will stop already playing sounds
class PreemptiveAudioPlayer {
  PreemptiveAudioPlayer._privateConstructor();
  static final PreemptiveAudioPlayer _internal =
      PreemptiveAudioPlayer._privateConstructor();
  factory PreemptiveAudioPlayer() => _internal;
  final _LinuxSupportingTts _tts = _LinuxSupportingTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  ///stop count is limited to _maxStopCount and if it's passed then _stopCount will be modded, 10_000 is an arbitrary choice but should be more then enough.
  static const int _maxStopCount = 10_000;

  ///used for synchronization by playIterable to make sure the method stops when it's supposed to
  int _stopCount = 0;
  //note: similar  functionality to the lines above could be achieved using a time stamp but there is no real advantage to that
  final Lock _stopCountLock = Lock();

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
      await playingCompleted();
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
    } else if (source is AudioFilePathSource) {
      await _audioPlayer.play(DeviceFileSource(source.path));
    } else if (source is AudioUrlSource) {
      await _audioPlayer.play(UrlSource(source.url));
    } else if (source is AudioByteSource) {
      await _audioPlayer.play(BytesSource(source.data));
    }
  }

  void playFromRawData(String raw) async {
    await stop();
    _audioPlayer.play(BytesSource(Utf8Encoder().convert(raw)));
  }

  Future<void> playingCompleted() async {
    await _tts.awaitFinishTTS();
    Duration? totalDuration = await _audioPlayer.getDuration();
    Duration? currentPosition = await _audioPlayer.getCurrentPosition();

    if (totalDuration != null && currentPosition != null) {
      Duration delay = totalDuration - currentPosition;
      await Future.delayed(delay);
    }
  }

  Future<void> stop() async {
    await _stopCountLock.synchronized(
      () async {
        _incrementStopCount();
        await _tts.stop();
        await _audioPlayer.stop();
      },
    );
  }
}

class _LinuxSupportingTts {
  final FlutterTts _tts = FlutterTts();
  Process? linuxTtsProcess;
  Future<void> speak(String toSpeak) async {
    if (Platform.isLinux) {
      linuxTtsProcess = await Process.start("speak", [toSpeak]);
    } else {
      _tts.speak(toSpeak);
    }
  }

  Future<void> stop() async {
    if (Platform.isLinux) {
      linuxTtsProcess?.kill();
    } else {
      await _tts.stop();
    }
  }

  Future<void> awaitFinishTTS() async {
    if (Platform.isLinux) {
      await linuxTtsProcess?.exitCode;
    } else {
      await _tts.awaitSpeakCompletion(true);
    }
  }
}
