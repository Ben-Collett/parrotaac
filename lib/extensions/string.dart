extension StringExtensions on String {
  bool get isInt {
    if (isEmpty) return false;
    final number = num.tryParse(this);
    return number != null;
  }
}
