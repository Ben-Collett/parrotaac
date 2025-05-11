import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parrotaac/backend/project/project_utils.dart';

final projectDirProvider = FutureProvider((ref) async => projectDirs());
