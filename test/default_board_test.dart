import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:parrotaac/default_board_strings.dart';
import 'package:parrotaac/parrot_project.dart';

void main() {
  const Map<String, dynamic> defaultManifestJson = {
    "root": "boards/root.obf",
    "format": "open-board-0.1",
    "paths": {
      "boards": {
        "root": "boards/root.obf",
      }
    }
  };
  test('nonAdded manifest', () {
    expect(defaultManifestJson, jsonDecode(defaultManifest()));
  });
  test('project name manifest ', () {
    Map<String, dynamic> clone = Map.of(defaultManifestJson);
    clone[ParrotProject.nameKey] = 'cool name';
    expect(clone, jsonDecode(defaultManifest(name: 'cool name')));
  });
  test('image path manifest', () {
    Map<String, dynamic> clone = Map.of(defaultManifestJson);
    clone[ParrotProject.imagePathKey] = 'path';
    expect(clone, jsonDecode(defaultManifest(imagePath: 'path')));
  });
  test('full default manifest', () {
    Map<String, dynamic> clone = Map.of(defaultManifestJson);
    clone[ParrotProject.nameKey] = 'cool name';
    clone[ParrotProject.imagePathKey] = 'path';
    expect(
      clone,
      jsonDecode(
        defaultManifest(name: 'cool name', imagePath: 'path'),
      ),
    );
  });
}
