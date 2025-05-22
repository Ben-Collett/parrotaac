import 'package:flutter_test/flutter_test.dart';
import 'package:parrotaac/file_utils.dart';

void main() {
  test('windows path to posix', () {
    String windowsPath = "this\\is\\a\\windows\\path";
    expect(windowsPathToPosix(windowsPath), "this/is/a/windows/path");
  });
}
