import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:parrotaac/backend/server/firebase_responses.dart';
import 'package:parrotaac/backend/server/user.dart';
import 'package:parrotaac/backend/simple_logger.dart';

import 'firebase_constants.dart';

class FirebaseAuthApi {
  /// Create a new user (sign up)
  static Future<User?> signUp(String email, String password) async {
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode == 200) {
      return User.fromLogin(
        CreateAccountResponse.fromJson(jsonDecode(response.body)),
      );
    } else {
      SimpleLogger().logError('Error: ${response.body}');
      return null;
    }
  }

  static Future<User?> signIn(String email, String password) async {
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode == 200) {
      LoginResponse loginResponse = SignInResponse.fromJson(
        jsonDecode(response.body),
      );
      return User.fromLogin(loginResponse);
    } else {
      SimpleLogger().logError('Error: ${response.body}');
      return null;
    }
  }
}
