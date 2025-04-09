import 'package:openboard_wrapper/sound_data.dart';
import 'package:parrotaac/audio/audio_source.dart';
import 'package:path/path.dart' as p;

extension SoundPlay on SoundData {
  AudioSource? getAudioSource({String? rootPath}) {
    AudioSource? out;
    if (data != null) {
      out = AudioByteSource.fromString(data!.data);
    } else if (path != null && rootPath != null) {
      out = AudioFilePathSource(p.join(rootPath, path));
    } else if (url != null) {
      out = AudioUrlSource(url!);
    }
    return out;
  }
}
