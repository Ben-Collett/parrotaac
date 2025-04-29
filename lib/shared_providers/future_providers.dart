import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../parrot_project.dart';

final projectDirProvider =
    FutureProvider((ref) async => ParrotProject.projectDirs());
