import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:parrotaac/backend/server/firebase_auth.dart';
import 'package:parrotaac/backend/server/firebase_database.dart';
import 'package:parrotaac/extensions/http_extensions.dart';

import 'user.dart';

final ValueNotifier<User?> currentUser = ValueNotifier(null);
bool _initialized = false;
Future<void> restoreUser() async {
  currentUser.value = await User.storedUser;
  if (!_initialized) {
    currentUser.addListener(() {
      currentUser.value?.updateStoredUser();
    });
    _initialized = true;
  }
}

Future<void> createAccountAndSignIn(String email, String password) async {
  User? user = await FirebaseAuthApi.signUp(email, password);

  if (user != null) {
    final http.Response response = await addUserToDatabase(user);
    assert(response.isSuccessfulResponse, """
      response was not valid for adding user to database
      response_header: ${response.headers}
      response_body: ${response.body}
      request_headers: ${response.request?.headers}
      request_url: ${response.request?.url}

      """);

    currentUser.value = user;
  }
}

Future<void> signIn(String email, String password) async {
  User? user = await FirebaseAuthApi.signIn(email, password);
  if (user != null) {
    currentUser.value = user;
  }
}

Future<void> logout() async {
  await currentUser.value?.logout();
  currentUser.value = null;
}
