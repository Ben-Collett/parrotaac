import 'dart:io';

bool get isComputer =>
    Platform.isLinux || Platform.isWindows || Platform.isMacOS;

bool get isMobile => Platform.isAndroid || Platform.isIOS || Platform.isFuchsia;
