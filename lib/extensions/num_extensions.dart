extension ConditionIncDec on int {
  int decrementedIf(bool condition) {
    if (condition) {
      return this - 1;
    }
    return this;
  }

  int incrementedIf(bool condition) {
    if (condition) {
      this + 1;
    }
    return this;
  }
}

extension NumExtensions on num {
  bool exclusiveIsInBetween(num lower, num upper) {
    return this > lower && this < upper;
  }
}
