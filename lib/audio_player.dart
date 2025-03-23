import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

///singleton
///using any of the play methods will stop already playing sounds
class PreemptiveAudioPlayer {
  PreemptiveAudioPlayer._privateConstructor();
  static final PreemptiveAudioPlayer _internal =
      PreemptiveAudioPlayer._privateConstructor();
  factory PreemptiveAudioPlayer() => _internal;
  final _LinuxSupportingTts _tts = _LinuxSupportingTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  void playFromRawData(String raw) async {
    await stop();
    _audioPlayer.play(BytesSource(Utf8Encoder().convert(raw)));
  }

  void playFromPath(String path) async {
    await stop();
    _audioPlayer.play(DeviceFileSource(path));
  }

  ///example usage: PreemptiveAudioPlayer().playFromUrl('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3');
  void playFromUrl(String url) async {
    await stop();
    _audioPlayer.play(UrlSource(url));
  }

  ///if you are running on linux you need to have "speak" as a command to play audio
  void playTTS(String toSpeak) async {
    if (toSpeak == '') {
      return;
    }
    await stop();
    _tts.speak(toSpeak);
  }
  //TODO: add way to get tts voices and set the current tts

  ///won't stop linux tts
  Future<void> stop() async {
    await _tts.stop();
    await _audioPlayer.stop();
  }
}

class _LinuxSupportingTts {
  final FlutterTts _tts = FlutterTts();
  Process? linuxTtsProcess;
  void speak(String toSpeak) async {
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
}
