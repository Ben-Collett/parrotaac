import 'dart:math';

import 'package:parrotaac/extensions/random_extensions.dart';

final _random = Random();

String generateRandomLetters({Random? random, required int letterCount}) {
  assert(letterCount > 0, "letter count should not be negative or zero");
  random ??= _random;
  String out = "";

  while (letterCount > 0) {
    out += _random.nextLetter();
    letterCount--;
  }
  return out;
}
