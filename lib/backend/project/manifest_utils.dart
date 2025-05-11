import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'parrot_project.dart';

File? getManifestFile(Directory dir) {
  return dir
      .listSync()
      .whereType<File>()
      .where((file) => p.basename(file.path) == 'manifest.json')
      .firstOrNull;
}

Map<String, dynamic>? getManifestJson(Directory dir) {
  File? manifest = getManifestFile(dir);
  if (manifest == null) {
    return null;
  }
  return jsonDecode(manifest.readAsStringSync());
}

void setProjectNameInManifest(Directory projectDir, String name) {
  File? manifest = projectDir
      .listSync()
      .whereType<File>()
      .where((f) => p.basename(f.path) == "manifest.json")
      .firstOrNull;
  if (manifest == null) {
    return;
  }
  String content = manifest.readAsStringSync();
  Map<String, dynamic> json = jsonDecode(content);
  json[ParrotProject.nameKey] = name;
  manifest.writeAsStringSync(jsonEncode(json));
}
