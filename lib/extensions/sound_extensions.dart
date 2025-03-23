import 'package:openboard_wrapper/sound_data.dart';
import 'package:parrotaac/audio_player.dart';
import 'package:path/path.dart' as p;

extension SoundPlay on SoundData {
  void play({String? rootPath}) {
    if (data != null) {
      PreemptiveAudioPlayer().playFromRawData(data!.data);
    } else if (path != null && rootPath != null) {
      PreemptiveAudioPlayer().playFromPath(p.join(rootPath, path));
    } else if (url != null) {
      PreemptiveAudioPlayer().playFromUrl(url!);
    }
  }
}
