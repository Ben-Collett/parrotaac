import 'dart:io';

import 'package:parrotaac/backend/project/project_utils.dart';
import 'package:parrotaac/shared_providers/future_controller.dart';

final projectDirController = FutureController<Iterable<Directory>>(
  compute: projectDirs,
);
