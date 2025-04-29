import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

//TODO: this function needs improved, I could use an exeteranl dependacny,like legalize, however everything I can find is under LGPL so I would need to learn about licensing for that. I could probably just use there regexes.
String sanitzeFileName(String name) {
  const invalidChars = r'[\\/:*?"<>|]';
  return name.replaceAll(RegExp(invalidChars), "");
}

String determineNoncollidingName(String inputPath, Iterable<String> dirNames) {
  final String extension = p.extension(inputPath);
  final String dirName = p.dirname(inputPath);
  String fileName = p.basenameWithoutExtension(inputPath);
  while (dirNames.contains(fileName)) {
    fileName = _incrementName(fileName);
  }
  String out = p.setExtension(fileName, extension);
  if (dirName != '.') {
    out = p.join(dirName, out);
  }
  return out;
}

///increments based on the following pattern [name] -> [name]_1, [name]_n -> [name]_{n+1}
String _incrementName(String name) {
  final regex = RegExp(r'_(\d+)$'); // Pattern to match _<number> at the end
  final match = regex.firstMatch(name);

  if (match != null) {
    final String baseNameWithoutNumber = name.substring(0, match.start);
    final number = int.parse(match.group(1)!);
    return "${baseNameWithoutNumber}_${number + 1}";
  } else {
    return '${name}_1';
  }
}

///WARNING: I highly recommend calling from an async context do to the amounts of IO
Future<void> writeDirectoryAsObz({
  required String sourceDirPath,
  required String outputDirPath,
}) async {
  final inputDir = Directory(sourceDirPath);
  if (!await inputDir.exists()) {
    throw Exception('Input directory does not exist: $sourceDirPath');
  }

  final dirName = p.basename(inputDir.path);
  final outputFileName = '$dirName.obz';

  final outputFilePath = p.join(outputDirPath, outputFileName);

  await Directory(outputDirPath).create(recursive: true);

  //Zip the directory and write to .obz file
  final encoder = ZipFileEncoder();
  encoder.create(outputFilePath);
  for (FileSystemEntity f in Directory(sourceDirPath).listSync()) {
    if (f is File) {
      await encoder.addFile(f);
    } else if (f is Directory) {
      await encoder.addDirectory(f);
    }
  }
  await encoder.close();
}
