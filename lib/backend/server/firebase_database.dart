import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/server/login_utils.dart';
import 'package:parrotaac/backend/server/user.dart';

void addUser(User user) {
  user.makeRequest((id) {
    throw UnimplementedError(); //TODO:
  });
}

void getCurrentUserData() async {
  currentUser.value?.makeRequest((id) {
    throw UnimplementedError(); //TODO:
  });
}

List<String> searchUsers(String search) {
  return [];
}

void updateProjectVersion(String projectId, String version) {}
String getProjectVersionOnSystem(ParrotProject project) {
  return "";
}

String getProjectVersion(String projectId) {
  return "";
}
