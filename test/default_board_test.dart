import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:parrotaac/backend/project/custom_manifest_keys.dart';
import 'package:parrotaac/default_board_strings.dart';

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
    clone[nameKey] = 'cool name';
    expect(clone, jsonDecode(defaultManifest(name: 'cool name')));
  });
  test('image path manifest', () {
    Map<String, dynamic> clone = Map.of(defaultManifestJson);
    clone[imagePathKey] = 'path';
    expect(clone, jsonDecode(defaultManifest(imagePath: 'path')));
  });
  test('last accessed manifest', () {
    Map<String, dynamic> clone = Map.of(defaultManifestJson);
    DateTime now = DateTime.now();
    clone[lastAccessedKey] = now.toString();
    expect(clone, jsonDecode(defaultManifest(lastAccessed: now)));
  });

  test('full default manifest', () {
    Map<String, dynamic> clone = Map.of(defaultManifestJson);
    DateTime now = DateTime.now();

    clone[nameKey] = 'cool name';
    clone[imagePathKey] = 'path';
    clone[lastAccessedKey] = now.toString();
    expect(
      clone,
      jsonDecode(
        defaultManifest(
          name: 'cool name',
          imagePath: 'path',
          lastAccessed: now,
        ),
      ),
    );
  });
}
