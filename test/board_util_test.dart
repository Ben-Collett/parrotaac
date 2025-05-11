import 'package:flutter_test/flutter_test.dart';
import 'package:parrotaac/file_utils.dart';

void main() {
  test('test determine name', () {
    List<String> dirs = ['this', 'this_1', 'is'];
    expect('this_2', determineNoncollidingName('this', dirs));
    expect('bye', determineNoncollidingName('bye', dirs));
    expect('is_1', determineNoncollidingName('is', dirs));
  });
}
