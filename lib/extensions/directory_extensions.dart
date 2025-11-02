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

extension DirectoryCopyExtension on Directory {
  /// Copies the *contents* of this directory into [target].
  /// Does not copy the directory itself, only its files and subdirectories.
  Future<void> copyContentTo(Directory target) async {
    if (!await target.exists()) {
      await target.create(recursive: true);
    }

    await for (final entity in list(recursive: false)) {
      final newPath = '${target.path}/${entity.uri.pathSegments.last}';
      if (entity is File) {
        await entity.copy(newPath);
      } else if (entity is Directory) {
        await Directory(newPath).create(recursive: true);
        await entity.copyContentTo(Directory(newPath));
      }
    }
  }
}
