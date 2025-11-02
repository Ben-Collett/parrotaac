import 'dart:io';
import 'package:path/path.dart' as p;

extension PathExtensions on FileSystemEntity {
  String get baseNameWithoutExtension => p.basenameWithoutExtension(path);
  String get baseName => p.basename(path);
  String get extension => p.extension(path);
}
