import 'dart:io';

import 'package:openboard_wrapper/obf.dart';

extension ParrotBoard on Obf {
  ///Requires you to include the file name in the path, you should also ensure the extension is .obf
  Future<void> writeTo(String path) async {
    final File file = File(path);
    Future<File> writeToFile(File file) => file.writeAsString(toJsonString());
    await file.create(recursive: true).then(writeToFile);
  }

  ///does not handle name collisions
  Obf rename(String name) {
    this.name = name;
    return this;
  }
}
