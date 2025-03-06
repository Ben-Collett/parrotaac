import "package:parrotaac/file_utils.dart";

mixin AACProject {
  String get name;
  set name(String name) {
    rename(name);
  }

  String get baseName {
    return sanitzeFileName(name);
  }

  //TODO: I can in the future add an overrde enum, and allow for a safe override if the checksum of the original files is the same as it is now
  ///returns the path wrote to
  Future<String> write({String? path});
  Future<bool> rename(String name);
  void renameToNonCollidingName(List<String> names) {
    rename(determineNoncollidingName(name, names));
  }
}
