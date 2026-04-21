Set<T> mergeToSet<T>(Iterable<Iterable<T>> iter) {
  final Set<T> out = {};

  for (final toAdd in iter) {
    out.addAll(toAdd);
  }
  return out;
}
