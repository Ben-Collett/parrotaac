import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

Future<XFile?> getAudioFile() async {
  //TODO: this may cause problems on IOS and android may need to do a custom selection on those platforms
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: FileType.audio,
  );

  return result?.xFiles.firstOrNull;
}

Future<List<String>> getFilesPaths(List<String> extensions) async {
  //TODO: this only works with any on linux I can try using type:FileType.custom and allowedExtensions on other OS's
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
  );
  if (result != null) {
    return result.paths.nonNulls.toList();
  }
  return [];
}

Future<String?> getUserSelectedDirectory() async {
  String? result = await FilePicker.platform.getDirectoryPath(
    dialogTitle: "select folder to export to",
  );
  return result;
}
