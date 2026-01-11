import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

mixin CustomCacheManager {
  Future<File> getSingleFile(String url, {String? key});
}

class MyDefaultCacheManager implements CustomCacheManager {
  static MyDefaultCacheManager? _instance;
  MyDefaultCacheManager._();
  factory MyDefaultCacheManager() {
    _instance ??= MyDefaultCacheManager._();
    return _instance!;
  }

  @override
  Future<File> getSingleFile(String url, {String? key}) =>
      DefaultCacheManager().getSingleFile(url, key: key);
}
