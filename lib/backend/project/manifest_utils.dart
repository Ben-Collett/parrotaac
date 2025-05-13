import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'custom_manifest_keys.dart';

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
  updateManifestProperty(project: projectDir, key: nameKey, value: name);
}

void updateAccessedTimeInManifest(Directory dir, {DateTime? time}) {
  DateTime newTime = time ?? DateTime.now();
  updateManifestProperty(
      project: dir, key: lastAccessedKey, value: newTime.toString());
}

void updateManifestProperty({
  required Directory project,
  required String key,
  required dynamic value,
}) {
  File? manifest = getManifestFile(project);
  if (manifest == null) {
    return;
  }
  String content = manifest.readAsStringSync();
  Map<String, dynamic> json = jsonDecode(content);
  json[key] = value;
  manifest.writeAsStringSync(jsonEncode(json));
}
