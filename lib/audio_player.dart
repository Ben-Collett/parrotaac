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
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

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
  ///if running on linux then it won't be prempted on press.
  void playTTS(String toSpeak) async {
    if (Platform.isLinux) {
      Process.run('speak', [toSpeak]);
    } else {
      await stop();
      _tts.speak(toSpeak);
    }
  }
  //TODO: add way to get tts voices and set the current tts

  ///won't stop linux tts
  Future<void> stop() async {
    //TODO: try to find a way to make the linux tts process to be killed on stop.
    if (!Platform.isLinux) {
      await _tts.stop();
    }
    await _audioPlayer.stop();
  }
}
