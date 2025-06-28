import 'package:flutter_test/flutter_test.dart';
import 'package:parrotaac/extensions/map_extensions.dart';

void main() {
  test('flat simple case', () {
    const m1 = {'a': 1, 'b': 2, 'c': 3};
    const m2 = {'a': 2, 'b': 2};
    final diff = m1.valuesThatAreDifferent(m2);
    const expected = {'a': 2, 'c': null};
    expect(diff, expected);
  });
  test("empty", () {
    const Map<String, dynamic> d1 = {};
    expect(d1.valuesThatAreDifferent(d1), {});
  });
  test("identical", () {
    const m1 = {
      'a': 1,
      'b': {'x': 10, 'y': 20},
      'c': 3,
    };
    expect(m1.valuesThatAreDifferent(m1), {});
  });
  test('recursive test', () {
    const m1 = {
      'a': 1,
      'b': {'x': 10, 'y': 20},
      'c': 3,
    };

    const m2 = {
      'a': 1, // same
      'b': {'x': 10, 'y': 99}, // y is different
      'd': 4, // only in m2
    };

    final diff = m1.valuesThatAreDifferent(m2);
    const expected = {
      'b': {'y': 99},
      'c': null,
      'd': 4,
    };
    return expect(diff, equals(expected));
  });

  test('Map difference with three levels of nesting', () {
    final m1 = {
      'level1': {
        'level2a': {
          'level3a': 1,
          'level3b': 2,
        },
        'level2b': {
          'level3c': 3,
        }
      },
      'rootKey': 'rootValue1',
    };

    final m2 = {
      'level1': {
        'level2a': {
          'level3a': 1, // same
          'level3b': 99, // changed
          'level3x': 42, // new
        },
        'level2b': {
          // level3c removed
          'level3d': 4, // new
        },
      },
      'rootKey': 'rootValue2', // changed
      'newRootKey': 'added', // new
    };

    final expectedDiff = {
      'level1': {
        'level2a': {
          'level3b': 99,
          'level3x': 42,
        },
        'level2b': {
          'level3c': null,
          'level3d': 4,
        },
      },
      'rootKey': 'rootValue2',
      'newRootKey': 'added',
    };

    final diff = m1.valuesThatAreDifferent(m2);

    expect(diff, equals(expectedDiff));
  });
}
