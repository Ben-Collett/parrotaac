import 'package:path/path.dart' as p;

//TODO: this function needs improved, I could use an exeteranl dependacny,like legalize, however everything I can find is under LGPL so I would need to learn about licensing for that. I could probably just use there regexes.
String sanitzeFileName(String name) {
  const invalidChars = r'[\\/:*?"<>|]';
  return name.replaceAll(RegExp(invalidChars), "");
}

String determineNoncollidingName(String inputPath, Iterable<String> dirNames) {
  String fileName = p.basenameWithoutExtension(inputPath);
  while (dirNames.contains(fileName)) {
    fileName = _incrementName(fileName);
  }
  return fileName;
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
