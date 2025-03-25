import 'package:parrotaac/parrot_board.dart';
import 'package:parrotaac/parrot_project.dart';

const defaultRootObf =
    '{"id":"root","format":"open-board-0.1","locale":"en","name":"root","buttons":[],"grid":{"rows":0,"columns":0,"order":[]},"images":[],"sounds":[]}';

String defaultManifest({String? name, String? imagePath}) {
  String out =
      '{"root":"boards/root.obf","format":"open-board-0.1","paths":{"boards":{"root":"boards/root.obf"}}';
  if (name != null) {
    out = '$out,"${ParrotProject.nameKey}":"$name"';
  }
  if (imagePath != null) {
    out = '$out,"${ParrotProject.imagePathKey}":"$imagePath"';
  }

  return "$out}";
}
