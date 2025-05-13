import "package:flutter/material.dart";
import "package:parrotaac/file_utils.dart";

mixin AACProject {
  String get name;

  ///generally should be an Image or an svg object but can technically be any widget
  Widget get displayImage;

  String get baseName {
    return sanitzeFileName(name);
  }

  //TODO: I can in the future add an overrde enum, and allow for a safe override if the checksum of the original files is the same as it is now
  ///returns the path wrote to
  Future<String> write({String? path});

  ///this method when overridden should always override displayData.name
  Future<bool> rename(String name);
  void renameToNonCollidingName(List<String> names) {
    rename(determineNoncollidingName(name, names));
  }
}

abstract class DisplayData {
  String get name;
  Widget get image;
  String? get path;
  DateTime? get lastAccessed;
  set image(Widget toDisplay);
}
