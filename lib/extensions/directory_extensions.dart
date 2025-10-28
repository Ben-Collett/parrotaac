import 'dart:io';

extension ToListFuture on Directory {
  Future<List<FileSystemEntity>> toListFuture({
    bool recursive = false,
    bool followLinks = true,
  }) {
    return exists().then(
      (exist) => exist
          ? list(recursive: recursive, followLinks: followLinks).toList()
          : [],
    );
  }
}
