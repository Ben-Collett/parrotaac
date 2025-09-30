import 'package:flutter/foundation.dart';
import 'package:parrotaac/backend/server/firebase_auth.dart';

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
