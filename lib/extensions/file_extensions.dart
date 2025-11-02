import 'dart:convert';
import 'dart:io';

extension ProcessLine on File {
  Future<void> forEachLine(Function(String) processLine) async {
    await for (final line
        in openRead().transform(utf8.decoder).transform(const LineSplitter())) {
      processLine(line);
    }
  }
}
