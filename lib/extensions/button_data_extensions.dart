import 'package:openboard_wrapper/button_data.dart';
import 'package:parrotaac/audio/audio_source.dart';
import 'package:parrotaac/extensions/sound_extensions.dart';

extension ButtonDataExtension on ButtonData {
  AudioSource getSource({String? projectPath}) {
    return sound?.getAudioSource(rootPath: projectPath) ??
        TTSSource(voclization ?? label ?? "");
  }
}
