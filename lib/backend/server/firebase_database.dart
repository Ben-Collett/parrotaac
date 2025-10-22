import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/server/login_utils.dart';
import 'package:parrotaac/backend/server/user.dart';

import 'firebase_constants.dart';

Future<http.Response> addUserToDatabase(User user) {
  return user.makeRequest((id) async {
    const collectionId = "users";

    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collectionId?documentId=${user.uid}',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $id',
      },
      body: jsonEncode({
        "fields": {
          "email": {"stringValue": user.email},
          "createdAt": {
            "timestampValue": DateTime.now().toUtc().toIso8601String(),
          },
        },
      }),
    );

    return response;
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
